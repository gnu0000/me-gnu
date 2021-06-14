#
# StringInput::Hooks.pm - hook handling for StringInput
#  C Fitzgerald xx/xx/2013
#
# this module is required by Gnu::StringInput


use strict;
use warnings;
use feature 'state';

my $NAM_HOOKS = "_hooks";


sub SIHooks    {v_isg($NAM_HOOKS    , 0, {}, @_)}

sub SIGetHook
   {
   my ($name) = @_;

   my $hooks = SIHooks();
   return $hooks->{$name};
   }


sub SICall
   {
   my ($hookname, $defaultfn, @params) = @_;

   my $fn = SIGetHook($hookname) || $defaultfn || die "\nBAD SICall: no default given for '$hookname'\n";
   return &{$fn}(@params);
   }


sub SISetHook
   {
   my (%params) = @_;

   my $hooks  = SIHooks();
   my $name   = $params{name};
   my $fn     = $params{fn};
   my $exists = exists $hooks->{$name};

   # delete
   delete $hooks->{$name} if $params{del} && $exists;
   return $exists         if $params{del};

   # add/change
   $hooks->{$name} = $fn;
   return $hooks->{$name};
   }


1;


