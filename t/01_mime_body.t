
use Test::More tests => 15;
use lib qw{ . ./t };
use File::Which;
{
  $ENV{EGG_TEST_MAIL_TO}   ||= 'mizuno@bomcity.com';
  $ENV{EGG_TEST_MAIL_FROM} ||= '';
  };
require 'test_mailsend.pl';

SKIP: {
	skip q{ Mail delivery command is not found. } unless which('sendmail');

ok my $e= prepare()->egg_virtual;
isa_ok $e, 'Egg::Plugin::MailSend';
ok my $mail= $e->mail;
isa_ok $mail, 'Egg::Plugin::MailSend::handler';
can_ok $mail, qw{ to from cc bcc reply_to return_path subject
  body_header body_footer finish attach x_mailer include_headers };
ok $mail->subject('test-subject');
ok $mail->body('test-body');
ok my $body= $mail->__mime_body( $mail->to );
like $body, qr{\n?Content\-Type\:\s+text/plain};
like $body, qr{\n?MIME\-Version\:\s+[\d\.]+};
like $body, qr{\n?Subject\:\s+test\-subject};
like $body, qr{\n?To\:\s+[^\@]+\@[^\s\n]+};
like $body, qr{\n?From\:\s+[^\@]+\@[^\s\n]+};
like $body, qr{\n\n+TEST_HEADER\n+\-+\ntest\-body\n\-+\nTEST_FOOTER};
ok $e->mail->send;

  };

