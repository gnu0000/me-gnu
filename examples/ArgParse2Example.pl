#!perl 
#
#

use lib "c:\\util\\bin\\perl\\lib";
use warnings;
use strict;
use Gnu::ArgParse2;
use Gnu::DebugUtil   qw(:ALL);
use Gnu::StringUtil  qw(Chip Trim TrimList _CSVParts LineString CleanInputLine);



MAIN:
   print "This is an internal test of Gnu::ArgParse2.\n\n";
   print LineString("number 1  '*^XSize= *^YSize= *^help'");
   
   my $ap1 = new Gnu::ArgParse2();
   $ap1->ParseTemplate("*^XSize= *^YSize= *^help") or print $ap1->GetError();
   $ap1->ParseArgs(@ARGV)                          or print $ap1->GetError();
   
   print "\n", LineString("number 1 info");
   print "  ap1->Is (XSize)  = ", $ap1->Is ("XSize")  ,"\n";
   print "  ap1->Get(XSize)  = ", $ap1->Get("XSize")  ,"\n"  if $ap1->Is ("XSize");
   print "  ap1->Is ()       = ", $ap1->Is ()         ,"\n";
   print "  ap1->Get()       = ", $ap1->Get()         ,"\n"  if $ap1->Is ();

   
   print "\n", LineString("number 1 all switched instances");
   foreach my $param (qw(XSize YSize help))
      {
      map{print "$param=". $ap1->Get($param, $_-1) . "\n"} (1 .. $ap1->Is($param));
      }
   print "\n", LineString("number 1 all unswitched instances");
   map{print "" . $ap1->Get(undef, $_-1) . "\n"} (1 .. $ap1->Is());
   
   
   
   print "\n", LineString("number 2  '^XSize= *^ZSize= *^help'");
   my $ap2 = new Gnu::ArgParse2();
   $ap2->ParseTemplate("*^XSize= *^ZSize= *^help foo") or print $ap2->GetError();
   $ap2->ParseArgs(@ARGV)                          or print $ap2->GetError();
   
   print "\n", LineString("number 2 info");
   print "  ap2->Is (XSize)  = ", $ap2->Is ("XSize")  ,"\n";
   print "  ap2->Get(XSize)  = ", $ap2->Get("XSize")  ,"\n"  if $ap2->Is ("XSize");
   print "  ap2->Is ()       = ", $ap2->Is ()         ,"\n";
   print "  ap2->Get()       = ", $ap2->Get()         ,"\n"  if $ap2->Is ();
   
   #print "\n\n", LineString("number 2 dump");
   #$ap2->Dump();
   #print DumpRef($ap1->{choices}, "  ", 7);
   
   print LineString("end");

