
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

SKIP: {
skip q{ Neither 'EGG_TO_ADDR' nor 'EGG_FROM_ADDR' of the environment variable are set. }
     if (! $ENV{EGG_TO_ADDR} or ! $ENV{EGG_FROM_ADDR});

skip q{ 'EGG_SMTP_HOST' of the environment variable is not set. }
     if (! $ENV{EGG_SMTP_HOST});

my $v= Egg::Helper::VirtualTest->new( prepare => {
  controller=> { egg_includes=> [qw/ MailSend /] },
  config => {
    plugin_mailsend=> {
      handler      => 'SMTP',
      smtp_host    => $ENV{EGG_SMTP_HOST},
      default_from => $ENV{EGG_FROM_ADDR},
      default_to   => $ENV{EGG_TO_ADDR},
      },
    },
  });

$v->disable_stderr;

ok my $e= $v->egg_context;
ok $e->mail->send( body => 'mail_smtp_test' );

  };
