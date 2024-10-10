#!perl
#
# Craig Fitzgerald 01/2014

#use lib "lib";
use warnings;
use strict;
use feature 'state';

use List::Util        qw(max min);
use List::MoreUtils   qw(uniq);
use Gnu::ArgParse;
use Gnu::StringUtil   qw(Chip Trim TrimList _CSVParts LineString LineString2 TrimNS CleanInputLine);
use Gnu::KeyInput     qw(GetKey KeyName DumpKey KeyMacroList KeyMacrosStream);
use Gnu::FileUtil     qw(SlurpFile SpillFile NormalizeFilename);
use Gnu::StringInput  qw(:ALL);
use Gnu::ListUtil     qw(OneOfStr);
use Gnu::Template     qw(Template InitTemplates);
use Gnu::DebugUtil    qw(DumpHash DumpRef);

# Note: This code predates Gnu::MetaStore thich takes care of saving state
# here, we save/load manually to $STATE_FILE
#
my $STATE_FILE      = "StringInputExample.sav";
my $DEFAULT_CONTEXT = "test";

MAIN:
   $| = 1;
   ArgBuild("*^context= *^nosave *^reset *^clear *^extern= *^samples *^help *^quiet *^debug *^play");
   ArgParse(@ARGV) or die ArgGetError();
   Setup();
   Run();


sub Run
   {
   while(1)
      {
      #, ignorecodes=>["67Sc","72SC","66sc"]
      my $str = SIGetString(TmpOptions());

      $str = zInterpolateAlias($str);

      my (@v,@sv,@sv2,@ssv,@all);
      my ($cmd, $sub) = CmdParts($str,\@v,\@sv,\@sv2,\@ssv,\@all);
      next unless $cmd;

      Is($cmd,"context","ctx"    ) ? SetContext(@sv ) :
      Is($cmd,"clear"  ,"reset"  ) ? ClearStuff($sub) :
      Is($cmd,"set"              ) ? SetOption (@ssv) :
      Is($cmd,"tset"             ) ? SetTOption(@ssv) :
      Is($cmd,"extern","external") ? SetExtern (@sv2) :
      Is($cmd,"history","hist"   ) ? SetHistory(@sv2) :
      Is($cmd,"show"  ,"view"    ) ? ShowStuff (@sv2) :
      Is($cmd,"save"  ,"write"   ) ? SaveState (@v  ) :
      Is($cmd,"load"  ,"read"    ) ? LoadState (@v  ) :
      Is($cmd,"list"             ) ? ListFile  (@v  ) :
      Is($cmd,"zalias"           ) ? zSetAlias (@ssv) :
      Is($cmd,"dir"              ) ? ListDir   (@v  ) :
      Is($cmd,"echo"             ) ? EchoStr   (@v  ) :
      Is($cmd,"help"             ) ? Help      ($sub) :
      Is($cmd,"?"     ,          ) ? Help      ("?" ) :
      Is($cmd,"exit" ,"quit"     ) ? Quit      (    ) :
      Is($cmd,"abort" ,"qq"      ) ? Quit      (1   ) :
         print "You Entered: '$str'\n";
      }
   }


sub CmdParts
   {
   my ($str, $v, $sv, $sv2, $ssv, $all) = @_;

#print "\n###pre : $str\n";
#   $str = InterpolateAlias($str);
#print "###post: $str\n";

   @{$all} = my ($cmd, $rest1, $sub, $rest2, $ssub, $rest3) = _StrBreakdown($str);
   @{$v}   = ($rest1);
   @{$sv}  = ($sub, $rest2);
   @{$sv2} = ($sub, $rest2, $ssub, $rest3);
   @{$ssv} = ($sub, $ssub, $rest3);
   return ($cmd, $sub);
   }


#                   cmd    rest1   sub    rest2 ssub  rest3
#                   ------ ----- -------- ----- ----- ------
# help             | help |     |        |     |     |
# show extern      | show | ..  | extern |     |     |
# show extern ctx  | show | ..  | extern | ..  | ctx |
# set  name        |  set | ..  | name   |     |     |
# set  name=       |  set | ..  | name   | ..  | =   |
# set  name=val    |  set | ..  | name   | ..  | =   | val
# extern add zzzz  |extern| ..  | add    | zzz | ..  | ...
#
sub _StrBreakdown
   {
   my ($str) = @_;

   #my ($cmd,$rest1,$sub,$rest2,$ssub,$rest3) = ("","","","","","");

   my ($cmd, $rest1) = $str =~ /^(\w+|\?)\s*(.*)$/;
   $rest1 = "" unless defined $rest1;
   return ("","","","","","") unless $cmd;

   my ($sub, $rest2) = $rest1 =~ /^(\w+)\s*(.*)$/;
   $rest2 = "" unless defined $rest2;
   return ($cmd,$rest1,"","","","") unless $sub;

   my ($ssub, $rest3) = $rest2 =~ /^(\w+|\=)\s*(.*)$/;
   $rest3 = "" unless defined $rest3;
   return ($cmd,$rest1,$sub,$rest2,"","") unless defined $ssub;

   return ($cmd,$rest1,$sub,$rest2,$ssub,$rest3);
   }


# context
# context help
# context show
# context list
# context listall
# context clear
# context wordregex
# context wordregex <regex>
# context (newctx)
#
sub SetContext
   {
   my ($sub,$rest) = @_;

   return !$sub                ? _ShowContext ()                                :
           $sub eq "show"      ? _ShowContext ()                                :
           $sub eq "list"      ? _ShowContexts()                                :
           $sub eq "listall"   ? _ShowContexts("_all_")                         :
           $sub eq "clear"     ? Ret(SIContext({clear=>1}), "Context cleared"  ):
           $sub eq "wordregex" ? _SetWordRegex($rest)                           :
           $sub eq "help"      ? Help("context")                                :
                                 Ret(SIContext($sub), "context changed to $sub");
   }


sub _SetWordRegex
   {
   my ($newregex) = @_;

   $newregex     = Trim($newregex||"");
   my $currregex = SIWordRegex();
   return print "Word Regex: $currregex\n" if !$newregex;

   my $qrnewregex = eval{qr/$newregex/};
   return print "Bad Regex: $newregex\n" if ($@);

   SIWordRegex($qrnewregex);
   return print "Word Regex changed from $currregex to $qrnewregex\n";
   }


# clear help ...... show clear help
# clear context ... clear hist/externs/tags for current context
# clear history ... clear history for current context
# clear extern .... clear externals for current context
# clear tags ...... clear tags for current context
# clear options ... clear options for current context
#
sub ClearStuff
   {
   my ($sub) = @_;

   return $sub eq "context" ? Ret(SIContext({clear=>1})            , "Context cleared"  ) :
          $sub eq "history" ? Ret(SIHistory([])                    , "history cleared"  ) :
          $sub eq "extern"  ? Ret(SIExternal([])                   , "externals cleared") :
          $sub eq "tags"    ? Ret(SIClearMacros(undef,tags_only=>1), "tags cleared"     ) :
          $sub eq "options" ? _ClearOptions()                                             :
          $sub eq "help"    ? Help("clear")                                               :
                              Ret(0, "unknown cmd 'clear $sub'\n");
   }



# set          - show all options
# set name     - show option value
# set name=    - clear option
# set name=val - set option
# set clear    - clear all options
#
sub SetOption
   {
   my ($opt, $set, $val) = @_;
      $set  = $set && ($set eq "="    );
   my $aclr = $opt && ($opt eq "clear");
   my $oclr = $set && !(defined($val) || length($val));

   return !$opt  ? _ShowOptions ()            :
           $aclr ? _ClearOptions()            :
          !$set  ? _ShowOption  ($opt)        :
           $oclr ? _ClearOption ($opt)        :
           $set  ? _SetOption   ($opt,$val)   :
                   Ret(0, "unknown set cmd\n");
   }


sub _ClearOption
   {
   my($opt) = @_;

   SIOption("_delete_" . $opt);
   print "option '$opt' deleted\n";
   }


sub _ClearOptions
   {
   my ($context) = @_;

   SIContext({push=>1},$context) if $context;

   my @optnames = _GetOptionList();
   map{_ClearOption($_)}@optnames;

   SIContext({pop=>1}) if $context;
   }


sub _SetOption
   {
   my($opt, $val) = @_;

   my $exists = SIOption("_exists_" . $opt);
   my $oldval = $exists ? _ostring(SIOption($opt)) : "";

   $val = Trim($val || "");
   SIOption($opt=>$val);
   return print "option '$opt' set to '$val'\n" if !$exists;
   return print "option '$opt' changed from '$oldval' to '$val'\n";
   }


sub _GetOptionList
   {
   my ($includeinternals) = @_;

   my @varnames = SIContext({varlist=>1});
   return @varnames if $includeinternals;

   my @optionnames = map{Gnu::StringInput::_InternalVar($_) ? () : ($_)} @varnames;
   return @optionnames;
   }


# tset          - show all temp options
# tset name     - show temp option value
# tset name=    - clear temp option
# tset name=val - set temp option
# tset clear    - clear all temp options
#
sub SetTOption
   {
   my ($opt, $set, $val) = @_;

      $set  = $set && ($set eq "=");
   my $aclr = $opt && ($opt eq "clear");
   my $oclr = $set && !(defined($val) || length($val));

   return !$opt  ? _ShowTOptions ()          :
           $aclr ? _ClearTOptions()          :
          !$set  ? _ShowTOptions ($opt)      :
           $oclr ? _ClearTOption ($opt)      :
           $set  ? _SetTOption   ($opt,$val) :
                   Ret(0, "unknown set cmd\n");
   }


sub _ClearTOption
   {
   my($opt) = @_;

   TmpOptions("delete", $opt);
   print "temp option '$opt' deleted\n";
   }


sub _ClearTOptions
   {
   TmpOptions("clear");
   print "temp options cleared\n";
   }

sub _SetTOption
   {
   my($opt, $val) = @_;

   $val = Trim($val || "");

   my ($oldval, $exists) = TmpOptions("getopts", $opt);
   TmpOptions("setopt", $opt, $val);
   return print "temp option '$opt' set to '$val'\n" if !$exists;
   return print "temp option '$opt' changed from '$oldval' to '$val'\n";
   }


# extern help  ................
# extern add val  .............
# extern addc val...  .........
# extern show  ................
# extern showb  ...............
# extern load file  ...........
# extern loadc file  ..........
# extern addf file  ...........
# extern addfc  file  .........
# extern clear  ...............
# extern setref ctx  ..........
# extern settype (a|c)data  ...
# extern setf cwd  ............
#
sub SetExtern
   {
   my ($sub, $val, $ssub, $sval) = @_;

   return $sub eq "help"   ? Help("extern")                                                                     :
          $sub eq "add"    ? Ret(SIExternal(data=>$val,add=>1), "external added"   )                            :
          $sub eq "adda"   ? Ret(SIExternal(data=>$val,add=>1,type=>"adata"), "adata added '$val'")             :
          $sub eq "addc"   ? Ret(SIExternal(data=>$val,add=>1,type=>"cdata",ctxdata=>1), "cdata  added '$val'") :
          #$sub eq "addz"   ? Ret(SIExternal(data=>$val,add=>1,type=>"cdata",ctxdata=>1,top=>"help welcome stuff"), "cdata  added '$val'") :
          $sub eq "show"   ? _ShowExternal ($val)                                                               :
          $sub eq "showb"  ? _ShowExternal ("",$val)                                                            :
          $sub eq "load"   ? _LoadExternal ($val                       )                                        :
          $sub eq "loada"  ? _LoadExternal ($val, type=>"adata"        )                                        :
          $sub eq "loadc"  ? _LoadExternal ($val, type=>"cdata"        )                                        :
          $sub eq "addf"   ? _LoadExternal ($val,                add=>1)                                        :
          $sub eq "addfa"  ? _LoadExternal ($val, type=>"adata", add=>1)                                        :
          $sub eq "addfc"  ? _LoadExternal ($val, type=>"cdata", add=>1)                                        :
          #$sub eq "addfz"  ? _LoadExternal ($val, type=>"cdata", add=>1, top=>"aaa bbb new zzz")                                        :
          $sub eq "clear"  ? Ret(SIExternal(clear=>1)         , "externals cleared")                            :
          $sub eq "setref" ? Ret(SIExternal(setref=>$val), "ctx reference changed to '$val'")                   :
          $sub eq "settype"? Ret(SIExternal(settype=>$val), "ctx type changed to '$val'")                       :
          $sub eq "setf"   ? Ret(SIExternal(settype=>"fdata", cwd=>$val), "file ctx changed to '$val'")         :
                             Help("extern")                                                                     ;
   }


##############################################################################
#
# history help
# history show
# history import file
# history export file
# history add    file
# history find   text
# history getref
# history setref context
# history clear
#
# history minsavelen   n
# history maxsaves     n
# history nohistmod    n
#
#
sub SetHistory
   {
   my ($sub, $val, $ssub, $sval) = @_;

   return $sub eq "help"       ? Help        ("history"  ) :
          $sub eq "show"       ? _ShowHistory($ssub      ) :
          $sub eq "import"     ? _ImportHist ($val       ) :
          $sub eq "export"     ? _ExportHist ($val       ) :
          $sub eq "add"        ? _AddHist    ($val       ) :
          $sub eq "find"       ? _FindHist   ($ssub      ) :
          $sub eq "getref"     ? _GetHistRef (           ) :
          $sub eq "setref"     ? _SetHistRef ($val       ) :
          $sub eq "clear"      ? _ClearHist  (           ) :
          $sub eq "minsavelen" ? _HistOpt    ($val, $sval) :
          $sub eq "maxsaves"   ? _HistOpt    ($val, $sval) :
          $sub eq "nohistmod"  ? _HistOpt    ($val, $sval) :
                                 Help        ("history")   ;
   }


#sub _ShowHistory
#   {
#   my ($ctx) = @_;
#   }

sub _ImportHist
   {
   my ($spec) = @_;

#debug
print "### debug : _ImportHist [$spec]  ###\n";
#debug

   SIHistory(import=>Trim($spec));
   }

sub _ExportHist
   {
   my ($spec) = @_;

#debug
print "### debug : _ExportHist [$spec]  ###\n";
#debug

   SIHistory(export=>Trim($spec));
   }

sub _AddHist
   {
   my ($spec) = @_;

#debug
print "### debug : _AddHist    [$spec]         ###\n";
#debug

   SIHistory(import=>Trim($spec),add=>1);
   }

sub _FindHist
   {
   my ($val) = @_;

#debug
print "### debug : _FindHist   [$val]          ###\n";
#debug

   }

sub _GetHistRef
   {
#debug
print "### debug : _GetHistRef             ###\n";
#debug
   my $refctx = SIHistory(getref=>1);
   print "ref context: $refctx\n";
   }


sub _SetHistRef
   {
   my ($refctx) = @_;
#debug
print "### debug : _SetHistRef    [$refctx]         ###\n";
#debug

   SIHistory(setref=>$refctx);
   print "ref context set to: $refctx\n";
   }

sub _ClearHist
   {

#debug
print "### debug : _ClearHist             ###\n";
#debug

   SIHistory(clear=>1);
   print "history cleared\n";
   }


sub _HistOpt
   {
   my ($name, $val) = @_;

#debug
print "### debug : _HistOpt  [$name, $val]           ###\n";
#debug

   SIHistory($name=>$val);

   print "history: $name set to $val\n";
   }


##############################################################################
#
# show info
#
#
# show  ...............
# show help  ..........
# show contexts  ......
# show context  .......
# show history  .......
# show extern  ........
# show macros  ........
# show tags  ..........
# show clip  ..........
# show options  .......
# show toptions  ......
# show goptions  ......
# show keymacros  .....
# show stream  ........
# show optlist  .......
# show key  ...........
# show debug  .........
# show debug2  ........
#
sub ShowStuff
   {
#   my ($sub, $ctx) = @_;
   my ($sub, $r2, $ctx, $r3) = @_;

#dedug
#print "\nDEBUG *** sub=$sub, r2=$r2, ctx=$ctx, r3=$r3 ***\n";
#dedug

   return
          $sub eq ""          ? Help("show")         :
          $sub eq "help"      ? Help("show")         :
          $sub eq "contexts"  ? _ShowContexts ($ctx) :
          $sub eq "context"   ? _ShowContext  ($ctx) :
          $sub eq "history"   ? _ShowHistory  ($ctx) :
          $sub eq "extern"    ? _ShowExternal ($ctx) :
          $sub eq "macros"    ? _ShowTags     ($ctx) :
          $sub eq "tags"      ? _ShowTags     ($ctx) :
          $sub eq "clip"      ? _ShowClip     ($ctx) :
          $sub eq "options"   ? _ShowOptions  ($r2 ) :
          $sub eq "toptions"  ? _ShowTOptions ()     :
          $sub eq "goptions"  ? _ShowGOptions ()     :
          $sub eq "keymacros" ? _ShowKeyMacros()     :
          $sub eq "stream"    ? _ShowStream   ($ctx) :
          $sub eq "optlist"   ? Help ("optlist")     :
          $sub eq "key"       ? _ShowKey      ($ctx) :
          $sub eq "debug"     ? _ShowDebug    ($ctx) :
          $sub eq "debug2"    ? _ShowDebug2   ($ctx) :
                              print "unknown cmd show $sub $ctx\n";
   }


sub _ShowSomething
   {
   my ($type, $datafn, $printfn, $context) = @_;

   my ($all, $extra, @ctxlist) = _CtxListFromParam($context);
   SIContext({push=>1});

   foreach my $ctx (@ctxlist)
      {
      SIContext($ctx);
      my $data = &{$datafn}($all, $extra);
      next unless $data;
      print "\n" . LineString("$type in context '$ctx'");
      &{$printfn}($data);
      }
   print LineString("");
   SIContext({pop=>1});
   }


sub _CtxListFromParam
   {
   my ($param) = @_;

   my $ctx = SIContext();
   $param = Trim($param || "") || $ctx;

   # test test+
   # all  all+
   #
   my ($ctxp, $exp) = $param =~/^(\w*||\*)(\+?)$/;
   $exp = $exp ? 1 : 0;

print "\n ########: [$param] [$ctxp] [$exp] ########\n";


   return $ctxp =~ /^(all)|(\*)$/ ? (1,$exp, SIContext({ctxlist=>1, all=>$exp})) :
                                    (0,$exp, $ctxp);
#
#          $ctxp =~ /^_all_$/      ? (1,1, SIContext({ctxlist=>1, all=>1})) :
#                                         (,$ctx_param)                     ;
   }


sub _ShowContexts # todo
   {
   my ($opt) = @_;

   my ($all, $extra, @ctxlist) = _CtxListFromParam($opt || "all");
   #my @ctxlist = _CtxListFromParam($opt || "all");
   my $currctx = SIContext();

   print "\n" . LineString("Context List");
   SIContext({push=>1});
   print " context         etype   externs   history   tags\n";
   print "-------------------------------------------------\n";

   foreach my $ctx (@ctxlist)
      {
      SIContext($ctx);

      my $type     = SIExternal(gettype=>1);
      my $extern   = SIExternal(getview=>1,prep=>0);
      my @exlines  = split(/^/, $extern);
      my $externct = scalar @exlines;
      my $tags     = SITagList();
      my @taglines = split(/^/, $tags);
      my $tagct    = scalar(@taglines);
      my $histct   = SIGetHistorySize();

      print sprintf(" %-15s %5s  %6d  %9d  %4d\n", $ctx, $type, $externct, $histct, $tagct);
      }
   SIContext({pop=>1});

   print LineString("");
   }


sub _ShowContext
   {
   my ($context) = @_;

   my $printfn = sub(){};
   return _ShowSomething("Context", \&_ContextInfo, $printfn, $context);
   }


sub _ContextInfo
   {
   _ShowHistory ();
   _ShowExternal();
   _ShowOptions ();
   _ShowTags    ();
   return "";
   }


sub _ShowHistory
   {
   my ($context) = @_;

   my $printfn = sub(){print join("\n", @{$_[0]}), "\n"};
   return _ShowSomething("History", \&SIHistory, $printfn, $context);
   }


sub _ShowExternal
   {
   my ($context,$toppath) = @_;

   $toppath ||= "";
   my $format = 1;
   if ($context && $context =~/^\d$/)
      {
      ($format, $context) = ($context, "");
      }
   $format ||= 1;

   my $datafn  = sub(){1};
   my $printfn = sub()
      {
      print "extern ($format): ", SIExternal(gettype=>1), "\n";
      print SIExternal(getview=>1,prep=>0,format=>$format, top=>$toppath), "\n";
      };
   return _ShowSomething("External", $datafn, $printfn, $context);
   }


sub _ShowTags
   {
   my ($context) = @_;

   my $printfn = sub(){print "$_[0]\n"};
   my $datafn  = sub(){SITagList(undef, undef, 1)};
   return _ShowSomething("Tags", $datafn, $printfn, $context);
   }


sub _ShowClip
   {
   my ($context) = @_;

   my $printfn = sub(){print "$_[0]\n"};
   return _ShowSomething("Clipboard", \&SIClipboard, $printfn, $context);
   }


sub _ShowOptions
   {
   my ($context) = @_;

   my $printfn = sub()          {print join("\n", @{$_[0]}), "\n"               };
   my $datafn  = sub(){my($lst,$extr)=@_; [map{_ShowOption($_,1)}(_GetOptionList($extr))]};
   return _ShowSomething("Options", $datafn, $printfn, $context);
   }


sub _ShowOption
   {
   my($opt, $return_only) = @_;

   my $val = SIOption("_exists_" . $opt) ? _ostring(SIOption($opt)) : "<nope>";


   my $optname = sprintf("%-10s", $opt);
   my $str     = " $optname = $val\n";

#
#
#   my $str = sprintf("  %-10s = $val\n", $opt);
##   my $str = " $opt = $val\n";
##
###debug
##print sprintf("debug: [%-10s] = $val", $opt);
##print "$opt=$val\n";
##
##

   print $str unless $return_only;
   return $str;
   }


sub _ShowTOptions
   {
   print "temp options: ", TmpOptions("asstring"), "\n";
   }


sub _ShowGOptions
   {
   return _ShowOptions("global");
   }


sub _ShowKeyMacros
   {
   my $data = KeyMacroList(indent=>2);
   print LineString("keyboard macros");
   print $data;
   print "\n";
   }


sub _ShowStream
   {
   my ($context) = @_;

   print "\n" . LineString("state stream");
#  print "Stream:\n", SIStateStream(), KeyMacrosStream(), "\n";

   my $stream = SIStateStream();
   foreach my $line (split /^/, $stream)
      {
      next if $context && !($line =~ /$context/);
      print $line;
      }

   }


sub _ShowKey
   {
   DumpKey(GetKey(ignore_ctl_keys=>1));
   }


sub _ShowDebug
   {
   my ($context) = @_;

   print LineString("debug stuff");
   _ShowOptions  ($context);
   _ShowContexts ($context);
   _ShowHistory  ($context);
   _ShowExternal ($context);
   _ShowTags     ($context);
   _ShowKeyMacros($context);
   _ShowClip     ($context);
   print LineString();

#   print LineString("node info");
#   Gnu::StringInput::NodeInfo(SICExternal());
#   print LineString("node info");
#   print Gnu::StringInput::_serializenodes(SICExternal(), "   ");
#   print LineString("node info");
#   print Gnu::StringInput::_serializenodes(SICExternal());
#   print LineString("ShowCExtern type 0");
#    Gnu::StringInput::ShowCExtern(SICExternal(),0);
#   print LineString("ShowCExtern type 1");
#    Gnu::StringInput::ShowCExtern(SICExternal(),1);
#   print LineString("ShowCExtern type 2");
#    Gnu::StringInput::ShowCExtern(SICExternal(),2);
   }


sub _ShowDebug2
   {
   my ($context) = @_;

   print LineString("extern root");
   my $top = SIExternal(getroot=>1);
   print DumpRef($top, "", 3) , "\n\n";

   print LineString("extern root noref");
   $top = SIExternal(getroot=>1,noref=>1);
   print DumpRef($top, "", 3) , "\n\n";

   print LineString("extern");
   $top = SIExternal();
   print DumpRef($top, "", 3) , "\n\n";

   print LineString("extern noref");
   $top = SIExternal(noref=>1);
   print DumpRef($top, "", 3) , "\n\n";

   my $a = SIExternal(getref=>1,noref=>1);
   my $b = SIExternal(getref=>1)         ;

   print LineString(SIExternal(getref=>1,noref=>1));
   print LineString(SIExternal(getref=>1)         );
   }



sub SaveState
   {
   my ($spec) = @_;

   $spec = Trim($spec || $STATE_FILE);

   open (my $filehandle, ">", $spec) or return print "Cant write to '$spec'\n";
   print $filehandle SIStateStream();
   print $filehandle KeyMacrosStream();
   close $filehandle;
   print "Saved State to '$spec'\n";
   }


sub LoadState
   {
   my ($spec) = @_;
   
   $spec = Trim($spec || $STATE_FILE);
   
   return SetupSamples() if $spec =~ /^samples$/;

   return print "Cant read '$spec'\n" unless -f $spec;
   my $contents = SlurpFile($spec);

   SIStateStream  ($contents);
   KeyMacrosStream($contents);
   print "Loaded State from '$spec'\n";
   }


sub _LoadExternal
   {
   my ($spec, %opt) = @_;


   my $ctx = SIContext();
   $spec   = Trim($spec);
   return print "External file '$spec' not found\n" unless -f $spec;

   my $data = SlurpFile($spec);

   SIExternal(data=>$data, %opt);
   Ret(0, "Loaded Externals from '$spec' to context $ctx", 1);
   }


sub ListFile
   {
   my ($spec) = @_;

   $spec = Trim($spec || $STATE_FILE);

   return print "Cant read '$spec'\n" unless -f $spec;
   my $data = SlurpFile($spec);
   print "\n" . LineString("$spec");
   print $data,"\n";
   print LineString();
   }


sub ListDir
   {
   my ($dir) = @_;

   $dir = Trim($dir || ".\\");
   print "\n" . LineString("dir listing of '$dir'");
   opendir(my $dh, $dir) or return print "Cant open dir '$dir'\n";
   my @all = readdir($dh);
   closedir($dh);

   foreach my $file (@all)
      {
      my $spec = "$dir\\$file";
      next unless -d $spec;
      next if $file =~ /^\./;
      print " [$file]\n";
      }
   foreach my $file (@all)
      {
      my $spec = "$dir\\$file";
      next unless -f $spec;
      print " $file\n";
      }
   print LineString();
   }


# alias          - show all option
# alias name     - show option value
# alias name=    - clear option
# alias name=val - set option
# alias clear    - clear all option
#
sub zSetAlias
   {
   my ($name, $set, $val) = @_;

#debug
#print ("#debug  in SetAlias: $name, $set, $val\n");

      $set  = $set  && ($set eq "="    );
   my $aclr = $name && ($name eq "clear");
   my $oclr = $set  && !(defined($val) || length($val));

   return !$name ? _zShowAliases ()            :
           $aclr ? _zClearAliases()            :
          !$set  ? _zShowAlias  ($name)        :
           $oclr ? _zClearAlias ($name)        :
           $set  ? _zSetAlias   ($name,$val)   :
                   Ret(0, "unknown alias cmd\n");
   }
#   return _ListAliases()     unless $name;
#   return _ClearAliases()    if $name =~ /^clear$/;
#   return _ShowAlias($name)  if !$val;
#   return _ClearAlias($name) if $val  =~ /^clear$/;
#   return _SetAlias($name,$value);
#   }

sub _zAliases
   {
   my ($new_aliases) = @_;

   state $aliases = {};

   $aliases = $new_aliases if $new_aliases;
   return $aliases;
   }

sub _zAlias
   {
   my ($name, $val) = @_;

   my $aliases = _zAliases();
   return $aliases->{$name} unless $val;
   return delete $aliases->{$name} if $val  =~ /^clear$/;
   return $aliases->{$name} = $val;
   }


sub _zShowAliases
   {
   my $aliases = _zAliases();
   my $colsize = max(map{length $_} (keys %{$aliases})) || 0;
   print "Aliases:\n";
   foreach my $name (sort keys %{$aliases})
      {
      print sprintf(" %-*s=%s\n", $colsize, $name, $aliases->{$name});
      }
   print "\n";
   }

sub _zClearAliases
   {
   print "Aliases cleared\n";
   return _zAliases({});
   }

sub _zShowAlias
   {
   my ($name) = @_;

   my $val = _zAlias($name) || "";
   print "$val\n";
   }

sub _zClearAlias
   {
   my ($name) = @_;

   _zAlias($name,"clear");
   }


sub _zSetAlias
   {
   my ($name, $val) = @_;
   _zAlias($name, $val);
   }


sub zIsAlias
   {
   my ($name) = @_;
   return defined _zAlias($name);
   }

sub zInterpolateAlias
   {
   my ($str) = @_;

   return $str unless $str;

   my @parts = (split(/\s/, $str), "", "", "", "", "", "", "", "", "");
   my $data = _zAlias($parts[0]);
   return $str unless defined $data;

   # replace %1 - %n
   $data =~ s{\%(\d)}{$parts[$1] ? $parts[$1] : "\%$1"}gei;

   # replace %$
   if ($data =~ /\%\$/)
      {
      my ($tail) = $str =~ /^\s*\w+\s*(.*?)$/;
      $tail ||= "";
      $data =~ s{\%\$}{$tail}gei;
      }

   return zInterpolateAlias($data);
   }


sub EchoStr
   {
   my ($str) = @_;

   print "$str\n";
   }

#sub _LoadExternal
#   {
#   my ($spec) = @_;
#
#   my $ctx = SIContext();
#   $spec = Trim($spec);
#   return print "External file '$spec' not found\n" unless -f $spec;
#
#$DB::single=1;
#
#   my $data = SlurpFile($spec);
#   #my @externals = ();
#   #foreach my $line (split /^/, $data)
#   #   {
#   #   push(@externals, $line) unless line eq "" || substr($line, 0, 1) eq '#';
#   #   }
#
##   my @externals = map{$_ =~ /^(#.*$)|(\s*$)/ ? () : ($_)} split(/^/, $data);
#   my @externals;
#   foreach my $line(split(/\n/, $data))
#      {
#      $line = CleanInputLine($line,1,0);
#      push @externals, $line unless $line eq "";
#      }
#
#   my $count = scalar @externals;
#   SIExternal([@externals]);
#   SIOption(excontext=>0);
#   SIOption(exfiles=>0);
#   print "Loaded $count Externals from '$spec' to context $ctx\n";
#   }
#
#sub _LoadCExternal
#   {
#   my ($spec) = @_;
#
#   my $ctx = SIContext();
#   $spec = Trim($spec);
#   return print "CExternal file '$spec' not found\n" unless -f $spec;
#
#   my $data = SlurpFile($spec);
#
##$DB::single=1;
#
#   SIExternal($data,"   ");
#   SIOption(excontext=>1);
#   SIOption(exfiles=>0);
#   print "Loaded CExternals from '$spec' to context $ctx\n";
#   }
#
#
######################################################################


sub Setup
   {
   Help("cmdline", 1) if ArgIs("help");

   Help("welcome" ) unless ArgIs("quiet");
   Help("commands") unless ArgIs("quiet");

   # load state
   $STATE_FILE = ArgGet() if ArgIs();
   my $do_load  = !ArgIs("noload") && !ArgIs("reset") && (-f $STATE_FILE);
   $do_load ? LoadState() : Reset();

   # global extern macros
   SIExternCallback("ctxlist", \&CtxListCallback, global=>1);
   SIExternCallback("optlist", \&OptListCallback, global=>1);
   SIExternCallback("test1"  , [qw(xword yword zword cword2 cword3 cword4)], global=>1);

   SetupSamples() if ArgIs("samples");

   # commands loaded to default context
   SIContext({push=>1},$DEFAULT_CONTEXT);
   SIExternal(data=>Template("cmds_external"), indent=>"   ");
   SIContext({pop=>1});
   print "commands loaded to context '$DEFAULT_CONTEXT'\n";

   my $default_ctx = ArgIs("context") ? ArgGet("context") : $DEFAULT_CONTEXT;
   SIContext($default_ctx);

   _LoadExternal(ArgGet("extern")) if ArgIs("extern");
   SISetMacro(code=>"72SC", fn=>\&KeyShowChain); # <shift>-<ctrl>-h

   print "initial context set to $default_ctx\n\n";
   }

#sub CtxListCallback
#   {
#   my ($search_str, $prev_str, $cpos, $cname) = @_;
#
#   my $ctxlist = [SIContext({ctxlist=>1})];
#   my ($match, $newpos) = Gnu::StringInput::_FindInList($ctxlist, $search_str, 1, $cpos);
#
#   return (!!$match, $match, $newpos);
#   }
sub CtxListCallback
   {
   return [SIContext({ctxlist=>1})];
   }

sub OptListCallback
   {
   return [qw (prompt    preset    context    allowdups
               nohistmod escape    wordregex
               nocr      noisy     trim       trimstart
               trimend   exfiles   exfileroot excontext)] ;
   }


sub KeyShowChain
   {
   my ($info, $str, $str_idx) = @_;

   my $ctx   = SIContext();
   my $etype = SIExternal(gettype=>1);
   my $chain = Gnu::StringInput::Ex_MakeChain($str);

   my ($pre, $word, $post) = Gnu::StringInput::_ExStringParts2 ($str, $str_idx, $chain);

   Gnu::StringInput::_aside(@_);
   print "\n" . LineString("word chain info in context $ctx");

   print "String      : [$str]  \n";
   print "Cursor Index: $str_idx\n";
   print "Current Word: [$word] \n";
   print "Pre String  : [$pre]  \n";
   print "Post String : [$post] \n";
   print "Word Regx   : **todo**\n";
   print "Chain       :         \n";
   map {print "   [word=>$_->{word}, start=>$_->{start}, len=>$_->{len}, end=>$_->{end}]\n"} (@{$chain});

   if ($etype eq "cdata")
      {
      Gnu::StringInput::Ex_ChainEnd(undef, $chain);
      print "\nChain with Nodes:\n";
      foreach my $entry  (@{$chain})
         {
         print "   [word=>$entry->{word}, start=>$entry->{start}, len=>$entry->{len}, end=>$entry->{end}]";
         print "      node:";
         my $node = $entry->{node};
         print "node:$node->{str}, level:$node->{level}, type:$node->{nodetype}\n" if $node;
         print "(none)\n" unless $node;
         }
      }
   print LineString(""), "\n";

#   my ($pre, $cword, $post, $cpos, $clen) = Gnu::StringInput::CurrentWordC($str, $str_idx, -1, -1);
#   my $chain  = Gnu::StringInput::Ex_MakeWordChain($pre) || [];
#   my $cstr   = join(", ", map{"'$_'"} @{$chain});
#   my $parent = Gnu::StringInput::Ex_FindParentNode(SIExternal(), @{$chain});
#   my $pparent = $parent ? $parent->{parent} : 0;
#
#   my ($node,$npos) = Gnu::StringInput::Ex_FindExternalCNode($cword, pre_str=>$pre, direction=>1, start=>0);
#
#   print "str    = '$str'                \n";
#   print "str_idx= '$str_idx'            \n";
#   print "pre    = '$pre'                \n";
#   print "cword  = '$cword'              \n";
#   print "post   = '$post'               \n";
#   print "cpos   = '$cpos', clen='$clen' \n";
#   print "chain  = $cstr                 \n";
#
###$DB::single=1;
#   print LineString("parent-parent node info") if $pparent;
#   print Gnu::StringInput::Ex_NodeInfo($pparent)     if $pparent;
#
#   print LineString("parent node info")    if $parent;
#   print Gnu::StringInput::Ex_NodeInfo($parent)  if $parent;
#
###   print LineString("parent node info") if $parent;
###   print Gnu::StringInput::_serializenodes($parent, "   ",1);
###   print LineString("parent node info") if $parent;
###   print Gnu::StringInput::_serializenodes($parent,undef,1);
##
#   print LineString("node info")               if $node;
#   print Gnu::StringInput::Ex_NodeInfo($node)        if $node;
#
   return Gnu::StringInput::_aside();
   }

sub Reset
   {
   SetupSamples();
   }

sub SetupSamples
   {
   SIContext({push=>1});

   # setup global context - provides default values for other all context
   SIContext("global");
   SISetMacro(code=>"112sc", tag=>"Hello There!");
   SISetMacro(code=>"113sc", tag=>"First|Second|Third");
   SIOption(prompt=>"Enter String");
   print "Fn key macros added to global context.\n";

   # setup default context, leave it pretty empty
   SIContext("sample1");
   SISetMacro(code=>"112sc", tag=>"This is from the sample1 context");
   SIExternal([qw(context set tset show extern save load help exit
                  optlist contexts history tags clip options toptions
                  stream key debug optlist add clear prompt preset
                  presetlast context external allowdups nohistmod
                  wordregex escape nocr noisy trim trimstart
                  trimend exfiles exfileroot)]);
   SIOption(skip_stream=>1);
   print "F1 key macros and simple externals added to context sample1 .\n";
   
   # setup test context, add externals and tags for entering i_str command
   SIContext("sample2");
   my $kv = 112;
   map{SISetMacro(code=>"".$kv++."sc", tag=>"show $_", replace=>1)}
      qw(history extern tags contexts stream options toptions optlist);
   SIExternal(data=>Template("cmds_external"), indent=>"   ");
   SIOption(skip_stream=>1);
   print "Fn1-8 key macros and cmd externals added to sample2 .\n";

   # setup test2 context, misc
   SIContext("sample3");
   SISetMacro(code=>"112sc", tag=>"This is from the test2 context");
   SISetMacro(code=>"113sc", tag=>"Nell");
   SISetMacro(code=>"114sc", tag=>"Hackworth");
   SISetMacro(code=>"115sc", tag=>"Takishi");
   SISetMacro(code=>"118sc", tag=>"This Instead!" , replace=>1);
   SISetMacro(code=>"119sc", tag=>"The End."      , finish =>1);
   SIExternal([qw(fred barney wilma joe bill bob cory craig caleb callie cade)]);
   SIOption(skip_stream=>1);
   print "F1-4 F7-8 key macros and simple externals added to context sample3.\n";

   SIContext("sample4");
#  SIOption("exfiles", 1);
   SIExternal(settype=>'fdata',cwd=>"c:\\");
   SISetMacro(code=>"112sc", tag=>"This is from the testf context|foogle");
   SIOption(skip_stream=>1);
   print "F1 key macro and filesystem externals added to context sample4.\n";

   SIContext("sample5");
   SIExternal(data=>Template("cmds_external"), indent=>"   ");
   SIOption(skip_stream=>1);
   print "cmd externals added to context sample5.\n";

   SIContext("sample6");
   SIExternal(data=>Template("sample6_extern"), indent=>"   ");
   SIOption(skip_stream=>1);
   print "context externals added to context sample6.\n";

   SIContext("sample7");
   SIExternal(data=>Template("sample7_extern"));
   SIOption(skip_stream=>1);
   print "simple externals added to context sample7.\n";

   SIContext("sample8");
   SIExternal(data=>Template("cmds_external"), indent=>"   ");
   SIHistory(data=>Template("sample8_history"));
   SIOption(skip_stream=>1);
   print "cmd externals and history set for context sample8.\n";

   SIContext({pop=>1});
   }

##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################
##########################################################################

sub Help
   {
   my ($topic, $do_exit) = @_;

   $topic ||= "help";
   $topic = "commands" if $topic eq "?";

   print Template("help_$topic") || Template("help_unknown");
   Quit(1) if $do_exit;
   }

sub Quit
   {
   my ($nosave) = @_;

   SaveState() unless $nosave || ArgIs("nosave");
   print "\nbye.\n";
   exit(0);
   }


sub Ret
   {
   my ($val, $message, $show_simsg, ) = @_;

   print "$message\n" if $message;

   my ($msg, $code) = SIMsg();
   print "SIMessage: $msg [$code]\n" if $show_simsg;
   return $val;
   }


sub TmpOptions
   {
   my ($cmd, $opt, $val) = @_;

   state $options = {prompt=>"Enter String"};

   $cmd ||= "";
   return          %{$options}      if !$cmd               ;
   return          $options         if $cmd =~ /^all$/     ;
   return _hstring($options)        if $cmd =~ /^asstring$/;
   return exists   $options->{$opt} if $cmd =~ /^exists$/  ;
   return delete   $options->{$opt} if $cmd =~ /^delete$/  ;
   return          $options->{$opt} if $cmd =~ /^getopt$/  ;
   return _hostring($options, $opt) if $cmd =~ /^getopts$/ ;
   return $options->{$opt} = $val   if $cmd =~ /^setopt$/  ;
   return $options = {}             if $cmd =~ /^clear$/   ;
   return $options;
   }

#####################################################################

sub _hostring
   {
   my ($hash, $key) = @_;

   my $exists = exists $hash->{$key};
   my $val = $exists ? _ostring($hash->{$key}) : "";
   return ($val, $exists);
   }


sub _ostring
   {
   my ($val) = @_;

   return "(undef)" if !defined $val;
   return _hstring($val) if ref $val eq "HASH";
   return _astring($val) if ref $val eq "ARRAY";
   return "'$val'";
   }

sub _hstring
   {
   my ($h) = @_;
   return "{" . join(",", map{"$_=>$h->{$_}"}(sort keys %{$h})) . "}";
   }

sub _astring
   {
   my ($a) = @_;
   return "[" . join(",", @{$a}) . "]";
   }


sub Is{OneOfStr(@_)}


__DATA__

[help_welcome]
  This program is an interactive string input program to test and demonstrate
  the Gnu::StringInput module. This is a module that allows the user to input
  strings like a command shell. Things like edit and move keys, command history
  recall, external data matches, saving and loading command history, multiple
  contexts, clipboards, macros and tags.

  Enter 'help' for help topics. enter '?' for help on commands.

[help_commands]
  These are the commands used by this interactive interface to
  manipulate the StringInput module.

    help    help ..... help on help cmd
    help    keys ..... help on using the string input UI
    help    topic .... help ("help help" for more)
    context cmd  ..... get/set context ("help context" for more)
    show    thing .... view things  ("help show" for more info)
    set     opt=val .. view/get/set options ("help set" for more)
    tset    opt=val .. view/get/set temp options ("help tset" for more)
    clear   cmd ...... clear context stuff ("help clear" for more info)
    extern  cmd ...... view/get/set/load externals ("help extern" for more)
    save    spec ..... save state (spec defaults to str2.sav)
    load    spec ..... load state (spec defaults to str2.sav)
    load    samples .. load sample data to sample contexts
    list    spec ..... display a file file
    dir     spec ..... list a directory
    exit ............. quit

[help_help]
  The list of help commands:

    help welcome .... the initial help page
    help commands ... the list of command
    help help ....... this page
    help features ... feature list
    help context .... help using the context command
    help keys ....... help using the string input UI
    help set ........ help using set cmd
    help tset ....... help using tset cmd
    help show ....... help using show cmd
    help extern ..... help using extern cmd
    help clear ...... help using clear cmd
    help optlist .... list all available option
    help cmdline .... help using commandline option

[help_context]
  A context defines a namespace for state information. Input history,
  external data, tags, and options all apply to the current context.

    context ................ show current context
    context show ........... show current context
    context list ........... list all context
    context clear .......... clear hist/externs/tags/options for current context
    context wordregex ...... show the regex for parsing the string into word
    context wordregex /rx/ . set the regex for parsing the string into word
    context (new) .......... change current context to the new context

[help_set]
  The set command is for context options. note that temporary option
  take precidence over these options if defined, and global options are
  used if a temporary or context option is not present.

    set ............ shows all options in context
    set name ....... shows options current value
    set name= ...... clears option
    set name=val ... sets the option
    set clear ...... remove all context option
    help optlist ... get lost of option

[help_tset]
  The tset command is for temporary options. temporary options take
  precidence over the current context options which take precidence over
  the global options.

    tset ............ shows all temp option
    tset name ....... shows temp options current value
    tset name= ...... clears temp option
    tset name=val ... sets temp option
    tset clear ...... remove all temp option
    help optlist ... get lost of option

[help_show]
  The show command shows context state data and other info.
  in the below list (ctx)  means a context name or blank for current
  in the below list (ctx+) means a context name or blank or "all"

    show contexts ........ show the list of context
    show context (ctx+) .. show information about a context
    show history (ctx+) .. show history data of a context
    show extern  (ctx+) .. show extern data of a context
    show tags    (ctx+) .. show tags defined for a context
    show clip    (ctx+) .. show clipboard data for a context
    show options (ctx)  .. show options defined for a context
    show toptions ........ show temporary option
    show goptions ........ show temporary option
    show keymacros ....... show keyboard macros defined
    show stream .......... show state stream
    show optlist ......... show options available
    show key ............. show key data (debug)
    show debug   (ctx+) .. show misc stuff

[help_extern]
  External data ....

    extern show    ..... show external
    extern showb path .. show externals starting with path
    extern add str ......add external
    extern addc str .....add external in context
    extern clear   ......clear external
    extern load  file ...load externals from line delimited file
    extern loadc file ...load ctx externals from line delimited file
    extern addf  file ...add externals from line delimited file
    extern addfc file ...add ctx externals from line delimited file
    extern setref ctx ...todo
    extern setf dir   ...set to exfile
    extern settype dtype

[help_history]
  Histort data ....

    history help ............ get help
    history show ............ show history
    history import file ..... import a hist file
    history export file ..... export a hist file
    history add    file ..... add hist from file
    history find   text ..... find an entry
    history getref .......... get reference ctx
    history setref context .. set reference ctx
    history clear ........... clear hist
    history minsavelen n .... set min str len to save
    history maxsaves   n .... set max size of list
    history nohistmod  n .... dont save as we entrt text

[help_clear]
  Clears data from the current context.  Using a context may still
  involve temporary or global state info.

   clear context ... clear hist/externs/tags/options for current context
   clear history ... clear history for current context
   clear extern .... clear externals for current context
   clear tags ...... clear tags for current context
   clear options ... clear options for current context

[help_list]
   Displays the contents of a file.

   list foo.txt ....... list contents of file
   list c:\test.dat ... list contents of file

[help_dir]
   Displays the contents of a directory.

   dir ................ list contents of dir
   dir savedata ....... list contents of dir
   dir c:\bkup ........ list contents of dir

[help_optlist]

  The list of options.
    prompt     = str    - print a label prompt
    preset     = str    - preset string value
    presetlast = 1      - preset string value to prev input
    context    = name   - context for history and macro
    allowdups  = 1      - allow duplicate entries in history
    nohistmod  = 1      - dont add to history
    escape     = n      - return empty string if user hits escape n time
    nocr       = 1      - dont print a \n when done
    noisy      = 1      - (disruptive to input) message when keyboard macro is started/stopped
    trim       = 1      - return string with begin/end whitespace removed
    trimstart  = 1      - return string with beginning whitespace removed
    trimend    = 1      - return string with ending    whitespace removed
    exfiles    = 1      - use filesystem for external data
    exfileroot = dir    - set root for exfiles, cwd is default
    ignorechars= str    - string if characters to ignore on input
    aliases    = 1        allow alias command

[help_keys]
  default key bindings:
    <up> ............. find prev entered string matching current str
    <down> ........... find next entered string matching current str
    <tab> ............ find next external string matching current str
    <shift>-<tab> .... find prev external string matching current str
    <fnkey> .......... Replace current string with string bound to fn key
    <shift>-<fnkey> .. Bind current string to this fn key
                        If string ends in \\\\n the string the string will
                        be returned immediately after hitting the fn key
                        If string contains | the values will toggle
    <home> ........... Move cursor to beginning of string
    <end> ............ Move cursor to end of string
    <ctrl><right> .... Move cursor right 1 word
    <ctrl><left> ..... Move cursor left 1 word
    <esc> ............ Clear string or reset to initial value or return empty
    <numpad>+ ........ Copy string (word if <ctrl>)
    <numpad>- ........ Cut string (word if <ctrl>)
    <numpad><ins> .... Add clipboard string (replace if <ctrl>)
    <ctrl>k .......... Add string to history and clear
    <shift><ctrl>d ... Debug info
    <shift><ctrl>t ... Show fn key tag
    <shift><ctrl>h ... Show history
    <shift><ctrl>? ... Show special key
    <shift><ctrl>x ... clear history

  keyboard macros:
   <F12> .............. start recording
   <F12> .............. end recording (and bind to to <F11>
   <Ctrl><#> .......... end recording (and bind to to <Ctrl-#>)
   <Shift><F12> ....... end recording (and bind to to _next_ key)
   <F11> .............. playback
   <Ctrl><#> .......... playback
   <Ctrl><Shift><F12> . enable/disable macro

[help_cmdline]
teststr.pl - test string input modulw

Usage: teststr.pl [options] [statefile]

Where:
   [options] is 0 or more of:
      /context=name .... set initial context
      /reset ........... reset state to initial setting
      /nosave .......... dont autosave state file at exit
      /clear ........... clear context state
      /extern=file ..... set external data from file
      /samples ......... setup sample contexts
      /help ............ this help
   [statefile] ......... file to load/save state (default is teststr.sav)

[help_unknown]
   unknown help topic

[cmds_external]
^context
   show
   list
   listall
   clear
   wordregex
   help
   {ctxlist}
^help
   welcome
   commands
   help
   features
   context
   keys
   set
   tset
   show
   extern
   history
   clear
   optlist
   cmdline
^set
   {optlist}
   clear
   help
^tset
   {optlist}
   clear
   help
^show
   contexts
   context
      {ctxlist}
      all
   history
      {ctxlist}
      all
   extern
      {ctxlist}
      all
   tag
      {ctxlist}
      all
   clip
      {ctxlist}
      all
   option
      {ctxlist}
      all
   toptions
   goptions
   keymacro
   stream
   optlist
   key
   debug
      {ctxlist}
      all
   help
^extern
   show
   showb
   add
   addc
   clear
   load
      {exfiles}
   loadc
      {exfiles}
   addf
      {exfiles}
   addfc
      {exfiles}
   setref
      {ctxlist}
   settype
   setf
   help
^history
   help
   show
   import
      {exfiles}
   export
      {exfiles}
   add
      {exfiles}
   find
      {any}
   getref
   setref
      {ctxlist}
   clear
   minsavelen
   maxsaves
   nohistmod
^save
   {exfiles}
^load
   {exfiles}
^clear
   context
   history
   extern
   tags
   options
   help
^alias
^list
   {exfiles}
^dir
   {exfiles}
^exit
zfoo
zbar
   zeppelin1
   zeppelin2
      qwerty1
      qwerty2
      qwerty3
         {exfiles}
   zeppelin3
[sample6_extern]
^word1
   word01
   word02
   word03
^word2
   word04
^word3
^word4
   word06
   word02
   word07
      word008
      word009
         word0001
         word0002
         word0003
         word0004
^word5
   word09
^word6
   word4
   word009
aword1
aword2
   aword21
   aword22
   aword23
   aword24
      aword241
      aword242
      aword243
   aword25
aword4
aword5
[sample7_extern]
this
is
a
test
[sample8_history]
dir
show extern
show history
[fini]
