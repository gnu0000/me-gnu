#
# MetaStore.pm - Single File Compressed,encryptedStorage for metadata or whatever
#
# Synopsis: 
#    todo...
#
#  C Fitzgerald 8/x/2013

package Gnu::MetaStore;

use warnings;
use strict;
#use Win32::Console;
use File::Copy;
use Crypt::RC4;
use feature 'state';
use Compress::Zlib;
use Archive::Zip   qw(:ERROR_CODES :CONSTANTS);
use Gnu::FileUtil  qw(SlurpFile SpillFile);

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(MSInit
                 MSGetData
                 MSSaveData
                 MSHasData
                 MSRemoveData
                 MSDataList
                 MSMessages
                 MSState
                 MSCopyArchive
                 MSGetArchiveSpec
                 );
our @EXPORT_OK = qw();
our $VERSION   = 0.10;

# externals
#
###############################################################################

sub MSGetData
   {
   my ($name, $binary) = @_;

   CallInit() || return 0;

   my $altspec = OptionalSpec($name);
   return MSGetExternalData($name, $altspec, $binary) if $altspec;

   my $zip    = GetZip() || return MSAbort("", 0, "could not get Meta Archive");
   my $member = $zip->memberNamed($name);
   return MSAbort("", 1, "'$name' not found") unless $member;
   my $data   = $zip->contents($name);
   return IsEncrypted($name) ? Decrypt($name, $data) : $data;
   }


sub MSGetExternalData
   {
   my ($name, $altspec, $binary) = @_;

   my $isx = IsEncrypted($name);
   $binary ||= $isx;

   MSAddMessage(1, "Loading '$name' from external file '$altspec'");
   my $data = SlurpFile($altspec, $binary);
   return $isx ? Decrypt($name, $data) : $data;
   }


sub MSSaveData
   {
   my ($name, $data, $binary) = @_;

   CallInit() || return 0;
   return MSAbort(0, 1, "not saving '$name'.") if Context("nosave");

   my $altspec = OptionalSpec($name);
   return MSSaveExternalData($name, $altspec, $data, $binary) if $altspec;

   my $zip = GetZip() || return MSAbort(0, 0, "could not get Meta Archive");;
   my $isx = IsEncrypted($name);
   $data = Encrypt($name, $data) if $isx;

   if ($zip->memberNamed($name))
      {
      $zip->contents($name, $data);
      }
   else
      {
      MSAddMessage(1, "Adding new member '$name'");
      my $member = $zip->addString($data, $name);
      $member->desiredCompressionMethod($isx ? COMPRESSION_STORED : COMPRESSION_DEFLATED);
      }
   return RewriteZip($zip);
   }


sub MSSaveExternalData
   {
   my ($name, $altspec, $data, $binary) = @_;

   my $isx = IsEncrypted($name);
   $binary ||= $isx;

   MSAddMessage(1, "Saving '$name' to file '$altspec'");
   $data = Encrypt($name, $data) if $isx;
   return SpillFile($altspec, $data, $binary);
   }


sub MSHasData
   {
   my ($name) = @_;

   CallInit() || return 0;

   return 2 if OptionalSpec($name);
   my $zip = GetZip() || return 0;
   return $zip->memberNamed($name) ? 1 : 0;
   }


sub MSRemoveData
   {
   my ($name) = @_;

   CallInit() || return 0;

   return MSAbort(0, 0, "will not remove optional spec data") if OptionalSpec($name);

   my $zip    = GetZip() || return MSAbort(0, 0, "could not get Meta Archive");
   my $member = $zip->memberNamed($name);

   return MSAbort("", 1, "'$name' not found") unless $member;

   $zip->removeMember($member);
   return RewriteZip($zip);
   }


sub MSDataList   
   {
   CallInit() || return 0;

   my $zip = GetZip() || return MSAbort(undef, 0, "could not get Meta Archive");

   my $info = [];
   my @names = $zip->memberNames();
   foreach my $name (sort @names)
      {
      my $member = $zip->memberNamed($name);
      my $csize  = $member->compressedSize();
      my $usize  = $member->uncompressedSize();
      my $mtime  = localtime($member->lastModTime());
      push(@{$info}, {name=>$name, mtime=>$mtime, usize=>$usize, csize=>$csize});
      }
   return $info;
   }


# 
sub MSMessages
   {
   my ($action, $ok, $message) = @_;

   state $messages = [];

   return $messages unless scalar(@_);
   return $messages = [] if $action == 2;
   push (@{$messages}, {ok=>$ok, message=>$message});

   print "$message\n" if Context("print_all") || Context("print_errors") && !$ok;
   return $messages;
   }


sub MSState
   {
   my $messages = MSMessages();
   return min (map{$_->{ok}} @{$messages});
   }


sub MSAddMessage    {return MSMessages(1, @_)}
sub MSClearMessages {return MSMessages(2)    }
sub MSGetMessages   {return MSMessages()     }


sub MSAbort
   {
   my ($ret, $ok, $message) = @_;

   MSAddMessage($ok, $message);
   return $ret;
   }

###############################################################################

sub OptionalSpec
   {
   my ($name) = @_;

   my $root = Context("root");
   my $spec = "$root\\$name";
   return -f $spec ? $spec : undef;
   }


sub MSGetArchiveSpec
   {
   return GetZipSpec();
   }


# returns $spec
#         ($spec, $tmpspec, $bkupspec) if wantarray
#
sub GetZipSpec
   {
   my $root = Context("root")       ;
   my $name = Context("store_name") ;
   my $spec = "$root\\$name";
   return ($spec, $spec . '_', $spec . '_bk', $spec . '_copy') if wantarray;
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
#   InitZip($spec) unless -f $spec;  
#   $zip->read($spec);
   $zip->read($spec) if -f $spec;
   return $zip;
   }


sub CloseZip
   {
   GetZip(1);
   }


sub RewriteZip
   {
   my ($zip) = @_;

   my ($spec, $tmpspec, $bkupspec) = GetZipSpec();

   my $status = $zip->writeToFileNamed($tmpspec);
   return MSAbort(0, 0, "error writing '$tmpspec'.") if $status != AZ_OK;
   
   CloseZip();
   rename ($spec, $bkupspec) if -f $spec;
   rename ($tmpspec, $spec);

   return $status == AZ_OK;
   }


# $method
#   1 - copy
#   2 - move
#
# $types
#   1 - archive 
#   2 - tmpspec 
#   3 - bkupspec
#   4 - copyspec
#
sub MSCopyArchive
   {
   my ($method, $srctype, $desttype) = @_;

   return MSAbort(0, 0, "invalid method param for MSCopyArchive")   unless $method   =~ /^[12]$/;
   return MSAbort(0, 0, "invalid srctype param for MSCopyArchive")  unless $srctype  =~ /^[1-4]$/;
   return MSAbort(0, 0, "invalid desttype param for MSCopyArchive") unless $desttype =~ /^[1-4]$/;

   CloseZip();
   my @specs = GetZipSpec();
   my($srcspec, $destspec) = @specs[$srctype-1,$desttype-1];
   return MSAbort(0, 0, "source file '$srcspec' does not exist for MSCopyArchive") unless -f $srcspec;

   my $ok = $method == 1 ? copy($srcspec, $destspec) : rename($srcspec, $destspec);
   return MSAbort($ok, 0, "copy/move failed for MSCopyArchive") unless $ok;
   return $ok;
   }




###############################################################################

sub Context
   {
   my ($setting, $val) = @_;

   state $context = {init=>0};

   $context->{$setting} = $val if scalar(@_) > 1;
   return $context->{$setting};
   }


sub MSInit
   {
   my (%options) = @_;

   my $options = \%options;
   _initopt($options, "root"          , "."       );
   _initopt($options, "store_name"    , "meta.zip");
   _initopt($options, "debug"         , 1         );
   _initopt($options, "create_store"  , 1         );
   _initopt($options, "create_member" , 1         );
   _initopt($options, "nosave"        , 0         );
   _initopt($options, "print_all"     , 0         );
   _initopt($options, "print_errors"  , 0         );
   _initopt($options, "password"      , ""        );

   MSClearMessages();
   my $spec = GetZipSpec();

   return MSAbort(0, 0, "root dir doesnt exist" ) unless -d Context("root");
   return MSAbort(0, 0, "metastore doesnt exist") unless -f $spec || Context("create_store");
   return Context("init", 1);
   }

sub _initopt
   {
   my ($options, $name, $default) = @_;

   return Context("$name", exists $options->{$name} ? $options->{$name} : $default);
   }

sub CallInit
   {
   MSClearMessages ();
   return MSAbort(0, 0, "MetaStore module not initialized") unless Context("init");
   return 1;
   }


sub IsEncrypted
   {
   my ($name) = @_;

   return $name =~ /_$/ ? 1 : 0;
   }


sub Encrypt
   {
   my ($name, $data) = @_;

   my $password = Context("password");
   return $data unless $password;
   $data = Compress::Zlib::memGzip($data);
   return RC4($name . $password, $data);
   }


sub Decrypt
   {
   my ($name, $data) = @_;

   my $password = Context("password");
   return $data unless $password;

   $data = RC4($name . $password, $data);
   return  Compress::Zlib::memGunzip($data);
   }


1; # two
  
__END__   
