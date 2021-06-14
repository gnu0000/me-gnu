#
# ArgParse2.pm - commandline Argument parser Class
#
#    !! Todo: finish this module, make this up to date with ArgParse.pm !!
# This is an object oriented version of ArgParse.pm
#
# Synopsis:
#
#    use Gnu::ArgParse2;
#
#    my $ap1 = new Gnu::ArgParse2();
#    $ap1->ParseTemplate("*^XSize= *^YSize= *^help") or die $ap1->GetError();
#    $ap1->ParseArgs(@ARGV)                          or die $ap1->GetError();
#   
#    Usage() if $obj->Is("help");
#    my $XSize = $obj->Get("XSize");
#    my $YSize = $obj->Get("YSize");
#    my $file  = $obj->Is() ? $obj->Get() : "default.txt";
#
# Argument Template definition: 
#
#    *^PName=
#    ||  |  |
#    ||  |  | Parameter value specifier
#    ||  |  | ------------------------
#    ||  |    - (space) Parameter has no value
#    ||  |  = - Parameter value is preceeded by whitespace, :, or = sign
#    ||  |  ? - like =, but value is optional
#    ||  |
#    ||  Parameter name to look for
#    ||
#    |Case Insensitivity Flag, Leave out to be Case Sensitive
#    |
#    Minimal Matching Flag, leave out for exact match only
# 
# Methods
#
#    my $obj = GetArgParser();
#    $obj->ParseTemplate("*^XSize= *^YSize= *^help") or die $obj->GetError();
#    $obj->ParseArgs(@ARGV)                          or die $obj->GetError();
#    $obj->Is
#    $obj->Get
#    $obj->Dump
#    $obj->GetError
#    $obj->Switch
#
# Craig Fitzgerald 8/1/2013

package Gnu::ArgParse2;

use warnings;
use strict;

require Exporter;
our $VERSION   = 0.11;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();


# constants
my $FREE_IDENT = "__free_param__";

##############################################################################
#

sub new
   {
   my ($class) = @_;
   
   my $self = {definition => "", 
               choices    => {}, 
               errormsg   => "",
               errorcode  => 0 ,
               ok         => 1 };
               
   return bless ($self, $class);
   }

   
sub ParseTemplate
   {
   my ($obj, $definition, $clear) = @_;
   
   $obj->{choices} = {} if $clear;
   $obj->ClearError();
   
   map {$obj->ParseTemplateVar($_)} split(" ", $definition);

   $obj->ParseTemplateVar($FREE_IDENT);
   
   return $obj->{ok};
   }
   

sub ParseTemplateVar
   {
   my ($obj, $var_def) = @_;
   
   my $choice = {string        => $var_def,
                 minimal_match => 0       ,
                 nocase        => 0       ,
                 value_type    => ' '     ,
                 hits          => []      };

   while (length $var_def)
      {
      if ($var_def =~ /^\*/)
         {
         $choice->{minimal_match} = 1;
         ($var_def) = $var_def =~ /^\*(.*)$/;
         next;
         }
      if ($var_def =~ /^\^/)
         {
         $choice->{nocase} = 1;
         ($var_def) = $var_def =~ /^\^(.*)$/;
         next;
         }
      if ($var_def =~ /^\w/)
         {
         my ($name, $value_type) = $var_def =~ /^(\w+)(.*)$/;
         $choice->{name} = $name;
         $value_type ||= " ";
         $choice->{value_type} = $value_type;
         $choice->{combinable} = 1 if $choice->{value_type} eq "-";
         
         last if ($var_def =~ /^$FREE_IDENT/);

         return $obj->SetError (99, "Unknown value type '$value_type'")
            unless $value_type =~ /=|\?| /;
            
         last;
         }
      return $obj->SetError (98, "Unknown param definition '$var_def'");
      }
   $obj->{choices}->{$choice->{name}} = $choice;
   return 1;
   }

   
sub ParseArgs
   {
   my ($obj, @args) = @_;
   
   $obj->ClearError();
   
   for (my $index=0; my $arg = $args[$index]; $index++)
      {
      my ($switch, $ident, $delimiter, $value);
      
      ($switch, $arg) = _EatSwitch ($arg);
      
      if (!$switch)
         {
         $obj->SaveFreeParam($arg, $index);
         next;
         }
      ($ident, $arg) = _EatIdent  ($arg);
         
      my $choice = $obj->FindChoice($ident);
      return 0 unless $choice;

      ($delimiter, $arg) = _EatDelimiter($arg, $choice);
      ($value    , $arg) = _EatValue    ($arg, $choice);
      
      return $obj->SetError (97, "parameter '$ident' does not use a value") 
         if ($value && ($choice->{value_type} eq " "));
      
      # no value when a value is expected?  maybe the next arg
      if (!$value && ($value ne "0") && ($choice->{value_type} =~ /=|\?/))
         {
         $value = $args[++$index];
         if ($value && $value =~ m[/|-])
            {
            $index--;
            $value="";
            return $obj->SetError (95, "No value provided for parameter '$ident'") 
               unless $choice->{value_type} eq "?";
            }
         }
      $obj->SaveSwitchedParam($ident, $value, $choice, $switch, $index);
      }
   return 1;
   }
   

# util, not class member
sub _EatSwitch   
   {
   my ($str) = @_;
   my $switch;

   ($switch, $str) = $str =~ /^\s*(--)?(.*)$/;
   return ($switch, $str) if $switch;
   
   
   ($switch, $str) = $str =~ /^\s*([-\/])?(.*)$/;
   return ($switch, $str);
   }

   
# util, not class member
sub _EatIdent    
   {
   my ($str) = @_;
   my $ident;
   
   return($str, "") if $str eq "?"; #special case
   ($ident, $str) = $str =~ /^\s*([^\t :=]+)([\t :=].*)?$/;
   return ($ident, $str);
   }

   
# util, not class member
sub _EatDelimiter   
   {
   my ($str, $choice) = @_;
   my $delimiter;
   
   return ("", "") unless $str;
   ($delimiter, $str) = $str =~ /^\s*([=: ])?(.*)$/;
   return ($delimiter, $str);
   }

   
# util, not class member
sub _EatValue       
   {
   my ($str, $choice) = @_;
   return ($str, "");
   }

   
# util, not class member
sub _EatChar
   {
   my ($str) = @_;
   
   my ($char, $rest) = $str =~ /^(.)(.*)$/;
   return ($char, $rest);
   }
   
   
sub SaveFreeParam   
   {
   my ($obj, $ident, $index) = @_;
   
   #my $choice = $CHOICES->{$FREE_IDENT};
   my $choice = $obj->{choices}->{$FREE_IDENT};
   
   my $hits   = $choice->{hits};
   my $hit    = {name=>$ident, value=>undef, index=>$index};
   
   push @{$hits}, $hit;
   }

   
sub SaveSwitchedParam   
   {
   my ($obj, $ident, $value, $choice, $switch, $index) = @_;

   $value = "" if !defined $value;
   
#   $value ||= "" if ($value ne "0");
   my $hits = $choice->{hits};
   my $hit  = {name=>$ident, value=>"$value", switch=>"$switch", index=>$index};
   push @{$hits}, $hit;
   }

   
sub FindChoice
   {
   my ($obj, $ident) = @_;
   
   # exact match?
   return $obj->{choices}->{$ident} if exists $obj->{choices}->{$ident};

   # case insensitive match   
   foreach my $name (sort keys %{$obj->{choices}})
      {
      my $choice = $obj->{choices}->{$name};
      return $choice if $ident =~ /^$name$/i && $choice->{nocase};
      }
      
   # minimal match 
   my $matched_choice = undef;
   my $match_count = 0;
   foreach my $name (sort keys %{$obj->{choices}})
      {
      my $choice = $obj->{choices}->{$name};

      if ($name =~ /^$ident/i)
         {
         # false match
         next if (!$choice->{nocase}) && !($ident =~ /^$name$/);
         $matched_choice = $choice;
         $match_count++;
         }
      }
   return $matched_choice if $match_count == 1;
   return $obj->SetError(94, "Unknown parameter specified: $ident") if !$match_count;
   return $obj->SetError(93, "Ambiguous parameter specified: $ident");
   }

   
sub Is
   {
   my ($obj, $name) = @_;

   $name ||= $FREE_IDENT;
   my $choice = $obj->{choices}->{$name};
   return 0 unless $choice;
   return scalar @{$choice->{hits}};
   }

   
sub Get
   {
   my ($obj, $name, $index) = @_;
   
   return $obj->GetFreeParam($index) unless $name;
   $index ||= 0;
   my $choice = $obj->{choices}->{$name};
   return undef unless $choice;
   return undef if $index >= scalar @{$choice->{hits}};
   return ${$choice->{hits}}[$index]->{value};
   }


sub Switch
   {
   my ($obj, $name, $index) = @_;
   
   return $obj->GetFreeParam($index) unless $name;
   $index ||= 0;
   my $choice = $obj->{choices}->{$name};
   return undef unless $choice;
   return undef if $index >= scalar @{$choice->{hits}};
   return ${$choice->{hits}}[$index]->{switch};
   }

   
sub GetFreeParam
   {
   my ($obj, $index) = @_;
   
   $index ||= 0;
   my $choice = $obj->{choices}->{$FREE_IDENT};
   return undef if $index >= scalar @{$choice->{hits}};
   return ${$choice->{hits}}[$index]->{name};
   }

sub GetError     {my ($obj) = @_; return $obj->{errormsg }}
sub GetErrorCode {my ($obj) = @_; return $obj->{errorcode}}
sub GetOK        {my ($obj) = @_; return $obj->{ok       }}

   
#$obj->SetError(code,msg,retval)
sub SetError   
   {
   my ($obj, $errorcode, $errormsg, $retval) = @_;
   
   $obj->{errorcode} = $errorcode; 
   $obj->{errormsg}  = $errormsg . "\n";
   $obj->{ok}        = $obj->{errorcode} ? 0 : 1;
   
   return scalar(@_) > 4 ? $retval : $obj->{ok};
   }
   
sub ClearError   
   {
   my ($obj) = @_;
   return $obj->SetError(0,"");
   }

   
sub Dump
   {
   my ($obj) = @_;
   
   foreach my $key (sort keys %{$obj->{choices}})
      {
      next if $key eq $FREE_IDENT;
      
      my $choice = $obj->{choices}->{$key};
      
      print "choice: $choice->{string}\n";
      print "   name         : $choice->{name         }\n";
      print "   value_type   : $choice->{value_type   }\n";
      print "   nocase       : $choice->{nocase       }\n";
      print "   minimal_match: $choice->{minimal_match}\n";
      
      if (exists $choice->{hits} && scalar @{$choice->{hits}})
         {
         print "   instances:\n";
         map {print "      $_->{name} => '$_->{value}' switch => '$_->{switch}'\n"} @{$choice->{hits}};
         }
      print "------------------------------------------------\n";
      }
   print "Unswitched parameters:\n";
   map {print "   $_->{name}\n"} @{$obj->{choices}->{$FREE_IDENT}->{hits}};
   }


1; # two

  
__END__   
