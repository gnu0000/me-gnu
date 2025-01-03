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
#    ...
#
package Gnu::Color;

use warnings;
use strict;
use feature 'state';
use List::Util   qw(min max);
use Gnu::Console qw(:ALL);

require Exporter;

our @ISA       = qw(Exporter);
our $VERSION   = 0.10;
our @EXPORT    = qw();
our @EXPORT_OK = qw(ColorString
                    SetColor
                    ColorStringByIndex
                    SetColorByIndex
                    SetPalette
                    GetPalette
                    ColorSpec
                    HSVToRGB
                    SplitColorString
                    CombineColorString
                    ConAttr);

our %EXPORT_TAGS = (ALL => [@EXPORT_OK]);

my @COLORINFO = (
   {name => "black"       , idx => $FG_BLACK       , palette => 0 , default => "0c/0c/0c", fgSGR => 30 , bgSGR => 40  },  #
   {name => "blue"        , idx => $FG_BLUE        , palette => 4 , default => "00/37/da", fgSGR => 34 , bgSGR => 44  },  #
   {name => "green"       , idx => $FG_GREEN       , palette => 2 , default => "13/a1/0e", fgSGR => 32 , bgSGR => 42  },  #
   {name => "cyan"        , idx => $FG_CYAN        , palette => 6 , default => "3a/96/dd", fgSGR => 36 , bgSGR => 46  },  #
   {name => "red"         , idx => $FG_RED         , palette => 1 , default => "c5/0f/1f", fgSGR => 31 , bgSGR => 41  },  #
   {name => "magenta"     , idx => $FG_MAGENTA     , palette => 5 , default => "88/17/98", fgSGR => 35 , bgSGR => 45  },  #
   {name => "brown"       , idx => $FG_BROWN       , palette => 3 , default => "c1/9c/00", fgSGR => 33 , bgSGR => 43  },  #
   {name => "lightgray"   , idx => $FG_LIGHTGRAY   , palette => 7 , default => "cc/cc/cc", fgSGR => 37 , bgSGR => 47  },  #
   {name => "gray"        , idx => $FG_GRAY        , palette => 8 , default => "76/76/76", fgSGR => 90 , bgSGR => 100 },  #
   {name => "lightblue"   , idx => $FG_LIGHTBLUE   , palette => 12, default => "3b/78/ff", fgSGR => 94 , bgSGR => 104 },  #  8b/a6/e0
   {name => "lightgreen"  , idx => $FG_LIGHTGREEN  , palette => 10, default => "16/c6/0c", fgSGR => 92 , bgSGR => 102 },  #  97/e0/8b
   {name => "lightcyan"   , idx => $FG_LIGHTCYAN   , palette => 14, default => "61/d6/d6", fgSGR => 96 , bgSGR => 106 },  #  8b/e0/d9
   {name => "lightred"    , idx => $FG_LIGHTRED    , palette => 9 , default => "e7/48/56", fgSGR => 91 , bgSGR => 101 },  #  e0/8b/95
   {name => "lightmagenta", idx => $FG_LIGHTMAGENTA, palette => 13, default => "b4/00/9e", fgSGR => 95 , bgSGR => 105 },  #  da/8b/e0
   {name => "yellow"      , idx => $FG_YELLOW      , palette => 11, default => "f9/f1/a5", fgSGR => 93 , bgSGR => 103 },  #  e0/d7/8b
   {name => "white"       , idx => $FG_WHITE       , palette => 15, default => "f2/f2/f2", fgSGR => 97 , bgSGR => 107 },  #
);

map{$_->{current} = $_->{default}} @COLORINFO;

my %NAMEMAP = map{$_->{name} => $_} @COLORINFO;
my %IDXMAP  = map{$_->{idx } => $_} @COLORINFO;

# Microsoft's names, not mine
my $CSI     = "\e[";  # CSI  means  Control Sequence Introducer
my $OSC     = "\e]";  # OSC  means  Operating system command
my $ST      = "\x07";
my $DEFAULT = ConAttr();


# SetColor()                      # reset
# SetColor("lightcyan on black")  # named colors (bg on fg)
# SetColor("on black")            # named colors (on bg)
# SetColor("lightcyan")           # named colors (fg)
# SetColor("d", "0")              # 0x0b fg, 0x00 bg
# SetColor(0x0b, 0x00)            #
sub SetColor {
   print ColorString(@_);
}


sub ColorString {
   my $ct = scalar @_;
   return $ct == 0 ? GenColor0(@_) :
          $ct == 1 ? GenColor1(@_) :
                     GenColor2(@_) ;
}

# SetColor("0c")                  # 0x00 bg, 0x0b fg
sub SetColorByIndex {
   print ColorStringByIndex(@_);
}


sub ColorStringByIndex {
   return GenColor1d(@_);
}


# no params given
# GenColor()                       # reset
sub GenColor0 {
   return GenColor1d($DEFAULT);
}


# 1 param given
# GenColor("lightcyan on black")   # named colors
# GenColor("on black")             # named colors
# GenColor("lightcyan")            # named colors
# GenColor("b0")                   # 0x0b bg, 0x00 fg
sub GenColor1 {
   return length $_[0] == 2 ? GenColor1h(@_) : GenColor1s(@_);
}


# 1 param given as hex
# GenColor("b0")                   # 0x0b bg, 0x00 fg
sub GenColor1h {
   my ($val1) = @_;
   return GenColor1d(hex($val1));
}


# 1 param given as integer
# GenColor(n)                   # 0x0b bg, 0x00 fg
sub GenColor1d {
   my ($val) = @_;

   my $fgSGR = $IDXMAP{$val & 0x0f       }->{fgSGR};  # ColorSpec($parts[0])->{fgSGR};
   my $bgSGR = $IDXMAP{($val & 0xf0) >> 4}->{bgSGR};  # ColorSpec($parts[2])->{bgSGR};
   return GenSGR($fgSGR, $bgSGR);
}


# 1 param given as color names or hex vals
# GenColor("lightcyan on black")   # named colors
# GenColor("on black")             # named colors
# GenColor("lightcyan")            # named colors
sub GenColor1s {
   my ($val1) = @_;
   my @parts = split(" ", $val1);

   if (scalar @parts >= 3) {
      die "invalid params" unless $parts[1] =~ /^on/i;
      my $fgSGR = ColorSpec($parts[0])->{fgSGR};
      my $bgSGR = ColorSpec($parts[2])->{bgSGR};
      return GenSGR($fgSGR, $bgSGR);
   }
   if (scalar @parts == 2) {
      die "invalid params" unless $parts[0] =~ /^on/i;
      return GenSGR(ColorSpec($parts[1])->{bgSGR});
   }
   if (scalar @parts == 1) {
      return GenSGR(ColorSpec($parts[0])->{fgSGR});
   }
}


# 2 params given as color names or hex vals
sub GenColor2 {
   my ($fg, $bg) = @_;

   my $fgSGR = ColorSpec($fg)->{fgSGR};
   my $bgSGR = ColorSpec($bg)->{bgSGR};
   return GenSGR($fgSGR, $bgSGR);
}


sub GenSGR {
   return join("", map {$CSI . $_ . "m"} @_);
}



# SetPalette("lightcyan")                    # reset color to default
# SetPalette("lightcyan", "61/d6/d6")        # set color by name
# SetPalette("b"        , "61/d6/d6")        # set color by hex value string
# SetPalette(0x0b       , "61/d6/d6")        # set color by number
# SetPalette("0:0c/0c/0c\n1:00/37/da,...")   # set entire pallette
sub SetPalette {
   my ($color, $rgb) = @_;

   return SetPaletteList($color) if length $color =~ /:/; 
   my $spec  = ColorSpec($color);
   $rgb = $spec->{default} if scalar @_ < 2;
   $rgb = CvtToRGB($rgb) if $rgb =~ /^~/;
   die "invalid color spec '$rgb'" unless $rgb =~ /^~?[0-9a-f]{2}\/[0-9a-f]{2}\/[0-9a-f]{2}/i;
   $spec->{current} = $rgb;
   print $OSC . "4;$spec->{palette};rgb:$rgb" . $ST;
}


sub SetPaletteList {
   my ($entries) = @_;

   for my $entry (split(",", $entries)) {
      my ($idx, $rgb) = split(":", $entry);
      my $spec = ColorSpec($idx);
      $rgb = CvtToRGB($rgb) if $rgb =~ /^~/;
      $spec->{current} = $rgb;
      print $OSC . "4;$spec->{palette};rgb:$rgb" . $ST;
   }
}

sub CvtToRGB {
   my ($hsv) = @_;

   return CombineColorString(HSVToRGB(SplitColorString($hsv)));
}


# GetPalette("b") -> "61/d6/d6"
# GetPalette()    -> "0,0c/0c/0c\n1,00/37/da,..."
sub GetPalette {
   my ($color) = @_;

   return ColorSpec($color)->{current} if scalar @_;
   map{$_->{current} => $_->{default}} @COLORINFO;
   return join(",", map{sprintf("%x:$COLORINFO[$_]->{current}", $_)} 0..15);
}


# ColorSpec("litecyan")  # specify color by name
# ColorSpec(11)          # specify color by decimal index
# ColorSpec("b")         # specify color by hex index
#
sub ColorSpec {
   my ($name_or_idx) = @_;

   #print "DEBUG: name_or_idx = [$name_or_idx]\n";

   return %IDXMAP{hex($name_or_idx)} if $name_or_idx =~ /^[0-9a-f]$/i;
   return %IDXMAP{$name_or_idx}      if $name_or_idx =~ /^[0-9]{1,2}$/;

   $name_or_idx =~ s/bright/light/i;
   $name_or_idx =~ s/dark//i;

   die "unknown color $name_or_idx" unless exists($NAMEMAP{lc $name_or_idx });
   return $NAMEMAP{lc $name_or_idx};
}


# split a color string into values
# "/01/FF/20" => (1, 255, 32)
# string may have a leading tilde
#
sub SplitColorString
   {
   my ($colorString, $separator) = @_;

   $separator = '/' if scalar @_ < 2;
   ($colorString) = $colorString =~ /^~?(.+)$/;

   my ($c1, $c2, $c3) = split($separator, $colorString);
   return (hex($c1), hex($c2), hex($c3));
   }


# combine color values to a string
# (1, 255, 32) =>  "/01/FF/20"
#
sub CombineColorString
   {
   my ($c1, $c2, $c3, $s) = @_;

   $s = '/' if scalar @_ < 4;
   return sprintf ("%2.2x$s%2.2x$s%2.2x", $c1, $c2, $c3);
   }


# converts a hue/saturation/value triple into a RGB color
# in the html format: #rrggbb
#
sub HSVToRGB {
   my ($h, $s, $v) = @_;

   my $dh = $h / 255 * 6;
   my $ds = $s / 255    ;
   my $dv = $v / 255    ;

   my $di = int $dh;
   my $df = $dh - $di;

   my $p1 = $dv * (1 - $ds);
   my $p2 = $dv * (1 - ($ds * $df));
   my $p3 = $dv * (1 - ($ds * (1 - $df)));

   my ($dr, $dg, $db);
   $di == 0 ? ($dr = $dv, $dg = $p3, $db = $p1) :
   $di == 1 ? ($dr = $p2, $dg = $dv, $db = $p1) :
   $di == 2 ? ($dr = $p1, $dg = $dv, $db = $p3) :
   $di == 3 ? ($dr = $p1, $dg = $p2, $db = $dv) :
   $di == 4 ? ($dr = $p3, $dg = $p1, $db = $dv) :
   $di == 5 ? ($dr = $dv, $dg = $p1, $db = $p2) :
              ($dr =      $dg =      $db = 0  ) ;

   return ($dr * 255, $dg * 255, $db * 255);
}


# converts a r/g/b triple into a HSV color
#sub RGBToHSV {
#   my ($r, $g, $b) = @_;
#
#   $r /= 255;
#   $g /= 255;
#   $b /= 255;
#   my $maxc = max($r, $g, $b);
#   my $minc = min($r, $g, $b);
#   my $v = $maxc;
#   return (0.0, 0.0, $v) if $minc == $maxc;
#   my $s = ($maxc - $minc) / $maxc;
#   my $rc = ($maxc - $r) / ($maxc - $minc);
#   my $gc = ($maxc - $g) / ($maxc - $minc);
#   my $bc = ($maxc - $b) / ($maxc - $minc);
#   #if ($r == $maxc) {
#   #    $h = 0.0 + $bc - $gc;
#   #} elsif ($g == $maxc) {
#   #    $h = 2.0 + $rc - $bc;
#   #} else {
#   #    $h = 4.0 + $gc - $rc;
#   #}
#   my $h = $r == $maxc ? 0.0 + $bc - $gc :
#           $g == $maxc ? 2.0 + $rc - $bc :
#                         4.0 + $gc - $rc ;
#   $h = ($h / 6.0) % 1.0;
#
##   return $h * 360, $s * 100, $v * 100;
#   return $h * 360, $s * 100, $v * 100;
#}



1; # two
