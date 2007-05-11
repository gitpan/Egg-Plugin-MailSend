
use Test::More tests => 10;
use Egg::Helper::VirtualTest;

my $v= Egg::Helper::VirtualTest->new;
my $file= $v->yaml_load( join '', <DATA> );
$v->prepare(
  controller=> { egg_includes=> [qw/ MailSend /] },
  config => {
    plugin_mailsend=> {
      handler  => 'CMD',
      cmd_path => '/usr/sbin/sendmail',
      default_from => 'dummy@dummy.domain',
      default_to   => 'dummy@dummy.domain',
      },
    },
  create_files => [$file],
  );

$v->disable_stderr;

ok my $e= $v->egg_context;
ok my $mail= $e->mail;
ok $mail->body('test-body');
ok $mail->attach({ Path=> $v->project_root. "/$file->{filename}" });
ok my $tmp= $mail->_mime_body( $mail->to );
my($header, $body)= $tmp=~/^(.+?)\n\n(.+)/s;
my($boundary)= $header=~m{\n?Content\-Type\:\s+multipart/mixed\;\s+boundary\=\"([^\"]+)};
ok $boundary;
$body=~s/^.+?$boundary//s;
my @data= split /$boundary/, $body;
is scalar(@data), 3;
like $data[1], qr{\n?Content\-Type\:\s+text/plain\;\s+name\=\"testfile\.txt\"};
like $data[1], qr{\n?Content\-Disposition\:\s+inline\;\s+filename\=\"testfile\.txt\"};
like $data[1], qr{\n\nmail_test};


__DATA__
filename: tmp/testfile.txt
value: |
  mail_test
