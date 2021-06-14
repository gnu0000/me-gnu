#!perl 
#
# Craig Fitzgerald
#

use lib "lib";
use warnings;
use strict;
#use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Cwd  qw( abs_path );
use File::Basename;
use Gnu::ArgParse;
use Gnu::MetaStore;


MAIN:
   print "Gnu::MetaStore internal test\n";
   print "params: *^name= *^debug *^read *^write *^add= ^*list *^debug *^help\n\n";

   ArgBuild("*^name= *^debug *^read *^write *^add= ^*list *^debug *^help");
   ArgParse(@ARGV) or die ArgGetError();

   my $arcspec = ArgGet() || 'MetaStoreTest.dat';

   my ($basename,$dir,$ext) = fileparse($arcspec, qr/\.[^.]*/);

   chop $dir if $dir =~ /\\$/;

   TestMS($dir, $basename . $ext);
   exit(0);


sub TestMS
   {
   my ($root, $name) = @_;

   print "root: $root\n";
   print "name: $name\n";

   MSInit(root          => $root  ,
          store_name    => $name  ,
          debug         => 1      ,
          create_store  => 1      ,
          create_member => 1      ,
          nosave        => 0      );

   my @names = qw(fred barney wilma betty);
   push(@names, ArgGet("add")) if ArgIs("add");

   if (ArgIs("read"))
      {
      foreach my $name (@names)
         {
         my $data = MSGetData($name);
         print "$name: $data\n\n";
   
         }
      }
   if (ArgIs("write"))
      {
      foreach my $name (@names)
         {
         my $data = "$name" x 10;
         MSSaveData($name, $data);
         }
      }

   if (ArgIs("list"))
      {
      my $info = MSDataList();
      foreach my $rec (@{$info})
         {
         print sprintf(" %6d [%6d] $rec->{mtime}  $rec->{name}\n", $rec->{usize}, $rec->{csize});
         }
      }
   print "\ndone\n";
   }


