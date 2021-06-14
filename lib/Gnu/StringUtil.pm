#
# StringUtil.pm - 
#
# 

package Gnu::StringUtil;

use warnings;
use strict;
require Exporter;

our @ISA         = qw(Exporter);
our $VERSION     = 0.10;
our @EXPORT      = qw();
our @EXPORT_OK   = qw(Chip 
                      Trim 
                      TrimList 
                      _CSVParts 
                      LineString 
                      ChopCR 
                      CleanInputLine 
                      LineString2 
                      TrimNS 
                      HtmlEncode);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);


# externals
#
###############################################################################

sub Chip
   {
   my ($string, $chip) = @_;

   my $chiplen = length $chip;
   $string = substr($string, $chiplen) if $string=~ /^$chip/;
   return $string;
   }


sub _CSVParts
   {
   my ($line) = @_;

   my @parts = split(",", $line);

   for (my $i=0; $i<scalar @parts; $i++)
      {
      $parts[$i] = Trim($parts[$i]);
      }
   return @parts;
   }


# Strips Leading and Trailing Spaces
sub Trim
   {
   my ($string) = @_;

   return $string if !$string; # undef or blank degenerate case

   $string =~ s/^[\r\n\s]+//;
   $string =~ s/[\r\n\s]+$//;
   return $string;
   }

sub TrimNS
   {
   my ($string, $trimlead, $trimtrail) = @_;

   return "" unless defined $string && $string ne "";

   $string =~ s/^[\r\n\s]+//  if  $trimlead ;
   $string =~ s/^[\r\n]+//    if !$trimlead ;
   $string =~ s/[\r\n\s]+$//  if  $trimtrail;
   $string =~ s/[\r\n]+$//    if !$trimtrail;
   return $string;
   }


sub TrimList
   {
   my (@strings) = @_;

   return map{Trim($_)} @strings;
   }


sub LineString
   {
   my ($message) = @_;

   my $line  = "-" x 10;
   $line .= " $message " if $message;
   $line .= "-" x (78 - length($line));
   $line .= "\n";

   return $line;
   }


sub LineString2
   {
   my ($message) = @_;

   my $line  = "-";
   $line .= "$message" if $message;
   $line .= "-" x (30 - length($line));
   $line .= "\n";
   return $line;
   }



sub ChopCR
   {
   my ($string) = @_;

   $string =~ s/[\r\n]+$//;
   return $string;
   }

sub CleanInputLine
   {
   my ($line, $trimlead, $trimtrail) = @_;

   $trimlead  = 1 unless defined $trimlead ;
   $trimtrail = 1 unless defined $trimtrail;

   $line = TrimNS($line, $trimlead, $trimtrail);
   return "" if $line =~ /^#/;
   return $line;
   }

   
sub HtmlEncode
   {
   my $str = shift;

   return unless defined $str;
   $str =~ s/&/&amp;/g;
   $str =~ s/=deg=/&deg;/g;
   $str =~ s/"/&quot;/g;
   $str =~ s/</&lt;/g;
   $str =~ s/>/&gt;/g;
   return $str;
   }


1; # two
  
__END__   
