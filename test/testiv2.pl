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
use Gnu::KeyInput  qw(GetKey);
use Win32;
use Win32::API;
use Win32::Console;
use Win32::Process;
use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow SendKeys);
use Time::HiRes;

my $TITLE = "TestApp";

my @files = (
   '\processor.jpg',
   '\processor2.jpg',
   'd:\media\pictures\pg\62773.jpg',
   'd:\media\pictures\pg\62774.jpg',
   'd:\media\pictures\pg\79473.jpg',
   'd:\media\pictures\pg\79476.jpg',
   'd:\media\pictures\pg\79496.jpg',
   'd:\media\pictures\pg\79497.jpg',
   'd:\media\pictures\pg\83829.jpg',
   'd:\media\pictures\pg\83971.jpg',
   'd:\media\pictures\pg\84068.jpg',
   'd:\media\pictures\pg\84069.jpg',
   'd:\media\pictures\pg\86712.jpg',
   'd:\media\pictures\pg\86714.jpg'
   );

MAIN:
   ArgBuild("*^exit");
   ArgParse(@ARGV) or die ArgGetError();

#   my $handle = FindConsoleWindow();


   print "Pressing <esc> exits.\n\n";

   foreach my $file (@files)
      {
      my $key = GetKey(ignore_ctl_keys=>1, noisy=>1);

      last if $key->{vkey} == 27;

      PlayerPlay($file);

      Focus();
      }
   PlayerClose();
   exit(0);





sub Focus
   {
#   my ($handle) = @_;
#  my ($handle) = FindWindowLike(undef, "$TITLE");
#
   print "sleeping...\n";
#   return if !$handle;
#
   MySleep(1.0);
   print "waking\n";

#   SetForegroundWindow($handle);


   my $GetConsoleWindow = new Win32::API("kernel32", "GetConsoleWindow", [],'N');
   my $handle = $GetConsoleWindow->Call();

   print ("handle is $handle\n");

   SetForegroundWindow($handle);
   }


sub FindConsoleWindow
   {
#   my $SetConsoleTitle = new Win32::API("kernel32", "SetConsoleTitle", ['P'],'N');
#   my $FindWindow      = new Win32::API("user32"  , "FindWindow"     , ['P','P'],'N');
#
#   return unless $SetConsoleTitle && $FindWindow;
#
#   $SetConsoleTitle->Call($TITLE);
#
#   MySleep(0.4);
#   return $FindWindow->Call(0, $TITLE);

   my $GetConsoleWindow = new Win32::API("kernel32", "GetConsoleWindow", [],'N');
   my $handle = $GetConsoleWindow->Call();

   print ("handle is $handle\n");

   return $handle;
   }


sub MySleep
   {
   my ($duration) = @_;
   Time::HiRes::sleep($duration);
   }
