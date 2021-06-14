# IVPlayer.pm - 
#  C Fitzgerald 8/x/2013
#
# Synopsis:
# 
# this module is a work in progress...
# 

package Gnu::IVPlayer;

use warnings;
use strict;
#use feature 'state';
use Win32;
use Win32::Process;
#use Time::HiRes;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(PlayerPlay
                 PlayerStop
                 PlayerClose
                 PlayerSendCommand
                 );
our @EXPORT_OK = qw();
our $VERSION   = 0.10;

#todo:.....
my $PLAYER_SPEC  = 'c:\Program Files (x86)\IrfanView\i_view32.exe';


#
###############################################################################

sub PlayerPlay
   {
   my ($spec) = @_;
   PlayerExec(" \"$spec\"");
   }

sub PlayerStop 
   {
   }

sub PlayerClose
   {
   PlayerExec("/killmesoftly");
   }

sub PlayerExec
   {
   my ($cmdline_options) = @_;

   MyExec($PLAYER_SPEC, "i_view32", $cmdline_options);
   }

sub MyExec
   {
   my ($spec, $appname, $paramlist) = @_;

   my $ProcessObj = " " x 10240;
   Win32::Process::Create($ProcessObj, $spec, "$appname $paramlist",
                          0, NORMAL_PRIORITY_CLASS, ".") 
      || die MyExecErr();
   }   

sub MyExecErr
   {
   print ":::" . Win32::FormatMessage( Win32::GetLastError());
   }


1; # two
  
__END__   
