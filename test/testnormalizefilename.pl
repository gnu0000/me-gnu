#!perl 
#
# Craig Fitzgerald
#

use lib "..\\lib";
use warnings;
use strict;
use Gnu::ArgParse;
use Gnu::FileUtil  qw(NormalizeFilename);


MAIN:
   ArgBuild("*^exit");
   ArgParse(@ARGV) or die ArgGetError();
   
   if (ArgIs("exit"))
      {
      PlayerClose();
      exit(0);
      }
      
   my $f1 = ArgGet();
   my $f2 = $f1;
   my $f1n = NormalizeFilename($f1, keep_dashes => 0);
   my $f2n = NormalizeFilename($f2, keep_dashes => 1);

   print "f1 orig: $f1 \n";
   print "f1  new: $f1n\n";
   print "f2 orig: $f2 \n";
   print "f2  new: $f2n\n";
                        
   exit(0);
