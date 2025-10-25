use warnings;
use strict;
use feature 'state';
use Win32;
use Win32::API;
use Win32::Process;

### temp ###
use lib "c:/projects/me/Gnu/lib";
### temp ###

use Gnu::ArgParse;
use Gnu::KeyInput  qw(GetKey);
use Gnu::Template  qw(:ALL);
use Gnu::ShowPic;

MAIN:
   Run();
   exit(0);


sub Run {
   $| = 1;

   ArgBuild("*^help");
   ArgParse(@ARGV) or die ArgGetError();

   my $dir = ArgGet()  or die "I need a dir param";
   my $files = Loadfiles($dir);
   my $fileCount = scalar @{$files};

   print join("\n", @{$files}) . "\n\n";

   while(1) {
      my $key = GetKey(ignore_ctl_keys=>1);
      last if $key->{vkey} == 27;

      my $index = int(rand($fileCount));
      my $file = $files->[$index];
      print "$file\n";

      ShowPic($file);
   }
}

sub Loadfiles {
   my ($dir) = @_;

   opendir(my $dh, $dir) or die "\ncant open dir '$dir'!";

   print "looking at files in '$dir'\n";
   my @all = readdir($dh);
   print "found " . scalar @all . " files\n";

   closedir($dh);

   my $files = [];
   
   foreach my $filename (@all) {
      my $spec = "$dir\\$filename";
      next unless -f $spec;
      next unless $spec =~ /\.(png|gif|jpg|jpeg)/i;
      push(@{$files}, $spec);
     
   }
   return $files;   
}


__DATA__
[usage]
Todo...
[fini]