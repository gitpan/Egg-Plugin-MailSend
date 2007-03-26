package Egg::Plugin::MailSend::ISO2022JP;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ISO2022JP.pm 75 2007-03-26 12:14:47Z lushe $
#
use strict;
use Jcode;

our $VERSION= '0.01';

sub setup {
	my($e)= @_;
	$e->isa('Egg::Plugin::MailSend')
	  || Egg::Error->throw(qq{ I want build in 'Egg::Plugin::MailSend'. });
	no strict 'refs';  ## no critic
	no warnings 'redefine';

	*{"Egg::Plugin::MailSend::mail_encode"}= sub {
		my($egg, $mail, $body)= @_;
		$_= Jcode->new(\$_)->iso_2022_jp for @$body;
		return (
		  Jcode->new($mail->subject)->mime_encode,
		  $body, { Encoding => '7bit', Charset=> 'ISO-2022-JP' },
		  );
	  };

	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::MailSend::ISO2022JP - Peculiar processing to Japanese mail is done.

=head1 SYNOPSIS

Controller

  use Egg qw/ MailSend MailSend::ISO2022JP /;

=head1 METHODS

=over 4

=item setup

Mail_encode of Egg::Plugin::MailSend is overwrited.

Please refer to the source code for details for the content of processing.

=back

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
