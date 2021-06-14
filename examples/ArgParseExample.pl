#!perl
#
# Craig Fitzgerald 01/2015

use warnings;
use strict;
use Gnu::ArgParse;

MAIN:
   print "This is a tiny test of Gnu::ArgParse.\n";
   print "There are many features not covered here.\n\n";

   print "Posible params: /debug /help /file=<file> <files...>\n\n";

   ArgBuild("*^file= *^debug *^help ?");

   #ArgAllowSlash(1);

   ArgParse(@ARGV) or die ArgGetError();

   print "operating system is : $^O\n";

   my $file = ArgIs("file") ? ArgGet("file") : "*not present*";
   print "file: $file\n";

   my $debug = ArgIs("debug") ? "yes" : "no";
   print "debug: $debug\n";

   my $help = ArgIs("help") ? "yes" : "no";
   print "help: $help\n";

   my $quest = ArgIs("?") ? "yes" : "no";
   print "quest: $quest\n";

   for my $i (0..ArgIs()-1)
      {
      my $free_param = ArgGet(undef,$i);
      print "unswitched: $free_param\n";
      }


