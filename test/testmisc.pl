#!perl 
#
# Craig Fitzgerald
#

use lib "c:\\util\\bin\\perl\\lib";
use warnings;
use strict;
use feature 'state';
use Archive::Zip     qw( :ERROR_CODES :CONSTANTS );
use Cwd              qw(abs_path getcwd cwd);
use Path::Class      qw(file);
use Gnu::ArgParse;
use File::Basename;
use Time::HiRes;
use Gnu::DebugUtil    qw(:ALL);

MAIN:
   my $a = "foo";
   my $c = $a .= " bar";
   print "c = $c\n";



   ArgBuild("*^context= *^nosave *^reset *^clear *^extern= *^help *^quiet *^debug");
   ArgParse(@ARGV) or die ArgGetError();
   
   my $i = 0;
   while (my $dir = ArgGet(undef,$i++))
      {
      $dir = "" if $dir eq "none";
      my $pre = $dir =~ /^(\.|\\|(\w\:))/ ? "" : ".\\";
      
      my $fulldir = $pre . $dir;

      print "------------dir $dir ($fulldir)---------------\n";
      
      opendir(my $dh, $fulldir) || print "cannot opendir '$dir'\n";
      next unless $dh;
      my @all = readdir($dh);
      closedir($dh);

      print "Dirs: ";
      foreach my $file (sort @all)
         {
         my $spec = "$dir\\$file";
         print "$spec, " if -d $spec;
         }
      print "\n\nFiles: ";
      foreach my $file (sort @all)
         {
         my $spec = "$dir\\$file";
         print "$spec, " if -f $spec;
         }
      print "\n\n";
      }
   exit(0);   

     


#
#
#
#
#
#   my $str = "";
#   $str
#   my @results = $str =~ /^\{(\w+)(:(.*))?\}$/;



#   my @zooset = ("this is a test"                        , 
#                 "this() that the- ?other"               , 
#                 "this"                                  , 
#                 ""                                  , 
#                 "that--there   whatever      is   this");
#
#   print DumpRef(\@zooset, "", 3);
#   
#   foreach my $zoo (@zooset)
#      {
##      my @parts = split(/\s/, $zoo);
#      my @parts = split(/\s+/, $zoo);
#
#      my $list = join(",", map{"[$_]"}@parts);
#
#      print " str: [$zoo]\n";
#      print "list: $list\n";
#      }
#   exit(0);
#
#
#
#
#
#
#
##   my @zooset = ("this", "this\nthat", "this\n", "\nthat");
##   
##   foreach my $zoo (@zooset)
##      {
##      my ($zip) = $zoo =~ /^(.*)$/s;
##      $zip = "<undef>" unless defined $zip;
##      $zip = "<blank>" unless length  $zip;
##      print "$zip\n";
##      }
##   exit(0);
#
#
#
#
#  my $cc = {a=>"fooo"};
##   my $cc = "fooo";
##   my $cc = "fooo";
##   my $bb = \$cc;
##   my $aa = _reftype($bb);
#
#   my $zzz;
#   $zzz = {a=>"fooo"};         print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#   $zzz =  ["a","fooo"];       print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#   $zzz =  \"a";               print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#   $zzz =  sub(){my $i=0;};    print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#   $zzz =  \{a=>"fooo"};       print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#   $zzz =  3;                  print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#   $zzz =  "foo";              print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#   $zzz =  undef;              print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#   $zzz =  0;                  print "ref='", _reftype($zzz,"_u","_z","_s"), "'\n";
#
#   exit(0);
#
#
##   print "ref='$aa'\n'";
#   exit(0);
#
#
#   foreach my $stry ("this is a string",
#                     "t\\his \\is \\a \\stri\\ng",
#                     "\\\\t\\\\his \\is \\a \\stri\\ng")
#      {
#      my $str6 = $stry;
#      $str6 =~ s[\\\\][~~underscore~~]g;
#      $str6 =~ s[\\(.)][$1]g;
#      $str6 =~ s[~~underscore~~][\\]g;
#
#      print "'$stry' => '$str6'\n";
#      }
#   exit(0);
#
#
#
#   my $str1 = "this"."\n"."is"."\n";
#
#   foreach my $strz (
#                     "this"                    , 
#                     "this\n"                  ,
#                     "this\n\n"                ,
#                     "this"."\n"."is"          ,
#                     "this"."\n"."is"."\n"     ,
#                     "this\n\nis\n\n"          )
#      {
#      my $multiline = $strz =~ /(.*)(\n)(.+)/;
#      my @linez = split(/^/, $strz);
#      my @linez2= grep(!/^\s*$/, @linez);
#      my $zct = scalar @linez;
#      my $zct2= scalar @linez2;
#      my $linestr  = join("\n", map{"[".$_."]"}@linez);
#      my $linestr2 = join("\n", map{"[".$_."]"}@linez2);
#
#      print "-----------------\n";
#      print "strz      : [$strz]\n";
#      print "multiline : $multiline\n";
#      print "linecount : $zct\n";
#      print "linecount2: $zct2\n";
#      print "lines     : $linestr\n";
#      print "lines2    : $linestr2\n";
#      }
#   exit (0);
#
#
#   foreach my $target ("foo", "foo.*", "f")
#      {
#      my $m  = $target;
#      my $qm = quotemeta($m);
#      my $x1 = qr/^$m/;
#      my $x2 = qr/^$m$/;
#      my $x3 = qr/^$qm/;
#      my $x4 = qr/^$qm$/;
#      my $x5 = qr/^$qm.*$/;
#
##   print "x1 is: $x1\n";
##   print "x2 is: $x2\n";
##   print "x3 is: $x3\n";
##   print "x4 is: $x4\n";
#
#      foreach my $str ("a", "foo", "foo ", "fo.*")
#         {
#         #print "x1 $str: ", ($str =~ /$x1/ ? "y" : "n"), "\n";
#         #print "x2 $str: ", ($str =~ /$x2/ ? "y" : "n"), "\n";
#         #print "x3 $str: ", ($str =~ /$x3/ ? "y" : "n"), "\n";
#         #print "x4 $str: ", ($str =~ /$x4/ ? "y" : "n"), "\n";
#
#         print "-----------------\n";
#         foreach my $patt ($x1, $x2, $x3, $x4, $x5)
#            {
#            my $result = $str =~ /$patt/ ? "y" : "n";
#            print sprintf("%-6s =~ %-16s : $result\n", $str, $patt);
#            }
#         }
#      }
#   exit (0);
#
#
#
#
#   my $fn = \&TestZZ1;
#
#   print "ref fn = ", ref $fn, "\n";
#   exit (0);
#
#
#   TestZZ1();
#   TestZZ2();
#   exit (0);
#
#
#
#sub TestZZ1
#   {
#   my $indenter = '...';
#   my $indentsize = length $indenter;
#   my $ndnt = quotemeta($indenter);
#
#   my @strs = ('foo'         ,
#               '^foo'        ,
#               '...foo'      ,
#               '......foo'   ,
#               '.......foo'  ,
#               '^.......foo' ,
#               '......^foo'  );
#               
#   foreach my $str (@strs)
#      {
#
#      my ($begin, $indent, $ext) = $str =~ /^(\^)?((?:$ndnt)*)(.*)$/;
#
#      $begin  = defined $begin ? "1" : "0";
#      $indent = "" unless defined $indent;
#      $ext    = "" unless defined $ext   ;
#      my ($blen, $ilen, $elen) = (length $begin ,length $indent,length $ext);
#      my $level = $ilen / $indentsize;
#      my $bedin = 
#
#      print sprintf ("match str [%-20s] = [%-5s][%-12s][%s]($blen, $ilen, $elen)[level $level !]\n", $str, $begin, $indent, $ext);
#      }
#   }
#
#
#sub TestZZ2
#   {
#   print "-------------------------------------\n";
#
#   my $indenter = '   ';
#   my $indentsize = length $indenter;
#   my $ndnt = quotemeta($indenter);
#
#   my @strs = ('foo'         ,
#               '^foo'        ,
#               '   foo'      ,
#               '      foo'   ,
#               '       foo'  ,
#               '^       foo' ,
#               '      ^foo'  );
#               
#   foreach my $str (@strs)
#      {
#
#      my ($begin, $indent, $ext) = $str =~ /^(\^)?((?:$ndnt)*)(.*)$/;
#
#      $begin  = defined $begin ? "1" : "0";
#      $indent = "" unless defined $indent;
#      $ext    = "" unless defined $ext   ;
#      my ($blen, $ilen, $elen) = (length $begin ,length $indent,length $ext);
#      my $level = $ilen / $indentsize;
#      my $bedin = 
#
#      print sprintf ("match str [%-20s] = [%-5s][%-12s][%s]($blen, $ilen, $elen)[level $level !]\n", $str, $begin, $indent, $ext);
#      }
#   }
#
#
##sub _reftype
##   {
##   my ($var) = @_;
##
##   return "z" unless $var;
##   my $r = ref($var);
##
##   return $r =~ /^HASH/   ? "h":
##          $r =~ /^ARRAY/  ? "a":
##          $r =~ /^SCALAR/ ? "s":
##          $r =~ /^CODE/   ? "c":
##          $r =~ /^REF/    ? "r":
##                            "" ;
##   }
#
#
#sub _reftype
#   {
#   my ($var,$undef_ret,$zero_ret) = @_;
#
#   return  (scalar @_ > 1 ? $undef_ret : "") unless defined $var;
#   return  (scalar @_ > 2 ? $zero_ret  : "") unless $var;
#
#   my $r = ref($var);
#   return "h" if $r =~ /^HASH/  ;
#   return "a" if $r =~ /^ARRAY/ ;
#   return "c" if $r =~ /^CODE/  ;
#   return "s" if $r =~ /^SCALAR/;
#   return "r" if $r =~ /^REF/   ;
#
##   return  (scalar @_ > 3 ? $scalar_ret : "") if $r =~ /^SCALAR/;
##   my $rr = ref(\$var);
##   return  (scalar @_ > 3 ? $scalar_ret : "") if $rr =~ /^SCALAR/;
##   return "";
#   }
#
#
##
##
##
##
##   my @a = ("aval", "bval", "cval");
##   my @b = @a;
##   my @c;
##
##   my @d = my ($a, $b, $c) = @c = @a;
##   my ($d, $e, $f) = my @e = @c = @a;
##
##
##   print "\@a=", join(",", @a) , "\n";
##   print "\@b=", join(",", @b) , "\n";
##   print "\@c=", join(",", @c) , "\n";
##   print "\@d=", join(",", @d) , "\n";
##   print "\@e=", join(",", @e) , "\n";
##
##   print "a=$a b=$b c=$c d=$d e=$e f=$f\n";
##
##   my @f = ("boo");
##   doit(\@f);
##   print "\@f=", join(",", @f) , "\n";
##
###   my ($x, $p, $q) = doit2();
###   my @p = @{$p};
###   my @q = @{$q};
###
###   print " x=$x\n";
###   print "\@p=", join(",", @p) , "\n";
###   print "\@q=", join(",", @q) , "\n";
###
###
###   my ($t, @r, @s);
###   ($t, \@r, \@s) = doit2();
###   print " t=$t\n";
###   print "\@r=", join(",", @r) , "\n";
###   print "\@s=", join(",", @s) , "\n";
##
##
##
##
##   exit(0);
##
##
##sub doit
##   {
##   my ($listref) = @_;
##
##   @{$listref} = ("xval", "yval", "zval");
##   }
##
##
##sub doit2
##   {
##   my $x = "xval";
##   my @p = ("kval", "lval");
##   my @q = ("mval", "nval");
##
##   return ($x, \@p, \@q);
##   }
##
