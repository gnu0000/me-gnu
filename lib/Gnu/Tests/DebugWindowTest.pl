#!c:/Perl/bin/perl.exe

use lib "../../lib";
use warnings;
use strict;
use Gnu::DebugWindow;



printf "Make sure you run DebugWindow.exe first!\n";


Dbg ("This is a message from the DebugWindow Test script!");
map {Dbg ('    ' x (12 - $_) . '***' x ($_ * 2))} (1 .. 10);
map {Dbg ('    ' x (12 - $_) . '***' x ($_ * 2))} reverse (1 .. 10);

my $Msg = "This is yet another message from the DebugWindow Test script.  This line is considerably longer for the sole purpose of demonstrating that a longer line can actually be presented in the debug window, which after all, could be important in certain contexts";
Dbg ($Msg);
