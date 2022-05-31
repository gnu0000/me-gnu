#
# ArgParse.pm - commandline Argument parser
# 
#    This module provides convenient access to commandline arguments. Swiched 
#    parameters (parameters preceeded by a slash or dash on windows or by a 
#    dash on linux), Unswitched parameters, case insensitivity, minimal matching,
#    multiple parameter use, and parameter values are all supported.
# 
# Synopsis:
#
#    use Gnu::ArgParse;
#
#    ArgBuild("*^XSize= *^YSize= *^help") or die ArgGetError();
#    ArgParse(@ARGV);
#
#    Usage() if ArgIs("help");
#    my $XSize = ArgGet("XSize");
#    my $YSize = ArgGet("YSize");
#
#
# Argument Template definition: 
#
#   *^PName=
#   ||  |  |
#   ||  |  | Parameter value specifier
#   ||  |  | ------------------------
#   ||  |    - (space) Parameter has no value
#   ||  |  = - Parameter value is preceeded by whitespace, :, or = sign
#   ||  |  ? - like =, but value is optional
#   ||  |
#   ||  Parameter name to look for
#   ||
#   |Case Insensitivity Flag, Leave out to be Case Sensitive
#   |
#   Minimal Matching Flag, leave out for exact match only
# 
# Craig Fitzgerald

package Gnu::ArgParse;

use warnings;
use strict;
use List::Util qw(sum);

require Exporter;

our $VERSION   = 0.20;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw();
our @EXPORT    = qw(ArgBuild
                    ArgParse
                    ArgAddConfig
                    ArgIs
                    ArgIsAny
                    ArgGet
                    ArgsGet
                    ArgGetAll
                    ArgDump
                    ArgGetError
                    ArgSwitch);

# constants
#
my $FREE_IDENT = "__free_param__";

# globals
#
my $CHOICES       = {};  # template storage
my $ERROR_MESSAGE = "";  # last error


sub ArgBuild
   {
   my ($definition, $clear) = @_;

   $CHOICES = {} if $clear;
   $ERROR_MESSAGE = "";
   
   map {ParseChoice($_)} split(" ", $definition);
   
   ParseChoice($FREE_IDENT);
   
   return !$ERROR_MESSAGE;
   }
   
   
sub ParseChoice
   {
   my ($choice_string) = @_;
   
   my $choice = {string           => $choice_string,
                 minimal_match    => 0             ,
                 case_insensitive => 0             ,
                 value_type       => ' '           ,
                 hits             => []            ,
                };

   while (length $choice_string)
      {
      if ($choice_string =~ /^\*/)
         {
         $choice->{minimal_match} = 1;
         ($choice_string) = $choice_string =~ /^\*(.*)$/;
         next;
         }
      if ($choice_string =~ /^\^/)
         {
         $choice->{case_insensitive} = 1;
         ($choice_string) = $choice_string =~ /^\^(.*)$/;
         next;
         }
      if ($choice_string =~ /^\w/)
         {
         my ($name, $value_type) = $choice_string =~ /^(\w+)(.*)$/;
         $choice->{name} = $name;
         $value_type ||= " ";
         $choice->{value_type} = $value_type;
         $choice->{combinable} = 1 if $choice->{value_type} eq "-";
         
         $value_type =~ /=|\?| /
            or return SetError ("Unknown value type '$value_type'");
         last;
         }
      if ($choice_string =~ /^$FREE_IDENT/)
         {
         last;
         }
      if ($choice_string =~ /^\?$/) # special case of allowable non-identifier
         {
         $choice->{name} = '?';
         last;
         }
      return SetError ("Unknown param definition '$choice_string'");
      }
   $CHOICES->{$choice->{name}} = $choice;
   return 1;
   }


sub ArgParse
   {
   my (@args) = @_;

   $ERROR_MESSAGE = "";
   
   for (my $index=0; my $arg = $args[$index]; $index++)
      {
      my ($switch, $ident, $delimiter, $value);
      
      ($switch, $arg) = EatSwitch ($arg);
      
      if (!$switch)
         {
         SaveFreeParam($arg, $index);
         next;
         }
      ($ident, $arg) = EatIdent  ($arg);
         
      my $choice = FindChoice($ident);
      return 0 unless $choice;

      ($delimiter, $arg) = EatDelimiter($arg, $choice);
      ($value    , $arg) = EatValue    ($arg, $choice);
      
      return SetError ("parameter '$ident' does not use a value") 
         if ($value && ($choice->{value_type} eq " "));
      
      # no value when a value is expected?  maybe the next arg
      if (!$value && ($value ne "0") && ($choice->{value_type} =~ /=|\?/))
         {
         $value = $args[++$index];
         if ($value && $value =~ m[/|-])
            {
            $index--;
            $value="";
            return SetError ("No value provided for parameter '$ident'") 
               unless $choice->{value_type} eq "?";
            }
         }
      SaveSwitchedParam($ident, $value, $choice, $switch, $index);
      }
   return 1;
   }


sub ArgAddConfig
   {
   my ($filespec) = @_;

   $filespec ||= GetDefaultFilespec();

   open (my $fh, "<", $filespec) or return 1;
   while (my $line = <$fh>)
      {
      chomp $line;
      next unless $line;
      next if $line =~ /^#/;
      my @params = split(" ", $line);
      ArgParse(@params) or return 0;
      }
   close $fh;
   return 1;
   }
   

sub EatSwitch   
   {
   my ($str) = @_;
   my $switch;

   ($switch, $str) = $str =~ /^\s*(--)?(.*)$/;
   return ($switch, $str) if $switch;
   
   if ($^O =~ /MSWin32/i) 
      {
      ($switch, $str) = $str =~ /^\s*([-\/])?(.*)$/;
      }
   else
      {
      ($switch, $str) = $str =~ /^\s*(-)?(.*)$/;
      }
   return ($switch, $str);
   }

   
sub EatIdent    
   {
   my ($str) = @_;
   my $ident;
   
   return($str, "") if $str eq "?"; #special case
   ($ident, $str) = $str =~ /^\s*([^\t :=]+)([\t :=].*)?$/;
   return ($ident, $str);
   }

   
sub EatDelimiter   
   {
   my ($str, $choice) = @_;
   my $delimiter;
   
   return ("", "") unless $str;
   ($delimiter, $str) = $str =~ /^\s*([=: ])?(.*)$/;
   return ($delimiter, $str);
   }

   
sub EatValue       
   {
   my ($str, $choice) = @_;
   return ($str, "");
   }

   
sub EatChar
   {
   my ($str) = @_;
   
   my ($char, $rest) = $str =~ /^(.)(.*)$/;
   return ($char, $rest);
   }
   
   
sub SaveFreeParam   
   {
   my ($ident, $index) = @_;
   
   my $choice = $CHOICES->{$FREE_IDENT};
   my $hits   = $choice->{hits};
   my $hit    = {name=>$ident, value=>undef, index=>$index};
   
   push @{$hits}, $hit;
   }

   
sub SaveSwitchedParam   
   {
   my ($ident, $value, $choice, $switch, $index) = @_;

   $value = "" if !defined $value;
   
#   $value ||= "" if ($value ne "0");
   my $hits = $choice->{hits};
   my $hit  = {name=>$ident, value=>"$value", switch=>"$switch", index=>$index};
   push @{$hits}, $hit;
   }

   
sub FindChoice
   {
   my ($ident) = @_;
   
   # exact match?
   return $CHOICES->{$ident} if exists $CHOICES->{$ident};

   # case insensitive match   
   foreach my $name (sort keys %{$CHOICES})
      {
      my $choice = $CHOICES->{$name};
      return $choice if $ident =~ /^$name$/i && $choice->{case_insensitive};
      }
      
   # minimal match 
   my $matched_choice = undef;
   my $match_count = 0;
   foreach my $name (sort keys %{$CHOICES})
      {
      my $choice = $CHOICES->{$name};

      if ($name =~ /^$ident/i)
         {
         # false match
         next if (!$choice->{case_insensitive}) && !($ident =~ /^$name$/);
         $matched_choice = $choice;
         $match_count++;
         }
      }
   return $matched_choice if $match_count == 1;
   return SetError("Unknown parameter specified: $ident") if !$match_count;
   return SetError("Ambiguous parameter specified: $ident");
   }

# return number of occurances of this argument
#   
sub ArgIs
   {
   my ($name) = @_;

   return GetFreeParamCount() unless $name;

   $name ||= $FREE_IDENT;
   my $choice = $CHOICES->{$name};
   return 0 unless $choice;
   return scalar @{$choice->{hits}};
   }


sub ArgIsAny
   {
   my (@names) = @_;

   return sum(map{ArgIs($_)} @names);
   }

   
# get nth occurances of this argument
#   
sub ArgGet
   {
   my ($name, $index) = @_;
   
   return GetFreeParam($index) unless $name;
   $index ||= 0;
   my $choice = $CHOICES->{$name};
   return undef unless $choice;
   return undef if $index >= scalar @{$choice->{hits}};
   return ${$choice->{hits}}[$index]->{value};
   }

# return a list of argument values (or undefs)
# ArgsGet("foo", "bar", "baz") -> ("yup", undef, 2)
#
sub ArgsGet
   {
   return map {ArgGet($_)} @_;
   }

# return an array of all invocations of a particular param
#
sub ArgGetAll
   {
   my ($name) = @_;

   return map {ArgGet($name, $_)} (0..ArgIs($name)-1);
   }

sub ArgSwitch
   {
   my ($name, $index) = @_;
   
   return GetFreeParam($index) unless $name;
   $index ||= 0;
   my $choice = $CHOICES->{$name};
   return undef unless $choice;
   return undef if $index >= scalar @{$choice->{hits}};
   return ${$choice->{hits}}[$index]->{switch};
   }

   
sub GetFreeParam
   {
   my ($index) = @_;
   
   $index ||= 0;
   my $choice = $CHOICES->{$FREE_IDENT};
   return undef if $index >= scalar @{$choice->{hits}};
   return ${$choice->{hits}}[$index]->{name};
   }


sub GetFreeParamCount
   {
   my $choice = $CHOICES->{$FREE_IDENT};
   return scalar @{$choice->{hits}};
   }


sub GetDefaultFilespec
   {
   my $filespec = $0;

   $filespec =~ s/\.\w+$/\.cfg/;
   return $filespec;
   }

   
sub SetError   
   {
   my ($msg) = @_;
   
   $ERROR_MESSAGE = $msg;
   return 0;
   }

   
sub ArgGetError   
   {
   return $ERROR_MESSAGE;
   }

   
sub ArgDump
   {
   foreach my $key (sort keys %{$CHOICES})
      {
      next if $key eq $FREE_IDENT;
      
      my $choice = $CHOICES->{$key};
      
      print "choice: $choice->{string}\n";
      print "   name            : $choice->{name            }\n";
      print "   value_type      : $choice->{value_type      }\n";
      print "   case_insensitive: $choice->{case_insensitive}\n";
      print "   minimal_match   : $choice->{minimal_match   }\n";
      
      if (exists $choice->{hits} && scalar @{$choice->{hits}})
         {
         print "   instances:\n";
         map {print "      $_->{name} => '$_->{value}' switch => '$_->{switch}'\n"} @{$choice->{hits}};
         }
      print "------------------------------------------------\n";
      }
   print "Unswitched parameters:\n";
   map {print "   $_->{name}\n"} @{$CHOICES->{$FREE_IDENT}->{hits}};
   }


1; # two

  
__END__   

=pod
=head1 NAME

Gnu::ArgParse - Commandline Argument Parsing Utility

=head1 SYNOPSIS

   use Gnu::ArgParse;

   ArgBuild("XSize= YSize= help");

   ArgParse(@ARGV) or die ArgGetError();

   Usage() if ArgIs("help");

   my $XSize = ArgGet("XSize");
   my $YSize = ArgGet("YSize");

   my $filename = ArgGet();


=head1 DESCRIPTION

This module provides convenient access to commandline arguments. Swiched 
parameters (parameters preceeded by a slash or dash on windows or by a 
dash on linux), Unswitched parameters, case insensitivity, minimal matching,
multiple parameter use, and parameter values are all supported.

=over

=item B<ArgBuild>

   ArgBuild("*^Type= *^Width= *^Height= *^Help");

   ArgBuild provides the module a template of the expected parameters.
   In the above example, the module may expect four switched parameters
   that are all case insensitive, may be minimally matched, and all but the
   help parameter is expected to have a value.

   so, for example the parameters: /t=jpg -Width=80 /hei:40 myfile.jpg
   would be considered valid parameters.

   The function returns true unless you screwed up the template, in which
   case you'll get a false return.

   The definition of an entry in the template string is as follows:

   *^PName=
   ||  |  |
   ||  |  | Parameter value specifier
   ||  |  | ------------------------
   ||  |    - (space) Parameter has no value
   ||  |  = - Parameter has a value that is preceeded by whitespace, :, or = sign
   ||  |  ? - Optional parameter value
   ||  |
   ||  Parameter name to look for
   ||
   |Case Insensitivity Flag, Leave out to be Case Sensitive
   |
   Minimal Matching Flag, leave out for exact match only


=item B<ArgParse>

   ArgParse(@ARGV)

   ArgParse parses the parameters for future querying.  You may call this
   function more than once if you have some values setup in the env (ALA PERL5OPT)
   or a config file with some preset values in it.

   I is also sometimes usefull to call this again with predefined values to use
   as defaults.

=item B<ArgAddConfig>

   ArgAddConfig(filespec)

   ArgAddConfig loads parameters from a config file. If you dont pass a filename
   the file is assumed to be the same filespec as the perl script but with a .cfg
   file extension. The contents of the file are just like the commandline args
   with the following extensions: lines beginning with a # char are ignored, and
   params can be on multiple lines.

=item B<ArgIs>

   ArgIs("MyParam")

   This will return the number of times the /MyParam parameter was specified on
   the commandline

   ArgIs()

   This will return the number unswitched parameters were specified on
   the commandline.

=item B<ArgGet>

   ArgGet("MyParam")

   This will return the value associated with the first occurence of the parameter.

   ArgGet("MyParam", 1)

   This will return the value associated with the second occurence of the parameter.

   ArgGet()

   This will return the first unswitched parameter

   ArgGet(undef, 2)

   This will return the third unswitched parameter

   ArgGet returns undef if the parameter was not specified, or if you asked for
   an index beyond the number of times the parameter was specified.

=item B<ArgsGet>

   This is like ArgGet() but accepts an array and returns an array

   ArgsGet("Param1", "Param2" ...)

   returns an array with the value of the parameters

=item B<ArgGetAll>

   This is like ArgGet() but returns an array of all invocations of the param

   So, if the user specified args like this: foo.pl -key=Bill -key=Patty

   ArgGetAll("key")

   returns an array with the values Bill and Patty

=item B<ArgGetError>

   ArgParse(@ARGV) or die ArgGetError();

   ArgBuild will return 0 if you messed up the template.
   ArgParse will return 0 if the user messed up the parameters.
   In either case, you can call ArgGetError() to get a description


   Example:

   ArgBuild("*^Fritos *^Frodo")
   ArgParse("/fr") or die ArgGetError();

   produces:
     Ambiguous parameter '/fr'


=item B<ArgDump>

   ArgDump()

   This is a debugging helper fn that will printout details of the
   stored template and any parsed parameters.

=back

=head1 REVISION HISTORY

=over

=item Version 0.20

But based on my C version which is from 1993!

=back

=head1 COPYRIGHT

Copyright (c) 2013 by Craig Fitzgerald

=cut


#two
1;