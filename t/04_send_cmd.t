
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;
use File::Which;

SKIP: {
skip q{ Neither 'EGG_TO_ADDR' nor 'EGG_FROM_ADDR' of the environment variable are set. }
     if (! $ENV{EGG_TO_ADDR} or ! $ENV{EGG_FROM_ADDR});

my $cmd= which('sendmail') || skip q{ PATH of 'sendmail' command is not obtained. };

my $v= Egg::Helper::VirtualTest->new( prepare => {
  controller=> { egg_includes=> [qw/ MailSend /] },
  config => {
    plugin_mailsend=> {
      handler  => 'CMD',
      cmd_path => $cmd,
      default_from => $ENV{EGG_FROM_ADDR},
      default_to   => $ENV{EGG_TO_ADDR},
      },
    },
  });

$v->disable_stderr;

ok my $e= $v->egg_context;
ok $e->mail->send( body => 'mail_cmd_test' );

  };
