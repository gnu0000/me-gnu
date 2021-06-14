#!perl.exe
#
# DebugWindow.pm
# Module for logging to a windows window
# Craig Fitz

package Gnu::DebugWindow;

require Exporter;
use strict;
use Win32::API;

our $VERSION = 0.01;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(Dbg);

sub Dbg
   {
   my ($Message) = @_;

   $Message .= '\0';
   my $FindWindow  = new Win32::API("user32", "FindWindow",  "IP"  , "I");
   my $SendMessage = new Win32::API("user32", "SendMessage", "IIPP", "I");
   return 0 if (!$FindWindow || !$SendMessage);

   my $hWnd = $FindWindow->Call (0, "Debug Window") or return 0;

   my $WM_COPYDATA = 0x004a;
   my $MessageLen = length $Message;
   my $cpData = pack ("IIp", 1, $MessageLen, $Message);
   my $Result = $SendMessage->Call ($hWnd, $WM_COPYDATA, 0, $cpData);

   return 1;
   }

1;
