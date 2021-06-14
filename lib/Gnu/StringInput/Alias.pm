#
# StringInput::Alias.pm - 
#  C Fitzgerald xx/xx/2013
#
# this module is required by Gnu::StringInput

use strict;
use warnings;


# constants
my $NAM_ALIASES     = "__aliases"    ;
my $NAM_ALIASES_REF = "__aliases_ref";

sub SIAliases 
   {
   my ($clear) = @_;
   
   return VarSet ($NAM_ALIASES=>{}) if $clear;
   return VarInit($NAM_ALIASES=>{});
   }


# get   : name, undef
# set   : name, val
# clear : name, "clear"
#   
sub SIAlias
   {
   my ($name, $val) = @_;
   
   my $aliases = SIAliases();
   return $aliases->{$name} unless defined $val;
   return delete $aliases->{$name} if ($val =~ /^clear$/ or $val eq "");
   return $aliases->{$name} = $val;
   }   
   
   
sub SIIsAlias
   {
   my ($name) = @_;
   return defined SIAlias($name);
   }   

   
################################################################  

# blaa          #                         return str  # (0, str     )
# alias         #            print list,  return ""
# alias clear   # clear all, print mag,   return ""
# alias foo     #            print alias  return ""
# alias foo=    # clear foo, print mag,   return ""
# alias foo=bar # set foo    print mag,   return ""
# 
sub _HandleAliasCmd
   {
   my ($str) = @_;
   
   my ($cmd, $result) = _ParseAliasCmd($str);
   return $str unless $cmd;
   print "$result\n" if $result;
   return "";
   }   

   
sub _ParseAliasCmd
   {
   my ($str) = @_;
   
   return (0, $str) unless SIIsAliasCmd($str);
   
   my ($name,$set,$val) = $str =~ /^alias\s+(\w+)?\s*(\=)?\s*(.*)$/;
   
      $set  = $set  && ($set eq "="    );
   my $aclr = $name && ($name eq "clear");
   my $oclr = $set  && !(defined($val) || length($val));

   return !$name ? return (1, _ShowAliases()                                ) :
           $aclr ? return (2, "aliases cleared"    , SIAliases(1)           ) :
          !$set  ? return (3, SIAlias($name) || ""                          ) :
           $oclr ? return (4, "alias cleared"      , SIAlias($name, "clear")) :
           $set  ? return (5, "alias set"          , SIAlias($name, $val)   ) :
                   return (0, $str                                          ) ;
   }   

 
sub SIIsAliasCmd
   {
   my ($str) = @_;
   
   $str =~ /^alias/;
   
   return ($str && $str =~ /^alias( |$)/) ? 1 : 0;
   }
   
   
sub _ShowAliases
   {
   my $aliases = SIAliases();
   my $colsize = max(map{length $_} (keys %{$aliases})) || 0;
   my $data    = "Aliases:\n";   
   foreach my $name (sort keys %{$aliases})
      {
      $data .= sprintf(" %-*s=%s\n", $colsize, $name, $aliases->{$name});
      }
   return "$data\n";   
   }


sub SIInterpolateAlias
   {
   my ($str) = @_;
   
   return $str unless $str;
   
   my @parts = (split(/\s/, $str), "", "", "", "", "", "", "", "", "");
   my $data = SIAlias($parts[0]);
   return $str unless defined $data;

   # replace %1 - %n   
   $data =~ s{\%(\d)}{$parts[$1] ? $parts[$1] : "\%$1"}gei;
   
   # replace %$  
   if ($data =~ /\%\$/)
      {
      my ($tail) = $str =~ /^\s*\w+\s*(.*?)$/;
      $tail ||= "";
      $data =~ s{\%\$}{$tail}gei;
      }
   
   return SIInterpolateAlias($data);
   }


################################################################  
#
#

sub Al_CreateStream
   {
   my (%options) = @_;

   return "" if SkipStream(0, "alias", %options);

   SIContext({push=>1});
   my $stream = "";
   foreach my $context (SIContext({ctxlist=>1,all=>1}))
      {
      $stream .= CreateContextAliasStream($context, %options);
      }
   SIContext({pop=>1});
   return $stream;
   }

sub CreateContextAliasStream
   {
   my ($context, %options) = @_;

   SIContext($context);
   return "" if SkipStream($context, "alias", %options);

   my $href = VarDefault($NAM_ALIASES_REF=>0);
   return "sialiasref:$context:$href\n" if ($href);
   
   my $aliases = SIAliases();
   my $stream = "";
   foreach my $name (sort keys %{$aliases})
      {
      $stream .= "sialias:$context:$name=$aliases->{$name}\n";
      }
   return $stream;
   }

sub Al_LoadStream
   {
   my ($stream, %options) = @_;

   return 0 if SkipStream(0, "alias", %options);

   my $all_alias = {};
   my $all_alias_ref = {};
   foreach my $line(split(/\n/, $stream)) 
      {
      $line = CleanInputLine($line,1,0);
      my ($linetype,$context,$entry) = $line =~ /^(sialias|sialiasref):([^:]+):(.*)$/;
      next unless $context && $entry;
      my ($name,$val) = $entry =~ /^(.+)=(.*)$/;
      next unless $name;
      
      $all_alias->{$context} = {} if !exists $all_alias->{$context};
      
      if ($linetype eq "sialiasref")
         {
         $all_alias_ref->{$context} = $entry;
         }
      else
         {
         $all_alias->{$context}->{$name} = $val;
         }
      }
   SIContext({push=>1});
   foreach my $context (keys %{$all_alias})
      {
      SIContext($context);
      next if SkipStream($context, "alias", %options);
      VarSet($NAM_ALIASES=>$all_alias->{$context});
      }
   foreach my $context (keys %{$all_alias_ref})
      {
      SIContext($context);
      next if SkipStream($context, "alias", %options);
      VarSet($NAM_ALIASES_REF=>$all_alias_ref->{$context});
      }
   SIContext({pop=>1});
   return 1;
   }
   
1;