#!perl
#
# Craig Fitzgerald
#

use warnings;
use strict;
use feature 'state';
use lib "c:/projects/me/Gnu/lib";
use Gnu::KeyInput  qw(GetKey KeyName KeyMacroCallback);


MAIN:
   my $play = 0;
   
   KeyMacroCallback(\&MacroMod);

   print "This is a test program that echo's key input using Gnu::KeyInput.\n";
   print "Pressing <esc> exits.\n\n";

   while(1)
      {
      #  print "Im only accepting an a, b, w, or an F1 (and F1 with any shift/ctrl)...\n";
      #  my $key = GetKey(codes=>["87sc","112"], chars=>['a','b']);

      my $key = GetKey(ignore_ctl_keys=>1, noisy=>1, play=>$play);
      $play = 0;
      my $name = KeyName($key);
      print sprintf("ascii:%3d  vkey:%3d  ctl:%3d  code:%5s  char:%s ($name)\n", $key->{ascii}, $key->{vkey}, $key->{ctl}, $key->{code}, $key->{char});
      last if $key->{vkey} == 27;

      if ($key->{vkey} == 80) # p key
         {
         $play = 1;
         print "\n ****** Play is set ******\n";
         }
      }


sub MacroMod
   {
   my ($key) = @_;

   print "\n",  KeyName($key, 1), " changed  \n";
   }