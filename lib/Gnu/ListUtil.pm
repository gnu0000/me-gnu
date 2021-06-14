#
# ListUtil.pm - misc array utils
#
# 

package Gnu::ListUtil;

use warnings;
use strict;
require Exporter;
use List::Util qw(max min);

our @ISA         = qw(Exporter);
our $VERSION     = 0.10;
our @EXPORT      = qw();
our @EXPORT_OK   = qw(OneOf OneOfStr SplitList NColumns Tuples ABList AnyHasVal);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);

# externals
#
###############################################################################


sub OneOf
   {
   my ($val, @possibles) = @_;

   map{return 1 if $val==$_} @possibles;
   return 0;

   #my ($val, @list) = @_;
   #foreach my $element (@list)
   #   {return 1 if $val == $element}
   }


sub OneOfStr
   {
   my ($val, @possibles) = @_;

   map{return 1 if $val eq $_} @possibles;
   return 0;
   }


sub AnyHasVal
   {
   my (@possibles) = @_;

   map{return 1 if $_} @possibles;
   return 0;
   }


sub SplitList
   {
   my ($list, $minsplit) = @_;

   $minsplit ||= 2;
   my $count = scalar @{$list};
   return ($list) unless $count >= $minsplit;

   my $pos = int(($count+1)/2);
   return ([@{$list}[0..$pos-1]],[@{$list}[$pos..$count-1]]);
   }


sub NColumns
   {
   my ($cols, $widths, $delim) = @_;

   $widths ||= [map{length $_->[0]} (@{$cols})];
   $delim  ||= " ";

   my $ncols   = scalar @{$cols};
   my $nrows   = [map{scalar @{$_}} (@{$cols})];
   my $maxrows = max(@{$nrows});
   my $text = "";
   foreach my $ridx (0..$maxrows-1)
      {
      my @parts = map{$ridx < $nrows->[$_] ? $cols->[$_]->[$ridx] : ""} (0..$ncols-1);
      @parts    = map{sprintf ("%*s", $widths->[$_], $parts[$_])}  (0..$ncols-1);
      $text    .= join($delim, @parts) . "\n";
      }
   return $text;
   }


sub Tuples
   {
   my (@p) = @_;

   push(@p, 0) if (scalar @p) % 2;
   return map{[@p[$_*2,$_*2+1]]}(0..$#p/2);
   }

sub ABList
   {
   my ($true_str,$false_str,@list) = @_;
   return map{$_ ? $true_str : $false_str} @list;
   }


sub ValMap
   {
   my ($val, %nv) = @_;

   return !(defined $val)   ? _vmval(["_undef","_false","_default"],undef,%nv) :
          !$val             ? _vmval(["_false","_default"         ],0,%nv) :
          !exists $nv{$val} ? _vmval(["_true" ,"_default"         ],0,%nv) :
                              $nv{$val};
   }


sub _vmval
   {
   my ($keys, $default, %nv) = @_;

   map{return $nv{$_} if exists $nv{$_}} (@{$keys});
   return $default;
   }



1; # two
  
__END__   
