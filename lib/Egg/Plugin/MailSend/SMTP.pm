package Egg::Plugin::MailSend::SMTP;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: SMTP.pm 75 2007-03-26 12:14:47Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Plugin::MailSend/;

our $VERSION= '0.01';

sub __setup {
	my($class, $e, $conf)= @_;
	$conf->{smtp_host} ||= 'localhost';
	$conf->{timeout}   ||= 7;
}


package Egg::Plugin::MailSend::SMTP::handler;
use strict;
use Net::SMTP;
use base qw/Egg::Plugin::MailSend::handler/;

sub __send_mail {
	my($self) = @_;
	my $conf  = $self->config;
	my $finish= $self->finish || sub {};
	my $result;
	for my $to_addr (ref($self->to) eq 'ARRAY' ? @{$self->to}: $self->to) {
		my $from= $self->from || next;
		my $body= $self->__mime_body($to_addr);
		my $smtp= Net::SMTP->new(
		  $conf->{smtp_host},
		  Debug  => $conf->{debug},
		  Timeout=> $conf->{timeout},
		  ) || Egg::Error->throw(q{ Connection error. });
		$smtp->mail($from);
		$smtp->to($to_addr);
		$self->cc  and $smtp->cc ($self->cc);
		$self->bcc and $smtp->bcc($self->bcc);
		$smtp->data();
		$smtp->datasend($body);
		$smtp->dataend();
		$smtp->quit();
		$self->e->debug_out("# + mailsend : to($to_addr), from($from)");
		$finish->($self->e, $self, $to_addr, \$body);
		++$result;
	}
	$result || 0;
}

1;

__END__

=head1 NAME

Egg::Plugin::MailSend::SMTP - Mail is transmitted by using Net::SMTP.

=head1 SYNOPSIS

Controller.

  use Egg qw/ MailSend /;

Configuration.

  plugin_mailsend=> {
    handler   => 'SMTP',
    debug     => 1,
    smtp_host => '192.168.0.25',
    timeout   => 7,
    ...
    .....
    },

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Plugin::MailSend>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
