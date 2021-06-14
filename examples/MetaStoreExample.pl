#!perl    
#
# MetaStore example
# Craig Fitzgerald

use Gnu::StringInput qw(:ALL);
use Gnu::Template;
use Gnu::MetaStore;


MAIN:
   Init();
   Run();
   Finalize();
   exit(0);

sub Init
   {
   $|=1;

   MSInit(store_name=>"MetaStoreExample.dat");
   my $data = MSGetData("strData");
   SIStateStream($data);
   }

sub Finalize
   {
   my $data = SIStateStream($data);
   MSSaveData("strData", $data);
   }

sub Run
   {
   while (1)
      {
      print Template("message");
      print Template("menu");

      $line = SIGetString(prompt=>"Enter sample #");

      $line eq "0" ? return       :
      $line eq "1" ? TestInput1() :
      $line eq "2" ? TestInput2() :
      $line eq "3" ? TestInput3() :
      $line eq "4" ? TestInput4() :
      $line eq "k" ? print Template("keys") : "";
      }
   }

sub TestInput1
   {
   my $line = "";

   print "This is a simple test of SIGetString()\n";
   print Template("toexit");

   SIContext("test1");
   while ($line !~ /^exit$/i)
      {
      $line = SIGetString(prompt=>"Enter string");
      print "You entered: $line\n";
      }
   }


sub TestInput2
   {
   my $line = "";

   print "This example uses the <tab> key to match local files\n";
   print Template("toexit");

   SIContext("test2");
   SIExternal(settype=>"fdata");
   while ($line !~ /^exit$/i)
      {
      $line = SIGetString(prompt=>"Enter string");
      print "You entered: $line\n";
      }
   }


sub TestInput3
   {
   my $line = "";

   print "This example uses the <tab> key to cycle through specific strings\n";
   SIContext("test3");
   SIExternal(["this","is","an","array"]);
   while ($line !~ /^exit$/i)
      {
      $line = SIGetString(prompt=>"Enter string");
      print "You entered: $line\n";
      }
   }


sub TestInput4
   {
   my $line = "";

   print "This example uses the <tab> key to add context sensitive data\n";
   SIContext("test4");
   SIExternal(data=>Template("cmds_external"), indent=>"   ");
   while ($line !~ /^exit$/i)
      {
      $line = SIGetString(prompt=>"Enter string");
      print "You entered: $line\n";
      }
   }


__DATA__
[message]
This sample uses Gnu::StringInput and Gnu::MetaStore
Gnu::StringInput is used to get user input, set macros, etc..
Gnu::MetaStore is used to save history, macros, etc..

[keys]
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

[menu]
1 - Minimal example
2 - Example that uses tab to cycle through local files
3 - Example that uses tab to cycle through internal strings
4 - Example that uses tab to cycle through context sensitive strings 
k - Help on edit keys
0 - exit

[toexit]
enter 'exit' to exit this test.

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
[fini]
