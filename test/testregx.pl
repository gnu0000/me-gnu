#!perl 
#
# Craig Fitzgerald
#

use lib "lib";
use warnings;
use strict;
use feature 'state';
use Archive::Zip     qw( :ERROR_CODES :CONSTANTS );
use Cwd              qw(abs_path getcwd cwd);
use Path::Class      qw(file);
use Gnu::ArgParse;
use File::Basename;
use Time::HiRes;
use Gnu::DebugUtil   qw(:ALL);
use Gnu::MiscUtil    qw(:ALL);



my ($zstring, $zword);
($zstring, $zword) = ("abcdefghij","123");
substr($zstring, 3, 0, $zword); print "substr: 3,0 : $zstring \n";
($zstring, $zword) = ("abcdefghij","123");
substr($zstring, 3, 1, $zword); print "substr: 3,1 : $zstring \n";
($zstring, $zword) = ("abcdefghij","123");
substr($zstring, 0, 0, $zword); print "substr: 0,0 : $zstring \n";
($zstring, $zword) = ("abcdefghij","123");
substr($zstring, 10, 0, $zword); print "substr: 99,0 : $zstring \n";
exit(0);



#TestIdentSplit2();
TestIdentSplit3();
exit(0);



my @testdata = 
     ('{foo}'       ,
      '{foo:}'      ,
      '{foo:bar}'   ,
      '{foo:\bar}'  ,
      '{foo:c:\bar}',
      '{}'          ,
      'foo'         ,
      ''            );

foreach my $string (@testdata)
   {
   tst($string);
   }
exit(0);





sub tst_0
   {
   my ($string) = @_;
   
   print "testing '$string':    ";
   
   my @results = $string =~ /^\{(\w+)(:(.*))?\}$/;
   
   print "   ";
   foreach my $result (@results)
      {
      print "[";
      print defined $result ? $result : "<undef>";
      print "] ";
      }
   print "\n";   
   }


sub tst
   {
   my ($string) = @_;
   
   my ($cname, undef, $dir) = $string =~ /^\{(\w+)(:(.*))?\}$/;
   $cname ||= "";
   $dir   ||= "";
   
   #$string .= " " x (20-length($string)
   $string = sprintf("%-20s", $string);
   
   print "testing $string  :  cname='$cname'  dir='$dir'\n";
   }



sub TestIdentSplit
   {
   my $idchars = qr'\w|\\|:|\.';
   IdentSplit ("this is a test"              , qr'\w'            , 0);
   IdentSplit ("this is a test"              , qr'\w|\\|:|\.'    , 0);
   IdentSplit ('file:  c:\archive\foo.zip'   , qr'\w|\\|:|\.'    , 0);
   IdentSplit ('file:  c:\archive\foo.zip'   , qr'\w'            , 0);     
   IdentSplit ('help {cmds}'                 , qr'\w|\\|:|\.'    , 0);
   IdentSplit ('help {cmds}'                 , qr'\w|\\|:|\.|{|}', 0);
   
   IdentSplit ("(this) is_a +test {foo},bar" , qr'\w'            , 0);
   IdentSplit ("(this) is_a +test {foo},bar" , qr'\S'            , 0);
   IdentSplit ("(this) is_a +test {foo},bar" , qr'\S'            , 0);
   IdentSplit ("(this) is_a +test {foo},bar" , qr'\w|\\|:|\.'    , 0);
   IdentSplit ("(this) is_a +test {foo},bar" , qr'\w|\\|:|\.|{|}', 0);
   
   
   print "\n";
   
   
   IdentSplit ("this is a test"              , 0,  qr'\s'               );
   IdentSplit ("this is a test"              , 0,  qr'\s|,'             );
   IdentSplit ('file:  c:\archive\foo.zip'   , 0,  qr'\s'               );
   IdentSplit ('file:  c:\archive\foo.zip'   , 0,  qr'\s|\"|\'|,|\||\+' );     
   IdentSplit ('help {cmds}'                 , 0,  qr'\s'               );
   IdentSplit ('help {cmds}'                 , 0,  qr'\s|\{|\}'         );
   

   IdentSplit ("(this) is_a +test {foo},bar" , 0,  qr'\s'               );
   IdentSplit ("(this) is_a +test {foo},bar" , 0,  qr'\W'               );
   IdentSplit ("(this) is_a +test {foo},bar" , 0,  qr'\s|\(|\)|\[|\]|,' );
   IdentSplit ("(this) is_a +test {foo},bar" , 0,  qr' |\t'             );
   IdentSplit ("(this) is_a +test {foo},bar" , 0,  qr' |\t|\+'          );
   
   

   print "\n";


   IdentSplit ("(this) is_a +test {foo},bar" , qr'\S',  qr'\(|\)|,|\+'  );
   
   
   
#   IdentSplit ("this is a test"              , qr'\w'            ,    );
#   IdentSplit ("this is a test"              , qr'\w|\\|:|\.'    ,    );
#   IdentSplit ('file:  c:\archive\foo.zip'   , qr'\w|\\|:|\.'    ,    );
#   IdentSplit ('file:  c:\archive\foo.zip'   , qr'\w'            ,    );     
#   IdentSplit ('help {cmds}'                 , qr'\w|\\|:|\.'    ,    );
#   IdentSplit ('help {cmds}'                 , qr'\w|\\|:|\.|{|}',    );
#   
#   IdentSplit ("(this) is_a +test {foo},bar" , qr'\w'            ,    );
#   IdentSplit ("(this) is_a +test {foo},bar" , qr'\S'            ,    );
#   IdentSplit ("(this) is_a +test {foo},bar" , qr'\w|\\|:|\.'    ,    );
#   IdentSplit ("(this) is_a +test {foo},bar" , qr'\w|\\|:|\.|{|}',    );
   
   }


sub IdentSplit
   {
   my ($str, $idrx, $nonidrx) = @_;
   
   $idrx    ||= "";
   $nonidrx ||= "";
   
   my ($ok, $last, $idx, @chain) = (0,0,-1,());

   foreach my $char (split("", $str))
      {
      $ok = $idrx ? 0 : 1;
      $ok = 1 if $idrx    and $char =~ /$idrx/;
      $ok = 0 if $nonidrx and $char =~ /$nonidrx/;
      
      
      $chain[++$idx]  = $char if $ok && !$last;
      $chain[$idx  ] .= $char if $ok &&  $last;
      $last = $ok;
      }  
   #return @chain;
   
   print sprintf("%-27s | %-27s |%-35s | %s\n", $idrx, $nonidrx, $str, join(" + ", @chain));
#   print "$str : ", join(" + ", @chain), "\n";
   }



#sub IdentSplitb
#   {
#   my ($str, $idcharregx, $splitters) = @_;
#   
#   $idrx    ||= "";
#   $nonidrx ||= "";
#   
#   my ($ok, $last, $idx, @chain) = (0,0,-1,());
#
#   foreach my $char (split("", $str))
#      {
#      my $isident    = $char      =~ /$idcharregx/;
#      my $issplitter = $splitters =~ qr/$char/;
#      
##      $ok = $idrx ? 0 : 1;
##      $ok = 1 if $idrx    and $char =~ /$idrx/;
##      $ok = 0 if $nonidrx and $char =~ /$nonidrx/;
#      
#      
#      $chain[++$idx]  = $char if $ok && !$last;
#      $chain[$idx  ] .= $char if $ok &&  $last;
#      $last = $ok;
#      }  
#   #return @chain;
#   
#   print sprintf("%-27s | %-27s |%-35s | %s\n", $idrx, $nonidrx, $str, join(" + ", @chain));
##   print "$str : ", join(" + ", @chain), "\n";
#   }


sub TestIdentSplit2
   {
   _IdentSplit2("the example: Foo::Bar::Baz(val)"     , qr/\w+/              );
   _IdentSplit2(" ... the example: Foo::Bar::Baz(val)", qr/\w+/              );
   _IdentSplit2("the example: Foo::Bar::Baz(val)"     , qr/(::)|\(|\)|(\w+)/ );
   _IdentSplit2(" ... the example: Foo::Bar::Baz(val)", qr/(::)|\(|\)|(\w+)/ );
   
   
   _IdentSplit2('load c:\misc\templates\master.txt /full', qr/(\w|\\|\:|\/|\.)+/);
   
   }
   
sub _IdentSplit2
   {
   my ($str, $idregx) = @_;
   
   my @chain = IdentSplit2(@_);
   print "---------------------------------------------\n";
   print "string : $str    \n";
   print "regx   : $idregx \n";
   print "chain  : ", join(" + ", @chain), "\n";
   }


sub IdentSplit2
   {
   my ($str, $idregx) = @_;

   my @chain;
   while(length $str)
      {
      last unless $str =~ /(\s*)($idregx)(.*)$/;
      my $match = $1;
      my $rest  = $+;
      
      push @chain, $match;
      $str = $rest;
      }
   return @chain; 
   }


   
   
sub TestIdentSplit3
   {
   _IdentSplit3("the example: Foo::Bar::Baz(val)"          , qr/(\w+)/                    , [0,1,2,3,4]);
   _IdentSplit3("the example: Foo::Bar::Baz(val)"          , qr/(::)|\(|\)|(\w+)/         , [         ]);
   _IdentSplit3(" ... the example: Foo::Bar::Baz(val)"     , qr/(\w+)/                    , [2        ]);
   _IdentSplit3(" ... the example: Foo::Bar::Baz(val)"     , qr/(::)|\(|\)|(\w+)/         , [20,21,22,4]);
   _IdentSplit3('load c:\misc\templates\master.txt /full'  , qr/(\w+)/                    , [         ]);
   _IdentSplit3('load c:\misc\templates\master.txt /full'  , qr/(\w|\\|\:|\/|\.)+/        , [10       ]);
   _IdentSplit3('load c:\misc\templates\master.txt /full'  , qr/(\w+)|(\\)|(\:)|(\/)|(\.)/, [         ]);
   _IdentSplit3(" ... the example: Foo::Bar::Baz(val) ..." , qr/(::)|\(|\)|(\w+)/         , [20,21,22,4]);
   }
   
sub _IdentSplit3
   {
   my ($str, $idregx, $idxs) = @_;
   
#   my @chain = IdentSplit3(@_);

#   my @chain = @{Ex_MakeChain2($str,wordregx=>$idregx)};
    my $chain = Ex_MakeChain2($str,wordregx=>$idregx);
    my @chain = @{$chain};
   
   my $idx    = 0;
   my $locstr = "." x length($str);
   foreach my $entry (@chain)
      {
      my $idz = chr(65 + $idx) x $entry->{len};
      substr($locstr,$entry->{start},$entry->{len}, $idz);
      $idx++;
      }
   
   print "\n";
   print "---------0---------1---------2----------3--------4\n";
   print "         01234567890123456789012345678901234567890\n";
   print "--------------------------------------------------\n";
   print "wordloc: $locstr\n";
   print "string : $str        (regx:$idregx)\n";
   
   foreach my $cursor (@{$idxs})
      {
      my $entry = WordAtIdx($cursor,@chain);
      my $label = sprintf("at[%2d]", $cursor);
      print "$label : " . " " x $cursor . "^";
      print "$entry->{match}\[$entry->{start},$entry->{end}\]\n" if $entry;
      print "[nomatch]\n"                                        if !$entry;
      }
   print "chain  : ", join(" + ", map{$_->{match}}(@chain)), "\n";
#  print "regx   : $idregx \n";
   

   print "\n";
   }

   

sub IdentSplit3
   {
   my ($str, $idregx) = @_;

   my @fullchain;
   my $pos = 0;
   while(length $str)
      {
      last unless $str =~ /^(.*?)($idregx)(.*)$/;
      my $skip  = $1 || "";
      my $match = $2 || "";
      my $rest  = $+;
      my $start = $pos + length($skip);
      my $len   = length($match);
      my $end   = $start + $len -1;
      
      push @fullchain, {match=>$match, start=>$start, len=>$len, end=>$end};
      
      $pos = $end+1;
      $str = $rest;
      }
   return @fullchain; 
   }
   

sub WordAtIdx
   {
   my ($idx, @chain) = @_;
   
   map{return $_ if InRange($idx,$_->{start},$_->{end})} @chain;
   map{return $_ if$idx == $_->{end}+1} @chain;
   
#   foreach my $entry (@chain)
#      {
#      #return $entry->{match} if $idx >= $entry->{start} and $idx <= $entry->{end}+1;
#      #return $entry if ($idx >= $entry->{start}) && ($idx <= $entry->{end}+1);
#      return $entry if ($idx >= $entry->{start}) && ($idx <= $entry->{end});
#      }
#   foreach my $entry (@chain)
#      {
#      return $entry if ($idx = $entry->{end}+1);
#      }
   return 0;
   }





