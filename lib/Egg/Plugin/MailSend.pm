package Egg::Plugin::MailSend;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: MailSend.pm 76 2007-03-26 13:01:19Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.03';

sub setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_mailsend} ||= {};
	$conf->{default_from} || die q{ I want setup config 'default_from'. };
	$conf->{default_subject} ||= 'Mail Subject.';
	$conf->{x_mailer} ||= __PACKAGE__. " v$VERSION";
	$conf->{handler}  ||= 'CMD';
	$conf->{debug}    ||= 0;
	my $pkg= __PACKAGE__."::$conf->{handler}";
	$pkg->require or die $@;
	$pkg->__setup($e, $conf);
	$e->next::method;
}
sub mail {
	$_[0]->{plugin_mailsend} ||= do {
		my $e= shift;
		my $pkg= __PACKAGE__. '::'
		       . $e->config->{plugin_mailsend}{handler}. '::handler';
		$pkg->new($e, @_);
	  };
}
sub mail_encode {
	my($e, $mail, $body)= @_;
	($mail->subject, $body, {});
}

package Egg::Plugin::MailSend::handler;
use strict;
use warnings;
use MIME::Entity;
use base qw/Egg::Component/;

__PACKAGE__->mk_accessors(qw/errstr/);

my @Names=
  qw/to from cc bcc reply_to return_path subject body_header body_footer/;

{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for my $accessor (qw/finish attach x_mailer include_headers/, @Names) {
		*{__PACKAGE__."::$accessor"}= sub {
			my $self= shift;
			return @_ ? do { $self->params->{$accessor}= shift }
			          : do { $self->params->{$accessor}  || "" };
		  };
	}
  };

sub new {
	my($class, $e)= splice @_, 0, 2;
	$class->SUPER::new( $e,
	  $e->config->{plugin_mailsend},
	  $class->__default_setup($e, @_),
	  );
}
sub reset {
	my $self= shift;
	$self->params( $self->__default_setup($self->e, @_) );
}
sub __default_setup {
	my($self, $e)= splice @_, 0, 2;
	my $param= $_[0] ? (ref($_[0]) eq 'HASH' ? $_[0]: {@_}): {};
	my $conf = $e->config->{plugin_mailsend};
	$param->{$_} ||= $conf->{"default_$_"} || "" for @Names;
	$param->{$_} ||= $conf->{$_} for qw{ x_mailer include_headers };
	$param;
}
sub send {
	my $self= shift;
	my $args= $_[0] ? (ref($_[0]) eq 'HASH' ? $_[0]: {@_}): {};
	if ($args->{to}) {
		$self->to($args->{to});
	} else {
		$self->to || Egg::Error->throw(q{ I want the to address. });
	}
	for my $method (qw{ body include_headers }, @Names[1..$#Names]) {
		$self->$method($args->{$method}) if $args->{$method};
	}
	$self->__send_mail;
}
sub body {
	my $self= shift;
	return $self->params->{body} unless @_;
	my $body= $_[1] ? [@_]: $_[0];
	$self->params->{body}= ref($body) ? $body: \$body;
}
sub __mime_body {
	my $self= shift;
	my $to= shift || Egg::Error->throw(q{ To address is not specified. });

	my $mime;
	{
		my %option;
		{
			my $e= $self->e;
			my($subject, $body, $headers);
			{
				my $tmp= $self->body
				  || Egg::Error->throw(q{ I want set 'mail body'. });
				if (ref($tmp) eq 'CODE') {
					my $scalar= $tmp->($e, $self, $to);
					$body= [$scalar];
				} else {
					$body= ref($tmp) eq 'ARRAY' ? $tmp: [$$tmp];
				}
			  };
			unshift @$body, $self->body_header if $self->body_header;
			push    @$body, $self->body_footer if $self->body_footer;
			($subject, $body, $headers)= $e->mail_encode($self, $body, {});
			$headers ||= {};
			%option= ( To=> $to, Subject=> $subject, Data=> $body );
			while (my($key, $value)= each %$headers) { $option{$key}= $value }
		  };
		if (my $hash= $self->include_headers) {
			while (my($key, $value)= each %$hash) { $option{$key} ||= $value }
		}
		for my $key ('x_mailer', @Names[1..5]) {
			my $name= ucfirst($key);  $name=~s{_([a-z])} ['-'.ucfirst($1)]e;
			$option{$name}= $self->$key || next;
		}
		$mime= MIME::Entity->build(%option);
	  };

	if (my $attach= $self->attach) {
		if (ref($attach) eq 'HASH') {
			eval{ $mime->attach(%$attach) };
			$@ and Egg::Error->throw($@);
		} elsif (ref($attach) eq 'ARRAY') {
			for my $hash (@{$self->attach}) {
				eval{ $mime->attach(%$hash) };
				$@ and Egg::Error->throw($@);
			}
		}
	}
	$mime->stringify; ##. "\n.\n";
}

1;

__END__

=head1 NAME

Egg::Plugin::MailSend - Plugin that offers mail delivery function for Egg.

=head1 SYNOPSIS

Controller.

  use Egg qw/ MailSend /;

Configuration.

  plugin_mailsend=> {
    handler         => 'SMTP',
    debug           => 1,
    smtp_host       => 'localhost',
    default_from    => 'WEB-Master <master@domain.name>',
    default_subject => 'WEB-Mailer.',
    },

Example of code.

  my $success= $e->mail->send(
    to=> [qw{ adder_1_@domain.name adder_2_@domain.name }],
    subject  => 'Mail subject.',
    body     => 'Mail body',
    );
  
  if ($success) {
    print "Mail was transmitted.";
  } else {
    print "Failed in the transmission of mail !!";
  }

=head1 CONFIGURATION

=head2 handler

Module name used for mail delivery.

Please set the name since Egg::Plugin::MailSend.

Default is 'CMD'.

=head2 debug

It is a flag for debug mode.

=head2 default_from

Addressor address used by default. * Indispensability.

=head2 default_to

Destination address used by default.

Two or more destinations can be set by setting it by the array reference.

=head2 default_subject

Subject of mail used by default.

=head2 default_body_header

Header of content of mail used by default.

=head2 default_body_footer

Footer of content of mail used by default.

=head2 default_return_path

Address reply error's occurring using it by default ahead.

=head2 default_reply_to

Reply_to address used by default.

=head2 default_cc

Cc address used by default.

=head2 default_bcc

Bcc address used by default.

=head2 include_headers

Additional header that wants to be inserted in header of mail.

Please set it by the HASH reference.

=head2 x_mailer

Mail delivery application name.

=head1 METHODS

=head2 my $mail= $e-E<gt>mail

The object of the module set with handler is returned.

The argument is passed and it is setting revokable.

  my $mail= $e->mail(
    default_from=> 'custom@domain.name',
    default_body_header=> "mail-header \n\n",
    default_body_footer=> "\n\n mail-footer",
    );

=head2 $mail->send ([PARAM])

The value of the default of Configuration can be overwrited by passing the 
parameter.

The following keys can be used for the parameter.

=over 4

=item to, from, cc, bcc, reply_to, return_path, subject, body_header, body_footer, body, attach, include_headers, x_mailer 

=back

  $mail->send(
    to    => 'foo@domain.name',
    cc    => [qw{ hoge@domain.name zoo@domain.name }],
    body  => 'Mail body.',
    return_path => 'error@domain.name',
    );

The value of body is used as a content of mail.
* You may pass it by the ARRAY reference and the CODE reference.

The chance to make the content of mail of each destination dynamically can 
be done by setting the CODE reference in the content of mail.

  my $count;
  my $mailbody= sub {
    my($e, $mail, $to_addr)= @_;
    ++$count;
    $mail->subject("Mail No: $count");
    <<END_BODY
  Mail No: $count
  -------------------------------
  ... ban, bo, bo, bon.
  END_BODY
    };
  
  $mail->send(
    to   => [qw{ a1@domail.name a2@domail.name a3@domail.name }],
    body => $mailbody,
    );

=head2 $mail->finish ([CODE_REF])

To do some processing after Mail Sending, the CODE reference is defined beforehand.

* Finish of each To address is called.

  my $mail= $e->mail;
  my @mailsend;
  $mail->finish( sub {
    my($e, $mail, $to_addr, $mail_body)= @_;
    push @mailsend, [$to_addr, $mail_body];
    } );
  my $mail->send(
    to=> [qw{ a1@domail.name a2@domail.name a3@domail.name }],
    body => $mailbody,
    );
  for (@mailsend) {
    $e->model->create({
      to_addr   => $_->[0],
      mail_body => ${$_->[1]},
      });
  }

=head2 mail_encode

The controller etc. can overwrite this method, and to do peculiar processing
to making mime body of mail, processing be added.

  package MYPROJECT;
  ..
  ..
  sub mail_encode {
    my($e, $mail, $body)= @_;
    ...
    for (@$body) {  ## $body の値は必ず ARRAY リファレンス
      ....
    }
    return ( $mail->subject, $body, { 'X-Custum-Header'=> 'banban.' } );
  }

* L<Egg::Plugin::MailSend::ISO2022JP> for Japanese Mail Sending is enclosed.
  Please see and that document.

=head2 reset

The set parameter has already been initialized.

=head2 setup

For start preparation of project.
Do not call it from the application.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Plugin::CMD>,
L<Egg::Plugin::SMTP>,
L<Egg::Plugin::ISO2022JP>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
