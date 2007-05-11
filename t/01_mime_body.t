
use Test::More tests => 19;
use Egg::Helper::VirtualTest;

my $v= Egg::Helper::VirtualTest->new( prepare => {
  controller=> { egg_includes=> [qw/ MailSend /] },
  config => {
    plugin_mailsend=> {
      handler  => 'CMD',
      cmd_path => '/usr/sbin/sendmail',
      default_from => 'dummy@dummy.domain',
      },
    },
  });

$v->disable_stderr;

ok my $e= $v->egg_context;
ok my $mail= $e->mail;
isa_ok $mail, 'Egg::Plugin::MailSend::handler';
isa_ok $mail, 'Egg::Plugin::MailSend::CMD::handler';
can_ok $mail, qw/
  to from cc bcc reply_to return_path subject
  finish_code attach x_mailer include_headers
  body_header body_footer
  /;

ok $mail->from;
is $mail->from, 'dummy@dummy.domain';
ok $mail->to('dummy_to@dummy.domain');
ok $mail->subject('test-subject');
ok $mail->body('test-body');
ok $mail->body_header("TEST_HEADER\n\n");
ok $mail->body_footer("\n\nTEST_FOOTER");
ok my $body= $mail->_mime_body( $mail->to );
like $body, qr{\n?Content\-Type\:\s+text/plain};
like $body, qr{\n?MIME\-Version\:\s+[\d\.]+};
like $body, qr{\n?Subject\:\s+test\-subject};
like $body, qr{\n?To\:\s+[^\@]+\@[^\s\n]+};
like $body, qr{\n?From\:\s+[^\@]+\@[^\s\n]+};
like $body, qr{\n\n+TEST_HEADER\n+\ntest\-body\n+TEST_FOOTER};

