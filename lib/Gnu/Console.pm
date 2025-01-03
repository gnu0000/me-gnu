#
# Console.pm
# This is a simple wrapper for Win32::Console output functions
# C Fitzgerald 8/27/2024
#
#
# Synopsis:
#    use Gnu::Console qw(:ALL);
#
#    ConCls();
# 
#    my $startColor = ConAttr();
# 
#    ConAttr($FG_BLUE | $BG_BLACK);
#    print "I'm blue!\n";
# 
#    ConAttr($FG_YELLOW | $BG_BLACK);
#    print "I'm yellow!\n";
# 
#    ConAttr($startColor);
# 
# 
# Subs:
#    ConCls()
#    ConAttr($FG_ | $BG_)                 - get/set the screen attribute
#    ConCursor($x, $y, $size, $visible)   - get/set cursor
#    ConInfo()                            - get console info - see below
#    ConReadAttr(number, col, row)        - read attrs
#    ConReadChar(number, col, row)        - read chars
#    ConSize($x, $y)                      - get/set buffer size
#    ConWindow($left, $top, $right, $bot) - get/set window size
#
#    OutputConsole()  - get the std output console handle
#
#
# Constants:
#    $FG_BLACK         $BG_BLACK
#    $FG_GRAY          $BG_GRAY
#    $FG_BLUE          $BG_BLUE
#    $FG_LIGHTBLUE     $BG_LIGHTBLUE
#    $FG_RED           $BG_RED
#    $FG_LIGHTRED      $BG_LIGHTRED
#    $FG_GREEN         $BG_GREEN
#    $FG_LIGHTGREEN    $BG_LIGHTGREEN
#    $FG_MAGENTA       $BG_MAGENTA
#    $FG_LIGHTMAGENTA  $BG_LIGHTMAGENTA
#    $FG_CYAN          $BG_CYAN
#    $FG_LIGHTCYAN     $BG_LIGHTCYAN
#    $FG_BROWN         $BG_BROWN
#    $FG_YELLOW        $BG_YELLOW
#    $FG_LIGHTGRAY     $BG_LIGHTGRAY
#    $FG_WHITE         $BG_WHITE
#
#
# ConInfo() returns an array:
#    Columns (X size) of the console buffer.
#    Rows (Y size) of the console buffer.
#    Current column (X position) of the cursor.
#    Current row (Y position) of the cursor.
#    Current attribute used for Write.
#    Left column (X of the starting point) of the current console window.
#    Top row (Y of the starting point) of the current console window.
#    Right column (X of the final point) of the current console window.
#    Bottom row (Y of the final point) of the current console window.
#    Maximum number of columns for the console window, given the current buffer size, font and the screen size.
#    Maximum number of rows for the console window, given the current buffer size, font and the screen size.
#
#
# ConCursor details
#   ($x, $y, $size, $visible) = $CONSOLE->Cursor();
#   Get position only:     ($x, $y) = $CONSOLE->Cursor();
#   Set x,y,size,visible:  $CONSOLE->Cursor(40, 13, 50, 1);
#   Set position only:     $CONSOLE->Cursor(40, 13);
#   Set size and visibility without affecting position:   $CONSOLE->Cursor(-1, -1, 50, 1);
#
#
# ConWindow (flag, left, top, right, bottom) detaiuls
#   Gets or sets the current console window size. 
#   If called without arguments, returns a 4-element list containing the current window coordinates 
#     in the form of left, top, right, bottom. 
#   To set the window size, you have to specify an additional flag parameter: 
#     if it is 0 (zero), coordinates are considered relative to the current coordinates; 
#     if it is non-zero, coordinates are absolute.
#
#
# todo: There are lots more things in Win32::Console than you see here
#   reading/writing blocks
#   scrolling
#   All the basic input functions - see Gnu::KeyInput for some of that
#
package Gnu::Console;

use warnings;
use strict;
use feature 'state';
use Win32::Console;

require Exporter;

our @ISA       = qw(Exporter);
our $VERSION   = 0.10;
our @EXPORT    = qw();
our @EXPORT_OK = qw(OutputConsole 
                    ConAttr
                    ConCls
                    ConCursor
                    ConInfo
                    ConReadAttr
                    ConReadChar
                    ConSize
                    $FG_BLACK         $BG_BLACK
                    $FG_GRAY          $BG_GRAY
                    $FG_BLUE          $BG_BLUE
                    $FG_LIGHTBLUE     $BG_LIGHTBLUE
                    $FG_RED           $BG_RED
                    $FG_LIGHTRED      $BG_LIGHTRED
                    $FG_GREEN         $BG_GREEN
                    $FG_LIGHTGREEN    $BG_LIGHTGREEN
                    $FG_MAGENTA       $BG_MAGENTA
                    $FG_LIGHTMAGENTA  $BG_LIGHTMAGENTA
                    $FG_CYAN          $BG_CYAN
                    $FG_LIGHTCYAN     $BG_LIGHTCYAN
                    $FG_BROWN         $BG_BROWN
                    $FG_YELLOW        $BG_YELLOW
                    $FG_LIGHTGRAY     $BG_LIGHTGRAY
                    $FG_WHITE         $BG_WHITE
                   );
our %EXPORT_TAGS = (ALL => [@EXPORT_OK]);


sub ConAttr     { return OutputConsole()->Attr(@_)   }
sub ConCls      { return OutputConsole()->Cls(@_)    }
sub ConCursor   { return OutputConsole()->Cursor(@_) }
sub ConInfo     { return OutputConsole()->Info()     }
sub ConReadAttr { return OutputConsole()->ReadAttr() }
sub ConReadChar { return OutputConsole()->ReadChar() }
sub ConSize     { return OutputConsole()->Size()     }
sub ConWindow   { return OutputConsole()->Window()   }


sub OutputConsole
   {
   state $console = InitConsole();
   return $console;
   }


sub InitConsole
   {
   my ($clear) = @_;

   my $console = Win32::Console->new(STD_OUTPUT_HANDLE); 
   $console->Cls() if $clear;
   return $console;
   }


1; # two
