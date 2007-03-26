
use Test::More qw/no_plan/;
use lib qw{ . ./t };
use File::Which;
{
  $ENV{EGG_TEST_MAIL_TO}   = '';
  $ENV{EGG_TEST_MAIL_FROM} = '';
  };
require 'test_mailsend.pl';

SKIP: {
	skip q{ Mail delivery command is not found. } unless which('sendmail');

my $file= {
  filename=> 'tmp/testfile.txt',
  value   => 'test',
  };

my $test= prepare(0, 0, { create_files=> [$file] });
ok my $e= $test->egg_virtual;
ok my $mail= $e->mail;
ok $mail->subject('test-subject');
ok $mail->body('test-body');
ok $mail->attach({ Path=> $test->project_root. "/$file->{filename}" });
ok my $tmp= $mail->__mime_body( $mail->to );
my($header, $body)= $tmp=~/^(.+?)\n\n(.+)/s;
my($boundary)= $header=~m{\n?Content\-Type\:\s+multipart/mixed\;\s+boundary\=\"([^\"]+)};
ok $boundary;
$body=~s/^.+?$boundary//s;
my @data= split /$boundary/, $body;
is scalar(@data), 3;
like $data[1], qr{\n?Content\-Type\:\s+text/plain\;\s+name\=\"testfile\.txt\"};
like $data[1], qr{\n?Content\-Disposition\:\s+inline\;\s+filename\=\"testfile\.txt\"};
like $data[1], qr{\n\ntest};

  };

