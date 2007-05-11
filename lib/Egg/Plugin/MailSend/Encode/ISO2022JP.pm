package Egg::Plugin::MailSend::Encode::ISO2022JP;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ISO2022JP.pm 130 2007-05-11 00:53:45Z lushe $
#

=head1 NAME

Egg::Plugin::MailSend::Encode::ISO2022JP - Plugin that does peculiar processing to Japan to mail.

=head1 SYNOPSIS

  use Egg qw/ MailSend MailSend::Encode::ISO2022JP /;
  
  __PACKAGE__->egg_startup(
    .....
    ...
    );

=head1 DESCRIPTION

It is a plugin to give peculiar processing to Japanese mail.

This plug-in generates 'Mail_encode' method to the controller of the project.

Please refer to the document of L<Egg::Plugin::MailSend>.

=cut
use strict;
use warnings;
use Jcode;

our $VERSION= '2.00';

sub _setup {
	my($e)= @_;
	$e->isa('Egg::Plugin::MailSend')
	   || die q{ I want build in 'Egg::Plugin::MailSend'. };

	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"$e->{namespace}::mail_encode"}= sub {
		my($egg, $mail, $body)= @_;
		$_= Jcode->new(\$_)->iso_2022_jp for @$body;
		return (
		  Jcode->new($mail->subject)->mime_encode, $body,
		  { Encoding => '7bit', Charset=> 'ISO-2022-JP' },
		  );
	  };

	$e->next::method;
}

=head1 SEE ALSO

L<Egg::Plugin::MailSend>,
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
