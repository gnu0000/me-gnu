#
# MiscUtil.pm - misc
#
# 

package Gnu::MiscUtil;

use warnings;
use strict;
use List::Util       qw(max min);

require Exporter;

our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(InRange SizeString NumScale);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);
our $VERSION     = 0.10;


# externals
#
###############################################################################


sub InRange
   {
   my ($val, $min, $max) = @_;

   return ($val >= $min && $val <= $max);
   }


sub SizeString
   {
   my ($size) = @_;

   my $char = "b";
   ($char = "k", $size /= 1024) if $size > 1024;
   ($char = "m", $size /= 1024) if $size > 1024;
   ($char = "g", $size /= 1024) if $size > 1024;

   return sprintf("%04d%s", $size, $char);
   }


sub NumScale
   {
   my ($num, $min) = @_;

   $num ||= 0;
   $min ||= 0;
   my $scale = 0;

   while ($num)
      {
      $scale++;
      $num = int($num/10);
      }
   return max($scale, $min);
   }



1; # two
  
__END__   
