#!perl
#
# Craig Fitzgerald 01/2017

#use lib "lib";
use warnings;
use strict;
use Cwd;
use Gnu::StringInput qw(:ALL);

MAIN:
   $| = 1;
   print "This is a minimal example showing path input (use <tab> to cycle)\n";
   Run();

sub Run {
   my $cwd = "c:\\";
   SIExternal(settype=>"fdata", cwd=>$cwd);
   my $dir = SIGetString(prompt=>"path:", preset=>$cwd);
}      
