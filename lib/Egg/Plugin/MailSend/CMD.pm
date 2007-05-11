package Egg::Plugin::MailSend::CMD;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CMD.pm 130 2007-05-11 00:53:45Z lushe $
#

=head1 NAME

Egg::Plugin::MailSend - It delivers by E-mail by the command.

=head1 SYNOPSIS

  use Egg qw/ MailSend /;
  
  __PACKAGE__->egg_startup(
    .....
    ...
    plugin_mailsend => {
      handler    => 'CMD',
      cmd_path   => '/usr/sbin/sendmail',
      cmd_option => '-t',
      debug      => 0,
      },
    );

  $e->mail->send( to=> '...' );

=head1 DESCRIPTION

It is a subclass for L<Egg::Plugin::MailSend > for use and the E-mail 
delivery of the mail command.

Please set PATH of the mail command by 'cmd_path'.
The acquisition of PATH of 'Sendmail' command is tried by L<File::Which>
when omitted.

Please set the option to pass to the mail command by 'cmd_option'.
Default is '-t'.

Please refer to the document of L<Egg::Plugin::MailSend>.

=cut
use strict;
use warnings;
use base qw/Egg::Plugin::MailSend/;

our $VERSION = '2.00';

package Egg::Plugin::MailSend::CMD::handler;
use strict;
use Email::Valid;
use base qw/Egg::Plugin::MailSend::handler/;

sub __setup {
	my($class, $e, $conf)= @_;
	$conf->{cmd_path} ||= do {
		require File::Which;
		File::Which::which('sendmail')
		      || die q{ I want setup config 'cmd_path' };
	  };
	$conf->{cmd_option} ||= '-t';
	$class->SUPER::__setup($e, $conf);
}
sub __send_mail {
	my($self) = @_;
	my $conf  = $self->config;
	my $finish= $self->finish_code || sub {};
	my $from  = $self->from || die q{ I want from address. };
	my $result;
	for my $to_addr (ref($self->to) eq 'ARRAY' ? @{$self->to}: $self->to) {
		Email::Valid->address($to_addr) || next;
		my $cmd_line= "$conf->{cmd_path} $conf->{cmd_option} $to_addr";
		my $body= $self->_mime_body($to_addr);
		$self->e->debug_out("# + mailsend : to($to_addr), from($from)");
		if ($conf->{debug}) {
			$self->e->debug_out($body);
		} else {
			open  MSEND, "| $cmd_line";  ## no critic
			print MSEND $body;
			close MSEND;
		}
		$finish->($self->e, $self, $to_addr, \$body);
		++$result;
	}
	$result || 0;
}

=head1 SEE ALSO

L<Email::Valid>,
L<File::Which>,
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
