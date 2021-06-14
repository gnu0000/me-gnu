#
# DebugUtil.pm 
#
# Synopsis:
#
#    my $chain = {---stuff---};
#    DumpHash("chain", $chain, 2);
#    print DumpRef($chain, " ", 10);
#    
# Functions:   
#    
#    DumpHash($label, $hash, $indent, $shallow)
#    DumpRef($var, $gap, $levels)
#    _StackLocation($stack_level_hint, $full_trace)
#    
# Craig Fitzgerald
#
package Gnu::DebugUtil;

use warnings;
use strict;
require Exporter;

our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(DumpHash DumpRef _StackLocation _StkStr);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);
our $VERSION     = 0.10;

###############################################################################


sub DumpHash
   {
   my ($label, $hash, $indent, $shallow) = @_;

   $shallow ||= 0;
   $indent  ||= 0;
   my $gap = " " x $indent;
   print "--------------------------------" unless $indent;
   print "\n";
   print "Hash: '$label': \n" if $label;
   foreach my $key (sort keys %{$hash})
      {
      print sprintf ("$gap%10s => ", $key);
      my $val     = $hash->{$key};

#      if ((ref $val) =~ /HASH/i)
#         {
#         DumpHash("", $val, $indent+2) 
#         }
#      else
#         {
#         print "'$val'";
#         }

#     DumpHash("", $val, $indent+2) if $recurse;
#     print "'$val'"                if $recurse;
      my $recurse = (defined $val) && ((ref $val) =~ /HASH/i) && !$shallow;
      $recurse ? DumpHash("", $val, $indent+2) : print "'$val'";
      print "\n";
      }
   print "--------------------------------\n" unless $indent;
   }

sub DumpRef
   {
   my ($var, $gap, $levels) = @_;

   return "" unless $levels;
   my ($type, $d_fn) = _reftype($var);
   return $d_fn->($var, $gap, $levels,$type);
   }


sub d_undef  {_d_type(@_)}
sub d_unknown{_d_type(@_)}
sub d_coderef{_d_type(@_)} 

sub d_hashref   
   {
   my ($var, $gap, $levels,$type) = @_;

   my $keyct = scalar (keys %{$var});
   my $str = "[hashref] ($keyct keys)\n";
   $str .= $gap . "---------------------------\n";
   foreach my $key (sort keys %{$var})
      {
      $str .=  $gap . "$key: " . 
               DumpRef($var->{$key},$gap . "  ",$levels-1) . "\n";
      }
   $str .= $gap . "---------------------------";
   return $str;
   }

sub d_arrayref  
   {
   my ($var, $gap, $levels,$type) = @_;

   my $rowct = scalar @{$var};
   my $str = "[arrayref] ($rowct rows)\n";
   $str .= $gap . "---------------------------\n";

   for my $index (0..$rowct-1)
      {
      $str .= $gap . 
               sprintf("[%-4d] ", $index) .
               DumpRef($var->[$index],$gap . "  ",$levels-1) . "\n";
      }
   $str .= $gap . "---------------------------";
   return $str;
   }

sub d_scalarref 
   {
   my ($var, $gap, $levels,$type) = @_;
   return "[$type]\n$gap" . DumpRef(${$var},$gap."  ",$levels-1);
   }


sub d_refref    
   {
   my ($var, $gap, $levels,$type) = @_;
   return "[$type]\n$gap" . DumpRef(${$var},$gap."  ",$levels-1);
   ;
   }

sub d_scalar    
   {
   my ($var, $gap, $levels,$type) = @_;
   return "$var";
   }

sub _d_type
   {
   my ($var, $gap, $levels,$type) = @_;

   return "[$type]";
   }

sub _reftype
   {
   my ($var) = @_;

   return ("*undefined*", \&d_undef    ) unless defined $var;

   my $r = ref($var);
   return ("hashref"    , \&d_hashref  ) if $r =~ /^HASH/   ;
   return ("arrayref"   , \&d_arrayref ) if $r =~ /^ARRAY/  ;
   return ("coderef"    , \&d_coderef  ) if $r =~ /^CODE/   ;
   return ("scalarref"  , \&d_scalarref) if $r =~ /^SCALAR/ ;
   return ("refref"     , \&d_refref   ) if $r =~ /^REF/    ;
   return ("*scalar*"   , \&d_scalar   ) if !$r             ;
   return ("*unknown*"  , \&d_unknown  )                    ;
   }
   
   
sub _StackLocation
   {
   my ($stack_level_hint, $full_trace) = @_;

   return _StkStr (($stack_level_hint||0)+1) unless $full_trace;

   my ($stack, $stackloc, $i);
   for ($i = $stack_level_hint+1; ($stackloc = _StackLocation ($i)) && $i < 20; $i++)
      {
      $stack .= $stackloc . "\n";
      }
   return $stack;
   }


sub _StkStr
   {
   my ($stack_level) = @_;

   my ($package, $filename, $line, $subr, $has_args, $wantarray) = caller ($stack_level);

   $filename ||= "";
   $subr     ||= "";
   $line     ||= "";

   return "$filename:$subr:$line";
   }

1; # two
  
__END__   
