#!perl
#
# Craig Fitzgerald
#

use lib "lib";
use warnings;
use strict;
use feature 'state';
use lib "c:/projects/me/Gnu/lib";
use Gnu::FileUtil  qw(SlurpFile SpillFile);
use Gnu::KeyInput  qw(GetKey KeyName KeyMacroCallback KeyMacrosStream QueueMacro);


MAIN:
   # key:
   #    vkey       67
   #    isshft     0
   #    sc         1
   #    ascii      99
   #    code       "67sc"
   #    ctl        0
   #    char       "c"
   #    isctrl     0
   # ---------------------------------------------

   test("122sc"  );
   test("99|67|0");
   test("A"      );
   test("<enter>");
   test("F11"    );
   test(97, 65, 0);


sub test
   {
   my ($m, $v, $c) = @_;

   my $result = _Key(@_);
   print "Test: $m  =>  $result\n";
   }



#  _Key($key)
#  _Key("122sc")             # code
#  _Key("99|67|0")           # triplet (from stream)
#  _Key("A")                 # ascii
#  _Key("<enter>")           # name
#  _Key("F11")               # name
#  _Key($ascii, $vkey, $ctl) # from console
sub _Key
   {
   my ($multi, $vkey, $ctl) = @_;

   return "key"      if  ref $multi eq "HASH";
   return "code"     if  $multi =~ /^\d+sc$/i;
   return "triplet"  if  $multi =~ /^\d+\|\d+\|\d+$/;
   return "ascii"    if  length($multi) == 1;
   return "name"     if  $multi =~ /^\</;
   return "console"  if  $vkey;
   return "unknown";
   }
