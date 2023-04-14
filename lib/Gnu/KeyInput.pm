#
# KeyInput.pm - console keyboard interface
#  C Fitzgerald 8/1/2013
#
# Synopsis:
#  my $key = GetKey(ignore_ctl_keys=>1);
#  print "\nYou gave me:\n"
#  print "  char         : '$key->{char}' \n"; # 'a'
#  print "  ascii code   : $key->{ascii}  \n"; # 97
#  print "  keyboard code: $key->{vkey}   \n"; # 65
#  print "  shift state  : $key->{isshft} \n"; # 0
#  print "  ctrl state   : $key->{isctrl} \n"; # 0
#  print "  key code     : '$key->{code}' \n"; # '65sc'
# 
#  note that 'code' is a simple keyboard encoding of a key combination,
#     w                 would be  "87sc"  # the # is the vkey
#     <shift>-w         would be  "87Sc"  # S|s is shift state
#     <shift>-<ctrl>-w  would be  "87sC"  # C|c is ctrl state
# 
#  print "Gimme a <ctrl>-F1 please: \n";
#  while (!KeyMatch(GetKey(ignore_ctl_keys=>1), "112sC"))
#     {
#     print "That wasn't <ctrl>-F1 !\n";
#     }
# 
#  or silently filter input:
# 
#  # only accept one of: a, b, w, F1 (with any combo of shift/ctrl F1)
#  #
#  my $key = GetKey(ignore_ctl_keys=>1, chars=>['a','b'], codes=>["87sc","112"]);
# 
#  # a yes/no prompt:
#  #
#  print "Wipe Disk (y,n,<enter>=y, <esc>=n)? ";
#  my $key = GetKey(ignore_ctl_keys=>1, chars=>['y','n'], vkeys=>[27,13]);
#
#  # many ways to test...
#  #
#  my $wipeok = ($key=>{char} == "y" || $key=>{char} == "\n");
#  my $wipeok = KeyPassesFilter($key, chars=>['y'], vkeys=>[13])
#  my $wipeok = KeyMatch($key, "89sc","13sc")
# 
# Macros:
#  <F12>      - start recording
#  <F12>      - end recording (and bind to to <F11>     
#  <Ctrl>#    - end recording (and bind to to <Ctrl-#>)
#  <Shift>F12 - end recording (and bind to to _next_ key)
#  <F11>      - playback
#  <Ctrl>#    - playback
# 
#  <Ctrl><Shift>F12 - enable/disable macros
#
# macro's may be saved/loaded via KeyMacrosStream()
# 
# 
# This all may seem like overkill, but I'm supporting both
#  coding for ascii/characters and  coding for key presses.
# (some keys dont generate an ascii/char value, and there
#  is more than 1 key combination to generate some asci values)
# 
# 
# this module is tightly bound to Win32::Console
# this module is a work in progress...
# 

package Gnu::KeyInput;

use warnings;
use strict;
use feature 'state';
use Win32::Console;
#use Win32::Console::ANSI qw(CursorSize);
use Gnu::MiscUtil    qw(InRange);
use Gnu::ListUtil    qw(OneOf);
use Gnu::StringUtil  qw(CleanInputLine);

require Exporter;

our @ISA       = qw(Exporter);
our $VERSION   = 0.10;
our @EXPORT    = qw();
our @EXPORT_OK = qw(GetKey 
                    KeyMacrosStream 
                    KeyMacroCallback 
                    IsCtlKey
                    IsFnKey
                    IsUnprintableChar
                    KeyName
                    DumpKey
                    KeyMacroList
                    MakeKey
                    KeyMatch
                    KeyCodesMatch
                    KeyPassesFilter
                    DecomposeCode
                    Flush
                    KeyReady
                    _Console
                    );
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);


# constants
#
sub _SHFT_MASK() {16}
sub _CTRL_MASK1() {8}
sub _CTRL_MASK2() {4}


# externals
#
###############################################################################

# options
#   echo=>1            - echo the input char (or '?' if not printable)
#   ignore_ctl_keys=>1 - don't return a <shift> or a <ctrl> key by itself
#   disable_macros=>1  - don't record / playback macro's
#   noisy=>1           - tell user when macro recording starts/stops
#   codes=>[...]       - only accept keys with these codes
#   vkeys=>[...]       - only accept keys with these vkeys
#   chars=>[...]       - only accept these chars
#
sub GetKey
   {
   my (%options) = @_;

   state $macro          = [];
   state $macro_state    = 0;
   state $macro_keyindex = 0;
   state $macros_enabled = 1;

   $macros_enabled = 0 if $options{disable_macros};
   my $isfiltered = IsFiltered(%options);

   while (1)
      {
      my $key;

      if ($macro_state == 2)
         {
         $key = $macro->[$macro_keyindex++];
         $macro_state = 0 if $macro_keyindex >= scalar @{$macro};
         }
      else
         {
         $key = _ConsoleInput();
         }
      next if $options{ignore_ctl_keys} && IsCtlKey($key);
 
      if (IsToggleMacrosKey($key) && $macro_state != 2)
         {
         next if $options{disable_macros};

         $macro = [];
         $macro_state = 0;
         $macros_enabled = 1 - $macros_enabled;
         my $statestr = $macros_enabled ? "enabled" : "disabled";
         print "macros $statestr\n" if $options{noisy};
         }

      # F12 to start recording, F12 to end and F11 to play
      # F12 to start recording, Ctl-1 thru 9 to end and Ctl-1 thru 9 to play
      # F12 to start recording, Shft-F12, <key> to end and <key> to play
      if (!$macro_state && IsRecordStartKey($key) && $macros_enabled)
         {
         $macro = [];
         $macro_state = 1;
         print "recording keys.\n" if $options{noisy};
         next;
         }
      if ($macro_state && IsRecordEndKey($key))
         {
         $macro_state = 0;
         my $play_key = BindMacro($key, $macro);
         print "recording ended (bound to ".KeyName($play_key).").\n" if $options{noisy};
         next;
         }
      if (IsMacroKey($key) && $macros_enabled)
         {
         next if $macro_state;
         $macro_keyindex = 0;
         $macro = KeyMacro($key) || [];
         $macro_state = 2 if scalar @{$macro};
         print "nothing to play back.\n" if !$macro_state && $options{noisy};
         next;
         }
      next if $isfiltered && !KeyPassesFilter($key, %options);

      print PrintableChar($key) if $options{echo};

      push(@{$macro}, {%{$key}}) if $macro_state == 1;
      return $key;
      }
   }

sub Flush
   {
   my $console = _Console();

   $console->Flush();
   }


# broken
sub KeyReady
   {
   my $console = _Console();

   while ($console->GetEvents())
      {
      my ($type, $down, undef, $vkey, undef, $ascii, $ctl) = $console->PeekInput();
      return 0 if !defined $type;
      return 1 if $type == 1 && $down == 1;
      $console->Input();
      }
   return 0;
   }



#   if (!defined $type) return 0;
#
#   if ($type != 1) {$console->Input(); return 0}
#   if ($down != 1) {$console->Input(); return 0}
#
#print "type  = " . (defined $type  ?  "$type"  : "undef") . ", ";
#print "down  = " . (defined $down  ?  "$down"  : "undef") . ", ";
#print "vkey  = " . (defined $vkey  ?  "$vkey"  : "undef") . ", ";
#print "ascii = " . (defined $ascii ?  "$ascii" : "undef") . ", ";
#print "ctl   = " . (defined $ctl   ?  "$ctl"   : "undef") . "\n";
#
#   return (defined $type && $type == 1 && $down == 1);
#   }


# get/set macros as a stream for io
#
#
sub KeyMacrosStream
   {
   my ($stream) = @_;

   return CreateMacroStream() if !scalar @_;
   return ParseMacroStream($stream);
   }


# set a callback fn if you want to save changes on the fly
#
#
sub KeyMacroCallback
   {
   my ($updated_callback_fn) = @_;

   state $callback_fn = undef;

   $callback_fn = $updated_callback_fn if scalar @_;
   return $callback_fn;
   }



#       todo
#sub PushKey
#   {
#   }


# internals
#
###############################################################################


# get/set macro hash
#
sub KeyMacros
   {
   my ($updated_macros) = @_;

   state $macros = {};
   $macros = $updated_macros if scalar @_;
   return $macros;
   }


# get/set a key's macro
#
sub KeyMacro
   {
   my ($key, $macro) = @_;

   my $hashkey = $key->{code};
   my $macros  = KeyMacros();
   if (scalar @_ > 1)
      {
      $macros->{$hashkey} = [@{$macro}];
      #KeyMacros($macros);
      my $callback = KeyMacroCallback();
      &{$callback}($key) if $callback;
      }
   return $macros->{$hashkey};
   }


sub InitConsole
   {
   my $console = Win32::Console->new(STD_INPUT_HANDLE); 
   $console->Cls();
   $console->Flush();

   return $console;
   }


sub CreateMacroStream
   {
   my $macros = KeyMacros();
   my $data = "";

   foreach my $bindcode (sort keys %{$macros})
      {
      my $keys = $macros->{$bindcode};
      next unless $keys and scalar @{$keys};

      my @keydefs = map{"$_->{ascii}|$_->{vkey}|$_->{ctl}"} @{$keys};
      my $keysstr = join(",",@keydefs);
      $data .="k:$bindcode:$keysstr\n";
      }
   return $data;
   }


sub ParseMacroStream
   {
   my ($stream) = @_;

   my $macros = {};
   foreach my $line (split /^/, $stream) 
      {
#      chomp $line;
#      chop $line if $line =~ /\x0D$/;
#      next if $line =~ /^#/;
#      next if $line =~ /^\s*$/;

#      next unless $line = CleanInputLine($line);
#      my ($linetype, $bindcode, $keystr) = split(/:/, $line  );
#      next unless $linetype eq "k";
#      my @keydefs                        = split(/,/, $keystr);

      $line = CleanInputLine($line,1,0);
      my ($bindcode, $keystr) = $line =~ /^k:([^:]+):(.*)$/;
      next unless $bindcode && $keystr;
      my @keydefs = split(/,/, $keystr);
      $macros->{$bindcode} = [];
      foreach my $keydef (@keydefs)
         {
         my ($ascii, $vkey, $ctl) = split(/\|/, $keydef);
         my $key = _Key($ascii, $vkey, $ctl);
         push(@{$macros->{$bindcode}}, $key);
         }
      }
   return KeyMacros($macros);
   }

   
#
#
# 
###############################################################################

sub _Console
   {
   state $console = InitConsole();
   
   return $console;
   }

sub _ConsoleInput
   {
   #state $console = InitConsole();
   
   my $console = _Console();

   while (1)
      {
      my ($type, $down, undef, $vkey, undef, $ascii, $ctl) = $console->Input();

      next unless defined $type && $type == 1 && $down == 1;
      return _Key($ascii, $vkey, $ctl);
      }
   }



   

#sub _ShowCursor
#   {
##   my $console = _Console();
##   
##   my $buff = " " x 256;
##   
##   my @a = $console->Info($buff);
##   
##   print "\n [[[", join(",", @a) , "]]]\n";
##   
##   print "\e[?25h";
#
#   my $sz = [50,0];
##   my $sz = [50];
#   my $old_size = CursorSize($sz);
#   
#   
#   #my @a = $console->Cursor();
#   #my @a = $console->Cursor([@a]);
##   return @a;
#   }
   

sub _Shifted
   {
   my ($ctl) = @_;

   return ($ctl & _SHFT_MASK) == _SHFT_MASK ? 1 : 0;
   }

sub _Ctrled
   {
   my ($ctl) = @_;
   return (($ctl & _CTRL_MASK1) == _CTRL_MASK1) || 
          (($ctl & _CTRL_MASK2) == _CTRL_MASK2) ? 1 : 0;
   }
   

#sub _OneOf
#   {
#   my ($val, @possibles) = @_;
#
#   map{return 1 if $val==$_} @possibles;
#   return 0;
#   }

#sub _InRange
#   {
#   my ($val, $min, $max) = @_;
#
#   return ($val >= $min && $val <= $max);
#   }

#
#
# options:
#  indent=>3
#  noname=>1
#  nocode=>1
#  nodata=>1
#
sub KeyMacroList
   {
   my (%options) = @_;

   my $macros = KeyMacros();
   my $data   = "";
   my $indent = " " x ($options{indent} || 0);
   foreach my $bindcode (sort keys %{$macros})
      {
      my $keys = $macros->{$bindcode};
      next unless $keys and scalar @{$keys};
      my $bindname = _NameFromCode($bindcode);
      my @keydefs  = map{KeyName($_)} @{$keys};
      my $keysstr  = join(", ",@keydefs);

      #$data .= sprintf("%-8s [%-5s]: %s\n", $bindname, $bindcode, $keysstr);
      $data .=  $indent;
      $data .=  sprintf("%-8s "  , $bindname) unless $options{noname};
      $data .=  sprintf("[%-5s] ", $bindcode) unless $options{nocode};
      $data .=  ": $keysstr"                  unless $options{nodata};
      $data .=  "\n";
      }
   return $data;
   }


sub IsFiltered
   {
   my (%options) = @_;

   return $options{codes} || $options{vkeys} || $options{chars};
   }


sub KeyPassesFilter
   {
   my ($key, %options) = @_;

   map{return 1 if KeyMatch($key, $_)} @{$options{codes}} if $options{codes};
   map{return 1 if $key->{vkey} eq $_} @{$options{vkeys}} if $options{vkeys};
   map{return 1 if $key->{char} eq $_} @{$options{chars}} if $options{chars};
   return 0;
   }


   
# key info
#
#   
##################################################   


sub KeyName
   {
   my ($key) = @_;
   
#print "debug: KeyName param ref is '" . (ref $key) .  "'\n";

   # allow KeyName($code) as well as KeyName($key)
   return _NameFromCode($key) unless ref $key eq "HASH";
   
   my $vkey = $key->{vkey};
   
#print "debug: KeyName vkey=$vkey\n";
   
   my $str = "";

   return "<shift>"   if $vkey == 16;
   return "<ctrl>"    if $vkey == 17;
   $str .= "<shift>-" if $key->{isshft};
   $str .= "<ctrl>-"  if $key->{isctrl};

   $str .= 
      $vkey == 13             ? "<enter>"                         :
      $vkey == 37             ? "<left>"                          :
      $vkey == 38             ? "<up>"                            :
      $vkey == 39             ? "<right>"                         :
      $vkey == 40             ? "<down>"                          :
      $vkey == 8              ? "<back>"                          :
      $vkey == 16             ? "<shift>"                         :
      $vkey == 17             ? "<ctrl>"                          :
      $vkey == 9              ? "<tab>"                           :
      $vkey == 46             ? "<del>"                           :
      $vkey == 45             ? "<ins>"                           :
      $vkey == 36             ? "<home>"                          :
      $vkey == 35             ? "<end>"                           :
      $vkey == 33             ? "<pgUp>"                          :
      $vkey == 34             ? "<pgDown>"                        :

      IsFnKey          ($key) ? sprintf("F%d", $key->{vkey}-111)  :
      IsDigitKey       ($key) ? chr($vkey)                        :
      IsLetterKey      ($key) ? chr($vkey-ord("A")+ord("a"))      :
      IsUnprintableChar($key) ? "?"                               :
                                $key->{char}                      ;
   return $str;
   }
   
   
sub _NameFromCode
   {
   my ($code) = @_;
   
#print "\ndebug:_NameFromCode($code)\n";
   
   my ($v,$s,$c,$ok,$any) = DecomposeCode($code);
   return "?" unless $ok;
   
   my $ctl = ($s eq "S" ? _SHFT_MASK : 0) | ($c eq "C" ? _CTRL_MASK1: 0);
   return KeyName(_Key($v, $v, $ctl));
   }
   

sub DumpKey
   {
   my ($key) = @_;

   print "\n-----------------\n";
   foreach my $hkey (sort keys %{$key})
      {
      print sprintf("  %-12s: %s\n", $hkey, $key->{$hkey});
      }
   print "-----------------\n";
   }

   
## todo -> _CodeFromKey()   
#sub _StringEncodeKey
#   {
#   my ($key) = @_;
#
#   return "$key->{vkey}" .
#          ($key->{isshft} ? "S" : "s") .
#          ($key->{isctrl} ? "C" : "c") ;
#   }


# accept key or code.  return code
#
# todo: move me   
sub _KeyCode
   {
   my ($key_or_code) = @_;
   
   return $key_or_code unless ref($key_or_code) eq "HASH";
   return $key_or_code->{code};
   }
   


# returns context,vkey,shft,ctl,isok,isany
#
sub DecomposeCode
   {
   my ($key_or_code) = @_;
   
   my $code = _KeyCode($key_or_code);

   my ($v,$s,$c) = (0, "", "");
   return ($v,$s,$c,0,1) if $code =~ /any$/;

   ($v,$s,$c) = $code =~ /^(\d+)(s?)(c?)$/i;

   return (0,"","",0,0) unless defined $v;
   return ($v,$s,$c,1,0);
   }
   
   
# key generation
#
#   
##################################################   


sub _Key
   {
   my ($ascii, $vkey, $ctl) = @_;

   my $isshft = _Shifted($ctl);
   my $isctrl = _Ctrled($ctl);
   my $state  = ($isshft ? "S" : "s") . ($isctrl ? "C" : "c");
   my $code   = "$vkey$state";
   my $char   = $ascii ? chr($ascii) : "";

   my $key = {ascii => $ascii,  isshft => $isshft,
              vkey  => $vkey ,  isctrl => $isctrl,
              ctl   => $ctl  ,  $state => 1      ,
              char  => $char ,  code   => $code  };
   return $key;
   }


sub MakeKey
   {
   my ($vkey, $isshft, $isctrl, $ascii, $char) = @_;

   $vkey   ||= 0;
   $isshft ||= 0;
   $isctrl ||= 0;
   $ascii  ||= 0;
   
   $ascii = ord($char) if (!$ascii && $char);
   if (!$vkey && $ascii)
      {
      $vkey = $ascii    if OneOf($ascii, 8,9, 13,27,32);
      $vkey = $ascii    if InRange($ascii, 48, 57) || InRange($ascii, 65, 90);
      $vkey = $ascii-32 if InRange($ascii, 97, 122);
      }
   my $ctl = ($isshft ? _SHFT_MASK : 0) | ($isctrl ? _CTRL_MASK1 : 0) ;
                      
   return _Key($ascii, $vkey, $ctl);
   }


sub _Copy
   {
   my ($key, %mods) = @_;

#  return {%{$key},  %mods};
   my %params = (%{$key}, %mods);
   return _Key(@params{"ascii", "vkey", "ctl"});
   }


# key finding - A  wip
#
#
##################################################   

sub IsCtlKey         { IsKey(@_, min_vkey=>16,  max_vkey=>18           )}
sub IsFnKey          { IsKey(@_, min_vkey=>112, max_vkey=>123          )}
sub IsDigitKey       { IsKey(@_, min_vkey=>48,  max_vkey=>57, isshft=>0)}
sub IsLetterKey      { IsKey(@_, min_vkey=>65,  max_vkey=>90           )}
sub IsUnprintableChar{!IsKey(@_, min_ascii=>32, max_ascii=>127         )}

sub PrintableChar
   {
   my ($key) = @_;

   return IsUnprintableChar($key) ? "?" : $key->{char};
   }

sub IsRecordStartKey 
   { 
   my ($key) = @_;
   return IsKey($key, vkey=>123, isshft=>0, isctrl=>0); # F12
   }

sub IsRecordEndKey   
   { 
   my ($key) = @_;
   return 
      IsKey($key, vkey=>123, isctrl=>0) ||                 # F12 / <Shift>F12
      IsKey($key, min_vkey=>48,  max_vkey=>57, isctrl=>1); # <ctrl>#
   }

sub IsMacroKey
   {
   my ($key) = @_;
   return KeyMacro($key) ? 1 : 0;
   }


sub BindMacro
   {
   my ($record_end_key, $macro) = @_;

   my $play_key = PlaybackKey($record_end_key);
   KeyMacro($play_key, $macro);
   return $play_key;
   }

#  stop recording via F12        , bind to F11
#  stop recording via <shift>F12 , bind to next key
#  stop via <ctrl>1thru9         , bind to <ctrl>1thru9
#
sub PlaybackKey
   {
   my ($key) = @_;

   return
      IsKey($key, vkey=>123, isshft=>0) ? _Copy($key, vkey=>122) :
      IsKey($key, vkey=>123, isshft=>1) ? _NonCtlKey()           :
                                          _Copy($key)            ;
   }


sub _NonCtlKey
   {
   while(1)
      {
      my $key = _ConsoleInput();
      return $key unless IsCtlKey($key);
      }
   }


sub IsToggleMacrosKey
   {
   my ($key) = @_;

   return IsKey($key, vkey=>123, isshft=>1, isctrl=>1); # F12
   }




# key finding
#
#   
##################################################   


sub IsKey
   {
   my ($key, %options) = @_;

   return 0 if exists $options{vkey     } && $key->{vkey  } != $options{vkey     };
   return 0 if exists $options{min_vkey } && $key->{vkey  } <  $options{min_vkey }; 
   return 0 if exists $options{max_vkey } && $key->{vkey  } >  $options{max_vkey }; 
   return 0 if exists $options{ascii    } && $key->{ascii } != $options{ascii    };
   return 0 if exists $options{min_ascii} && $key->{ascii } <  $options{min_ascii}; 
   return 0 if exists $options{max_ascii} && $key->{ascii } >  $options{max_ascii}; 
   return 0 if exists $options{char     } && $key->{char  } ne $options{char     };
   return 0 if exists $options{isshft   } && $key->{isshft} != $options{isshft   };
   return 0 if exists $options{isctrl   } && $key->{isctrl} != $options{isctrl   };
   return 1; 

   }
   
   
#sub KeyMatch  ->  KeyCodesMatch
#   {
#   my ($key, @codes) = @_;
#   
#   map{return 1 if _ReducedCode($key->{code},$_) eq $_} @codes;
#
##   foreach my $code (@codes)
##      {
##      my $kcode = $key->{code};
##      $kcode =~ s/S//i unless $code =~ /S/i;
##      $kcode =~ s/C//i unless $code =~ /C/i;
##      return 1 if $kcode eq $code;
##      }
#   return 0;
#   }
   
sub KeyMatch {KeyCodesMatch(@_)};
   
sub KeyCodesMatch
   {
   my ($key, @codes) = @_;
   
   return CodesMatch($key->{code}, @codes);
   }

   
sub CodesMatch
   {
   my ($code, @codes) = @_;
   
   map{return 1 if _ReducedCode($code, $_) eq $_} @codes;
   }
   
   
sub _ReducedCode
   {
   my ($code, $match) = @_;
   
   $code =~ s/S//i unless $match =~ /S/i;
   $code =~ s/C//i unless $match =~ /C/i;
   return $code;
   }
   
   
   
   
#needed ?   
#sub CodeKeysMatch
#   {
#   my ($code, @keys) = @_;
#   }
   
   

1; # two
  
__END__   
