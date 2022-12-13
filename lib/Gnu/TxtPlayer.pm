# TxtPlayer.pm - 
#  C Fitzgerald 8/x/2013
#
# Synopsis:
# 
# adapter compatible with SMPlayer
# 

package Gnu::TxtPlayer;

use warnings;
use strict;
use feature 'state';
use Win32;
use Win32::Console;
use Win32::Process;
use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow SendKeys);
use Time::HiRes;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(PlayerInit
                 PlayerPlay
                 PlayerQueue
                 PlayerStop
                 PlayerClose
                 PlayerIsAction
                 PlayerAction
                 PlayerFullscreen
                 PlayerActions
                 PlayerSendCommand
                 PlayerSendKey
                 );
our @EXPORT_OK = qw();
our $VERSION   = 0.10;

# constants
#
my $DEFAULT_PLAYER_ACTIONS = 
   {
    "play"       =>{action=>"play"           },
    "close"      =>{action=>"close"          },
    "quit"       =>{action=>"quit"           },
    "37sc"       =>{action=>"{LEFT}"         },
    "40sc"       =>{action=>"{DOWN}"         },
    "40Sc"       =>{action=>"rewind3"        },
    "39sc"       =>{action=>"{RIGHT}"        },
    "38sc"       =>{action=>"{UP}"           },
    "38Sc"       =>{action=>"forward3"       },
    };


#todo:.....
my $PLAYER_SPEC  = "C:\\util\\tcmd\\tcmd.exe";     #  /C /N /NT view
my $PLAYER_TITLE = 'tcmd';
my $APP_TITLE    = 'view';
my $DEBUG        = 1;

#
###############################################################################

sub PlayerPlay
   {
   my ($spec, $add_to_playlist) = @_;

   my $addto = $add_to_playlist      ?  " -add-to-playlist " : "" ;
   my $fs    = Context("fullscreen") ?  " -fullscreen "      : "" ;
   PlayerExec(" \"$spec\" $addto $fs", Context("keep_focus"));
   }


sub PlayerQueue
   {
   my ($curr) = @_;

   my $queue_spec = Context("scratch_dir") . "\\" . Context("queue_file");
   open (my $fh, ">", $queue_spec) or return;
   foreach my $file (@{$curr})
      {
      print $fh $file->{spec} . "\n";
      }
   close($fh);
   PlayerPlay($queue_spec, 0);
   }



sub PlayerStop {PlayerSendCommand("stop", 1)  }
sub PlayerClose{PlayerSendCommand("close",0,1)}


sub PlayerFullscreen
   {
   my $state   = Context("fullscreen", 1-Context("fullscreen"));
   PlayerSendCommand($state ? "fullscreen" : "exit_fullscreen");
   }

sub PlayerSendCommand
   {
   my ($cmd, $delay, $quiet) = @_;

   my $ok = PlayerIsRunning();
   print "dont see player.\n" unless $ok || $quiet;
   return unless $ok;

   PlayerExec(" -send-action $cmd", 0); # , Context("keep_focus"));
   MySleep($delay) if $delay;
   }


sub PlayerSendKey
   {
   my ($keystr, $count, $delay) = @_;

   $count ||= 1;
   $delay ||= 0;
   my ($handle) = FindWindowLike(undef, "TxtPlayer");
   return if !$handle;

   print "DEBUG: sending keys [$keystr]\n" if Context("debug");

   SetForegroundWindow($handle);
   map{SendKeys($keystr)} (1..$count);
   SetForegroundWindow(Context("window_handle"));
   MySleep($delay) if $delay;
   }


sub PlayerActions
   {
   state $player_actions = $DEFAULT_PLAYER_ACTIONS;

   return $player_actions;
   }

sub PlayerIsAction
   {
   my ($key) = @_;

   my $actions = PlayerActions();

   return $actions->{$key->{code}} || $actions->{$key->{char}} if ref($key) eq "HASH";
   return $actions->{$key};
   }


sub PlayerAction
   {
   my ($action) = @_;

   my $method = ($action->{action} =~ /\{(.*)\}/ ? 1 : 0);
   my $delay  = $action->{delay} || 0;

   PlayerSendCommand($action->{action}, $delay) if ($method == 0);
   PlayerSendKey    ($action->{action}, $delay) if ($method == 1);
   }


sub PlayerExec
   {
   my ($cmdline_options, $keep_focus) = @_;

   return if Context("noaction");

   MyExec($PLAYER_SPEC, $PLAYER_TITLE, $cmdline_options);

   ActivateMe() if $keep_focus;
   }


sub MyExec
   {
   my ($spec, $appname, $paramlist) = @_;

   return "Player module not initialized!\n" unless Context("init");

   my $ProcessObj = " " x 10240;
   my $parm = "$appname /C /N /NT view $paramlist";

   print "DEBUG: [$spec] [$parm]\n" if Context("debug");

   Win32::Process::Create($ProcessObj, $spec, $parm, 0, NORMAL_PRIORITY_CLASS, ".")
      || die MyExecErr();
   }   

sub MyExecErr
   {
   print ":::" . Win32::FormatMessage( Win32::GetLastError());
   }


sub FindConsoleWindow
   {
   my $SetConsoleTitle = new Win32::API("kernel32", "SetConsoleTitle", ['P'],'N');
   my $FindWindow      = new Win32::API("user32"  , "FindWindow"     , ['P','P'],'N');

   return unless $SetConsoleTitle && $FindWindow;

   my $newtitle = sprintf("%s-%d", Context("app_title"), $$);
   $SetConsoleTitle->Call($newtitle);

   MySleep(0.4);
   return $FindWindow->Call(0, $newtitle);
   }


sub ActivateMe
   {
   my $window_handle = Context("window_handle") || return -1;
   MySleep(0.5);
   SetForegroundWindow($window_handle);
   MySleep(0.5);
   SetForegroundWindow($window_handle);
   }


sub MySleep
   {
   my ($duration) = @_;

   $duration ||= Context("sleep_duration");
   Time::HiRes::sleep($duration);
   }


sub PlayerIsRunning
   {
   my @handles = FindWindowLike(undef, "TxtPlayer");
   return scalar(@handles) ? 1 : 0;
   }


sub Context
   {
   my ($setting, $val) = @_;

   state $context = {init=>0};

   $context->{$setting} = $val if scalar(@_) > 1;
   return $context->{$setting};
   }


sub GetTmpDir
   {
   return $ENV{TMP} || "c:\\tmp";
   }

sub _GetComSpec
   {
   return $ENV{COMSPEC} || "";
   }

sub PlayerInit
   {
   my (%options) = @_;

   my $options = \%options;
   _initopt($options, "player_spec"   , $PLAYER_SPEC );
   _initopt($options, "player_title"  , $PLAYER_TITLE);
   _initopt($options, "app_title"     , $APP_TITLE   );
   _initopt($options, "scratch_dir"   , GetTmpDir()  );
   _initopt($options, "queue_file"    , "z.m3u"      );
   _initopt($options, "sleep_duration", 0.4          );
   _initopt($options, "fullscreen"    , "0"          );
   _initopt($options, "keep_focus"    , 1            );
   _initopt($options, "debug"         , $DEBUG       );
   _initopt($options, "window_handle" , 0            );
   _initopt($options, "noaction"      , 0            );
   _initopt($options, "init"          , 1            );
   Context("window_handle", FindConsoleWindow()) unless Context("window_handle") || !Context("keep_focus");
   }

sub _initopt
   {
   my ($options, $name, $default) = @_;

   return Context("$name", exists $options->{$name} ? $options->{$name} : $default);
   }


1; # two
  
__END__   
