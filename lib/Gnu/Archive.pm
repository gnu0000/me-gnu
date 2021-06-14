#
# Archive.pm - archive file access
#
# Look at this as a very simplified access to a zip file
#
# Synopsis:
#    use Gnu::Archive;
#
#    InitArchive('c:\stuff\foo.stuff', allow_new=>1, allow_externals=>1)l
#    my $data = GetFile("metadata.bin");
#    .....
#    SaveFile("metadata", $data);
#
#  See Gnu::MetaStore for a more fleshed out implementation
#  This module prints to stdout
#
# Craig Fitzgerald 8/1/2013

package Gnu::Archive;
use warnings;
use strict;
use feature 'state';
use Win32::Console;
use Archive::Zip   qw(:ERROR_CODES :CONSTANTS);
use File::Basename;

require Exporter;

our $VERSION   = 0.10;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(InitArchive
                    GetFile
                    SaveFile
                    RemoveFile
                    MemberList);


# externals
#
###############################################################################

# returns result of last operation
# in scalar context, returns error state
# in list context, returns (state, extended state)
#
# state:
#  0 = ok
#  1 = error condition
#
# extended state
#  0 = hunky dory
#  1 = not initialized
#  2 = item not found
#  3 = external found/used
#
#     well, thats the basic plan anyway ...
#
#sub AcrchiveStatus
#   {
#   state $state  = 1;
#   state $xstate = 1;
#
#   ($state, $xstate) = @_ if (scalar @_ > 1);
#   return ($state, $xstate) if wantarray;
#   return $state;
#   }


# InitArchive - external
#
# initializes the module, not the archive!
# Nothing will work until you call this
#
# options
#    allow_externals=>1   # first check for/use external files
#    allow_new_archive=>1 # create new archive if needed
#    nosave=>1            # readonly access 
#
#
sub InitArchive
   {
   my ($spec, %options) = @_;

   ArchiveSpec($spec);
   Options(%options);
   }


# external
#
# returns the file contents
# returns '' if the file doesn't (yet) exist
# returns undef if there's a real problem
#
sub GetFile
   {
   my ($name) = @_;

   my $altspec = OptionalSpec($name) || return undef;
   #print "Loading altername file '$altspec'\n" if $altspec && !Option("quiet");
   return SlurpFile($altspec) if $altspec;

   my $zip    = GetZip() || return undef;
   my $member = $zip->memberNamed($name);
   return $zip->contents($name) if $member;
   return '';
   }

# external
#
#
sub SaveFile
   {
   my ($name, $data) = @_;

   #return Abort(0, "not saving '$name'.") if Option("nosave");
   my $altspec = OptionalSpec($name);
   #print "Saving altername file '$altspec'\n" if $altspec && !Option("quiet");
   return SpillFile($altspec, $data) if $altspec;

   my $zip = GetZip();
   if ($zip->memberNamed($name))
      {
      $zip->contents($name, $data);
      }
   else
      {
      my $member = $zip->addString($data, $name);
      $member->desiredCompressionMethod( COMPRESSION_DEFLATED );
      }
   my ($spec, $tmpspec, $bkupspec) = GetZipSpec();

   my $status = $zip->writeToFileNamed($tmpspec);
   return print "error writing '$tmpspec'. \n"  if $status != AZ_OK;
   
   CloseZip();
   rename ($spec, $bkupspec) if -f $spec;
   rename ($tmpspec, $spec);
   return $status == AZ_OK;
   }


sub RemoveFile
   {
   my ($name) = @_;

   my $altspec = OptionalSpec($name) || return undef;
   return print "not deleting optional metafile '$altspec\n." if $altspec;
   my $zip    = GetZip() || return undef;
   my $member = $zip->memberNamed($name);
   $zip->removeMember($member) if $member;
   return $member ? 1 : 0;
   }


# external
#
sub MemberList
   {
   # todo
   }

# internals
#
###############################################################################




sub OptionalSpec
   {
   my ($name) = @_;

   my $root = Context("root");
   my $spec = "$root\\$name";
   return -f $spec ? $spec : undef;
   }


sub GetZipSpec
   {
   my $root = Context("root") ;
   my $name = FileName("zip") ;
   my $spec = "$root\\$name";
   return ($spec, $spec . '_', $spec . '_bk') if wantarray;
   return $spec;
   }

sub GetZip
   {
   my ($close) = @_;

   state $zip = OpenZip();

   return $zip = undef if $close;
   return $zip if $zip;
   return $zip = OpenZip();
   }

sub OpenZip
   {
   my $spec = GetZipSpec();
   my $zip = Archive::Zip->new();
   InitZip($spec) unless -f $spec;  
   $zip->read($spec);
   return $zip;
   }

sub InitZip
   {
   my ($newspec) = @_;

   print "Initializing '$newspec'.\n" unless Option("quiet");

   my $data = Template("defaultdll");
   my $decoded = decode_base64($data);
   SpillFile($newspec, $decoded, 1);
   }


sub CloseZip
   {
   GetZip(1);
   }

sub ListZip
   {
   my $zip = GetZip();
   my @names = $zip->memberNames();
   print "\nmetadata members:\n";

   foreach my $name (sort @names)
      {
      my $member = $zip->memberNamed($name);
      my $csize  = $member->compressedSize();
      my $usize  = $member->uncompressedSize();
      my $mtime  = localtime($member->lastModTime());
      print sprintf(" %6d [%6d] $mtime  $name\n", $usize, $csize);
      }
   print "\n\n";
   }

sub CopyZipMember
   {
   my ($source_name, $dest_name, $quiet) = @_;

   $quiet ||= Option("quiet");

   my $data = GetFile($source_name);
   SaveFile($dest_name, $data);
   print "done.\n" unless $quiet;
   }

1; # two

