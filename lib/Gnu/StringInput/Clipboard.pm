#
# StringInput::Clipboard.pm - clipboard handling for StringInput
#  C Fitzgerald xx/xx/2013
#
# this module is required by Gnu::StringInput


use strict;
use warnings;
use feature 'state';

my $NAM_CLIPBOARD  = "__clipboard";



# Clipboard fns
#
################################################################################

# SIClipboard -external-
#
# get/set clipboard
# todo: allow named clipboards
#
sub SIClipboard
   {
   my ($str) = @_;
   
   return GVarInit($NAM_CLIPBOARD=>"") unless scalar @_;
   return GVar($NAM_CLIPBOARD=>$str);
   
   
#   return GVar($NAM_CLIPBOARD=>@_) || "";
#
#   state $clipboard = "foo";
#
#   $clipboard = $str if scalar @_;
#   return $clipboard;
#   return "yet to come";
   }


# -internal-
sub Cl_CreateStream
   {
   my (%opt) = @_;

   return "" if SkipStream(0, "clipboard", %opt);
   
   my $clipboard = SIClipboard();
   return "siclip:$clipboard\n";
   }

   
# -internal-
sub Cl_LoadStream
   {
   my ($stream, %opt) = @_;
   
   return 0 if SkipStream(0, "clipboard", %opt);

   foreach my $line(split(/\n/, $stream)) 
      {
      my ($entry) = $line =~ /^siclip:(.*)$/;
      return SIClipboard($entry) if $entry;
      }
   }

1; 