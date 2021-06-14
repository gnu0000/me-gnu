package Gnu::Gscript;

use warnings;
use strict;
use lib "../../lib";
no warnings 'recursion';
use feature 'state';
use Time::HiRes;
use Gnu::DebugUtil qw(DumpRef  _StkStr);
use Gnu::Gscript::Tokenize qw(:ALL);
use Gnu::Gscript::Parse    qw(:ALL);

require Exporter;
our $VERSION     = 0.40;
our @ISA         = qw(Exporter);
our @EXPORT      = qw(Gscript);

################################################################################
#
# The GScript class
#
# Synopsis1:
#     var $result = Gscript(file => "foo.scr");
#
#
# Synopsis2:
#     var $gs = Gnu:Gscript->New(loglevel => 1);
#     var $gs = Gnu:Gscript->New(subs => {ZapIt => \&ZapIt});
#
#     $gs->Load(file => 'foo.scr');
#     die ($gs->GetError()) if $gs->IsError();
#
#     my $result1 = $gs->Eval();
#     die ($gs->GetError()) if $gs->IsError();
#
#     $gs->Options(logLevel => 1, vars => {echo=>0, show=>1});
#     my $result2 = $gs->Eval();
#
# options:
#    vars         => {name=>val, ...}      predefine some global variables
#    subs         => {name=>\&name, ,...}  add bindings to perl subs
#    loglevel     => 0 - 3                 set logging level for evaluation of script
#    parseloglevel=> 0 - 3                 set logging level for parsing of script
#    tokenloglevel=> 0 - 3                 set logging level for tokenizing of script
#    dieOnError   => 0 | 1                 kill process on any error
#
# construct:
#     var $gs = Gnu:Gscript->New()
#     var $gs = Gnu:Gscript->New(options...)
#
# load file/script
#     $gs->Load(file => 'foo.scr', options...)
#     $gs->Load(script => $scriptString, options...)
#
# Execute the script
#     $ret = $gs->Eval(options...)
#
# Run is load plus execute
#     $ret = $gs->Run(file => 'foo.txt', options...)
#     $ret = $gs->Run(script => 'foo.txt', options...)
#
# Set / Change options
#     $gs->Options(options...)
#
# Add vars or subs (van be done via options too)
#     $gs->AddVars(varname => varvalue, ...)
#     $gs->AddFns(fnname => \&fnname, ...)
#
# Check/Get error state
#     $bool = $gs->IsError()
#     $ret = $gs->GetError()

my $GLOBAL_SCOPE = {__parent__ => undef, PI => 4 * atan2(1,1)};

my $PERL_FNS = {
   defined => sub{defined $_[1]},
   keys    => sub{_keys($_[1])},
   count   => sub{scalar keys %{$_[1]}},
   length  => sub{length ($_[1])},
   print   => sub{shift; print(@_)},
   sprintf => sub{shift; sprintf(shift @_, @_)},
   println => sub{shift; print(@_, "\n")},
   int     => sub{int  ($_[1])},
   abs     => sub{abs  ($_[1])},
   exp     => sub{exp  ($_[1])},
   log     => sub{log  ($_[1])},
   log10   => sub{log  ($_[1])/log(10)},
   sqrt    => sub{sqrt ($_[1])},
   rand    => sub{rand ($_[1])},
   srand   => sub{srand($_[1])},
   sin     => sub{sin  ($_[1])},
   cos     => sub{cos  ($_[1])},
   atan    => sub{atan2($_[1],$_[2])},
   asin    => sub{atan2($_[1], sqrt(1-$_[1]*$_[1]))},
   acos    => sub{atan2(sqrt(1-$_[1]*$_[1]), $_[1])},
   oct     => sub{oct  ($_[1])},
   hex     => sub{hex  ($_[1])},
#  time    => sub{time ($_[1])},
   timer   => sub{timer($_[1])},
   dumpref => sub{DumpRef($_[1], "  ", 20)},
   dmpstk  => \&DumpStack,
};

# todo: leaf prop should be defer, defer should be removed and a fn in table
my %OPS = (
   '='      => {fn => sub {$_[1] =   $_[2]}, assign=>2},
   '+='     => {fn => sub {$_[1] +=  $_[2]}, assign=>1},
   '-='     => {fn => sub {$_[1] -=  $_[2]}, assign=>1},
   '*='     => {fn => sub {$_[1] *=  $_[2]}, assign=>1},
   '/='     => {fn => sub {$_[1] /=  $_[2]}, assign=>1},
   '?'      => {fn => sub {_Eval($_[0], $_[1]) ? _Eval($_[0], $_[2]) : _Eval($_[0], $_[3])}, defer=>1},
   'or'     => {fn => sub {$_[1]  or $_[2]}},
   'xor'    => {fn => sub {$_[1] xor $_[2]}},
   'and'    => {fn => sub {$_[1] and $_[2]}},
   'not'    => {fn => sub {not $_[1]      }},
   ','      => {fn => sub {$_[1]          }},
   ';'      => {fn => sub {$_[2]          }},
   '=>'     => {fn => sub {$_[1] =>  $_[2]}},
   '||'     => {fn => sub {$_[1] ||  $_[2]}},
   '&&'     => {fn => sub {$_[1] &&  $_[2]}},
   '|'      => {fn => sub {$_[1] |   $_[2]}},
   '&'      => {fn => sub {$_[1] &   $_[2]}},
   '=='     => {fn => sub {$_[1] ==  $_[2]}},
   '!='     => {fn => sub {$_[1] !=  $_[2]}},
   'eq'     => {fn => sub {$_[1] eq  $_[2]}},
   'ne'     => {fn => sub {$_[1] ne  $_[2]}},
   '<=>'    => {fn => sub {$_[1] <=> $_[2]}},
   'cmp'    => {fn => sub {$_[1] cmp $_[2]}},
   '<'      => {fn => sub {$_[1] <   $_[2]}},
   '>'      => {fn => sub {$_[1] >   $_[2]}},
   '<='     => {fn => sub {$_[1] <=  $_[2]}},
   '>='     => {fn => sub {$_[1] >=  $_[2]}},
   'lt'     => {fn => sub {$_[1] lt  $_[2]}},
   'gt'     => {fn => sub {$_[1] gt  $_[2]}},
   'le'     => {fn => sub {$_[1] le  $_[2]}},
   'ge'     => {fn => sub {$_[1] ge  $_[2]}},
   '+'      => {fn => sub {defined $_[2] ? $_[1] + $_[2] :   $_[1]}},
   '-'      => {fn => sub {defined $_[2] ? $_[1] - $_[2] : 0-$_[1]}},
#  '.'      => {fn => sub {$_[1] .   $_[2]}},
   '*'      => {fn => sub {$_[1] *   $_[2]}},
   '/'      => {fn => sub {$_[1] /   $_[2]}},
   '%'      => {fn => sub {$_[1] %   $_[2]}},
   '=~'     => {fn => sub {$_[1] =~  $_[2]}},
   '!~'     => {fn => sub {$_[1] !~  $_[2]}},
   '!'      => {fn => sub {!$_[1]         }},
   '++'     => {fn => sub {++$_[1]        }, assign=>1},
   '--'     => {fn => sub {--$_[1]        }, assign=>1},
   '**'     => {fn => sub {$_[1] **  $_[2]}},
   '['      => {fn => sub {$_[1]->{$_[2]} }},
   'int'    => {fn => sub {$_[1]->{val}   }, leaf=>1},
   'float'  => {fn => sub {$_[1]->{val}   }, leaf=>1},
   'string' => {fn => sub {$_[1]->{val}   }, leaf=>1},
   'istring'=> {fn => sub {Istring($_[0],$_[1]) }, leaf=>1},
   'ident'  => {fn => sub {Val($_[0],$_[1])     }, leaf=>1},
   'fn'     => {fn => sub {Fn($_[0],$_[1])      }, leaf=>1},
   'true'   => {fn => sub {1              }, leaf=>1},
   'false'  => {fn => sub {0              }, leaf=>1},
   '.'      => {fn => \&EvalDot            , leaf=>1},
   'if'     => {fn => \&EvalIf             , leaf=>1},
   'for'    => {fn => \&EvalFor            , leaf=>1},
   'while'  => {fn => \&EvalWhile          , leaf=>1},
   'var'    => {fn => \&EvalVar            , leaf=>1},
   'return' => {fn => \&EvalReturn         , leaf=>1},
   'next'   => {fn => \&EvalNext           , leaf=>1},
   'last'   => {fn => \&EvalLast           , leaf=>1},
   '{'      => {fn => \&EvalBlock          , leaf=>1},
   '{{'     => {fn => \&EvalHash           , leaf=>1},
);

###############################################################################
#
# Exported Fn's
#

# A quick non object call:
#  Gscript(file => 'foo.scr', options...)
#  Gscript(script => 'x=2;', options...)
#
sub Gscript
   {
   my (%options) = @_;

   my $gs = Gnu::Gscript->New();
   $gs->Load(%options);
   return undef if IsError();
   return $gs->Eval();
   }


###############################################################################
#
# OO interface
#

sub New
   {
   my ($class, %options) = @_;

   my $self = {options=>{}};
   my $gs = bless ($self, $class);
   $gs->{scope        } = {__parent__ => $GLOBAL_SCOPE};
   $gs->{subs         } = {%{$PERL_FNS}};
   $gs->{loglevel     } = 0;
   $gs->{parseloglevel} = 0;
   $gs->{tokenloglevel} = 0;
   $gs->Options(%options);
   return $gs;
   }

sub Load
   {
   my ($gs, %options) = @_;

   return $gs->SetError("no file or script option given") unless $options{file} || $options{script};
   $gs->Options(%options);
   $gs->{returns} = [];
   $gs->{err    } = "";
   $gs->{isnext } = 0 ;
   $gs->{islast } = 0 ;
   $gs->{script } = exists $options{file} ? $gs->LoadFile($options{file}) : $options{script};
   $gs->{tree   } = Parse($gs->{script});
   return $gs->SetError(GetParseError()) unless $gs->{tree};
   $gs->{fns    } = $gs->DefineFns({}, $gs->{tree});
   }

sub Options
   {
   my ($gs, %options) = @_;

   $gs->AddVars(%{$options{vars}}) if exists $options{vars};
   $gs->AddSubs(%{$options{subs}}) if exists $options{subs};

   $gs->{loglevel} = $options{loglevel}      if exists $options{loglevel     };
   SetParseLogLevel($options{parseloglevel}) if exists $options{parseloglevel};
   SetTokenLogLevel($options{tokenloglevel}) if exists $options{tokenloglevel};

   $gs->{options} = {%{$gs->{options}}, %options};
   }

sub Eval
   {
   my ($gs, %options) = @_;

   $gs->Options(%options);
   $gs->PushScope();
   my $val = $gs->_Eval($gs->{tree});
   $gs->PopScope();

   return pop(@{$gs->{returns}}) if (scalar @{$gs->{returns}});
   return $val;
   }

sub Run
   {
   my ($gs, %options) = @_;

   $gs->Load(%options);
   return undef if IsError();
   return $gs->Eval();
   }

sub DefineFns
   {
   my ($gs, $fns, $node) = @_;

   return $fns unless $node;

   $gs->FnDecl($fns, $node) if ($node->{type} eq "fn" && $node->{right});
   $gs->DefineFns($fns, $node->{left});
   $gs->DefineFns($fns, $node->{right});
   return $fns;
   }

sub FnDecl
   {
   my ($gs, $fns, $node) = @_;

   $fns->{$node->{val}} = $node;
   }

sub _Eval
   {
   my ($gs, $node) = @_;

#Check($gs);

   return undef if $gs->Skip($node);

   $gs->Log(2, "[type:$node->{type}, val:$node->{val}]\n");

   my $type = $node->{type};
   $type = $node->{val} if $type eq "op";
   my $op = $OPS{$type} or $gs->Die("unknown token '$type'", $node);
   my $fn = $op->{fn};
   return &$fn($gs, $node)        if $op->{leaf};
   return $gs->Assign($node, $op) if $op->{assign};
   return &$fn($gs, $node->{left}, $node->{right}, $node->{extra}) if $op->{defer};
   return &$fn($gs, $gs->_Eval($node->{left}), $gs->_Eval($node->{right}), $gs->_Eval($node->{extra}));
   }

sub Skip
   {
   my ($gs, $node) = @_;

#Check($gs);

   return 1 if (scalar @{$gs->{returns}}) or !defined $node;
   return 1 if $gs->{isnext} || $gs->{islast};
   return 0;
   }

sub EvalIf
   {
   my ($gs, $node) = @_;

#Check($gs);

   $gs->PushScope();
   my $truth = $gs->_Eval($node->{cond});
   $truth ? $gs->_Eval($node->{true}) : $gs->_Eval($node->{false});
   $gs->PopScope();
   return $truth;
   }

sub EvalFor
   {
   my ($gs, $node) = @_;

#Check($gs);

   $gs->PushScope();
   $gs->_Eval($node->{var});
   while($gs->_Eval($node->{cond}))
      {
      $gs->_Eval($node->{body});
      $gs->{isnext}=0;
      last if $gs->{islast};
      $gs->_Eval($node->{op});
      }
   $gs->{islast}=0;
   $gs->PopScope();
   return 0;
   }

sub EvalWhile
   {
   my ($gs, $node) = @_;
   
#Check($gs);

   $gs->PushScope();
   while($gs->_Eval($node->{cond}))
      {
      $gs->_Eval($node->{body});
      $gs->{isnext}=0;
      last if $gs->{islast};
      }
   $gs->{islast}=0;
   $gs->PopScope();
   return 0;
   }

sub EvalDot
   {
   my ($gs, $node) = @_;

#Check($gs);

   my $l = $gs->_Eval($node->{left});
   if (ref $l eq "HASH")
      {
      return $l->{$node->{right}->{val}};
      }
   return $l . $gs->_Eval($node->{right});
   }


sub EvalVar
   {
   my ($gs, $node, $nocheck) = @_;

#Check($gs);

   my $ident = $node->{left};
   my $init  = $node->{right};
   my $name  = $ident->{val};
   my $here  = exists $gs->{scope}->{$name};
   $gs->Die ("Variable '$name' redefined.", $node) if $here && !$nocheck;

   my $val = $gs->{scope}->{$name} = defined $init ? $gs->EvalVarInit($init) : undef;
   return $val;
   }

sub EvalVarInit   
   {
   my ($gs, $node) = @_;

#Check($gs);

   return $gs->_Eval($node);
   }

sub EvalReturn
   {
   my ($gs, $node) = @_;

#Check($gs);

   my $val = $gs->_Eval($node->{left});
   push(@{$gs->{returns}}, $val);
   return $val;
   }

sub EvalNext
   {
   my ($gs, $node) = @_;
   
#Check($gs);

   $gs->{isnext} = 1;
   }

sub EvalLast
   {
   my ($gs, $node) = @_;
   
#Check($gs);

   $gs->{islast} = 1;
   }

sub EvalBlock
   {
   my ($gs, $node) = @_;

#Check($gs);

   $gs->PushScope();
   my $val = $gs->_Eval($node->{left});
   $gs->PopScope();
   return $val;
   }

sub EvalHash
   {
   my ($gs, $node) = @_;

#Check($gs);

   my $val = $gs->PushScope();
   $gs->EvalHashEntry($node->{left});
   $gs->PopScope();

   delete $val->{__parent__};
   return $val;
   }

sub EvalHashEntry
   {
   my ($gs, $node) = @_;

#Check($gs);

   return unless $node;
   if ($node->{type} eq ',')
      {
      $gs->EvalHashEntry($node->{left});
      $gs->EvalHashEntry($node->{right});
      return;
      }
   $gs->EvalVar($node); # type='=>'
   }

# x++ <-- defer inc/dec is broken
# allowing bare assignment of undeclared vars (= only)
sub Assign
   {
   my ($gs, $node, $op) = @_;

#Check($gs);

   my $name = $node->{left}->{val};
   my $type = $node->{left}->{type};
   $gs->Die("not an lval '$name'", $node) unless $type =~ /ident|\[/;
   my $fn = $op->{fn};
   my $val = $op->{assign} == 2 ? $gs->_Eval($node->{right}) : 
                                  &$fn($gs, $gs->_Eval($node->{left}), $gs->_Eval($node->{right}));
   $gs->Log(1, "assigning '$val' to $name");
   return $gs->SetVal($node->{left}, $val);
   }

sub Val
   {
   my ($gs, $node) = @_;

#Check($gs);

   return $gs->GetVal($node);
   }

sub Fn
   {
   my ($gs, $node) = @_;
   
#Check($gs);

   return if $node->{right}; # a fn declaration, not a call
   my $name = $node->{val};

   if ($gs->{fns}->{$name})
      {
      $gs->Log(2, "calling script fn '$name'");

      my $fnnode = $gs->{fns}->{$name};
      $gs->PushFnScope($fnnode->{left}, $node->{left});
      my $ret = $gs->_Eval($fnnode->{right});
      $gs->PopScope();

      return (scalar @{$gs->{returns}}) ? pop(@{$gs->{returns}}) : $ret;
      }

   if ($gs->{subs}->{$name})
      {
      $gs->Log(2, "calling perl sub '$name'");
      $gs->PushScope();
      my $fn = $gs->{subs}->{$name};
      my $val = &$fn($gs, $gs->_Args($node->{left}));
      $gs->PopScope();
      return $val;
      }
   return $gs->Log(0, "fn/sub '$name' not defined");

   # This can call any locally defined sub - probably a bad idea
   #
   #   no strict 'vars';
   #   my $exists = !!$main::Gnu::Gscript::Eval::{$name};
   #   return Log(1, "fn '$name' not defined") unless $exists;
   #   Log(2, "calling sys fn '$name'");
   #   local *sym = $main::GnuGscript::Eval::{$name};
   #   return undef unless defined &sym;
   #   return &sym($val);
   }

sub CallFn
   {
   my ($gs, $name, @args) = @_;

#Check($gs);

   my $fnnode = $gs->{fns}->{$name};
   return $gs->Log(0, "fn '$name' not defined") unless $fnnode;
   $gs->Log(2, "calling fn '$name'");

   $gs->PushFnScope2($fnnode->{left}, @args);
   my $ret = $gs->_Eval($fnnode->{right});
   $gs->PopScope();
   return $ret;
   }

sub _Params
   {
   my ($gs, $node) = @_;

#Check($gs);

   return () unless $node;
   return ($node->{val}) if $node->{type} eq "ident";
   return ($gs->_Params($node->{left}), $gs->_Params($node->{right}));
   }

sub _Args
   {
   my ($gs, $node) = @_;

#Check($gs);

   return () unless $node;
   return ($gs->_Eval($node)) unless $node->{type} eq ",";
   return ($gs->_Eval($node->{left}), $gs->_Args($node->{right}));
   }

sub FindScope
   {
   my ($gs, $node, $strict) = @_;

#Check($gs);

   my $name = $node->{val};
   my $scope = $gs->{scope};
   while ($scope)
      {
      return $scope if exists $scope->{$name};
      $scope = $scope->{__parent__};
      }
   $gs->Die("Variable $name is not declared", $node) if $strict;
   return $gs->{scope};
   }

sub GetVal
   {
   my ($gs, $node) = @_;

#Check($gs);

   my $name = $node->{val};
   my $scope = $gs->FindScope($node, 1);

   my $val = $scope->{$name};
   return $val;
   }

sub GetValByName
   {
   my ($gs, $name) = @_;

#Check($gs);

   my $scope = $gs->FindScopeByName($name);
   my $val = exists $scope->{$name} ? $scope->{$name} : "";
   # todo
   #if ($node->{hash})
   #   {
   #   my $key = $gs->_Eval($node->{key});
   #   return $val->{key};
   #   }
   return $val;
   }

sub SetVal
   {
   my ($gs, $node, $val) = @_;

#Check($gs);

   if ($node->{type} eq "[")
      {
      my $scope = $gs->FindScope($node->{left}, 0);
      my $name = $node->{left}->{val};

      $scope->{$name} = {} if !defined $scope->{$name};

      $gs->Die ("'$name' is not a hash", $node) unless ref($scope->{$name}) eq "HASH";
      return $scope->{$name}->{$gs->_Eval($node->{right})} = $val
      }
   my $name = $node->{val};
   my $scope = $gs->FindScope($node, 0);
   $gs->Die ("'$name' is a hash", $node) if ref($scope->{$name}) eq "HASH";
   return $scope->{$name} = $val;
   }

# sub Istring
#    {
#    my ($gs, $node) = @_;
# 
# #Check($gs);
# 
#    my $str = $node->{val};
# 
#    my $idx = 0;
#    $str =~ s{\{([^\}]+)\}}{$gs->SubEval($1, $idx++)}gei;
#    return $str;
#    }
# 
# sub SubEval
#    {
#    my ($gs, $expr, $idx) = @_;
# 
# #printf "IDX[$idx][$expr]\n";
# 
#    $gs->{subtree} = Parse($expr);
#    return $expr unless $gs->{subtree};
#    $gs->PushScope();
#    my $val = $gs->_Eval($gs->{subtree});
# 
#    $gs->PopScope();
# 
#    return $val;
#    }
 
sub Istring
   {
   my ($gs, $node) = @_;

   my $str = $node->{val};

   my $idx = 0;
   $str =~ s{\{([^\}]+)\}}{$gs->SubEval($node, $1, $idx++)}gei;
   return $str;
   }

sub SubEval
   {
   my ($gs, $node, $expr, $idx) = @_;

   # cache parse trees for interpolated elements
   my $subtree = $node->{subtree}->{$idx};
   if (!$subtree) {
      $subtree = $node->{subtree}->{$idx} = Parse($expr);
   }
   return $expr unless $subtree;

   $gs->PushScope();
   my $val = $gs->_Eval($subtree);
   $gs->PopScope();

   return $val;
  }



#############################################################################
#
# Scopes
#

sub PushScope
   {
   my ($gs) = @_;

   return $gs->{scope} = {__parent__ => $gs->{scope}};
   }

sub PopScope
   {
   my ($gs) = @_;

#Check($gs);

   $gs->{scope} = $gs->{scope}->{__parent__};
   }

sub PushFnScope
   {
   my ($gs, $nameNode, $valNode) = @_;

#Check($gs);

   $gs->{scope} = {__parent__ => $gs->{scope}};
   @{$gs->{scope}}{$gs->_Params($nameNode)} = $gs->_Args($valNode);
   }


sub PushFnScope2
   {
   my ($gs, $nameNode, @args) = @_;

#Check($gs);

   $gs->{scope} = {__parent__ => $gs->{scope}};
   @{$gs->{scope}}{$gs->_Params($nameNode)} = @args;
   }


sub FindScopeByName
   {
   my ($gs, $name) = @_;

#Check($gs);

   my $scope = $gs->{scope};
   while ($scope)
      {
      return $scope if exists $scope->{$name};
      $scope = $scope->{__parent__};
      }
   return $gs->{scope};
   }

##############################################################################
#
#
#

sub LoadFile
   {
   my ($gs, $filespec) = @_;

#Check($gs);

   open (my $filehandle, "<", $filespec) or return $gs->SetError("Can't open '$filespec'", "");
   my $contents;
   local $/ = undef;
   $contents = <$filehandle>;
   close $filehandle;
   return $contents;
   }

sub AddVars
   {
   my ($gs, %vars) = @_;

#Check($gs);

   return $gs->{scope} = {%{$gs->{scope}}, %vars};
   }

sub AddSubs
   {
   my ($gs, %subs) = @_;

#Check($gs);

   return $gs->{subs} = {%{$gs->{subs}}, %subs};
   }

##############################################################################
#
#
#

sub Die
   {
   my ($gs, $msg, $node) = @_;

   print "Error: $msg";
   print " [$node->{line},$node->{col}]" if $node;
   print "\n";
   exit(1);
   }

sub Log
   {
   my ($gs, $level, $msg) = @_;

#Check($gs);

   return unless $level <= $gs->{loglevel};
   print "eval: $msg\n";
   }

sub SetEvalLogLevel
   {
   my ($gs, $level) = @_;
   
   $gs->{loglevel} = $level;
   }

sub IsError
   {
   my ($gs) = @_;

#Check($gs);

   return !!$gs->{err};
   }

sub GetError
   {
   my ($gs) = @_;

#Check($gs);

   return $gs->{err};
   }

sub SetError
   {
   my ($gs, $message, $ret) = @_;

#Check($gs);

   $gs->{err} = $message;
   return $ret;
   }

sub Stk
   {
   my ($message) = @_;

   print "$message\n";
   for (my $i = 1; $i < 10; $i++)
      {
      my ($stackline) = _StkStr($i) =~ /^.*\/(.*)$/;
      print "STK: $stackline\n";
      }
   }

sub Check
   {
   my ($gs) = @_;

   my $class = ref $gs;

   return if $class =~ /Gnu::Gscript/;

   Stk("BAD class ref");
   exit(0);
   }


##############################################################################
#
# built in perl subs
#

sub DumpStack
   {
   my ($gs) = @_;

   my $scope = $gs->{scope};
   my $level = 0;

   print "*********************\n";
   print DumpRef($scope, "  ", 10);
   print "\n*********************\n";
   }

sub _keys
   {
   my ($hashref) = @_;

   my $i = 0;
   return {map {$i++ => $_} (sort keys %{$hashref})};
   }

sub timer
   {
   my ($index, $return_diff) = @_;

   state $on = {};
   state $start = {};

   $index = 1 unless defined $index;
   $on->{$index} = 0 unless exists $on->{$index};
   $on->{$index} = !$on->{$index};

   my $time  = Time::HiRes::time();
   my @local = localtime($time);
   my ($sec,$min,$hour) = @local;
   my $msg = sprintf("Timer $index ". ($on->{$index}?"on":"off") .": %02d:%02d:%02d",$hour, $min, $sec);

   if ($on->{$index}) 
      {
      $start->{$index} = [$time, @local];
      return $msg;
      } 
   my $diff = $time - $start->{$index}->[0];
   return $diff if $return_diff;
   my $h = int($diff/3600);
   my $m = int(($diff-$h*3600)/60);
   my $s = $diff-$h*3600-$m*60;
   return $msg . sprintf("  Elapsed: %02d:%02d:%3.3f", $h, $m, $s);
   }

#print "included: ", __PACKAGE__, "\n";

1; # two
  
