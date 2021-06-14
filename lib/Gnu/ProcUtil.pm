#
# ProcUtil.pm
# 
package Gnu::ProcUtil;

use warnings;
use strict;
use Win32::Console;
use feature 'state';
use Win32;
use Win32::Console;
use Win32::Process;

require Exporter;

our $VERSION     = 0.10;
our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(StartProcess StartProcessError StartCmdShell StartExplorer);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);

# externals
#
###############################################################################


# returns 0 if failure, unless $dieonerror = true
#
sub StartProcess
   {
   my ($spec, $appname, $paramlist, $dieonerror) = @_;

   my $ProcessObj = " " x 10240;
   my $ok = Win32::Process::Create($ProcessObj, $spec, "$appname $paramlist",
                                   0, NORMAL_PRIORITY_CLASS, ".");
   die StartProcessError() if $dieonerror && !$ok;
   return $ok;
   }   

   
sub StartProcessError
   {
   print ":::" . Win32::FormatMessage( Win32::GetLastError());
   }

sub StartCmdShell
   {
   my ($dir) = @_;

   $dir ||=  "c:\\";
#  SysCommand('tcc.exe', " /K \"$dir\"");
   my $syscmd = "start tcc /D \"$dir\"";
#  print "$syscmd\n" ;#if Option("debug");
   system($syscmd);
   }


sub StartExplorer
   {
   my ($dir) = @_;

   $dir ||=  "c:\\";
   #SysCommand('"%windir%\explorer.exe"', "\"$dir\"");
   #StartProcess('%windir%\explorer.exe', 'explorer',  "\"$dir\"");
   my $windir = $ENV{"WINDIR"} || "c:\\Windows";
   StartProcess("$windir\\explorer.exe", 'explorer',  "\"$dir\"");
   }




1; # two
  
__END__   
