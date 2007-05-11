use inc::Module::Install;

name         'Egg-Plugin-MailSend';
all_from     'lib/Egg/Plugin/MailSend.pm';
version_from 'lib/Egg/Plugin/MailSend.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release' => 2.00;
requires 'Email::Valid' => 0.17;
requires 'File::Which'  => 0.05;
requires 'Jcode'        => 2.06;
requires 'MIME::Entity' => 5.42;
requires 'Net::SMTP'    => 2.30;

build_requires 'Test::Simple';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
