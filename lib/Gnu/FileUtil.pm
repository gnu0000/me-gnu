#
# FileUtil.pm
#
# Functions:   
# 
#    SlurpFile($filespec, $isbinary)
# 
#    SpillFile($filespec, $content, $isbinary)
# 
#    NormalizeFilename($name, %options)
#       options:
#           lowercase
#           uppercase
#           keep_underscores
#           keep_dashes
#           keep_score
#           keep_dots
#           oddout
#
# Craig Fitzgerald

package Gnu::FileUtil;

use warnings;
use strict;
use Win32::Console;
use feature 'state';

require Exporter;

our @ISA         = qw(Exporter);
our $VERSION     = 0.10;
our @EXPORT      = qw();
our @EXPORT_OK   = qw(SlurpFile SpillFile NormalizeFilename);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);

# constants
#


# externals - io
#
###############################################################################

sub SlurpFile
   {
   my ($filespec, $isbinary) = @_;

   $isbinary ||= 0;
   open (my $filehandle, "<", $filespec) or return "";
   binmode $filehandle if $isbinary;
   my $contents;
   local $/ = undef;
   $contents = <$filehandle>;
   close $filehandle;
   return $contents;
   }


sub SpillFile
   {
   my ($filespec, $content, $isbinary) = @_;

   $content  ||= "";
   $isbinary ||= 0;
   open (my $filehandle, ">", $filespec) or return 0;
   binmode $filehandle if $isbinary;
   print $filehandle ${$content}  if ref $content eq "SCALAR";
   print $filehandle $content     if ref $content ne "SCALAR";
   close $filehandle;
   return 1;
   }


# externals - string
#
###############################################################################
#
# lowercase
# uppercase
# keep_underscores
# keep_dashes
# keep_score
# keep_dots
# keep_commas
#
sub NormalizeFilename
   {
   my ($name, %options) = @_;

   return $name unless $name;
   my $file = {name=>$name, newname=>$name, options=>{%options}};

   RemoveScore    ($file);
   RemoveComma    ($file);
   RemoveDot      ($file);
   Case           ($file);
   SpecialAnd     ($file);
   CvtChars       ($file);
   CollapseScores ($file);
   AddScore       ($file);
   OddOut         ($file);

   return $file->{newname};
   }


###############################################################################


sub RemoveScore
   {
   my ($file) = @_;

   $file->{score} = "";
   return if $file->{options}->{keep_underscores};

   while (1)
      {
      my ($scorechar, $name) = $file->{newname} =~ /^(_|!)(.*)$/;
      last unless $scorechar && $name;
      $file->{score}  .= $scorechar;
      $file->{newname} = $name;
      }
   $file->{score} = "" unless $file->{options}->{keep_score};
   }


sub RemoveComma
   {
   my ($file) = @_;

   return if $file->{options}->{keep_commas};

   $file->{newname} =~ s/,//g;
   }


sub RemoveDot
   {
   my ($file) = @_;

   return if $file->{options}->{keep_dots};
   while (1)
      {
      my ($pre, $post) = $file->{newname} =~ /^(.+)\.(.*\..*)$/;
      last unless $pre && $post;
      $file->{newname} = $pre . "_" . $post;
      }
   }

sub Case      
   {
   my ($file) = @_;

   $file->{newname} = lc $file->{newname} if $file->{options}->{lowercase};
   $file->{newname} = uc $file->{newname} if $file->{options}->{uppercase};
   }

sub SpecialAnd 
   {
   my ($file) = @_;

   if ($file->{newname} =~ /_&_/)
      {
      $file->{newname} =~ s/_&_/_and_/g;
      }
   if ($file->{newname} =~ /\w&\w/)
      {
      $file->{newname} =~ s/&/_and_/g;
      }
   }


sub CollapseScores
   {
   my ($file) = @_;

   while ($file->{newname} =~ s/__/_/g) {};
   }


sub AddScore
   {
   my ($file) = @_;

   $file->{newname} = $file->{score} . $file->{newname};
   }


sub OddOut
   {
   my ($file) = @_;

   return unless $file->{options}->{oddout};

   $file->{newname} =~ s/[^a-zA-Z0-9_.\-]/_/g;
   }


sub CvtChars       
   {
   my ($file) = @_;

   $file->{newname} =~ s/-/_/g    unless $file->{options}->{keep_dashes};
   $file->{newname} =~ s/\s/_/g;  
   $file->{newname} =~ s/%/_/g;  
   $file->{newname} =~ s/\[/(/g;  
   $file->{newname} =~ s/\]/)/g;  
   $file->{newname} =~ s/&/and/g;
   $file->{newname} =~ s/#/_/g;
   $file->{newname} =~ s/,/_/g;  
   $file->{newname} =~ s/\+/_/g;  
   $file->{newname} =~ s/\@/_/g;  
   $file->{newname} =~ s/\!/_/g;  
   $file->{newname} =~ s/\~/_/g;  
   $file->{newname} =~ s/\'//g    unless $file->{options}->{keep_quotes};
   }

1; # two
  
__END__   
