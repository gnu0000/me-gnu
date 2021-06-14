#
# StringInput::Counters.pm - internal counter handling for StringInput
#  C Fitzgerald xx/xx/2013
#
# this module is required by Gnu::StringInput

use strict;
use warnings;
use feature 'state';



# $action: "mark"  - set a marker
#          "inc"   - increment count, return # since marker
#          "count" - return # since marker
#           undef  - set a marker return full count since tmp context
sub TCounter
   {
   my ($varname, $action) = @_;

   state $marks={};

   return $marks unless $varname;
                        
   $varname = "_si_" . $varname;
   
   return TVarInc($varname) if !$action;

   return  $marks->{$varname} = TVarInit($varname=>0) if $action eq "mark";

   my $mark = $marks->{$varname} || 0;
   return  TVarDefault($varname=>0) - $mark if $action eq "count";
   return  TVarInc($varname) - $mark;
   }

sub TMarkCounters{map{TCounter($_, "mark" )}@_}
sub TSetCounters {_SetMsg(); map{TCounter($_, "mark" )}@_}
sub TGetCounters {map{TCounter($_, "count")}@_}
sub TIncCounters {map{TCounter($_, "inc"  )}@_}

1;