use Egg::Helper;

my %BaseParam=(
  controller=> {
    egg=> 'MailSend',
    },
  config=> {
    plugin_mailsend=> {
      debug               => 1,
      handler             => 'CMD',
      default_to          => ($ENV{EGG_TEST_MAIL_TO}   || 'a@text.domain'),
      default_from        => ($ENV{EGG_TEST_MAIL_FROM} || 'a@text.domain'),
      default_subject     => 'TEST',
      default_body_header => "TEST_HEADER\n---\n",
      default_body_footer => "\n---\nTEST_FOOTER\n",
      },
    },
  );

sub prepare {
	my $controller = shift || {};
	my $config     = shift || {};
	my $others     = shift || {};
	while (my($key, $value)= each %$controller)
	  { $BaseParam{controller}{$key}= $value }
	while (my($key, $value)= each %$config)
	  { $BaseParam{config}{plugin_mailsend}{$key}= $value }
	while (my($key, $value)= each %$others) { $BaseParam{$key}= $value }
	my $t= Egg::Helper->run('O:Test');
	$t->prepare( \%BaseParam );
	return $t;
}

1;
