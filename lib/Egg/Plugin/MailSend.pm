package Egg::Plugin::MailSend;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: MailSend.pm 130 2007-05-11 00:53:45Z lushe $
#

=head1 NAME

Egg::Plugin::MailSend - Mail is delivered for Egg Plugin.

=head1 SYNOPSIS

  use Egg qw/ MailSend /;
  
  __PACKAGE__->egg_startup(
    .....
    ...
    plugin_mailsend => {
      default_from    => 'user@mydomain.name',
      default_subject => 'mail subject.',
      handler         => 'SMTP',
      smtp_host       => '192.168.1.1',
      timeout         => 7,
      debug           => 0,
      },
    );

  # Mail is transmitted.
  $e->mail->send(
    to      => 'hoge@mail.address',
    subject => 'Mail subject.',
    body    => 'Mail body',
    ) || return q{ Fails in transmission of mail. };
  
  # The same mail is transmitted to two or more addresses.
  $e->mail->send(
    to      => [qw/ hoge@mail.address foo@address /],
    subject => 'Mail subject.',
    body    => 'Mail body',
    ) || return q{ Fails in transmission of mail. };
  
  # ARRAY is passed to the content of mail.
  $e->mail->send(
    to      => [qw/ hoge@mail.address foo@address /],
    subject => 'Mail subject.',
    body    => [ $mail_header, $mail_body, $mail_footer ],
    );
  
  # CODE is passed to the content of mail.
  $e->mail->send(
    to      => [qw/ hoge@mail.address foo@address /],
    subject => 'Mail subject.',
    body    => sub {
      my($mail, $e, $to)= @_;
      my $body= ... create mail body code.
      \$body;
      },
    );
  
  # The code that wants to be executed after it delivers by E-mail each is set.
  my $mail= $e->mail;
  $mail->finish_code( sub {
    my($mail, $e, $to_addr, $body_scalar_ref)= @_;
    .... code ...
    } );
  
  $mail->send(
    to=> [qw/ hoge@mail.address foo@address boo@oo.jp /],
    .....
    ...
    );
  
  # The setting of default is temporarily changed.
  $e->mail(
    default_reply_to    => 'addr1@hhh.bo, addr2@dddd.hh',
    default_return_path => 'admin@support.gg',
    )->send(
    to => 'hoge@mail.address',
    .....
    ...
    );


=head1 DESCRIPTION

It is a plugin for E-mail delivery.

=head1 CONFIGURATION

Please set it to 'plugin_mailsend' with HASH.

=head2 handler

Name of module that becomes handler object.

  # If Egg::Plugin::MailSend::SMTP is used, it is the following.
  handler => 'SMPT',

It treats assuming that 'CMD' is specified when omitting it.

=head2 debug

Debug mode.

* The behavior of debug mode changes by the handler object.

=head2 default_from

Address used when from address is omitted.

=head2 default_to

Address used when to address is omitted.

=head2 default_subject

Subject used when subject is omitted.

=head2 default_body_header

Header buried under content of mail without fail.

=head2 default_body_footer

Footer buried under content of mail without fail.

=head2 default_return_path

Error mail destination address of transmission failure.

=head2 default_reply_to

Address set to Reply_to.

=head2 default_cc

Address set to Cc header.

=head2 default_bcc

Address set to Bcc header.

=head2 include_headers

To add an original mail header, it sets it by the HASH reference.

=cut
use strict;
use warnings;

our $VERSION = '2.00';

=head1 METHODS

=cut

sub _setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_mailsend} ||= {};
	$conf->{default_from} || die q{ I want setup config 'default_from'. };
	$conf->{default_subject} ||= 'Mail Subject.';
	$conf->{x_mailer} ||= __PACKAGE__. " v$VERSION";
	$conf->{handler}  ||= 'CMD';
	$conf->{debug}    ||= 0;

	my $pkg= __PACKAGE__."::$conf->{handler}";
	$pkg->require or die $@;
	$pkg.= '::handler';
	$pkg->__setup($e, $conf);
	no warnings 'redefine';
	*_create_mail= sub { $pkg->new(@_) };

	$e->next::method;
}

=head2 mail ( [SETUP_HASH] )

The handler object to do Mail Sending is returned.

If SETUP_HASH is specified, the setting of default is overwrited.

It tries to generate the object newly annulling the object before when
SETUP_HASH is given though the same object uses and it is turned from now
on when called once usually.

=cut
sub mail {
	my $e= shift;
	return ($e->{plugin_mailsend} ||= $e->_create_mail) unless @_;
	$e->{plugin_mailsend}= $e->_create_mail(@_);
}

=head2 mail_encode

This method is called so that the handler object may make the chance of the 
adjustment of the content of mail.

It passes by the method of default usually. Please do this method in override 
as a controller etc. if you want to do something by this method.

For instance, the text is JIS code in the mail of Japan, and it is hoped to 
add some headers in addition. This method is used to solve it.

Please refer to the document of L<Egg::Plugin::MailSend::ISO2022JP>.

=cut
sub mail_encode {
	my($e, $mail, $body)= @_;
	($mail->subject, $body, {});
}

package Egg::Plugin::MailSend::handler;
use strict;
use warnings;
use MIME::Entity;
use base qw/Egg::Base/;
use Carp qw/croak/;

=head2 HANDLER METHODS

The module for the handler
L<Egg::Plugin::MailSend::CMD>,
L<Egg::Plugin::MailSend::SMTP>,
It drinks and 2 kinds are prepared.

Please refer to that document.

=cut

my @Names=
  qw/to from cc bcc reply_to return_path subject body_header body_footer/;

sub __setup {
	my($class, $e, $conf)= @_;
	$class->config($conf);
	@_;
}

=head2 new

Constructor for handler.

=cut
sub new {
	my($class, $e)= splice @_, 0, 2;
	$class->SUPER::new( $e, $class->_default_setup($e, @_) );
}

=head2 reset ( [SETUP_HASH] )

The setting is initialized. SETUP_HASH overwrites the setting.

=cut
sub reset {
	my $self= shift;
	$self->params( $self->_default_setup($self->e, @_) );
}

=head2 send ( [PARAM_HASH] )

Mail is transmitted, and the frequency that succeeds in the transmission is 
returned.

  $e->mail->send(
    to => 'gooo@mail.address',
    .....
    ...
    );

=cut
sub send {
	my $self = shift;
	my %param= ( %{$self->params}, %{ $_[1] ? {@_}: ($_[0] || {}) } );
	if ($param{to}) {
		$self->to($param{to});
	} else {
		$self->to || croak q{ I want the to address. };
	}
	for my $method (qw{ body include_headers }, @Names[1..$#Names]) {
		$self->$method($param{$method}) if $param{$method};
	}
	$self->__send_mail;
}

=head2 body ( [MAIL_BODY] )

The content of mail can be registered beforehand.

Please give MAIL_BODY SCALAR or ARRAY.

=cut
sub body {
	my $self= shift;
	return $self->params->{body} unless @_;
	$self->params->{body}=
	   (ref($_[0]) eq 'CODE' or ref($_[0]) eq 'ARRAY') ? $_[0]
	  : ref($_[0]) eq 'SCALAR' ? [${$_[0]}]: [$_[0]];
}

=head2 to ( [TO_ADDR] )

The destination of mail can be registered beforehand.

Please give TO_ADDR SCALAR or ARRAY.

=head2 from ( [FROM_ADDR] )

The transmission origin of mail can be registered beforehand.

Please give FROM_ADDR with SCALAR.

=head2 cc ( [CC_ADDR] )

The Cc address can be registered beforehand.

Please give it by the character string of ',' delimitation when you specify
two or more addresses.

=head2 bcc ( [BCC_ADDR] )

The Bcc address can be registered beforehand.

Please give it by the character string of ',' delimitation when you specify
two or more addresses.

=head2 reply_to ( [REPLY_ADDR] )

The address can be registered beforehand the reply ahead.

=head2 return_path ( [RETURN_ADDR] )

It can register replying ahead of the error mail beforehand.

=head2 subject ( [SUBJECT_STRING] )

The subject of mail can be registered beforehand.

=head2 body_header ( [HEADER_TEXT] )

The header buried under the content of mail can be registered beforehand.

=head2 body_footer ( [FOOTER_TEXT] )

The footer buried under the content of mail can be registered beforehand.

=cut
{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for my $accessor
	(qw/finish_code attach x_mailer include_headers/, @Names) {
		*{__PACKAGE__."::$accessor"}= sub {
			my $self= shift;
			return @_ ? do { $self->params->{$accessor}= shift }
			          : do { $self->params->{$accessor} || ""  };
		  };
	}
  };

sub _default_setup {
	my($self, $e)= splice @_, 0, 2;
	my %param= ( %{$self->config}, %{ $_[1] ? {@_}: ($_[0] || {}) } );
	$param{$_} ||= $param{"default_$_"} || "" for @Names;
	\%param;
}
sub _mime_body {
	my $self= shift;
	my $to= shift || croak q{ To address is not specified. };

	my $mime;
	{
		my %option;
		{
			my $e= $self->e;
			my($subject, $body, $headers);
			{
				my $tmp= $self->body || croak q{ I want set 'mail body'. };
				$body= ref($tmp) eq 'CODE' ? do {
					my $scalar= $tmp->($self, $e, $to)
					         || die q{ Mail body doesn't return. };
					[ ref($scalar) ? $$scalar: $scalar ];
				  }: $tmp;
				unshift @$body, $self->body_header if $self->body_header;
				push    @$body, $self->body_footer if $self->body_footer;
			  };
			($subject, $body, $headers)= $e->mail_encode($self, $body, {});
			$headers ||= {};
			%option= ( To=> $to, Subject=> $subject, Data=> $body );
			while (my($key, $value)= each %$headers) { $option{$key}= $value }
		  };
		if (my $hash= $self->include_headers) {
			while (my($key, $value)= each %$hash) { $option{$key} ||= $value }
		}
		for my $key ('x_mailer', @Names[1..5]) {
			my $name= ucfirst($key);
			   $name=~s{_([a-z])} ['-'.ucfirst($1)]e;
			$option{$name}= $self->$key || next;
		}
		$mime= MIME::Entity->build(%option);
	  };

	if (my $attach= $self->attach) {
		if (ref($attach) eq 'HASH') {
			eval{ $mime->attach(%$attach) };
			$@ and die $@;
		} elsif (ref($attach) eq 'ARRAY') {
			for my $hash (@{$self->attach}) {
				eval{ $mime->attach(%$hash) };
				$@ and die $@;
			}
		}
	}
	$mime->stringify; ##. "\n.\n";
}

=head1 SEE ALSO

L<MIME::Entity>,
L<Egg::Plugin::MailSend::CMD>,
L<Egg::Plugin::MailSend::SMTP>,
L<Egg::Plugin::MailSend::Encode::ISO2022JP>,
L<Egg::Base>,
L<Egg::Release>,


=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>


=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
