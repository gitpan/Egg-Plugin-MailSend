
use Test::More tests=> 8;
use lib qw{ . ./t };
use File::Which;
eval "use Jcode";
plan skip_all => "Jcode required for Japanese character encoder." if $@;
{
  $ENV{EGG_TEST_MAIL_TO}   = '';
  $ENV{EGG_TEST_MAIL_FROM} = '';
  };
require 'test_mailsend.pl';

SKIP: {
	skip q{ Mail delivery command is not found. } unless which('sendmail');

ok my $e= prepare
  ({ egg=> [qw{ MailSend MailSend::ISO2022JP }] })->egg_virtual;
isa_ok $e, 'Egg::Plugin::MailSend::ISO2022JP';
ok my $mail= $e->mail;
ok $mail->subject('test-subject');
ok $mail->body('test-body');
ok my $body= $mail->__mime_body( $mail->to );
like $body, qr{\n?Content\-Type\:\s+text/plain\;\s+charset=\"ISO\-2022\-JP\"};
like $body, qr{\n?Content\-Transfer\-Encoding\:\s+7bit};

  };
