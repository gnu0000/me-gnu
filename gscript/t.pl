my $a = 1;
my $b = "fred";
my $c = 14.73;
my $d = ["joe"];
my $e = {z => 1};

use strict;
use warnings;


#print "\a is a ", ref(\$a), "\n";
#print "\b is a ", ref(\$b), "\n";
#print "\c is a ", ref(\$c), "\n";
#print "\d is a ", ref(\$d), "\n";
#print "\e is a ", ref(\$e), "\n";
#print "d  is a ", ref($d) , "\n";
#print "e  is a ", ref($e) , "\n";


print "a is a ", "1" + "2"        , "\n";
print "b is a ", "1" . "2"        , "\n";
print "c is a ", 1 + 2            , "\n";
print "d is a ", 1 . 2            , "\n";
print "e is a ", "fred" + "bob"   , "\n";
