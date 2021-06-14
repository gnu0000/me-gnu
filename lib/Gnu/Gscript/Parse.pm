#
# Craig Fitzgerald 2020-09-06
#
package Gnu::Gscript::Parse;

use warnings;
use strict;
no warnings 'recursion';
use lib "../../../lib";
use Gnu::Gscript::Tokenize qw(Tokenize GetTokenError);
use Gnu::DebugUtil qw(DumpRef  _StkStr);

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(Parse GetParseError GetParseErrorTree SetParseLogLevel);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);
our $VERSION     = 0.10;

my $TOKENS = [];
my $ERR;
my $ERRTREE;
my $LOGLEVEL = 0;

###############################################################################
#  stmt  ;
#  block {}
#    if
#    else
#    while
#    for
#    var
#    return
#    next
#    last
#    expr
#        ;
#        or xor
#        and
#        not
#        , =>
#        = += -= *= /=
#        ? :
#        ||
#        &&
#        |
#        &
#        == != eq ne <=> cmp
#        < > <= >= lt gt le ge
#        + -
#        * / %
#        =~ !~
#        ! + -
#        ++ --
#        **
#        ()
#        int float string ident fn

sub Parse
   {
   my ($expr) = @_;

   $ERR = "";
   $TOKENS = Tokenize($expr);
   return SetError(GetTokenError()) unless $TOKENS;

   my $tree = ParseAll();
   DumpTree($tree, 0, "tree") if $LOGLEVEL;
   return SetError("Parse Error: Unexpected: '$TOKENS->[0]->{val}'", $TOKENS->[0]) if scalar @{$TOKENS};

   return length GetParseError() ? undef : $tree;
   }

sub ParseAll
   {
   Log(4, "ParseAll");

   my $node = ParseStmt();
   $node = Node(Chain(), $node, ParseStmt()) while ($node && HasMore() && !Peek("}"));
   return $node;
   }
   
sub ParseBlock
   {
   Log(4, "ParseBlock");

   my $node = Node(Eat("{"), ParseAll());
   Eat("}");
   return $node;
   }

sub ParseStmt
   {
   return undef if Peek("}");

   return ParseBlock()  if Peek("{");
   return ParseIf()     if Peek("if");
   return ParseFor()    if Peek("for");
   return ParseWhile()  if Peek("while");
   return ParseReturn() if Peek("return");
   return ParseNext()   if Peek("next");
   return ParseLast()   if Peek("last");
   return ParseExpression();
   }

sub ParseIf
   {
   Log(4, "ParseIf");
   my $tok = Eat("if");
   Eat("(");
   $tok->{cond} = ParseExpression();
   Eat(")");

   $tok->{true} = ParseStmt();
   if (Peek("else"))
      {
      Eat("else");
      $tok->{false} = ParseStmt();
      }
   return $tok;
   }

sub ParseFor
   {
   Log(4, "ParseFor");
   my $tok = Eat("for");
   Eat("(");
   $tok->{var}  = ParseExpression();
   $tok->{cond} = ParseExpression();
   $tok->{op}   = ParseExpression();
   Eat(")");
   $tok->{body} = Peek("{") ? ParseBlock() : ParseStmt();
   return $tok;
   }

sub ParseWhile
   {
   Log(4, "ParseWhile");
   my $tok = Eat("while");
   Eat("(");
   $tok->{cond} = ParseExpression();
   Eat(")");
   $tok->{body} = Peek("{") ? ParseBlock() : ParseStmt();
   return $tok;
   }

sub ParseVar
   {
   Log(4, "ParseVar");
   my $tok = ParseVarIdent(Eat("var"));
   $tok = Node(Chain(), $tok, ParseVarIdent(Convert(Eat(","),"var"))) while (Peek(","));
   Eat(";");
   return $tok;
   }

sub ParseVarIdent 
   {
   my ($tok) = @_;

   Log(4, "ParseVarIdent");
   $tok->{left} = Eat("ident");
   if (Peek("="))
      {
      Eat("=");
#     $tok->{right} = ParseInit();
      $tok->{right} = ParseExpr05();
      }
   return $tok;
   }

#sub ParseInit
#   {
#   Log(4, "ParseInit");
#   return Peek("{") ? ParseHashInit() : ParseExpr05();
#   }
   
#sub ParseHashInit
#   {
#   Log(4, "ParseHashInit");
#
#   my $tok = Eat("{");
#   my $node = ParseHashEntry();
#   $node = Node(Eat(","), $node, ParseHashEntry()) while Peek(",");
#   Eat("}");
#   return Node($tok, $node);
#   }
#

sub ParseReturn
   {
   Log(4, "ParseReturn");
   my $tok = Eat("return");
   $tok->{left} = ParseExpr05() unless Peek(";");
   Eat(";");
   return $tok;
   }

sub ParseNext
   {
   Log(4, "ParseNext");
   my $tok =  Eat("next");
   Eat(";");
   return $tok;
   }

sub ParseLast
   {
   Log(4, "ParseLast");
   my $tok = Eat("last");
   Eat(";");
   return $tok;
   }

sub ParseExpression
   {
   return Peek("var") ? ParseVar() : ParseExpr00();
   }

sub ParseExpr00
   {
   Log(4, "ParseExpr00");
   my $node = ParseExpr01();
   my @ops = ("or", "xor");
   $node = Node(Eat(@ops), $node, ParseExpr01()) while(Peek(@ops));
   Eat(";") if Peek(";");
   return $node;
   }

sub ParseExpr01
   {
   Log(4, "ParseExpr01");
   my $node = ParseExpr02();
   my @ops = ("and");
   $node = Node(Eat(@ops), $node, ParseExpr02()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr02
   {
   Log(4, "ParseExpr02");
   my @ops = ("not");
   return Node(Eat(@ops), ParseExpr02()) if Peek(@ops); 
   return ParseExpr03();
   }

sub ParseExpr03
   {
   Log(4, "ParseExpr03");
   my $node = ParseExpr04();
   my @ops = (",", "=>");
   return Node(Eat(@ops), $node, ParseExpr03()) if Peek(@ops); 
   return $node;
   }

sub ParseExpr04
   {
   Log(4, "ParseExpr04");
   my $node = ParseExpr05();
   my @ops = ("=", "+=", "-=", "*=", "/=");
   return Node(Eat(@ops), $node, ParseExpr04()) if Peek(@ops); 
   return $node;
   }

sub ParseExpr05
   {
   Log(4, "ParseExpr05");
   my $node = ParseExpr06();
   if (Peek("?"))
      {
      my $q = Eat("?");
      my $tnode = ParseExpr06();
      Eat(":");
      my $fnode = ParseExpr05();
      return Node($q, $node, $tnode, $fnode);
      }
   return $node;
   }

sub ParseExpr06
   {
   Log(4, "ParseExpr06");
   my $node = ParseExpr07();
   my @ops = ("||");
   $node = Node(Eat(@ops), $node, ParseExpr07()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr07 # l->r
   {
   Log(4, "ParseExpr07");
   my $node = ParseExpr075();
   my @ops = ("&&");
   $node = Node(Eat(@ops), $node, ParseExpr075()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr075 # l->r
   {
   Log(4, "ParseExpr075");
   return ParseExpr08() unless Peek("{");
#   my $node = Node(Convert(Eat("{"), "{{"), ParseExpr03());
#   Eat("}");
#   return $node;

   my $tok = Convert(Eat("{"), "{{");
   my $node = ParseHashEntry();
   $node = Node(Eat(","), $node, ParseHashEntry()) while Peek(",");
   Eat("}");
   return Node($tok, $node);
   }

sub ParseExpr08 # l->r
   {
   Log(4, "ParseExpr08");
   my $node = ParseExpr09();
   my @ops = ("|");
   #return Node(Eat(@ops), $node, ParseExpr08()) if Peek(@ops); 
   $node = Node(Eat(@ops), $node, ParseExpr09()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr09 # l->r
   {
   Log(4, "ParseExpr09");
   my $node = ParseExpr10();
   my @ops = ("&");
   $node = Node(Eat(@ops), $node, ParseExpr10()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr10 # l->r
   {
   Log(4, "ParseExpr10");
   my $node = ParseExpr11();
   my @ops = ("==", "!=", "eq", "ne", "<=>", "cmp");
   $node = Node(Eat(@ops), $node, ParseExpr11()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr11 # l->r
   {
   Log(4, "ParseExpr11");
   my $node = ParseExpr12();
   my @ops = ("<", ">", "<=", ">=", "lt", "gt", "le", "ge");
   $node = Node(Eat(@ops), $node, ParseExpr12()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr12 # l->r
   {
   Log(4, "ParseExpr12");
   my $node = ParseExpr13();
   my @ops = ("+", "-", ".");
   $node = Node(Eat(@ops), $node, ParseExpr13()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr13 # l->r
   {
   Log(4, "ParseExpr13");
   my $node = ParseExpr14();
   my @ops = ("*", "/", "%");
   $node = Node(Eat(@ops), $node, ParseExpr14()) while(Peek(@ops));
   return $node;
   }

sub ParseExpr14
   {
   Log(4, "ParseExpr14");
   my $node = ParseExpr15();
   my @ops = ("=~", "!~");
   return Node(Eat(@ops), $node, ParseExpr14()) if Peek(@ops); 
   return $node;
   }

sub ParseExpr15
   {
   Log(4, "ParseExpr15");
   my @ops = ("!", "+", "-");
   return Node(Eat(@ops), ParseExpr16()) if Peek(@ops); 
   return ParseExpr16();
   }

sub ParseExpr16
   {
   Log(4, "ParseExpr16");
   my @ops = ("++", "--");
   return Node(Eat(@ops), ParseExpr17()) if Peek(@ops);

   my $node = ParseExpr17();
   return Node(Eat(@ops), $node) if Peek(@ops);
   return $node;

   #return ParseExpr17();
   }

sub ParseExpr17
   {
   Log(4, "ParseExpr17");
   my $node = ParseExpr175();
   my @ops = ("**");
   return Node(Eat(@ops), $node, ParseExpr175()) if Peek(@ops); 
   return $node;
   }

sub ParseExpr175
   {
   Log(4, "ParseExpr175");

   my $node = ParseExpr18();
   while (Peek("["))
      {
      $node = Node(Eat("["), $node, ParseExpr00());
      Eat("]");
      }
   return $node;
   }

sub ParseExpr18
   {
   Log(4, "ParseExpr18");
   return ParseExpr19() unless Peek("(");
   Eat("(");
   my $node = ParseExpression();
   Eat(")");
   return $node;
   }

sub ParseExpr19
   {
   Log(4, "ParseExpr19");
   return ParseFn() if Peek("fn");
   my @types = ("int", "float", "string", "istring", "ident", "true", "false");
   return Node(Eat(@types));
   }

sub ParseFn
   {
   Log(4, "ParseFn");
   my $name = Eat("fn");
   Eat("(");
   my $params = Peek(")") ? undef : ParseExpr03();
   Eat(")");

   if (Peek("=>"))
      {
      Eat("=>");
      return Node($name, $params, ParseStmt(), undef, 1);
      }
   return Node($name, $params);
   }

sub ParseHashEntry
   {
   Log(4, "ParseHashEntry");
   my $key = Eat("string", "istring", "int", "ident");
   return Node(Eat("=>"), $key, ParseExpr05());
   }

sub Peek
   {
   my (@expects) = @_;

   return 0 unless scalar @{$TOKENS};
   my $actual = $TOKENS->[0]->{type};
   $actual = $TOKENS->[0]->{val} if $actual eq "op";
   foreach my $expect (@expects)
      {
      Log(4, "   Peek: $actual vs $expect");
      return 1 if $actual eq $expect;
      }
   return 0;
   }

sub Eat
   {
   my (@expects) = @_;
   
   return SetError("Incomplete expression. Looking for (".join(" ", @expects).")") unless HasMore();

   my $tok = shift @{$TOKENS};

   my ($eater) = _StkStr(1,1) =~ /^.*\/(.*)$/;
   Log(3, "Eating: [type:$tok->{type}, val:$tok->{val}] eaten by " . $eater);

   my $actual = $tok->{type};

   foreach my $expect (@expects)
      {
      return $tok if $actual eq $expect;
      }
   my $exlist = join(",", @expects);
   return SetError("Expected:'$exlist' but got:'$actual'", $tok);
   }

sub Node
   {
   my ($tok, $left, $right, $extra, $nocheck) = @_;

   return undef unless defined $tok;

   $tok->{left } = $left  if defined $left;
   $tok->{right} = $right if defined $right;
   $tok->{extra} = $extra if defined $extra;

   my $check = !$nocheck && (scalar @_ > 2) && ((!defined $left || !defined $right));
   SetError("operand '$tok->{val}' requires 2 operands", $tok) if $check;
   return $tok;
   }

sub Chain
   {
   return {type=>";", val=>";"};
   }

sub Convert
   {
   my ($node, $newval) = @_;

   $node->{type} = $node->{val} = $newval;
   return $node;
   }

sub HasMore
   {
   return scalar @{$TOKENS};
   }

sub SetError
   {
   my ($msg, $tok) = @_;
   $ERR = $msg;
   $ERR .= " ($tok->{line},$tok->{col})" if $tok;

   print "$ERR\n";
   exit(1);
   
   return undef;
   }

sub GetParseError
   {
   return $ERR;
   }

sub DumpTree
   {
   my ($node, $level, $prefix) = @_;

   print "  "x$level . "$prefix ";
   print "[undef]\n" unless $node;
   return unless $node;
   print "'$node->{type}' = '$node->{val}'\n";

   $level++ unless ($node->{type} eq ";") && $LOGLEVEL == 1;
   foreach my $key (sort keys %{$node})
      {
      next if $key =~ /type|val|line|col|init/;
      DumpTree($node->{$key}, $level, $key . ":");
      }
   #DumpTree($node->{left} , $level+1, "left:");
   #DumpTree($node->{right}, $level+1, "right:");
   }

sub Log
   {
   my ($level, $msg) = @_;

   return unless $level <= $LOGLEVEL;
   print "parse: $msg\n";
   }

sub SetParseLogLevel
   {
   my ($level) = @_;
   
   $LOGLEVEL = $level;
   }

###############################################################################

#print "included: ", __PACKAGE__, "\n";

1; # two
  
__END__   
