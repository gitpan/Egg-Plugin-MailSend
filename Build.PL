use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Plugin::MailSend',
  dist_version_from => 'lib/Egg/Plugin/MailSend.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {
    'Egg::Release'         => 1.2001,
    'Email::Valid'         => 0,
    'File::Which'          => 0,
    'Jcode'                => 0,
    'MIME::Entity'         => 5.42,
    'Net::SMTP'            => 2.30,
    'UNIVERSAL::require'   => 0,
    'Test::More'           => 0,
    'Test::Pod'            => 0,
#    'Test::Perl::Critic'  => 0,
#    'Test::Pod::Coverage' => 0,
    },

  );

$builder->create_build_script();
