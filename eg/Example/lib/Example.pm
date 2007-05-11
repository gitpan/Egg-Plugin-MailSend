package Example;
use strict;
use warnings;
use Egg qw/ -Debug
  MailSend
  MailSend::Encode::ISO2022JP
  Dispatch::Fast
  Debugging
  Log
  /;

our $VERSION= '0.01';

__PACKAGE__->egg_startup(

  title      => 'Example',
  root       => '/path/to/Example',
  static_uri => '/',
  dir => {
    lib      => '< $e.root >/lib',
    static   => '< $e.root >/htdocs',
    etc      => '< $e.root >/etc',
    cache    => '< $e.root >/cache',
    tmp      => '< $e.root >/tmp',
    template => '< $e.root >/root',
    comp     => '< $e.root >/comp',
    },
  template_path=> ['< $e.dir.template >', '< $e.dir.comp >'],

  plugin_mailsend => {
    handler             => 'SMTP',
    smtp_host           => '192.168.1.1',
    timeout             => 7,
    debug               => 0,
    default_subject     => 'mail subject.',
    default_from        => 'user@mydomain.name',
    default_to          => 'user@mydomain.name',
    default_reply_to    => 'user@mydomain.name',
    default_return_path => 'user@mydomain.name',
    },

  );

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(
  _default => sub {
    my($dispatch, $e)= @_;
    require Egg::Helper::BlankPage;
    $e->response->body( Egg::Helper::BlankPage->out($e) );
    },
  );
# ----------------------------------------------------------

1;
