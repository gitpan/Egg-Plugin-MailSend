use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Plugin::MailSend',
  dist_version_from => 'lib/Egg/Plugin/MailSend.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {
    'Egg::Release' => 2.00,
    'Email::Valid' => 0.17,
    'File::Which'  => 0.05,
    'Jcode'        => 2.06,
    'MIME::Entity' => 5.42,
    'Net::SMTP'    => 2.30,

    'Test::Simple'          => 0,
    'Test::Pod'             => 0,
    'Test::Perl::Critic'    => 0,
    'Test::Pod::Coverage'   => 0,
    },

  );

$builder->create_build_script();
