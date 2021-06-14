#!perl 
#
# Craig Fitzgerald
#

use lib "lib";
use warnings;
use strict;
use feature 'state';
use Archive::Zip     qw( :ERROR_CODES :CONSTANTS );
use Cwd              qw(abs_path getcwd cwd);
use Path::Class      qw(file);
use Gnu::ArgParse;
use File::Basename;
use Win32;
use Win32::Process;
use Time::HiRes;
use Gnu::      qw(TVar PVar GVar Var ITVar IPVar IGVar IVar VarContext);

my $ZIP = undef;
my $ZIP_FILE  = "test.zip";
my $ZIP_FILE2 = "test2.zip";
my $ZIP_BACKUP_FILE  = "test.bak";

MAIN:

   my @a = ("a", "b", "c");
   my @b = @a;

   exit(0);



   testline();
   exit(0);

   my @ga = qw(foo init_foo delete_foo);
   foreach my $gt (@ga)
      {
      my ($g0, $g1, $g2) = $gt =~ /^(init_)?(delete_)?(.*)$/;
      $g0 ||= "";
      $g1 ||= "";
      $g2 ||= "";

      print "$gt:     [$g0, $g1, $g2]\n";
      }
   exit(0);




   ZTest();
   exit(0);

   #my $qq1;
   #($qq1, my $qq2) = (5, 6);
   #print "qq1=$qq1, qq2=$qq2\n\n";

   my $hh1 = {joe =>{key1=>"a", key2=>"b"},
              bill=>{key1=>"c", key2=>"d"},
              bob =>{key1=>"e", key2=>"f"}};

   my @guys = sort{$a->{key1} cmp $b->{key1}}(values %{$hh1});
   map{print " :: $_->{key1} ::\n"} @guys;


#   my ($qq1, $qq2) = (1,2);
#   ($qq1, $qq2) += (5,5);
#   print "qq1=$qq1, qq2=$qq2\n\n";
#
#
#
#   exit(0);




   TestDirStuff();

   MyTestRef();

   MyTestExec();

   my $q1 = "foo"    ;
   my $q2 = "min_foo";
   my $q3 = "max_foo";


   foreach my $str qw(q1 q0 zoo)
      {
      my ($q) = $str =~ /^q(\d+)$/;
      my $qd = defined $q;
      my $qe = defined $q ? 1 : 0;
      $q = "undef" if !$qd;
      print "[$str] '$q' '$qd' '$qe'\n";
      }
   exit(0);


   TestQ("foo"    );
   TestQ("min_foo");
   TestQ("max_foo");
   exit(0);


   my $t1 = "test";
   my $t2 = 5;
   my $t3 = \&Test2;

   my $t1r = \$t1;
   my $t2r = \$t2;
   my $t3r = \$t3;

   print "ref t1  : ", ref($t1),  "\n"; #            
   print "ref t2  : ", ref($t2),  "\n"; #
   print "ref t3  : ", ref($t3),  "\n"; #  CODE   
   print "ref t1r : ", ref($t1r), "\n"; #  SCALAR 
   print "ref t2r : ", ref($t2r), "\n"; #  SCALAR 
   print "ref t3r : ", ref($t3r), "\n"; #  REF    
   exit(0);


   print "A: " . file(abs_path($0))->dir  . "\n";
   print "B: " . dirname($0)              . "\n";
   print "C: " . "[$0]"                   . "\n";

   ArgBuild("*^name= *^debug *^help");
   ArgParse(@ARGV) or die ArgGetError();

   $ZIP_FILE = ArgGet() || "test.zip";
   $ZIP_FILE2 = $ZIP_FILE . "_";
   $ZIP_BACKUP_FILE  = $ZIP_FILE . "_bk";
   Test2();

sub Test2
   {
   my $data = GetFile('key.pl');
   SaveFile('key.pl', "replacement_data");

   $data = GetFile('fred.txt');
   SaveFile('fred.txt', "replacement_data2");

   $data = GetFile('key.pl');
   print "key.pl: $data\n";

   $data = GetFile('fred.txt');
   print "fred.txt: $data\n";
   }

sub Test
   {
   my $zip = GetZip();

   my @names   = $zip->memberNames();
   print join(",", @names), "\n";

#   my $member   = $zip->memberNamed( 'key.pl' );
#   my $contents = $zip->contents( 'key.pl' );
#   print "contents:\n\n$contents\n";

   my $data = GetFile($zip,'key.pl');
   SaveFile($zip,'key.pl', "replacement_data");

   GetFile($zip,'fred.txt');
   SaveFile($zip,'fred.txt', "replacement_data2");

   $data = GetFile($zip,'key.pl');
   print "key.pl: $data\n";

   $data = GetFile($zip,'fred.txt');
   print "fred.txt: $data\n";


# Add a file from a string with compression
#   my $string_member = $zip->addString( 'This is a test', 'stringMember.txt' );
#   $string_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
   }


sub GetZip
   {
   return $ZIP if $ZIP;
   return $ZIP = OpenZip($ZIP_FILE);
   }

sub OpenZip
   {
   my ($name) = @_;

   my $zip = Archive::Zip->new();
   $zip->read($name) if -f $name;  
   return $zip;
   }

sub CloseZip
   {
   $ZIP = undef;
   }


sub GetFile
   {
   my ($name) = @_;

   my $zip = GetZip() || return undef;

   my $member = $zip->memberNamed($name);
   return $zip->contents($name) if $member;

   return '';
   }


sub SaveFile
   {
   my ($name, $data) = @_;

   my $zip = GetZip();

   if (!$zip->memberNamed($name))
      {
      print "creating member $name\n";
      my $member = $zip->addString('', $name);
      $member->desiredCompressionMethod( COMPRESSION_DEFLATED );
      }
   $zip->contents($name, $data);

   my $status = $zip->writeToFileNamed($ZIP_FILE2);
   die "error somewhere" if $status != AZ_OK;
   
   return unless $status == AZ_OK;

   CloseZip();

   rename ($ZIP_FILE, $ZIP_BACKUP_FILE) if -f $ZIP_FILE;
   rename ($ZIP_FILE2, $ZIP_FILE);

   return $status == AZ_OK;
   }


#
#
#
#  # Create a Zip file
#   my $zip = Archive::Zip->new();
#   
#   # Add a directory
#   my $dir_member = $zip->addDirectory( 'dirname/' );
#   
#   # Add a file from a string with compression
#   my $string_member = $zip->addString( 'This is a test', 'stringMember.txt' );
#   $string_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
#   
#   # Add a file from disk
#   my $file_member = $zip->addFile( 'xyz.pl', 'AnotherName.pl' );
#   
#   # Save the Zip file
#   unless ( $zip->writeToFileNamed('someZip.zip') == AZ_OK ) {
#       die 'write error';
#   }
#   
#   # Read a Zip file
#   my $somezip = Archive::Zip->new();
#   unless ( $somezip->read( 'someZip.zip' ) == AZ_OK ) {
#       die 'read error';
#   }
#   
#   # Change the compression type for a file in the Zip
#   my $member = $somezip->memberNamed( 'stringMember.txt' );
#   $member->desiredCompressionMethod( COMPRESSION_STORED );
#   unless ( $zip->writeToFileNamed( 'someOtherZip.zip' ) == AZ_OK ) {
#       die 'write error';
#   }
#

sub TestQ
   {
   my ($str) = @_;
   my ($member, $cmptype) = TestSplit($str);
   print "str:$str, member:$member, cmptype:$cmptype\n";
   }

sub TestSplit
   {
   my ($str) = @_;
   my($a,$b) = $str =~ /^(min|max)_(.+)$/;
   return ($b,$a) if $a && $b;
   return ($str, "");
   }


sub MyTestExec
   {
   my $ProcessObj = " " x 10240;

   Win32::Process::Create($ProcessObj,
                          "C:\\windows\\system32\\notepad.exe",
                          "notepad temp.txt",
                          0,
                          NORMAL_PRIORITY_CLASS,
                          ".")|| die Terr();

   MySleep(5);
   exit(0);
   }


sub MySleep
   {
   my ($duration) = @_;

   $duration ||= Context("sleep_duration");
   Time::HiRes::sleep($duration);
   }



sub Terr
   {
   print Win32::FormatMessage( Win32::GetLastError());
   }



sub MyTestRef
   {
   my $curr = [{size=>10, _filterpass=>1 },
               {size=>11, _filterpass=>1 },
               {size=>12, _filterpass=>1 },
               {size=>13, _filterpass=>0 },
               {size=>14, _filterpass=>1 },
               {size=>15, _filterpass=>0 }];
   my %options = (lst_startidx => 0,
                  lst_filtered => 1,
                  lst_maxrows  => 99);


   my $size = FileListTotalSize($curr, %options);
   print "size is '$size'\n";
   exit(0);
   }


sub FileListTotalSize
   {
   my ($curr, %options) = @_;

   my $size = 0;
#   my $sizefn = sub() {return ${$_[1]} += $_[0]->{size}};
#   my $iter = EachFile($curr, $sizefn, \$size, %options);

#   my $sizefn = sub() {$size += $_[0]->{size}};
#   my $iter = EachFile($curr, $sizefn, undef, %options);

#   my $sizefn = sub() {$size += $_[0]->{size}};

   my $iter = EachFile($curr, sub(){$size += $_[0]->{size}}, 0, %options);
   print "hits is '$iter->{hits}'\n";
   return $size;
   }


sub FileIterator
   {
   my ($curr, %options) = @_;

   return    {
              files     => $curr                          ,
              filecount => scalar @{$curr}                ,
              idx       => $options{lst_startidx} || 0    ,
              filtered  => $options{lst_filtered} || 0    ,
              maxrows   => $options{lst_maxrows}  || 99999,
              hits      => 0                              ,
             };
   }

sub NextFile
   {
   my ($iter) = @_;

   while($iter->{idx}  < $iter->{filecount} &&
         $iter->{hits} < $iter->{maxrows}     )
      {
      my $file = $iter->{files}->[$iter->{idx}];
      $iter->{idx} += 1;
      next if $iter->{filtered} && !HasFilterAtt($file);
      $iter->{hits} += 1;
      return $file;
      }
   return undef;
   }

sub EachFile
   {
   my ($curr, $fn, $userdata, %options) = @_;

   my $iter = FileIterator($curr, %options);
   while (my $file = NextFile($iter))
      {
      $fn->($file, $userdata, $iter, %options);
      }
   return $iter;
   }

sub HasFilterAtt
   {
   my ($file) = @_;

   return $file->{_filterpass} ? 1 : 0;
   }


sub TestDirStuff
   {
   ArgBuild("*^root= *^search= *^help");
   ArgParse(@ARGV) or die ArgGetError();

   #print "A: " . file(abs_path($0))->dir  . "\n";

   my $root   = ArgGet("root"  ) || "";
   my $search = ArgGet("search") || "";

   my ($cdir, $tdir, $sname) = PrepSpec($root, $search);
   my $redo0 = $tdir . $sname;
   my $redo1 = $tdir . "new";

   print "\nPrepSpec:\n";
   print "  root   =  '$root'   \n";
   print "  search =  '$search' \n";
   print "  cdir   =  '$cdir'   \n";
   print "  tdir   =  '$tdir'   \n";
   print "  sname  =  '$sname'  \n";
   print "  redo0  =  '$redo0'  \n";
   print "  redo1  =  '$redo1'  \n";

#   $root   =~ tr[/][\\];
#   $search =~ tr[/][\\];
#   chop $root if $root =~ /\\$/;
#   $root .= "\\" if length $root;
#
#   my $spec   = $root . $search;
#   print "root   = '$root'   \n";
#   print "search = '$search' \n";
#   print "spec   = '$spec'   \n";
#
##   print "getcwd = ", getcwd(), "\n";
##   print "   cwd = ", cwd()   , "\n";
#
# 
#   print "\nFileparse of '$spec':\n";
#   my ($name,$path,$suffix) = fileparse($spec);
#   print "  name   = '$name'   \n";
#   print "  path   = '$path'   \n";
#   print "  suffix = '$suffix' \n";


   print "\nContents of '$cdir': ";
   my $files = [];
   $files = _GatherFiles($cdir, $files);
   print join(", ", @{$files}[0..3]), "\n";

   exit(0);
   }



sub _GatherFiles
   {
   my ($dir, $files) = @_;

   $dir = ".\\" if $dir eq "";

   opendir(my $dh, $dir);
   my @all = readdir($dh);
   closedir($dh);
   foreach my $file (@all)
      {
      next if $file eq '.';
      next if $file eq '..';
      push(@{$files}, $file);
      }
   return $files;
   }



sub PrepSpec
   {
   my ($root, $search) = @_;

   $root   =~ tr[/][\\];
   chop $root if $root =~ /\\$/;
   $root .= "\\" if length $root;
   my $spec = $root . $search;

   my (undef,$trimdir) = fileparse($search);
   $trimdir = '' if $trimdir eq ".\\";

   my ($name,$dir) = fileparse($spec);
   $dir = '' if $dir eq ".\\";

   return ($dir, $trimdir, $name);
   }

sub ZTest
   {
   Temp(a=>"b", c=>"d", e=>"f");
   PrintVar(0, qw(a c e));

   Temp(g=>"h", i=>"j", c=>"x");
   PrintVar(0, qw(a c e g i));

   Perm(a=>"B", c=>"D", e=>"F");
   PrintVar(1, qw(a c e));

   Perm(g=>"H", i=>"J", c=>"X");
   PrintVar(1, qw(a c e g i));

   PrintVar(0, qw(a c e g i));

   Temp("*reset*", {a=>"1", c=>"2", e=>"3"});
   PrintVar(0, qw(a c e));
   Temp(a=>"z", init_c=>"w", init_g=>"y", init_k=>"l");
   PrintVar(0, qw(a c e g k));

   my @z00 = Temp(a=>"z", init_c=>"w", init_g=>"y", init_k=>"l");
   print "setreturns: @z00 \n";
   print "setreturns: ", join(", ", @z00), "\n";
   my $z09 = Temp(a=>"z");
   print "setreturns: $z09 \n";
   $z09 = Temp("a");
   print "setreturns: $z09 \n";

   print "--------------------- \n";
   PrintVar(0, qw(a c e g i k));
   @z00 = xvar(1, a=>"zx", c=>"wx", g=>"yx", i=>"6x", k=>"lx");
   print 'z00 = xvar(1, a=>"zx", c=>"wx", g=>"yx", i=>"6x", k=>"lx");',"\n";

   PrintVar(0, qw(a c e g i k));
   print "setreturns: @z00 \n";
   @z00 = xvar(0, a=>"z", c=>"w", g=>"y", i=>"6", k=>"l");
   print 'z00 = xvar(0, a=>"z", c=>"w", g=>"y", i=>"6", k=>"l");',"\n";
   PrintVar(0, qw(a c e g i k));
   print "setreturns: @z00 \n";


   }

sub PrintVar
   {
   my ($isperm, @vars) = @_;
   print "Temp  ", join(",  ", map{"$_ = " . Temp($_)}@vars) if !$isperm;
   print "Perm  ", join(",  ", map{"$_ = " . Perm($_)}@vars) if  $isperm;
   print "\n";
   }

sub Temp{TVar(@_)};
sub Perm{PVar(@_)};



sub xvar
   {
   my ($initonly, @params) = @_;
   return $initonly ? ITVar(@params) : return TVar (@params);
   }




sub testline
   {
   print __LINE__;
   testline2(__LINE__);
   }

sub testline2
   {
   my ($ln) = @_;

   print "\n$ln\n";
   }




}



#sub _vars
#   {
#   state $all_vars = {};
#
#   #my $context = SIContext();
#   my $context = "foo";
#
#   $all_vars->{$context} = {} unless $all_vars->{$context};
#   #$all_vars->{$context} = $data if $data;
#   return $all_vars->{$context};
#   }
#
#sub _var
#   {
#   my  $set = shift;
#   my ($name, $val) = @_;
#
#   my $vars = _vars();
#   $vars->{$set} = {} unless $vars->{$set};
#   return $vars->{$set} = $val if $name eq "*reset*";
#   return $vars->{$set}->{$name} unless scalar @_ > 1;
#
#   my %params = @_;
#   while (my($key,$val) = each %params)
#      {
#      my $init = $key =~ /^_(.*)$/;
#      $key = $1 if $init;
#      $vars->{$set}->{$key} = $val unless $init and exists $vars->{$set}->{$key};
#      }
#   }
