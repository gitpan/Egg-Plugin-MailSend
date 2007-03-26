package Egg::Plugin::MailSend::CMD;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CMD.pm 75 2007-03-26 12:14:47Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use base qw/Egg::Plugin::MailSend/;

sub __setup {
	my($class, $e, $conf)= @_;
	$conf->{cmd_path} ||= do {
		File::Which->require;
		File::Which::which('sendmail')
		  || Egg::Error->throw(q{ I want setup config 'cmd_path' });
	  };
	$conf->{cmd_option} ||= '-t';
}


package Egg::Plugin::MailSend::CMD::handler;
use strict;
use Email::Valid;
use base qw/Egg::Plugin::MailSend::handler/;

sub __send_mail {
	my($self) = @_;
	my $conf  = $self->config;
	my $finish= $self->finish || sub {};
	my $from  = $self->from || 'dummy@mail.domain';
	my $result;
	for my $to_addr (ref($self->to) eq 'ARRAY' ? @{$self->to}: $self->to) {
		Email::Valid->address($to_addr) || next;
		my $cmd_line= "$conf->{cmd_path} $conf->{cmd_option} $to_addr";
		my $body= $self->__mime_body($to_addr);
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

1;

__END__

=head1 NAME

Egg::Plugin::MailSend::CMD - Mail Sending by the Mail delivery command is done.

=head1 SYNOPSIS

Controller.

  use Egg qw/ MailSend /;

Configuration.

  plugin_mailsend=> {
    handler    => 'CMD',
    debug      => 1,
    cmd_path   => '/usr/sbin/sendmail',
    cmd_option => '-t',
    ...
    .....
    },

  # When debug is effective, mail is not transmitted.
  # Because the content of mail is output to the log, it becomes it.

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
