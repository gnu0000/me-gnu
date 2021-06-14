
package Gnu::Test;

use warnings;
use strict;
#use Gnu::Test::Helpers;
require Gnu::Test::Helpers;

require Exporter;

our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(TestMethod);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);
our $VERSION     = 0.10;


sub TestMethod
   {
   my ($val) = @_;
   
   print "helper1 says: ", Helper1($val), "\n";
   }


1; # two
  
__END__   
