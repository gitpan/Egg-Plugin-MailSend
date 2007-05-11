
use Test::More tests => 4;
BEGIN {
  use_ok('Egg::Plugin::MailSend');
  use_ok('Egg::Plugin::MailSend::SMTP');
  use_ok('Egg::Plugin::MailSend::CMD');
  use_ok('Egg::Plugin::MailSend::Encode::ISO2022JP');
  };
