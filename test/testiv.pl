#!perl 
#
# Craig Fitzgerald
#

use lib "..\\lib";
use warnings;
use strict;
use Gnu::ArgParse;
use File::Basename;
use Gnu::IVPlayer;


MAIN:
   ArgBuild("*^exit");
   ArgParse(@ARGV) or die ArgGetError();
   
   if (ArgIs("exit"))
      {
      PlayerClose();
      exit(0);
      }
      
   my $filespec = ArgGet();
   PlayerPlay($filespec);
   exit(0);
