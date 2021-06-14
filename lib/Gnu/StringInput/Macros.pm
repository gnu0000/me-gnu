use strict;
use warnings;
use feature 'state';

#
# StringInput::Macros.pm - macro handling for StringInput
#  C Fitzgerald xx/xx/2013
#
# this module is required by Gnu::StringInput
#
#
#  Ma_GlobalMacros()  init/return href
#  Ma_Macros()        init/return href
#  Ma_GetMacro        get macro
#  Ma_SetMacro        set macro, delete macro
#  Ma_EnableMacro     enable/disable             
#  Ma_FindMacro       find macro
#
#  SISetMacro
#  SIClearMacros
#########################################################################


my $NAM_MACROS = "__macros";


# init if needed
# returns href of all global macros
#
sub Ma_GlobalMacros
   {
   state $foo = GVarSet($NAM_MACROS=>Ma_InitGlobalMacros());

   my $macros = GVar($NAM_MACROS);
   
#   my $macros = GVarDefault($NAM_MACROS=>0) || 
#                GVarSet    ($NAM_MACROS=>Ma_InitGlobalMacros());
                
# print "\n", LineString("global macros");
# print DumpRef($macros, "   ", 3);
# print "\n", LineString("");
                
   return $macros;
   }

   
# returns href of all context macros
#
sub Ma_Macros
   {
   my $macros = VarInit($NAM_MACROS=>{});
   return $macros;
   }

   
# gets a specific macro in current or global context
#   
#  Ma_GetMacro("107Sc")
#  Ma_GetMacro("39", global=>1)
#
#  opt
#     global=>1
#   
sub Ma_GetMacro
   {
   my ($code, %opt) = @_;
   
   my $macros = $opt{global} ? Ma_GlobalMacros() : Ma_Macros();
   return $macros->{$code};
   }
   
   
# sets a specific macro in current or global context
#
#  Ma_SetMacro("107Sc", $macro)
#  Ma_SetMacro("39"   , $macro, global=>1)
#  Ma_SetMacro("39"   , 0, global=>1, delete=>1)
#
#  macro  -- packaged macro hash (Ma_PrepareMacro)
#  opt
#     global=>1
#     delete=>1
#   
sub Ma_SetMacro   
   {
   my ($code, $macro, %opt) = @_;
   
   my $macros = $opt{global} ? Ma_GlobalMacros() : Ma_Macros();
   return delete $macros->{$code} if $opt{delete};
   return $macros->{$code} = $macro;
   }
   
#
#   
sub SISetMacro   
   {
   my (%params) = @_;
   
   my $macro = Ma_PrepareMacro(%params);
   my $code  = $macro->{code};
   
   return Ma_SetMacro($code, $macro);
   }
   
   
#  enable/disable a macro 
#  Ma_EnableMacro("107Sc", 0           )
#  Ma_EnableMacro("107Sc", 1           )
#  Ma_EnableMacro("107Sc", 0, global=>1)
#   
sub Ma_EnableMacro   
   {
   my ($code, $enable, %opt) = @_;
   
   my $macro = Ma_GetMacro($code, %opt) || return 0;
   return $macro->{disabled} = !$enable;
   }
   
   
# finds match in current or global context
# returns "any" handler as a default
#   
sub Ma_FindMacro
   {
   my ($code, %opt) = @_;

   
#print "\n", LineString("macros");
#print DumpRef(Ma_Macros(), "   ", 3);
#print "\n", LineString("global macros");
#print DumpRef(Ma_GlobalMacros(), "   ", 3);
#print "\n", LineString("");

#Log(1, "\n" . LineString("macros")        . DumpRef(Ma_Macros()      , "   ", 3));
#Log(1, "\n" . LineString("global macros") . DumpRef(Ma_GlobalMacros(), "   ", 3));
   
   my $codes = _Ma_CodesForFindMacro($code);
   my $macro = _Ma_Find(Ma_Macros      (), $codes, 0) ||
               _Ma_Find(Ma_GlobalMacros(), $codes, 1);
   return $macro;
   }
   
sub _Ma_CodesForFindMacro
   {
   my ($code) = @_;
   
   my ($v, $s, $c, $ok) = DecomposeCode($code);
   return () unless $ok;
   my @codes = ("$v$s$c", "$v$s", "$v$c", "$v");
   return [@codes];
   }
   
sub _Ma_Find
   {
   my ($macros, $codes, $return_any) = @_;
   
#Log(1, "Ma_Find($return_any): " . join(",", @{$codes}));

   foreach my $code (@{$codes})
      {
      my $macro = $macros->{$code};
      return $macro if $macro && !$macro->{disabled};
      }
   return $return_any ? $macros->{any} : undef;
   }
   
   

# options
#   tags_only
#
sub SIClearMacros
   {
   my (%opt) = @_;
   
   my $macros = $opt{global} ? Ma_GlobalMacros(): Ma_Macros();
   foreach my $code (keys %{$macros})
      {
      my $macro = $macros->{$code};
      next if $macro->{default};
      next if !$macro->{istag} && $opt{tags_only};
      delete $macros->{$code};
      }
   }
   

# creates the initial href of global macros and returns it
#   
sub Ma_InitGlobalMacros
   {
   my $edit_keymap = EditKeymap();
   
#Log(2, LineString("keymap igm"), DumpRef($edit_keymap, "   ", 3));
                
   my $macros = {};
   foreach my $code (keys %{$edit_keymap})
      {
#Log(3, "igm code = [$code]\n");

      my $entry = $edit_keymap->{$code};
      $macros->{$code} = Ma_PrepareMacro(%{$entry}, default=>1, code=>$code);
      }
      
   return $macros;
   }

   
# identify bindkey options:
#    key=>$key
#        -or-
#    code=>""
#------------------------
# action options
#    tag=>"str" | fn=>\&fn
#------------------------
# context options
#    global=>1  | nothing (current context)
#------------------------
# misc options
#    replace=>1  : for tags, replace line rather than insert
#    finish=>1   : return string after macro
#    nosave=>1   : exclude from stream i/o
#    extra=?     : user data
#
sub Ma_PrepareMacro
   {
   my (%params) = @_;
   
   my $code = $params{code} || $params{key}->{code};
   
   my $istag   = ($params{tag} || !$params{fn}) ? 1 : 0;
   my $fn      = $istag ? \&KeyTag : $params{fn};

   my $macro = {code     => $code                  ,
                fn       => $fn                    ,
                istag    => $istag                 ,
                tag      => $params{tag}     || "" ,
                default  => $params{default} || 0  ,
                disabled => $params{disabled}|| 0  ,
                finish   => $params{finish}  || 0  ,
                replace  => $params{replace} || 0  ,
                nosave   => $params{nosave}  || 0  ,
                extra    => $params{extra}   || "" };
   return $macro;
   }

   
sub _GetMacroTag
   {
   my ($tagstr, $idx) = @_;

   $idx ||= 0;
   return $tagstr unless defined $tagstr && $tagstr =~ /\|/;
   my @subtags = (split(/\|/, $tagstr), "");
#  my @subtags = split(/\|/, $tagstr);
   my $tagcount = scalar @subtags;
   return @subtags[$idx % $tagcount];
   }


# -internal-
#
# note: we can only save tag macros
#
sub Ma_CreateStream
   {
   my (%options) = @_;

   return "" if SkipStream(0, "macro", %options);

   SIContext({push=>1});
   my $stream = "";

   foreach my $context (SIContext({ctxlist=>1,all=>1}))
      {
      SIContext($context);
      $stream .= Ma_CreateContextStream($context, %options);
      }
   SIContext({pop=>1});
   return $stream;
   }


sub Ma_CreateContextStream
   {
   my ($context, %options) = @_;
   
   return "" if  SkipStream($context, "macro", %options);
   my $stream = "";

   my $macros = Ma_Macros();
   foreach my $code (sort keys %{$macros})
      {
      my $macro = $macros->{$code};
      next if $macro->{default} || $macro->{nosave} || !$macro->{istag};

      $stream .= "simac:$context"      .
                  ":$macro->{code}"    .
                  ":$macro->{finish}"  .
                  ":$macro->{replace}" .
                  ":$macro->{tag}"     .
                  ":$macro->{extra}"   .
                  "\n";
      }
   return $stream;
   }

   
sub Ma_LoadStream
   {
   my ($stream, %options) = @_;
   
   return 0 if  SkipStream(0, "macro", %options);

   my $all = {};
   foreach my $line(split(/\n/, $stream)) 
      {
      my %params;
      my @vals = $line =~ /^(simac):([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):(.*)$/;

      @params{qw(ltyp context code finish replace tag extra)} = @vals;
      next unless $params{code} && $params{tag};
      
      my $context = $params{context};
      $all->{$context} ||= [];
      push (@{$all->{$context}}, {%params});
      }
      
   SIContext({push=>1});
   foreach my $ctx (keys %{$all})
      {
      SIContext($ctx);
      next if SkipStream($ctx, "macro", %options);
      
      my $newmacros = $all->{$ctx};
      my $isglobal = $ctx =~ /^global$/;
      foreach my $macro (@{$newmacros})
         {
         SISetMacro(%{$macro}, global=>$isglobal);
         }
      }
   SIContext({pop=>1});
   return 1;   
   }
   

sub SIMacroKeyName
   {
   my ($macro) = @_;
   
   return KeyName($macro->{code});
   }
   
   
sub SITagList
   {
   my ($context, $delim, $add_globals) = @_;

   $delim = "\n" unless defined $delim && length $delim;
   my $tags = {};
   _tags_hash(Ma_GlobalMacros(),$tags,1) if $add_globals;

   SIContext({push=>1},$context) if $context;
   _tags_hash(Ma_Macros(),$tags,0);
   SIContext({pop=>1}) if $context;

   return join($delim, map{"  ".$tags->{$_}}(sort keys %{$tags}));
   }

sub _tags_hash
   {
   my ($macros, $tags, $isglobal) = @_;
   my $suffix = $isglobal ? " (global)" : "";
   map{_tag_hash($macros,$tags,$_,$suffix)} (keys %{$macros});
   return $tags;
   }

sub _tag_hash
   {
   my ($macros, $tags, $code, $suffix) = @_;
   my $macro = $macros->{$code} || return;
   return unless $macro->{istag};
   my ($tag, $name) =  ($macro->{tag}, SIMacroKeyName($macro));
   $tags->{$code} = "$name: '$tag'$suffix";
   }


1;
