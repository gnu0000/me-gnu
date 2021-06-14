#
# StringInput::Options.pm - macro handling for StringInput
#  C Fitzgerald xx/xx/2013
#
# this module is required by Gnu::StringInput



use strict;
use warnings;
use feature 'state';


# SIOption - get/set/init/delete 1 or more
#            context variables(context options)
# general ui:

#   SIOption prams          ret    descr
#   ---------------------------------------------------
#   (foo=>5)               |5    | set context var to val 5
#   (foo=>5,baz=>"z")      |(5,z)| set multiple context var, ret list 
#   (foo)                  |5    | get val from
#   (_delete_foo)          |1    | delete context var foo
#   (_exists_foo)          |0    | return 1 if exists
#   (_init_foo=>9)         |val|9| set var if new return val
#   (_default_foo=>7)      |9    | ret var or deflt value if  new
#   (_delete_foo=>1,bar=>7)|(1,7)| always 2params each if multiple
#
# options: (SIOption to set ctx,  SiStrigInput() to set call only)
#
#.   prompt       => "str"    - print a label prompt
#.   preset       => "str"    - preset string value
#.   presetlast   => 1        - preset string value to prev input
#.   context      => "name"   - context for history and macros (note: setting a context is 'sticky')
#.   external     => [,,]     - set external match strings for 'tab' key
#.   allowdups    => 1        - allow duplicate entries in history
#.   nohistmod    => 1        - dont add to history
#?   wordregex    => qr/regex/- specify word parsing regex
#
#.   escape       => n        - return empty string if user hits escape n times
#.   nocr         => 1        - dont print a \n when done
#.   noisy        => 1        - (disruptive to input) message when keyboard macro is started/stopped
#.   trim         => 1        - return string with begin/end whitespace removed
#.   trimstart    => 1        - return string with beginning whitespace removed
#.   trimend      => 1        - return string with ending    whitespace removed
#   exfiles      => 1        - use filesystem for external data
#   exfileroot   => "dir"    - set root for exfiles, cwd is default
##  excontext    => 1        - use contextual matching for external data
#.   nospecialkeys=> 1        - disable <shift>-<ctrl>- d,t,h,?,x keys
#.   ignorechars  => str      - string if characters to ignore on input
#.   ignorecodes  => [code,,] - arrayref of key codes to ignore (exact codes)
#.   mygetkeyfn   => \&fn     - replace Gnu::KeyInput::GetKey with your own
#
#
# aliases
# buildcontext
#
#
#
#
sub SIOption
   {
   return Var(@_);
   }


sub Op_CreateStream
   {
   my (%opt) = @_;

   return "" if SkipStream(0, "option", %opt);

   SIContext({push=>1});
   my $stream = "";
   foreach my $context (SIContext({ctxlist=>1,all=>1}))
      {
      $stream .= CreateContextOptionStream($context, %opt);
      }
   SIContext({pop=>1});
   return $stream;
   }


sub CreateContextOptionStream
   {
   my ($context, %opt) = @_;
   
   

#   return "" if $opt{"skip_" . $context . "_options"};
#   return "" if $opt{"skip_" . $context . "_all"};
#   return "" if $context eq "temp";
   my $stream = "";
   SIContext($context);
   
   return "" if $context eq "temp";
   return "" if SkipStream($context, "option", %opt);
   
   my @varnames = SIContext({varlist=>1});
   foreach my $vname (@varnames)
      {
      next if _InternalVar($vname);
      next if $vname =~ /^__/;
      my $value = Var($vname);
      next unless defined $value;
#my $rval = ref $value;
#next if $rval && $rval ne "Regexp";
      next if ref $value;
      my $b64val = encode_base64($value);
      $stream .= "siopt:$context:$vname:$b64val";
      }
   return $stream;
   }



sub Op_LoadStream
   {
   my ($stream, %opt) = @_;
   
   return 0 if SkipStream(0, "option", %opt);

   my $all_options = {};
   foreach my $line(split(/\n/, $stream)) 
      {
      $line = CleanInputLine($line,1,0);
      
      my ($linetype,$context,$vname,$entry) = $line =~ /^(siopt):([^:]+):([^:]+):(.*)$/;
      next unless $context && $vname;
      $all_options->{$context} = {} if !exists $all_options->{$context};
      $all_options->{$context}->{$vname} = decode_base64($entry);
      }
   SIContext({push=>1});
   foreach my $context (keys %{$all_options})
      {
      SIContext($context);
      
      next if SkipStream($context, "option", %opt);
      
      my $ctxopts = $all_options->{$context};
      foreach my $vname (keys %{$ctxopts})
         {
         VarSet($vname=>$ctxopts->{$vname});
         }
      }
   SIContext({pop=>1});
   return 1;
   }



1;