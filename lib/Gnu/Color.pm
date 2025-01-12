#
# Color.pm
# Console Colors and palette
#
#   https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#
#   print "\x1b]4;14;rgb:c0/c0/ef\x07"; # B0 0B
# C Fitzgerald 12/22/2024
#
# Synopsis:
#
#   # SetColor($fg, $bg, $isWinIndex) Set the console foreground/background colors
#   # SetColor($words) ... Set the console foreground/background colors from words
#   # $fg ................ Foreground color index 0x0 - 0xf
#   # $bg ................ Background color index 0x0 - 0xf
#   # $isWinIndex ........ Are the indexes Windows or ANSI based
#
#   SetColor("lightblue on black");
#   SetColor(0xd, 0x0, 1);
#
#   # set the color via the winddows hex color
#
#   SetColorHex(0x080f);
#
#   # returns the string that sets the console color
#   # same params as SetColor
#
#   my $colorStr = GetColorString();
#
#   # returns the string that sets the console color
#   # same params as SetColorHex
#
#   my $colorStr = GetHexColorString();
#
#   # returns the current console colors as a hex string
#
#   my $currentColors = GetHexColor();
#
#
#   # ColorNameToIndex($name, $genWinIndex)
#   # Gets the index of a named color
#   # $genWinIndex .... return a windows index or an ANSI index
#   #
#
#   my $idx = ColorNameToIndex("lightmagenta");
#
#   # GetColorInfo()                  Get all colors info
#   # GetColorInfo($idx, $isWinIndex) Get info for a specific color
#
#   @colorInfo = GetColorInfo();
#   my $redInfo = GetColorInfo(0x4, 1);
#
#   # returns a string if the last call generated an error eg: "Unknown color 'foo'"
#   GetColorError();
#
package Gnu::Color;

use warnings;
use strict;
use feature 'state';
use List::Util   qw(min max);
use Gnu::Console qw(ConAttr);
use Gnu::StringUtil qw(Trim);

require Exporter;

our @ISA       = qw(Exporter);
our $VERSION   = 0.10;
our @EXPORT    = qw();
our @EXPORT_OK = qw(SetColor
                    SetColorHex
                    GetColorString
                    GetHexColor
                    GetHexColorString
                    ColorNameToIndex
                    GetColorInfo
                    GetColorError);


our %EXPORT_TAGS = (ALL => [@EXPORT_OK]);

my $CSI       = "\e[";  # CSI  means  Control Sequence Introducer - Microsoft's name, not mine
my @WinToAnsi = (0, 4, 2, 6, 1, 5, 3, 7, 8, 12, 10, 14, 9, 13, 11, 15);
my $ERROR_MESSAGE = "";  # last error


my @COLORINFO = (
   {name => "black"       , ansiIdx => 0 , winIdx => 0 , fgSGR => 30 , bgSGR => 40  },  #
   {name => "red"         , ansiIdx => 1 , winIdx => 4 , fgSGR => 31 , bgSGR => 41  },  #
   {name => "green"       , ansiIdx => 2 , winIdx => 2 , fgSGR => 32 , bgSGR => 42  },  #
   {name => "brown"       , ansiIdx => 3 , winIdx => 6 , fgSGR => 33 , bgSGR => 43  },  #
   {name => "blue"        , ansiIdx => 4 , winIdx => 1 , fgSGR => 34 , bgSGR => 44  },  #
   {name => "magenta"     , ansiIdx => 5 , winIdx => 5 , fgSGR => 35 , bgSGR => 45  },  #
   {name => "cyan"        , ansiIdx => 6 , winIdx => 3 , fgSGR => 36 , bgSGR => 46  },  #
   {name => "lightgray"   , ansiIdx => 7 , winIdx => 7 , fgSGR => 37 , bgSGR => 47  },  #
   {name => "gray"        , ansiIdx => 8 , winIdx => 8 , fgSGR => 90 , bgSGR => 100 },  #
   {name => "lightred"    , ansiIdx => 9 , winIdx => 12, fgSGR => 91 , bgSGR => 101 },  #  e0/8b/95
   {name => "lightgreen"  , ansiIdx => 10, winIdx => 10, fgSGR => 92 , bgSGR => 102 },  #  97/e0/8b
   {name => "yellow"      , ansiIdx => 11, winIdx => 14, fgSGR => 93 , bgSGR => 103 },  #  e0/d7/8b
   {name => "lightblue"   , ansiIdx => 12, winIdx => 9 , fgSGR => 94 , bgSGR => 104 },  #  8b/a6/e0
   {name => "lightmagenta", ansiIdx => 13, winIdx => 13, fgSGR => 95 , bgSGR => 105 },  #  da/8b/e0
   {name => "lightcyan"   , ansiIdx => 14, winIdx => 11, fgSGR => 96 , bgSGR => 106 },  #  8b/e0/d9
   {name => "white"       , ansiIdx => 15, winIdx => 15, fgSGR => 97 , bgSGR => 107 },  #
);

my %NAMEMAP = map{$_->{name} => $_} @COLORINFO;


sub GetColorString {
   my ($fg, $bg, $isWinIndex) = @_;

   return GetColorStringFromWords($fg) if scalar @_ == 1;

   ($fg, $bg) = ($WinToAnsi[$fg], $WinToAnsi[$bg]) if $isWinIndex;

   my $fgSGR = $COLORINFO[$fg]->{fgSGR};
   my $bgSGR = $COLORINFO[$bg]->{bgSGR};
   return GenSGR($fgSGR, $bgSGR);
}


sub GetColorStringFromWords {
   my $partStr = join(" ", @_);
   my @parts = split(" ", $partStr);

   my $ct = scalar @parts;
   my ($p1, $p2, $p3) = @parts;

   my $curr = GetHexColor();
   my $fg = $curr & 0xf;
   my $bg = ($curr & 0xf0) >> 4;

   if ($ct == 0) {
      printf "%2.2x", $curr; 
      exit(0);
   }
   if ($ct == 1) {
      if (length $p1 == 2) {
         return GetHexColorString(hex($p1));
      }
      $fg = ColorNameToIndex($p1, 1);
   }
   if ($ct == 2) {
      return SetError("", "invalid params")  unless $p1 =~ /^on/i;
      $bg = ColorNameToIndex($p2, 1);
   }
   if ($ct >= 3) {
      return SetError("", "invalid params")  unless $p2 =~ /^on/i;
      $fg = ColorNameToIndex($p1, 1);
      $bg = ColorNameToIndex($p3, 1);
   }
   return GetColorString($fg - 0, $bg - 0, 1);
}



sub SetColor {
   #my ($fg, $bg, $isWinIndex) = @_;
   print GetColorString(@_);
}


sub GetHexColorString {
   my ($hex) = @_;

   my $fg = $WinToAnsi[$hex & 0x0f];
   my $bg = $WinToAnsi[($hex & 0xf0) >> 4];

   my $fgSGR = $COLORINFO[$fg]->{fgSGR};
   my $bgSGR = $COLORINFO[$bg]->{bgSGR};
   return GenSGR($fgSGR, $bgSGR);
}


sub SetColorHex {
   print GetHexColorString(@_);
}


sub GetHexColor {
   return ConAttr();
}


sub ColorNameToIndex {
   my ($name_or_idx, $genWinIndex) = @_;

   my $idx;

   if ($name_or_idx =~ /^[0-9a-f]$/i) {
      $idx = hex($name_or_idx);
      $genWinIndex = 0;
   } elsif ($name_or_idx =~ /^[0-9]{1,2}$/) {
      $idx = $name_or_idx;
      $genWinIndex = 0;
   } else {
      my $info = $NAMEMAP{$name_or_idx};
      return SetError(0, "Unknown color '$name_or_idx'")if !$info;
      $idx = $info->{ansiIdx};
   }
   return $genWinIndex ? $WinToAnsi[$idx] : $idx;
}


sub GetColorInfo {
   my ($idx, $isWinIndex) = @_;

   return @COLORINFO unless scalar @_;

   $idx = $WinToAnsi[$idx] if $isWinIndex;
   return $COLORINFO[$idx];
}


sub GenSGR {
   return join("", map {$CSI . $_ . "m"} @_);
}


sub SetError {
   my ($ret, $msg) = @_;
   
   $ERROR_MESSAGE = $msg;
   return $ret;
}

   
sub GetColorError {
   return $ERROR_MESSAGE;
}


1; # two
