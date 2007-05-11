
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

SKIP: {
eval{ require Jcode };
skip q{ Jcode module is not installed. } if $@;

my $v= Egg::Helper::VirtualTest->new( prepare => {
  controller=> { egg_includes=> [qw/ MailSend MailSend::Encode::ISO2022JP /] },
  config => {
    plugin_mailsend=> {
      handler  => 'CMD',
      cmd_path => '/usr/sbin/sendmail',
      default_from => 'dummy@dummy.domain',
      default_to   => 'dummy@dummy.domain',
      },
    },
  });

$v->disable_stderr;

ok my $e= $v->egg_context;
can_ok $e->{namespace}, 'mail_encode';
ok my $mail= $e->mail;
ok $mail->subject('メール送信テスト');
ok $mail->body('body');
ok my $body= $mail->_mime_body( $mail->to );
like $body, qr{\n?Content\-Type\:\s+text/plain\; +charset=\"ISO\-2022\-JP\"}s;
like $body, qr{\n?Content\-Transfer\-Encoding\:\s+7bit}s;
like $body, qr{\n?Subject\:\s+\=\?ISO\-2022\-JP\?}s;

  };

