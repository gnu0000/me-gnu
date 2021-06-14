#!perl 
#
# Craig Fitzgerald
#

use lib "c:\\util\\bin\\perl\\lib";
use warnings;
use strict;
use feature 'state';
use Archive::Zip     qw( :ERROR_CODES :CONSTANTS );
use Cwd              qw(abs_path getcwd cwd);
use Path::Class      qw(file);
use Gnu::ArgParse;
use File::Basename;
use Time::HiRes;
use Gnu::DebugUtil    qw(:ALL);
use Gnu::Var         qw(:ALL);

MAIN:
   ArgBuild("*^context= *^nosave *^reset *^clear *^extern= *^help *^quiet *^debug");
   ArgParse(@ARGV) or die ArgGetError();
   
my $str1 = "this is a test string";
my $chain = Ex_MakeChain($str1);
#foreach my $entry


   foreach my $entry (@{$chain})
      {
      my $start = $entry->{start};
      return $str_idx-$laststart if $str_idx <= $start;
      $laststart = $start;
      }
   return $str_idx-$laststart;


# general stringinput
# used for isoverwordword
# used by external for finding context and adding cdata nodes
#
# in: 
#    $string - input string to break into chain
#    %opt:
#       wordregex   => qw\\  for parsing word ident
#       nousecache => 1     dont use tmp cache
#       nosavecache=> 1     dont save to tmp cache
#
#     wordregex examples:
#       wordregex=> qr/(\w+)/             # normal ident
#       wordregex=> qr/(\w|\\|\:)+/       # allow \ and : in identifiers
#       wordregex=> qr/(::)|\(|\)|(\w+)/  # normal ident or '::' or '(' or ')'
#
# uses:
#    V(wordregex)         unless opt wordregex provided
# out:
#    returns an arrayref of wordentries
#
# returns
#    $chain  - an arrayref of wordentries
#              a wordentry is a hashref containing:
#
#        word  => string   - a word from the string
#        start => #        - starting index in the string
#        end   => #        - ending index in the string
#        len   => #        - the length of the word
#
sub Ex_MakeChain
   {
   my ($str, %opt) = @_;
   
   my $regex  = $opt{wordregex} || _WordRegex();
   
   my $chain = _Ex_CachedChain($str, $regex);
   return $chain unless !$chain || $opt{nousecache};
   
   $chain = [];
   
   my ($chainstr, $pos) = ($str, 0);
   
   while(length($chainstr))
      {
      last unless $chainstr =~ /^(.*?)($regex)(.*)$/;
      
      my ($skip, $word, $rest) = ($1||"", $2||"", $+);
      
      my $start = $pos + length($skip);
      my $len   = length($word);
      my $end   = $start + $len -1;
      
      push @{$chain}, {word=>$word, start=>$start, len=>$len, end=>$end};
      ($pos,$chainstr)  = ($end+1,$rest);
      }
   return _Ex_CachedChain($str, $regex, $chain) unless $opt{nosavecache};
   return $chain; 
   }
   


# caches 
#   
sub  _Ex_CachedChain
   {
   my ($str, $regex, $chain) = @_;
   
   my $cache = TVarInit(_ex_chain_cache=>{});
   return $cache->{$str . $regex} unless  scalar @_ > 2;
   return $cache->{$str . $regex} = $chain;
   }


sub _WordRegex
   {
   return V("wordregex") || qr/(\w|\\|\:)+/;
   }
   
