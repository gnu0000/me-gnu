#
#
#
#
#package Gnu::Test::Helpers;
#
#use warnings;
#use strict;
#
#require Exporter;
#
#our @ISA         = qw(Exporter);
#our @EXPORT      = qw();
#our @EXPORT_OK   = qw(TestMethod);
#our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);
#our $VERSION     = 0.10;

sub Helper1
   {
   my ($val) = @_;
   
   $val ||= "Yo";
   
   return "[$val]";
   }


1; # two
  
__END__   
