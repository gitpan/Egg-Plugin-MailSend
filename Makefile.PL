use inc::Module::Install;

name         'Egg-Plugin-MailSend';
all_from     'lib/Egg/Plugin/MailSend.pm';
version_from 'lib/Egg/Plugin/MailSend.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release' => 1.2001;
requires 'Email::Valid';
requires 'File::Which';
requires 'Jcode';
requires 'MIME::Entity' => 5.42;
requires 'Net::SMTP'    => 2.30;
requires 'UNIVERSAL::require';

build_requires 'Test::More';
build_requires 'Test::Pod';
# build_requires 'Test::Perl::Critic';
# build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
