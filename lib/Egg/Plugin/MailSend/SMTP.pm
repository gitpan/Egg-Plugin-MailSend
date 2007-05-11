package Egg::Plugin::MailSend::SMTP;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: SMTP.pm 130 2007-05-11 00:53:45Z lushe $
#

=head1 NAME

Egg::Plugin::MailSend::SMTP - Mail is delivered by Net::SMTP.

=head1 SYNOPSIS

  use Egg qw/ MailSend /;
  
  __PACKAGE__->egg_startup(
    .....
    ...
    plugin_mailsend => {
      handler    => 'SMTP',
      smtp_host  => '192.168.1.1',
      timeout    => 7,
      debug      => 0,
      },
    );

  $e->mail->send( to=> '...' );

=head1 DESCRIPTION

It is a subclass for L<Egg::Plugin::MailSend> for E-mail delivery by using 
L<Net::SMTP>.

Please set the address of the SMTP server to 'smtp_host'.
Default is 'localhost'.

Please set the number of seconds until connected time-out of the SMTP server to
'Timeout'. Default is '7'.

Please refer to the document of L<Egg::Plugin::MailSend>.

=cut
use strict;
use warnings;
use base qw/Egg::Plugin::MailSend/;

our $VERSION= '2.00';

package Egg::Plugin::MailSend::SMTP::handler;
use strict;
use Net::SMTP;
use base qw/Egg::Plugin::MailSend::handler/;

sub __setup {
	my($class, $e, $conf)= @_;
	$conf->{smtp_host} ||= 'localhost';
	$conf->{timeout}   ||= 7;
	$class->SUPER::__setup($e, $conf);
}
sub __send_mail {
	my($self) = @_;
	my $conf  = $self->config;
	my $finish= $self->finish_code || sub {};
	my $from  = $self->from || die q{ I want from address. };
	my $result;
	for my $to_addr (ref($self->to) eq 'ARRAY' ? @{$self->to}: $self->to) {
		my $body= $self->_mime_body($to_addr);
		my $smtp= Net::SMTP->new(
		  $conf->{smtp_host},
		  Debug  => $conf->{debug},
		  Timeout=> $conf->{timeout},
		  ) || die qq{ '$conf->{smtp_host}' Connection error. };
		$smtp->mail($from);
		$smtp->to($to_addr);
		$self->cc  and $smtp->cc ($self->cc);
		$self->bcc and $smtp->bcc($self->bcc);
		$smtp->data();
		$smtp->datasend($body);
		$smtp->dataend();
		$smtp->quit();
		$self->e->debug_out("# + mailsend : to($to_addr), from($from)");
		$finish->($self, $self->e, $to_addr, \$body);
		++$result;
	}
	$result || 0;
}

=head1 SEE ALSO

L<Egg::Net::SMTP>,
L<Egg::Plugin::MailSend>,
L<Egg::Plugin::MailSend::Encode::ISO2022JP>,
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
