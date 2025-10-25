# ShowPic.pm - 
#  C Fitzgerald 8/x/2013
#
# Synopsis:
# 
# this module is a work in progress...
# 

package Gnu::ShowPic;

use warnings;
use strict;
use feature 'state';
use Win32;
use Win32::API;
use Win32::Process;
use Gnu::Var qw(:ALL);

require Exporter;
our @ISA = qw(Exporter);


my $SetFGWindow      = Win32::API->new("user32"  , "SetForegroundWindow", ['N'],'N');
my $AllowSetFGWindow = Win32::API->new("user32"  , "AllowSetForegroundWindow", ['I'], 'I');
my $ShowWindow       = Win32::API->new("user32"  , "ShowWindow", ['N','I'], 'I');
my $KeyEvent         = Win32::API->new("user32"  , "keybd_event", ['I','I','N','N'], 'V');
my $SetConsoleTitle  = Win32::API->new("kernel32", "SetConsoleTitle", ['P'],'N');
my $FindWindow       = Win32::API->new("user32"  , "FindWindow", ['P','P'],'N');

my $PLAYER_SPEC  = 'C:\util\iview\i_view64.exe';

our @EXPORT = qw(ShowPic);
our @EXPORT_OK = qw();
our $VERSION   = 0.10;


sub ShowPic
   {
   my ($spec) = @_;

   state $hwnd = FindConsoleWindow(sprintf("%s-%d", "test", $$));

   MyExec($PLAYER_SPEC, "i_view", "\"$spec\"");
   ForceForeground($hwnd);
   }


sub MyExec
   {
   my ($spec, $appname, $paramlist) = @_;

   my $ProcessObj = " " x 10240;
   Win32::Process::Create($ProcessObj, $spec, "$appname $paramlist", 0, NORMAL_PRIORITY_CLASS, ".") 
      || die "Cant create process $!\n";
   }   


sub ForceForeground {
    my ($hwnd) = @_;

    $AllowSetFGWindow->Call(-1) if $AllowSetFGWindow;
    $ShowWindow->Call($hwnd, 9) if $ShowWindow;   # SW_RESTORE = 9

    my $VK_MENU = 0x12;
    my $KEYEVENTF_KEYUP = 0x0002;
    $KeyEvent->Call($VK_MENU, 0, 0, 0);                # key down
    $KeyEvent->Call($VK_MENU, 0, $KEYEVENTF_KEYUP, 0); # key up

    return $SetFGWindow->Call($hwnd);
}


sub FindConsoleWindow
   {
   my ($title) = @_;

   return unless $SetConsoleTitle && $FindWindow;

   $SetConsoleTitle->Call($title);

   return $FindWindow->Call(0, $title);
   }


1; # two
  
__END__   
