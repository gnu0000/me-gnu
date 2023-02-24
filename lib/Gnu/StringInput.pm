#
# StringInput.pm - commandline like string input
#  C Fitzgerald 8/1/2013  This is a mess
#
# Synopsis:
#  my $str = SIGetString();
#  my $str = SIGetString(prompt=>"Gimme a string", preset=>"okay");
#  my $str = SIGetString(prompt=>"username", preset=>"$lastentry", context=>"username");
#
#  > SIGetString provides:
#      cmdline like editing: moving: right/left, ctrl-right/left, home/end; clear: esc; deleting: del/back;
#      copy/cut/paste:       numpad +/numpad -/numpad <ins>
#      input history:        up/down (matching what you have typed so far)
#      macros:               add macro's via SISetMacro()
#      tags:                 shift-FN to store cmdline as tag, Fn to insert it, and via SISetMacro()
#      externals:            tab & shift tab to recall app defined strings or to do
#                            filename completion, or even context sensitive text completion. etc...
#                            There is a lot to the extern stuff. See SIExternal SIExternCallback
#      keyboard macros:      (via KeyInput)
#        <F12>      - start recording keys
#        <F12>      - end recording keys (and bind to to <F11>     
#        <Ctrl>#    - end recording keys (and bind to to <Ctrl-#>)
#        <Shift>F12 - end recording keys (and bind to to _next_ key)
#        <F11>      - playback keys
#        <Ctrl>#    - playback keys
#        <Ctrl><Shift>F12 - enable/disable key macros
#
#  > SIGetString can act in different contexts, so that, for example:
#        my $name = SIGetString(context=>"names");
#        my $file = SIGetString(context=>"files");
#    where each input will have its own cmd history, tags, macros & externals.
#    you can also get/set context via SIContext()
#
#  > SIStateStream allows you to load/store 
#        options, macros, clipboard, history, externals, and aliases
#
# default key bindings:
#    <shift><ctrl>? .... This help
#    <up> .............. find prev entered string matching current str
#    <down> ............ find next entered string matching current str
#    <tab> ............. find next external string matching current str
#    <shift>-<tab> ..... find prev external string matching current str
#    <fnkey> ........... Replace current string with string bound to fn key
#    <shift>-<fnkey> ... Bind current string to this fn key
#                         If string ends in \\\\n the string the string will
#                         be returned immediately after hitting the fn key
#    <home> ............ Move cursor to beginning of string
#    <end> ............. Move cursor to end of string
#    <ctrl><right> ..... Move cursor right 1 word
#    <ctrl><left> ...... Move cursor left 1 word
#    <esc> ............. Clear string or reset to initial value or return empty
#    <numpad>+ ......... Copy string (word if <ctrl>)
#    <numpad>- ......... Cut string (word if <ctrl>)
#    <numpad><ins> ..... Add clipboard string (replace if <ctrl>)
#    <ctrl>k ........... Add string to history and clear
#    <shift><ctrl>d .... Debug info
#    <shift><ctrl>t .... Show fn key tags
#    <shift><ctrl>h .... Show history
#    <shift><ctrl>? .... Show special keys
#    <shift><ctrl>x .... clear history
#
# exported fns:
#     SIGetString ......... the main input fn
#     SIContext ........... get set current context
#     SIStateStream ....... get set state (cmd history & tags & external & macros & aliases)
#     SISetMacro .......... get/set macros and tags
#     SIMacroCallback ..... get notification when macro is changed
#     SIClipboard ......... get/set clipboard string
#     SIExternal .......... get/set external data (for tab/shift tab)
#     SIExternalCallback .. handle dynamic external data
#
#   stuff you shouldn't need:
#     SIHistory ........... get/set internal history datastructure
#     SIGetHistory ........ get/set internal history datastructure for current context
#     SIFindHistory ....... find history matching a string in the current context
#     SIAddHistory ........ add to cmd history
#     SISetHistory ........ etc ...
#     SIGetHistorySize .... 
#     SIMacros ............ 
#     SIGetMacro .......... 
#     SIMacroKeyName ......
#
# this module is tightly bound to Gnu::KeyInput
#
# todo: 
#   Document the full api, provide examples including macros and hooks
# 
#   Simplify SIExternals. We should not need the type:
#    - remove adata type, roll into cdata
#    - remove fdata type, roll into a true callback for cdata
# 
#    - cext {/match/}
#    - walk nodes as we are building the word chain (done?)
#       - this allows different parsing regexes for different nodes
#       - this allows associating the chain entry with a node which can allow lots of stuff
#    - true callbacks in extern data
#    - {/match/} in extern data
#
#  Expand hook functionality beyond the existing external data handling
#  Cleanup API. We need a clean lower level api for the hooks, and macros to use
#
#  Code cleanup all over, particularly External.pm
#
package Gnu::StringInput;

use lib "../../lib";
use warnings;
use strict;
use feature 'state';

use List::Util       qw(max min sum);
use List::MoreUtils  qw(uniq);
use File::Basename;
use MIME::Base64;
use Cwd              qw(getcwd abs_path);
use Gnu::FileUtil    qw(SlurpFile SpillFile);
use Gnu::StringUtil  qw(CleanInputLine LineString TrimNS Trim);
use Gnu::ListUtil    qw(OneOf OneOfStr ABList AnyHasVal);
use Gnu::KeyInput    qw(GetKey IsCtlKey IsFnKey IsUnprintableChar MakeKey KeyName DumpKey DecomposeCode KeyMatch);
use Gnu::Var         qw(:ALL);
use Gnu::DebugUtil   qw(:ALL);
use Gnu::MiscUtil    qw(:ALL);

require Exporter;
our @ISA       = qw(Exporter);
our $VERSION   = 0.20;
our @EXPORT    = qw();
our @EXPORT_OK = qw(SIGetString
                    SIContext
                    SIStateStream
                    SIMacroCallback
                    SIHistory
                    SIGetHistory
                    SIFindHistory
                    SIAddHistory
                    SISetHistory
                    SIGetHistorySize
                    SIGetLastVal
                    SIExternal
                    SIAddExternal
                    SIWordRegex
                    SIMacros
                    SIGetMacro
                    SIGetSpecificMacro
                    SIEnableMacro
                    SIClearMacros
                    SISetMacro
                    SIMacroKeyName
                    SIClipboard
                    SITagList
                    SIHooks
                    SIGetHook
                    SISetHook
                    SIOption
                    SIContextList
                    SIExternCallback
                    SIMsg
                    );

our %EXPORT_TAGS = (MIN =>[qw(SIGetString SIOption SIContext)],
                    BASE=>[qw(SIGetString SIOption SIContext SIExternal SIAddExternal SIWordRegex SIStateStream)],
                    ALL =>[@EXPORT_OK]);


# constants
my $DEFAULT_CONTEXT  = "default";

require Gnu::StringInput::Counters;
require Gnu::StringInput::Message;
require Gnu::StringInput::Hooks;
require Gnu::StringInput::Options;
require Gnu::StringInput::Macros;
require Gnu::StringInput::History;
require Gnu::StringInput::External;
require Gnu::StringInput::Clipboard;
require Gnu::StringInput::Alias;


# default global key mappings
#
# hashkey for keymap: (vkey)(S)(C)
#    (vkey)     : the keyboard key for the binding key
#    (S)        : 'S'|'s'|''  meaning shift,noshift,or dont care
#    (C)        : 'C'|'c'|''  meaning ctrl,noctrl,or dont care
#
sub EditKeymap
   {
   return
      {
      "13"  => {fn=> \&KeyDone, finish=>1},  # return
      "27"  => {fn=> \&KeyReset          },  # escape
      "37"  => {fn=> \&KeyLeft           },  # Left
      "39"  => {fn=> \&KeyRight          },  # Right
      "36"  => {fn=> \&KeyHome           },  # Home
      "35"  => {fn=> \&KeyEnd            },  # End
      "38"  => {fn=> \&KeyUp             },  # Up
      "40"  => {fn=> \&KeyDown           },  # Down
      "8"   => {fn=> \&KeyBack           },  # Back
      "46"  => {fn=> \&KeyDel            },  # Del
      "107s"=> {fn=> \&KeyCopy           },  # numpad +
      "109s"=> {fn=> \&KeyCut            },  # numpad -
      "45s" => {fn=> \&KeyPaste          },  # numpad <ins>
      "75sC"=> {fn=> \&KeyAddHistory     },  # <ctrl>-k
      "68SC"=> {fn=> \&KeyDebugInfo      },  # <shift>-<ctrl>-d
      "84SC"=> {fn=> \&KeyShowTags       },  # <shift>-<ctrl>-t
      "72SC"=> {fn=> \&KeyShowHistory    },  # <shift>-<ctrl>-h
      "191SC"=>{fn=> \&KeyShowSpecial    },  # <shift>-<ctrl>-?
      "88SC"=> {fn=> \&KeyClearHistory   },  # <shift>-<ctrl>-x
      "9sc" => {fn=> \&KeyTab            },  # <tab>
      "9Sc" => {fn=> \&KeyShiftTab       },  # <shift><tab>
      "any" => {fn=> \&KeyAny            },  # a char
      };
   }


# SIGetString -external-
#
# the main function - get a string like a command prompt
#
# options
#   prompt       => "str"    - print a label prompt
#   preset       => "str"    - preset string value
#   presetlast   => 1        - preset string value to prev input
#   context      => "name"   - context for history and macros (note: setting a context is 'sticky')
#   external     => [,,]     - set external match strings for 'tab'
#   allowdups    => 1        - allow duplicate entries in history
#   nohistmod    => 1        - dont add to history
#   wordregex    => qr/regex/- specify word parsing regex
#
#   escape       => n        - return empty string if user hits escape n times
#   nocr         => 1        - dont print a \n when done
#   noisy        => 1        - (disruptive to input) message when keyboard macro is started/stopped
#   trim         => 1        - return string with begin/end whitespace removed
#   trimstart    => 1        - return string with beginning whitespace removed
#   trimend      => 1        - return string with ending    whitespace removed
##  exfiles      => 1        - use filesystem for external data
#   exfileroot   => "dir"    - set root for exfiles, cwd is default
##  excontext    => 1        - use contextual matching for external data
#   nospecialkeys=> 1        - disable <shift>-<ctrl>- d,t,h,?,x keys
#   ignorechars  => str      - string if characters to ignore on input
#   ignorecodes  => [code,,] - arrayref of key codes to ignore (exact codes)
#   mygetkeyfn   => \&fn     - replace Gnu::KeyInput::GetKey with your own
#   aliases      => 1        - allow aliases
#                             
###############################################################################

sub SIGetString
   {
   my (%options) = @_;

   SIContext({push=>1}, $options{context});

   InitTVars({%options});
   SIExternal($options{external}) if TVarExists("external"); # todo: this should be temp

   #my ($preset,$prompt,$noisy,$last) = VVd(preset=>"",prompt=>"",noisy=>0,_last_str=>"");
   my ($preset,$presetlast,$laststr,$ignorechars) = VVd(preset=>"",presetlast=>0,_last_str=>"",ignorechars=>"");

   my ($prompt,$noisy,$ignorecodes,$getkeyfn) = VVd(prompt=>"",noisy=>0,ignorecodes=>0,mygetkeyfn=>\&GetKey);
   $preset = ($presetlast ? $laststr : $preset) || "";
   my ($str, $str_idx) = ($preset, length $preset);
   my $keys = [];

   print "$prompt: " if $prompt;
   print "$str";

   my ($prev_key, $finish) = (undef, 0);
   while(1)
      {
      my $key = &{$getkeyfn}(ignore_ctl_keys=>1, noisy=>$noisy);

      next if $ignorechars && IgnoreChar($key, $ignorechars);
      next if $ignorecodes && IgnoreCode($key, $ignorecodes);
      
      unshift @{$keys}, $key;

      my $macro = Ma_FindMacro($key->{code});
      my $fn    = $macro->{fn};
      my $info  = {%{$macro},
                   str   => $str   , str_idx => $str_idx ,
                   key   => $key   , prev_key=> $prev_key,
                   keys  => $keys  ,
                   prompt=> $prompt,
                   preset=> $preset, strlen  => length($str) };

      $info = (&{$fn}($info, $str, $str_idx, $key)) if $fn;
      if ($info)
         {
         $str     = $info->{str    } if exists $info->{str    };
         $str_idx = $info->{str_idx} if exists $info->{str_idx};
         $finish  = $info->{finish } || 0;
         }
      last if $macro->{finish} || $finish;
      $prev_key = $key;
      }
   print "\n" unless V("nocr");

   $str =~ s/^[\r\n\s]+// if V("trim") || V("trimstart");
   $str =~ s/[\r\n\s]+$// if V("trim") || V("trimend");

   SIAddHistory($str, V(allowdups=>0)) unless V("nohistmod");
   VarSet(_last_str=>$str);
   
   $str = _HandleAliasCmd($str)    if V("aliases");
   $str = SIInterpolateAlias($str) if V("aliases");
   Ex_BuildContextChain($str)      if V("buildcontext");

   SIContext({pop=>1});
   return $str;
   }


sub SIGetLastVal
   {
   return ResolveVar("_last_str");
   }
   
sub IgnoreChar
   {
   my ($key, $ignorechars) = @_;   
   return 0 if IsUnprintableChar($key);
   return $ignorechars =~ /$key->{char}/;
   }
   
sub IgnoreCode
   {
   my ($key, $ignorecodes) = @_;   
#  !KeyMatch($key, @{$ignorecodes});
   map{return 1 if $key->{code} eq $_} @{$ignorecodes};
   return 0;
   }


# SIContext -external-
#
# get/set input context
# A context identifies a scope for macros and command history.
# The default context is 'default'.
#
sub SIContext {VarContext(@_)}
sub SIContextList{VarContext({ctxlist=>1})}


############################################################################################



# default global key handlers -internal-
#
########################################


sub KeyAny
   {
   my ($info, $str, $str_idx) = @_;

   return KeySaveFn (@_) if IsFnKey($info->{key}, isshft=>1, isctrl=>0);
   return KeyAddChar(@_);
   }


sub KeyAddChar
   {
   my ($info, $str, $str_idx) = @_;

   return {} if IsUnprintableChar($info->{key});

   
   $str = AddChar($str, $str_idx, $info->{key}->{char});
   WriteStr($str, $str_idx, $str_idx+1);
   return {str=>$str,str_idx=>$str_idx+1};
 
   # or
   #return AddString($str, $str_idx,$info->{key}->{char});
   }


sub KeyDone
   {
   return {};
   }


sub KeySaveFn
   {
   my ($info, $str, $str_idx) = @_;

   my $code = $info->{key}->{code};
   $code =~ s/S/s/i;

  my $tag = $str;
  my %opt = (del=>($tag eq ""));
  if ($tag =~ /\\n$/)
     {
     chop $tag;
     chop $tag;
     $opt{finish} = 1;
     }
   SISetMacro(code=>$code, tag=>$tag, %opt);
   EraseString($str, $str_idx);
   return {str=>"",str_idx=>0};
   }


sub KeyTag
   {
   my ($info, $str, $str_idx) = @_;

   my $idx = _GetRepeatCount($info->{keys});
   my $tag = _GetMacroTag($info->{tag}, $idx);
   
   return ReplaceString($str, $str_idx, $tag) if $info->{replace};

   my $parts = $idx ? TVar("kt_parts") : TVar(kt_parts=>[_ExStringParts2($str, $str_idx)]);
   my @p = @{$parts};
   $p[1] = $tag if length $tag;
   
   return RejoinString($str, $str_idx, @p);
   }



sub KeyClear
   {
   my ($info, $str, $str_idx) = @_;

   EraseString($str, $str_idx);
   return {str=>"",str_idx=>0};
   }


sub KeyReset
   {
   my ($info, $str, $str_idx) = @_;

   my $hits   = _GetRepeatCount($info->{keys}) +1;
   my $abort  = $hits >= V(escape=>5); #   $info->{escape} ? 1 : 0;

   my $newstr = ($hits % 2) && $str ? "" : V(preset=>"");
   my $ret    = ReplaceString($str, $str_idx, $newstr);
   $ret->{finish} = 1 if $abort;
   return $ret;
   }


sub KeyLeft
   {
   my ($info, $str, $str_idx) = @_;

   return {} unless $str_idx;

   my $offset = $info->{key}->{isctrl} ? WordLeftOffset($str, $str_idx) : 1;
   $str_idx   = MoveCursor($str, $str_idx, 0-$offset);

   return {str=>$str,str_idx=>$str_idx};
   }


sub KeyRight
   {
   my ($info, $str, $str_idx) = @_;

   return {} unless $str_idx < length($str);

   my $offset = $info->{key}->{isctrl} ? WordRightOffset($str, $str_idx) : 1;
   $str_idx   = MoveCursor($str, $str_idx, $offset);

   return {str=>$str,str_idx=>$str_idx};
   }


sub KeyHome
   {
   my ($info, $str, $str_idx) = @_;

   MoveCursor($str, $str_idx, 0-$str_idx);

   return {str=>$str,str_idx=>0};
   }


sub KeyEnd
   {
   my ($info, $str, $str_idx) = @_;

   my $offset = max(0, length($str) - $str_idx);
   $str_idx = MoveCursor($str, $str_idx, $offset);

   return {str=>$str,str_idx=>$str_idx};
   }


sub KeyUp
   {
   return KeyUpDown(1, @_);
   }


sub KeyDown
   {
   return KeyUpDown(-1, @_);
   }


sub KeyUpDown
   {
   my ($direction, $info, $str, $str_idx) = @_;

   my $continue = $info->{prev_key} && IsHistoryKey($info->{prev_key}) ? 1 : 0;
   my $entry = FindHistory($str, $direction, $continue);
   return {} unless length($entry);

   EraseString($str, $str_idx);
   $str = $entry;
   print "$str";
   return {str=>$str,str_idx=>length($str)};
   }


sub KeyTab
   {
   return KeyFindExternal3(1, @_);
   }


sub KeyShiftTab
   {
   return KeyFindExternal3(-1, @_);
   }

#########################new######################################
#########################new######################################

sub KeyFindExternal3
   {
   my ($direction, $info, $str, $str_idx) = @_;
   
   my $xinfo = _ExGetState3($direction, $info, $str, $str_idx);
   _ExFindNextExtern3 ($xinfo);
   return _ExApplyNextExtern3($xinfo);
   }
   
sub _ExGetState3
   {
   my ($direction, $info, $str, $str_idx) = @_;

   my $continue = IsExternalKeys(@{$info}{"key","prev_key"});
   my $xinfo    = $continue ? TVar("xfo_state") : TVarSet(xfo_state=>_ExStateInit3($str, $str_idx));
   
   @{$xinfo}{qw(str str_idx direction continue)} = ($str, $str_idx, $direction, $continue);
   
   map{$xinfo->{$_} = $info->{$_} ||""} qw(fmode ttype exdir);
   return $xinfo;
   }

sub _ExStateInit3
   {
   my ($str, $str_idx) = @_;
   
   my $type  = SIExternal(gettype=>1);
   my $xinfo = {type=>$type, ttype=>"", exdir=>""};
   @{$xinfo}{qw(pre sword post)} = _ExStringParts2($str, $str_idx);
   return $xinfo;
   }

sub _ExFindNextExtern3
   {
   my ($xinfo) = @_;
   
   my %opt;
   @opt{qw(direction continue rootdir pre_str)} = @{$xinfo}{qw(direction continue exdir pre)};
   
   my ($sword, $type, $ttype) = @{$xinfo}{qw(sword type ttype)};
   
   $xinfo->{eword} = $ttype eq "fdata" ? FindExternalF($sword, %opt) :
                     $type  eq "cdata" ? FindExternalC($sword, %opt) :
                     $type  eq "fdata" ? FindExternalF($sword, %opt) :
                                         FindExternalA($sword, %opt) ;
   return $xinfo->{eword};
   }
   
sub _ExApplyNextExtern3
   {
   my ($xinfo) = @_;
   
   return {} unless length($xinfo->{eword});
   return RejoinString(@{$xinfo}{qw(str str_idx pre eword post)});
   }
   

sub KeyBack
   {
   my ($info, $str, $str_idx) = @_;

   return {} if !$str_idx;
   
   
   # <ctrl>-back = delete to current word left
   if ($info->{key}->{isctrl})
      {
      my $offset = WordLeftOffset($str, $str_idx-1);
      return {} unless $offset;
      return RejoinString($str, $str_idx, 
                           substr($str,0,$str_idx-$offset), 
                           "", 
                           substr($str,$str_idx));
      }
   
   $str = DelChar($str, $str_idx);
   $str_idx--;
   print "\b";
   WriteStr($str, $str_idx, $str_idx);
   return {str=>$str,str_idx=>$str_idx};
   }


sub KeyDel
   {
   my ($info, $str, $str_idx) = @_;
   
   # <ctrl>-del = delete current word
   if ($info->{key}->{isctrl})
      {
      my ($pre, $word, $post) = _ExStringParts2($str, $str_idx);
      return RejoinString($str, $str_idx, $pre, "", $post);
      }
   #del = delete char right
   return {} unless $str_idx < $info->{strlen};
   $str = DelChar($str, $str_idx+1);
   WriteStr($str, $str_idx, $str_idx);
   return {str=>$str,str_idx=>$str_idx};
   }


sub KeyAddHistory
   {
   my ($info, $str, $str_idx) = @_;

   SIAddHistory($str);
   return KeyClear(@_);
   }


sub KeyClearHistory
   {
   my ($info, $str, $str_idx) = @_;

   return KeyAny(@_) if V("nospecialkeys");

   #VHistory([]);
   SIHistory([]);
   return {};
   }


sub KeyCopy
   {
   my ($info, $str, $str_idx) = @_;

   SIClipboard($info->{key}->{isctrl} ? CurrentWord($str, $str_idx) : $str);
   return {};
   }


sub KeyCut
   {
   my ($info, $str, $str_idx) = @_;

   SIClipboard($info->{key}->{isctrl} ? CurrentWord($str, $str_idx) : $str);

   # todo: erase curr word if ctl
   return KeyClear(@_);
   return {};
   }


sub KeyPaste
   {
   my ($info, $str, $str_idx) = @_;

#   my $clip    = SIClipboard();
#   my $replace = $info->{key}->{isctrl};
#
#   return AddString($str, $str_idx, $clip, $replace);
#
#todo: wip

   return RejoinString($str, $str_idx, 
                       substr($str,0,$str_idx), 
                       SIClipboard(),
                       substr($str,$str_idx));
   }


sub KeyDebugInfo
   {
   my ($info, $str, $str_idx) = @_;

   return KeyAny(@_) if V("nospecialkeys");

   my ($len,$prompt) = @{$info}{"strlen","prompt"};
   my $all = _GetRepeatCount($info->{keys});

   _aside(@_);   
   print "\n\n" . LineString("Debug info") x ($all ? 5 : 1);

   my $currctx = SIContext();
   my @allctx = VarContext({push=>1, all=>1, ctxlist=>1});
   my @ctxlist = $all ? (@allctx) : ($currctx);

   foreach my $context (@ctxlist)
      {
      SIContext($context);
      my $marker = $context eq $currctx ? "(current)" : "";
      print "\n" . LineString("Context: '$context' $marker");

      my $wordregex = _WordRegex();
      print "Word Regex: $wordregex\n";

      print "\nHistory in context '$context':\n";
      print "  ", join("\n  ", @{SIHistory()}), "\n";

      print "\nCxternals in context '$context' (type",Ex_Data(gettype=>1),"):\n";
      print SIExternal(getview=>1), "\n";

      print "Tags in context '$context':\n";
      print SITagList();
      }
   VarContext({pop=>1});
   print LineString();
   return _aside();   
   }


sub _OptStr
   {
   my $bulkstr = "";
   my @varnames = VarContext({varlist=>1});
   foreach my $vname (@varnames)
      {
      next if _InternalVar($vname);
      #next if $vname =~/^($NAM_HISTORY)|($NAM_EXTERNAL)|($NAM_HOOKS)|($NAM_MACROS)$/;
      my $value = Var($vname);
      $value = "(undef)" if !defined $value;
      #my $kind = ref $value;
      $bulkstr .= sprintf("  %-10s = $value\n", $vname);
      }
   return $bulkstr;
   }

sub _InternalVar # todo: cleanup
   {
   my ($vname) = @_;
#  return $vname =~/^($NAM_HISTORY)|($NAM_EXTERNAL)|($NAM_HOOKS)|($NAM_MACROS)$/;
#  return 0; # todo
   return $vname =~/^__/;
   }


sub KeyShowTags
   {
   my ($info, $str, $str_idx) = @_;

   return KeyAny(@_) if V("nospecialkeys");

   my $context = SIContext();
   _aside(@_);
   print "\n" . LineString("Tags in context $context"), SITagList(), "\n";
   print LineString();
   return _aside();   
   }

   
sub KeyShowHistory
   {
   my ($info, $str, $str_idx) = @_;

   return KeyAny(@_) if V("nospecialkeys");
   _aside(@_);

   my $all = _GetRepeatCount($info->{keys});
   my $currctx = SIContext();
   my @allctx = VarContext({push=>1, all=>1, ctxlist=>1});
   my @ctxlist = $all ? (@allctx) : ($currctx);
   print "\n";
   foreach my $context (@ctxlist)
      {
      SIContext($context);
      my $marker = $context eq $currctx ? "(current)" : "";
      print LineString("History in context $context $marker:");
      print "  ", join("\n  ", @{SIHistory()}), "\n";
      }
   print LineString();
   VarContext({pop=>1});
   return _aside();
   }


sub KeyShowSpecial
   {
   my ($info, $str, $str_idx) = @_;

   return KeyAny(@_) if V("nospecialkeys");

   _aside(@_);
   print LineString("special keys:");
   print " <shift>-<fnkey>  ..... store string as fn tag\n";
   print " <shift>-<ctrl>-d ..... debug info            \n";
   print " <shift>-<ctrl>-t ..... show tags             \n";
   print " <shift>-<ctrl>-h ..... show history          \n";
   print " <shift>-<ctrl>-? ..... show this help        \n";
   print " <shift>-<ctrl>-x ..... clear history         \n";
   return _aside();
   }


#################################
#
# key handler helpers and GetString util fns -internal-
#
# for debugging. to use 
#    _aside($info, $str, $str_idx) -or- _aside($str, $str_idx)
#    print debug messages ...
#    _aside()
#
sub _aside
   {
   my ($info, $str, $str_idx) = @_;
   
   # my ($str, $str_idx) = @_; also works
   ($info, $str, $str_idx) = ({strlen=>length($info),prompt=>VVd(prompt=>"whatever")}, @_)
      if (scalar(@_) == 2);

   state $_info;
   state $_str;
   state $_str_idx;
   
   if ($info)
      {
      ($_info, $_str, $_str_idx) = ($info, $str, $str_idx);
      return print "\n";
      }
   my ($len,$prompt) = @{$_info}{"strlen","prompt"};
   print "$prompt: " if $prompt;
   print "$_str";
   MoveCursor($_str, $_str_idx, $_str_idx - $len);
   return {};
   }
   
   
sub _GetRepeatCount
   {
   my ($keys) = @_;

   my $keycount = scalar @{$keys};
   my $keycode = $keys->[0]->{code};
   my $repeats = 0;
   foreach my $i (1..$keycount-1)
      {
      last unless $keys->[$i]->{code} eq $keycode;
      $repeats += 1;
      }
   return $repeats;
   }
   
   
sub IsHistoryKey
   {
   my ($key) = @_;

   return ($key->{vkey} == 38 || $key->{vkey} == 40); # up/down for now
   }


sub IsExternalKey
   {
   my ($key) = @_;

   return ($key->{vkey} == 9); # tab sh/tab
   }


sub IsExternalKeys
   {
   my (@keys) = @_;

   map{return 0 unless $_ and $_->{vkey} == 9} @keys;
   return 1;
   }


sub WordLeftOffset
   {
   my ($str, $str_idx) = @_;

   return 0 if !$str_idx || !length($str);
   my $chain = Ex_MakeChain($str);
   my $laststart = 0;
   
   foreach my $entry (@{$chain})
      {
      my $start = $entry->{start};
      return $str_idx-$laststart if $str_idx <= $start;
      $laststart = $start;
      }
   return $str_idx-$laststart;
   }
   
sub WordRightOffset
   {
   my ($str, $str_idx) = @_;

   my $len = length($str);
   return 0 unless $str_idx < $len;
   
   my $chain = Ex_MakeChain($str);
   
   map{return $_->{start}-$str_idx if $_->{start} > $str_idx} @{$chain};
   return max(0,$len-$str_idx);
   }
   

sub AddChar
   {
   my ($str, $str_idx, $char) = @_;

   substr($str,$str_idx,0,$char);
   return $str;
   }


sub DelChar
   {
   my ($str, $str_idx) = @_;

   substr($str,$str_idx-1,1,"");
   return $str;
   }

   
sub WriteStr
   {
   my ($str, $backct, $forwardct) = @_;

   my $strlen = length $str;

   print "\b" x $backct;
   print "$str \b";
   print "\b" x ($strlen - $forwardct);
   }

sub MoveCursor
   {
   my ($str, $str_idx, $offset) = @_;

   print substr($str, $str_idx, $offset) if $offset > 0;
   print "\b" x (0-$offset)              if $offset < 0;
   return $str_idx + $offset;
   }

sub EraseString
   {
   my ($str, $str_idx) = @_;

   my $len    = length($str);
   my $to_end = max(0, $len - $str_idx);

   print " "     x $to_end;
   print "\b \b" x ($str_idx + $to_end);

   return 0; #$str_idx
   }
   
# examples:
#    qr/(\w+)/              - words are alphanumeric only
#    qr/(\w|\\|\:|\/|\.)+/  - words are alphanumeric but can also contain chars \, /, :, . 
#    qr/(\S+)/              - words may contain anything but whitespace
#    qr/(::)|\(|\)|(\w+)/   - words are alphanumeric plus special words ::, (, )
#test: qr/([^\s\,\;]+/        - words may contain anything but whitespace , or ;
#   
sub SIWordRegex
   {
   my ($newregex) = @_;
   
   return _WordRegex() unless $newregex;
   
   return SIOption("wordregex", @_) || "";
   }


   
sub _WordRegex
   {
   return V("wordregex") || qr/(\w|\\|\:)+/;
   }
   
   
sub ReplaceString
   {
   my ($str, $str_idx, $newstr) = @_;

   EraseString($str, $str_idx);
   print "$newstr";
   return {str=>$newstr,str_idx=>length($newstr)};
   }

   
# adds addstr to str at cursor pos
# sets cursor to end of insert
#   
sub AddString
   {
   my ($str, $str_idx, $addstr, $replace) = @_;

   return ReplaceString($str, $str_idx, $addstr) if ($replace);
   
   my $strlen = length($str);
   my $addlen = length($addstr) || return {};
   my $offset = $str_idx - $strlen;
   
   EraseString($str, $str_idx);
   
   substr($str,$str_idx,0,$addstr);
   print "$str";
   
   $str_idx = MoveCursor($str, length($str), $offset) if $offset;
   
   return {str=>$str,str_idx=>$str_idx};
   }


# replaces str with :  pre+nword+post
# sets cursor to end of nword
#
sub RejoinString
   {
   my ($str, $str_idx, $pre, $nword, $post) = @_;
   
   #my $nwlen = length($nword) || return {};

   EraseString($str, $str_idx);

   my $nstr  = $pre . $nword . $post;
   my $nslen = length($nstr );
   my $nwlen = length($nword);
   my $nidx  = length($pre  ) +  $nwlen;
   
   print "$nstr";
   my $offset = $nidx - $nslen;
   $nidx = MoveCursor($nstr, $nslen, $offset) if $offset;
   
   return {str=>$nstr,str_idx=>$nidx};
   }


sub CurrentWord
   {
   my ($str, $str_idx, $chain) = @_;
   
   my $entry = _ExFindChainEntry2($str, $str_idx, $chain);
   return $entry ? $entry->{word} : "";
   }
   

   
# general stringinput
# used for isoverwordword
# used by external for finding context and adding cdata nodes
#
# in: 
#    $string - input string to break into chain
#    %opt:
#       wordregex   => qw\\  for parsing word ident
#       nousecache => 1     dont use tmp cache
#       nosavecache=> 1     dont save to tmp cache
#
#     wordregex examples:
#       wordregex=> qr/(\w+)/             # normal ident
#       wordregex=> qr/(\w|\\|\:)+/       # allow \ and : in identifiers
#       wordregex=> qr/(::)|\(|\)|(\w+)/  # normal ident or '::' or '(' or ')'
#
# uses:
#    V(wordregex)         unless opt wordregex provided
# out:
#    returns an arrayref of wordentries
#
# returns
#    $chain  - an arrayref of wordentries
#              a wordentry is a hashref containing:
#
#        word  => string   - a word from the string
#        start => #        - starting index in the string
#        end   => #        - ending index in the string
#        len   => #        - the length of the word
#
sub Ex_MakeChain
   {
   my ($str, %opt) = @_;
   
   my $regex  = $opt{wordregex} || _WordRegex();

   my $chain = $opt{nousecache} ? undef : _Ex_CachedChain($str, $regex);
   return $chain if $chain;
   $chain = [];
   
   my ($chainstr, $pos) = ($str, 0);
   
   while(length($chainstr))
      {
      last unless $chainstr =~ /^(.*?)($regex)(.*)$/;
      
      my ($skip, $word, $rest) = ($1||"", $2||"", $+);
      
      my $start = $pos + length($skip);
      my $len   = length($word);
      my $end   = $start + $len -1;
      
      push @{$chain}, {word=>$word, start=>$start, len=>$len, end=>$end};
      ($pos,$chainstr)  = ($end+1,$rest);
      }
   return _Ex_CachedChain($str, $regex, $chain) unless $opt{nosavecache};
   return $chain; 
   }
   
   
# caches 
#   
sub  _Ex_CachedChain
   {
   my ($str, $regex, $chain) = @_;
   
   my $cache = TVarInit(_ex_chain_cache=>{});
   return $cache->{$str . $regex} unless  scalar @_ > 2;
   return $cache->{$str . $regex} = $chain;
   }
   
   
sub _ExFindChainEntry2
   {
   my ($str, $idx, $chain) = @_;
  
#  my ($chain, $idx) = @_;
   
   $chain ||= Gnu::StringInput::Ex_MakeChain($str);
   
   map{return $_ if InRange($idx,$_->{start},$_->{end})} @{$chain};
   
   # special case. well match a word with the cursor 1 spot past
   map{return $_ if $idx == $_->{end}+1}  @{$chain};

   return undef;   
   }
   
   
#   
#   
sub _ExStringParts2
   {
   my ($str, $idx, $chain) = @_;
   
   $chain ||= Gnu::StringInput::Ex_MakeChain($str);
   
   my $len      = length $str;
#  my $entry    = _ExFindChainEntry2($chain, $idx);
   my $entry    = _ExFindChainEntry2($str, $idx, $chain);
   my $leftpos  =  $entry ? $entry->{start}-1 : $idx - 1;
   my $rightpos =  $entry ? $entry->{end}  +1 : $idx;
   
   my $pre  = $leftpos >= 0   ? substr($str, 0, $leftpos+1) : "";
   my $word = $entry          ? $entry->{word}              : "";
   my $post = $rightpos<$len  ? substr($str,$rightpos)      : "";

   return ($pre, $word, $post);   
   }
   

#############################################################################

# opt
#   direction
#   start
#   allowregex
#   exact
#
#
sub _FindInList
   {
   my ($set, $search_str, %opt) = @_;

   my $direction = $opt{direction} || 1;
   my $start     = $opt{start    } || 0;

   my ($ex_size, $pos)  = (scalar @{$set}, $start);
   my $target = $opt{allowregex} ? $search_str : quotemeta $search_str;
   my $pattern= $opt{exact     } ? qr/^$target$/ : qr/^$target/;

   foreach (0..$ex_size-1)
      {
      $pos = $pos % $ex_size;
      return ($set->[$pos], $pos) if ($set->[$pos] =~ /$pattern/i);
      $pos += $direction;
      }
   return ("", 0);
   }

#############################################################################
#
# search type F internals

sub _FixDirSlash
   {
   my ($dir, $set_if_blank) = @_;

   $dir = "" unless defined $dir;
   if ($dir eq ""){return $set_if_blank ? ".\\" : ""}

   $dir =~ tr[/][\\];
   chop $dir if $dir =~ /\\$/;
   return "$dir\\";
   }

#########################################################################
#########################################################################
#########################################################################

# _KeyCode
# param: key or code, returns code
#
# todo: move me
sub _KeyCode
   {
   my ($key_or_code) = @_;

   return $key_or_code unless ref($key_or_code) eq "HASH";
   return $key_or_code->{code};
   }


# State fns
#
################################################################################

# SIStateStream -extenal
#
# get/set current state (options,macros,clipboard,history,externals,aliases)
#
# generate:
#  $stream = SIStateStream()
#  $stream = SIStateStream(undef,skip_file_histoty_stream=>1)
#
# load:
#  SIStateStream($stream)
#  SIStateStream($stream,skip_file_histoty_stream=>1)
#
sub SIStateStream
   {
   my ($stream, %opt) = @_;

   return Op_CreateStream(%opt) .
          Ma_CreateStream(%opt) .
          Cl_CreateStream(%opt) .
          Hi_CreateStream(%opt) .
          Ex_CreateStream(%opt) .
          Al_CreateStream(%opt) if !defined $stream;

   Op_LoadStream($stream, %opt);
   Ma_LoadStream($stream, %opt);
   Cl_LoadStream($stream, %opt);
   Hi_LoadStream($stream, %opt);
   Ex_LoadStream($stream, %opt);
   Al_LoadStream($stream, %opt);
   }

#########################################################################
#

# $doset = 0 :   set name=>val params (temp context)
# $doset = 1 :  init name=>val params (temp context)
#
sub tv_is
   {
   my ($doset, @params) = @_;

   return $doset ? TVarSet(@params) : TVarInit (@params);
   }

# $name       variable name (tmp or ctx scope)
# $scoped=0   get/set ctx var only
#        =1   look for tmp var first, set tmp var
# $init       init value if not exist and no data
# $data       set value if present, a get var if empty
#
sub v_isg
   {
   my ($name, $scoped, $init, $data) = @_;

   # look at temp first if scoped and a get
   return TVar($name) if $scoped && TVarExists($name) && !$data;

   # look at ctx next if a get
   return  Var($name) if VarExists($name) && !$data;

   # init/set temp var if scoped
   return TVarInit($name => $init) if $scoped && !$data;
   return TVarSet ($name => $data) if $scoped;

   return VarInit($name => $init) unless $data;
   return VarSet ($name => $data);
   }



sub _BulkStr
   {
   my ($listref) = @_;

   return "" unless $listref;

   my $len     = min(30, max(10, map{length $_}(@{$listref})) || 0);
   my $linect  = max(1, min(6, int(120 / $len)));
   my $idx     = 0;
   my $bulkstr = "  ";
   foreach my $str (@{$listref})
      {
      $bulkstr .= sprintf("%-*s  ", $len, $str);
      $bulkstr .= "\n  " unless ++$idx % $linect;
      }
   $bulkstr .= "\n" if $idx % $linect;
   return $bulkstr;
   }

# _optval(optname,defaultvalue,%opt)
# return default unless has nonzero val (exists if  _e, defined if _d)
#
sub _optval_e {my($n,$d,%o)=@_; return exists ($o{$n}) ? $o{$n}:$d};
sub _optval_d {my($n,$d,%o)=@_; return defined($o{$n}) ? $o{$n}:$d};


sub _reftype
   {
   my ($var,$undef_ret,$zero_ret) = @_;

   return  (scalar @_ > 1 ? $undef_ret : "") unless defined $var;
   return  (scalar @_ > 2 ? $zero_ret  : "") unless $var;

   my $r = ref($var);
   return "h" if $r =~ /^HASH/  ;
   return "a" if $r =~ /^ARRAY/ ;
   return "c" if $r =~ /^CODE/  ;
   return "s" if $r =~ /^SCALAR/;
   return "r" if $r =~ /^REF/   ;
   return "$r";
   }

sub TVarInc
   {
   my ($varname) = @_;

   return TVar($varname=>TVarDefault($varname=>0)+1);
   }
   
sub SkipStream
   {
   my ($context, $type, %options) = @_;
   
   
   return 1 if $options{"skip_stream"};   
   return 1 if $options{"skip_". $type ."_stream"};   
   return 0 if !$context;
   
   # options   
   #    skip_default_stream
   #    skip_default_history_stream
   #    skip_history_stream
   #
   return 1 if $options{"skip_". $context ."_". $type ."_stream"};   
   return 1 if $options{"skip_". $context             ."_stream"};   

   # context may have skip directive  
   #    skip_stream
   #    skip_history_stream
   return 1 if VarDefault(skip_stream=>0);
   return 1 if VarDefault("skip_". $type ."_stream"=>0);

   return 0;
   }
   

1; # two


__END__
