#
# Craig Fitzgerald 2020-09-06
#
package Gnu::Gscript::Tokenize;

use warnings;
use strict;
use feature 'state';
use lib "../../../lib";
use Gnu::StringUtil qw(TrimNS Trim);

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(Tokenize GetTokenError SetTokenLogLevel);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);
our $VERSION     = 0.10;

my $ERR;
my $LOGLEVEL = 0;
my $ROW      = 0;
my $LLEN     = 0;


###############################################################################

sub Tokenize
   {
   my ($script) = @_;

   $ERR = "";
   my $tokens = [];

   $ROW = 0;
   foreach my $line (split("\n", $script))
      {
      $ROW++;
      chomp $line;
      $line = TrimNS($line, 0, 1);
      $LLEN = length $line;
      #next if $line =~ /\s*#/;
      TokenizeLine($line, $tokens);
      return () if GetTokenError();
      }
   DumpTokens($tokens) if $LOGLEVEL;
   return $tokens;
   }

sub TokenizeLine
   {
   my ($expr, $tokens) = @_;

   $expr = Trim($expr);
   while (length $expr)
      {
      last if $expr =~ /^\s*#/;

      my $ret = 
         TokenizeNum     ($expr) ||
         TokenizeKeyword ($expr) ||
         TokenizeIdent   ($expr) ||
         TokenizeString  ($expr) ||
         TokenizeOp1     ($expr) ||
         TokenizeOp2     ($expr) ||
         TokenizeOp3     ($expr) ||
         SetError        ($expr);
         return () if !defined $ret;
         push (@{$tokens}, $ret->{tok});
         $expr = $ret->{rest};
      }
   return $tokens;
   }

sub SetError
   {
   my ($expr) = @_;

   my $col = $LLEN - length($expr);
   $ERR = "Token Error [". $ROW .",". $col ."] --> $expr";
   return undef;
   }

sub GetTokenError
   {
   return $ERR;
   }

sub TokenizeNum
   {
   my ($expr) = @_;

   my ($tok, $deci, $rest) = $expr =~ /^\s*(\d*(\.?)\d+)(([^a-zA-Z]+|$).*)$/;
   return undef unless defined $tok;
   my $type = $deci ? "float" : "int";
   #return ({tok=>{type=>$type, val=>$tok}, rest=>$rest});
   return ({tok=>Tok($type,$tok,$expr), rest=>$rest});
   }


sub TokenizeKeyword
   {
   my ($expr) = @_;

   my ($tok, $rest) = $expr =~ /^\s*(and|or|not|xor|lt|gt|le|ge|eq|ne|cmp|true|false|for|while|if|else|var|return|next|last)(([^0-9a-zA-Z]|$).*)$/;
   return undef unless $tok;
   #return ({tok=>{type=>$tok, val=>$tok}, rest=>$rest});
   return ({tok=>Tok($tok,$tok,$expr), rest=>$rest});
   }

sub TokenizeIdent
   {
   my ($expr) = @_;

   my ($tok, $rest, $paren) = $expr =~ /^\s*([a-zA-Z]\w*)\s*((\(?).*)$/;
   return undef unless $tok;
   my $type = $paren ? "fn" : "ident";
   #return ({tok=>{type=>$type, val=>$tok}, rest=>$rest});
   return ({tok=>Tok($type,$tok,$expr), rest=>$rest});
   }


# ++ -- && || <=>
sub TokenizeOp1
   {
   my ($expr) = @_;

   my ($tok, $rest) = $expr =~ /^\s*(\+\+|--|&&|\|\||<=>)(.*)$/;
   return undef unless $tok;
   #return ({tok=>{type=>$tok, val=>$tok}, rest=>$rest});
   return ({tok=>Tok($tok,$tok,$expr), rest=>$rest});
   }

# == != <= >= <> ** += -= *= /= =>
sub TokenizeOp2
   {
   my ($expr) = @_;

   my ($tok, $rest) = $expr =~ /^\s*(==|!=|<=|>=|\+=|-=|\*=|\/=|<>|\*\*|=>)(.*)$/;
   return undef unless $tok;
   #return ({tok=>{type=>$tok, val=>$tok}, rest=>$rest});
   return ({tok=>Tok($tok,$tok,$expr), rest=>$rest});
   }

# = + - * / < > & | ! ? : % ( ) . , ; { } [ ]
sub TokenizeOp3
   {
   my ($expr) = @_;

   my ($tok, $rest) = $expr =~ /^\s*(=|\+|-|\*|\/|<|>|&|\||!|\?|:|%|\(|\)|\.|,|;|{|}|\[|\])(.*)$/;
   return undef unless $tok;
   #return ({tok=>{type=>$tok, val=>$tok}, rest=>$rest});
   return ({tok=>Tok($tok,$tok,$expr), rest=>$rest});
   }

sub Tok
   {
   my ($type, $val, $expr) = @_;
   return {type=>$type, val=>$val, line=>$ROW, col=>$LLEN - length($expr)};
   }

sub DumpTokens
   {
   my ($tokens) = @_;

   print "TOKENS:\n--------------------------------\n";
   foreach my $token (@{$tokens})
      {
#      print("[val:$token->{val},    type:$token->{type}, line:$token->{line}, col:$token->{col}]\n");
#      print("['$token->{type}',  '$token->{val}'] ($token->{line},$token->{col})\n");
      print sprintf("[%-10s  %-8s  (%d,%d)\n", "'$token->{val}'", $token->{type}, $token->{line}, $token->{col});
      }
   print "--------------------------------\n";
   }

sub SetTokenLogLevel
   {
   my ($level) = @_;

   $LOGLEVEL = $level;
   }

sub ApplyEscapes
   {
   my ($str) = @_;

   $str =~ s/\\n/\n/g;
   $str =~ s/\\t/\t/g;
   $str =~ s/\\r/\r/g;
   return $str;
   }

sub TokenizeString
   {
   my ($expr) = @_;

   my ($quote, $tok, undef, undef, undef, $rest) = $expr =~ /^\s*(["'])((\\{2})*|(.*?[^\\](\\{2})*))\1(.*)$/;
   return undef unless defined $tok;
   my $type = $quote =~ /"/ ? "istring" : "string";
   $tok = ApplyEscapes($tok);
   return ({tok=>Tok($type,$tok,$expr), rest=>$rest});
   }

#print "included: ", __PACKAGE__, "\n";

1; # two
  
__END__   
