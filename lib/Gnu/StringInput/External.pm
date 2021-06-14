#
# StringInput::External.pm - external handling for StringInput
#  C Fitzgerald xx/xx/2013
#
# this module is required by Gnu::StringInput
#
#todo: clean this up
#  exfileroot       SIExternal(settype=>"fdata", cwd=>)
#  rootdir
#  root
#  cwd
#  dir
#

use strict;
use warnings;                                         
use feature 'state';


# constants
my $MAX_EXTERNAL = 200;
my $NAM_EXTERNAL = "__external" ;


################################################################################
######## tag:exstart
#######
######## external access/get/set/info
########
######## SIExternal()                               get extern data
######## SIExternal($data)                          set extern data
######## SIExternal($data,opt=>val,opt=>val,...)    set extern data w/options
######## SIExternal(export=>filespec,opt=>val,...)  export extern data
######## SIExternal(import=>filespec,opt=>val,...)  import extern data
######## SIExternal(opt=>val,opt=>val,...)          get/set misc
########
######## options:
########    setref=>"ctx"             set referring context
########    (settype=>"[acf]data")    (internal) set/return context's extern data type
########    (noref=>1)                (internal) use this external, not referring context external if exists
########
########    (getroot=>1)              (internal) return context's extern root
########    gettype=>1                return data type (adata, cdata fdata)
########    getref=>1                 return context that has the extern data if redirected or ""
########
########    import=>"file"            import data from file, return $ok
########        (noref=>1)              (internal) ignore ref redirection
########        type=>"[acf]data"     (internal) provide type of data
########        indent=>"   "         (cdata) provide import format info
########    export=>"file"            get/return exportable \n delim buff
########        (top=>node)           (internal,cdata) provide head node
########        indent=>0             (internal,cdata) provide starting indent
########        levels=>99            (internal,cdata) provide crawl depth
########        noexpanded=>0         include entries created via callback
########        otype .....
########    getview=>1                get/return viewable \n delim buff
########        filespec=>"file"      save to a file
########        top=>node             (internal,cdata) provide head node
########        indent=>0             (internal,cdata) provide starting indent
########        levels=>99            (internal,cdata) provide crawl depth
########        noexpanded=>1         exclude entries created via callback
########    clear=>1                  remove all data
########
#########################################################################
# new:
#
# command options
#   getroot  => 1        : see below for specific uses
#   gettype  => 1        : ..
#   settype  => 1        : ..
#   import   => filespec : ..
#   export   => filespec : ..
#   getview  => 1        : ..
#   clear    => 1        : ..
#   getref   => 1        : ..
#   setref   => ctx      : ..
#
# source modifier options (SMoptions)
#   context  => ctx      : specify context to query
#   initroot => 1        : initialize all External data for this context
#   noref    => 1        : internal: ignore ref context redirection
#
#
#
# (Internal) Get data root node
#----------------------------------------
#   SIExternal(getroot=>1) : gets full internal data structure
#
#
# Get data type (adata, cdata, or fdata)
#----------------------------------------
#   SIExternal(gettype=>1) : gets type of external data
#
#   other options:
#     (SMoptions)
#     typeindex =>1        : (see return below)
#
#   returns:
#     "adata", "cdata, or "fdata" if typeindex =>0
#      0, 1, or 2                 if typeindex =>1
#                    
#
# Set data type (adata, cdata, or fdata)
#----------------------------------------
#   SIExternal(settype=>"cdata") : sets type of external data
#
#   Can be combined with options, for example:
#     SIExternal(settype=>"cdata",import=>"data.cext");
#
#   other options:
#     (SMoptions)
#
#   settype options specific to fdata:
#     cwd =>dir : set starting directory for dirmatches
#                 SIExternal(settype=>'fdata',cwd=>'c:\myproj\data');
#
#   returns:
#     extern data if used without other command options
#     or whatever other comand specifies
#
#
# Import data
#----------------------------------------
#   SIExternal($data)               : load from buffer (newline delim or array ref)
#   SIExternal(import=>"data.cext") : load extern data from file
#   SIExternal(data=>$data)         : load from buffer (newline delim or array ref)
#
#   Note: data for loading must be of the same type as context's data type
#     SIExternal(import=>"data.cext", settype=>"cdata"             ) : load adata from export file
#     SIExternal(import=>"data.ext",  settype=>"adata"             ) : load cdata from export file
#     SIExternal(settype=>"adata",add=>1,data=>[qw(new words here)]) : add a few words
#
#   general import data options:
#     (SMoptions)
#     type => type            : (depricated, use settype) set load this type of data, do not change active type
#     add  => 1               : dont clear existing data before loading
#
#   adata specific import options:
#     duplicates => 1         : allow duplicate entries
#
#   cdata specific import options:
#     indent => "   "         : (internal) provide indent format for data
#     top    => "word word.." : provide word list to identify parent of import data
#     top    => $node         : (internal) provide actual parent node
#     replace=> 1             : new data words replace existing words
#     format => 3|4           : (internal) specift that data is I/O stream format(3), or context data format(4), otherwise its export format data
#
#
# Export data
#----------------------------------------
#   SIExternal(export=>1)           : return export data as a text buffer
#   SIExternal(export=>"data.cext") : export to data and return data
#
#   general export data options:
#     (SMoptions)
#
#   cdata specific export options:
#     indent => "   "         : (internal) provide indent format for data
#     top    => "word word.." : provide word list to identify parent of export data
#     top    => $node         : (internal) provide actual parent node
#     noexpanded => 1         : exclude entries created via macro callback (def: 1 unless otype is 1)
#     prep       => 1         : expand nodes with macros
#
#
# Get data view
#----------------------------------------
#   SIExternal(getview=>1)           : return view data as a text buffer
#   SIExternal(getview=>"data.dump") : export view and return view
#
#   general get view options:
#     (SMoptions)
#
#   cdata specific export options:
#     indent     => "   "         : (internal) provide indent format for data
#     top        => "word word.." : provide word list to identify parent of export data
#     top        => $node         : (internal) provide actual parent node
#     indent     => "   "         : string for indenting
#     indents    => 0             : starting indent level
#     levels     => 99            : # levels to traverse
#     lineprefix => ""            : string at start of each line
#     linesuffix => ""            : string at end of each line
#     infocol    => 45            : column for node details
#     noexpanded => 1             : exclude entries created via macro callback (def: 1 unless otype is 1)
#     prep       => 1             : expand nodes with macros
#
#
# (Internal) Get raw data
#----------------------------------------
#   SIExternal() : return raw data of current type
#
#
# (Internal) Get/Set reference type
#----------------------------------------
#   SIExternal(getref=>1)       : return original context
#   SIExternal(setref=>context) : set reference context
#
#
# Clear data
#----------------------------------------
#   SIExternal(clear=>1)        : return original context
#
sub SIExternal
   {
   my $argcount = scalar(@_) || return Ex_Data();
   my %setdata  = $argcount % 2 ? (data => shift(@_)) : ();
   my %opt = (%setdata, @_);

   Ex_RefCtx($opt{setref }, %opt) if defined $opt{setref };
   Ex_ExType($opt{settype}, %opt) if defined $opt{settype};

   return $opt{getroot} ? Ex_Root    (%opt)                                    :
          $opt{gettype} ? Ex_ExType  (0,%opt)                                  :
          $opt{getref } ? Ex_RefCtx  (0,%opt)                                  :  
          $opt{import } ? Ex_DataIn  (filespec=>$opt{import }, %opt)           :
          $opt{export } ? Ex_DataOut (filespec=>$opt{export }, %opt)           :
          $opt{getview} ? Ex_DataOut (filespec=>$opt{getview},format=>1, %opt) :
          $opt{clear  } ? Ex_Data    (%opt, initroot=>1)                       :
          $opt{data   } ? Ex_DataIn  (%opt)                                    :
                          Ex_Data    (%opt)                                    ;
   }


#  context
#  initroot
#  noref
#
# returns extern root
#
sub Ex_Root
   {
   my (%opt) = @_;

   my $context = $opt{context} || SIContext();

   return _Ex_InitRoot($context) if $opt{initroot};

   my $root = _Ex_GetTrueRoot($context);
   return $root if $opt{noref};

   while ($root->{refctx})
      {
      $root = _Ex_GetTrueRoot($root->{refctx});
      }
   return $root;
   }


# dont use
sub _Ex_GetTrueRoot
   {
   my ($context) = @_;

   return _VarDefault($context, $NAM_EXTERNAL=>0) || _Ex_InitRoot($context);
   }

#
sub _Ex_InitRoot
   {
   my ($context) = @_;

   $context ||= SIContext();

   my $root  = _VarDefault($context, $NAM_EXTERNAL=>{});
   my $cdata = Ex_CreateInitialNode();
   @{$root}{qw(adata cdata fdata type refctx)} = ( [], $cdata, "", "adata",  "" );
   return _VarSet($context, $NAM_EXTERNAL=>$root);
   }


# GetData of current type
# opt:
#   root
#   context
#   initroot
#   noref
# ret:
#   root data of current type
#
sub Ex_Data
   {
   my (%opt) = @_;

   my $root = $opt{root} || Ex_Root(%opt);
   my $type = $opt{type} || $root->{type};
   return $root->{$type};
   }


# type: "adata","cdata","fdata"
#  opt:
#     cwd=>dir
#
sub Ex_ExType
   {
   my ($type, %opt) = @_;

   my $root = Ex_Root(%opt);
   my $getidx = $opt{typeindex};

   return 0 if $getidx && $root->{type} eq "adata";
   return 1 if $getidx && $root->{type} eq "cdata";
   return 2 if $getidx && $root->{type} eq "fdata";
   return 0 if $getidx;

   return $root->{type} unless $type;
   $root->{type}  = $type;
   
   # todo: this is asymmetric
   $root->{fdata} = $opt{cwd}||""  if $type eq "fdata";
   
   return $type;
   }


#  opt
#    context
#
# todo: finish refctx or remove completely
#
sub Ex_RefCtx
   {
   my ($refctx, %opt) = @_;

   my $root = Ex_Root(noref=>1, %opt);
   $root->{refctx} = $refctx if $refctx;
   $root->{refctx} = ""      if $opt{deleteref};
   return $root->{refctx};
   }





#########################################################################
#
# searching top
#

# SIFindExternal  -external-

# option     value  default exttype  desc
# ----------------------------------------
# direction  1,-1   1       all      search direction
# start      #      0       all      index to start looking
# pre_str    str    ""      context  previous string to provide context
# dir        dir    <cwd>   exfiles  provides dir to look in
#    todo... these comments



sub SIFindExternal #(search_str, %opt)
   {
   my ($search_str, %opt) = @_;

   return Ex_TypeRoute([\&SIFindExternalA,\&SIFindExternalC,\&SIFindExternalF],[@_], %opt);
   }

sub SIFindExternalA
   {
   my ($search_str, %opt) = @_;
   my $set = Ex_Data(type=>"adata");
   my ($match, $newpos) = _FindInList($set, $search_str, %opt);
   return ($match, $newpos) if wantarray;
   return $match;
   }


sub SIFindExternalC
   {
   my ($search_str, %opt) = @_;

   my ($node, $pos) = Ex_FindMatchNode($search_str, %opt);
   
   TVar(currentnode=>$node||0);
   my $nodetype = $node ? $node->{nodetype} : 0;

   # nodetypes
   #   0 - a normal string
   #   1 - a callback (shouldnt happen cause they get pre expanded out)
   #   2 - an exfile (this will get replaced later)
   #   3 - an {any} use search str
   #
   my $str = !$node       ? "" :          # no match
             $nodetype==2 ? FindExternalF($search_str,%opt,rootdir=>$node->{exdir},start=>$opt{oidx}||$opt{start}) : #newnew   
             $nodetype==3 ? "" :          # {any}
                            $node->{str}; # others
   
   return ($str, $pos, $node) if wantarray;
   return $str;
   }


sub SIFindExternalF
   {
   my ($search_str, %opt) = @_;
   
   
   my $start     = $opt{start    } ||= 0;
   my $direction = $opt{direction} ||= 1;
   my $rootdir   = $opt{rootdir  } ||= "";
   my $dir       = $opt{dir      } ||= "";
   my $contents  = ExternalDirContents($dir);
   
   my $ex_size   = scalar @{$contents};
   
   my $pos       = $start;
   my  $target   = SICall("quoteexternalpath", sub(){quotemeta $_[0]}, $search_str);
   foreach (0..$ex_size-1)
      {
      $pos = $pos % $ex_size;

      if ($contents->[$pos] =~ /^$target/i)
         {
         return ($contents->[$pos], $pos) if wantarray;
         return $contents->[$pos];
         }
      $pos += $direction;
      }
   return ("", 0) if wantarray;
   return "";
   }

#############################################################################

# FindExternal -internal-
# keeps find state for multiple search matching
#
sub FindExternalA
   {
   my ($search_str, %opt) = @_;

   my ($direction, $continue) = @opt{"direction", "continue"};
   my ($last_idx, $target) = tv_is(!$continue, fe_lastidx=>0,fe_target=>$search_str);

   my $idx = $last_idx + $direction * $continue;
   $idx  = -1 if !$continue && $direction == -1;

   my ($str, $new_idx) = SICall("sifindexternal", \&SIFindExternalA, $target, direction=>$direction, start=>$idx);

   TVar(fe_lastidx=>$new_idx);
   return $str;
   }


# FindExternal -internal-
# keeps find state for multiple search matching
#
sub FindExternalC
   {
   my ($search_str, %opt) = @_;

   my ($pre_str, $direction, $continue) = @opt{"pre_str", "direction", "continue"};

   my ($last_idx, $target, $prestr) = tv_is(!$continue, feic_lastidx=>0,feic_target=>$search_str,feic_prestr=>$pre_str);

   my $idx  = $last_idx + $direction * $continue;

#new   
#  $idx  = -1 if !$continue && $direction == -1;
  ($idx,$last_idx)  = (-1,-1) if !$continue && $direction == -1;

   my %callopt = (start=>$idx, direction=>$direction, pre_str=>$prestr, continue=>$continue, oidx=>$last_idx);
   my ($str, $new_idx) = SICall("sifindexternalincontext", \&SIFindExternalC, $target, %callopt);

   TVar(feic_lastidx=>$new_idx);
   return $str;
   }


# FindExternal -internal-
# keeps find state for multiple search matching
#
sub FindExternalF
   {
   my ($search_str, %opt) = @_;
   
   my $direction = $opt{direction} ||= 1;
   my $continue  = $opt{continue } ||= 0;
   my $rootdir   = $opt{rootdir  } ||= VarDefault(rootdir=>"");

   my($target,$lastidx,$currdir,$trimdir) = tv_is(!$continue, fep_target=>"",fep_lastidx=>0,fep_currdir=>"",fep_trimdir=>"");

   if (!$continue)
      {
      $lastidx = 0;
      ($currdir, $trimdir, $target) = _PrepSpec($rootdir, $search_str);
      TVar(fep_target=>$target, fep_lastidx=>0, fep_currdir=>$currdir, fep_trimdir=>$trimdir);
      }
   my $idx = !$continue && $direction == -1 ? -1 : $lastidx + $direction * $continue;

   my ($match, $new_idx) = SIFindExternalF($target, start=>$idx, direction=>$direction, dir=>$currdir);

   $lastidx = $new_idx;

   TVar(fep_lastidx=>$new_idx);
   
   return $trimdir . $match if length $match;
   return "";
   }


sub ExternalDirContents
   {
   my ($dir) = @_;

   my $name = "_ex_dir_" . _FixDirSlash($dir);
   $name =~ tr[/\\][__];

   #return TVarInit($name=>GatherDirContents());
   return TVar($name) if TVarExists($name);
   return TVar($name=>GatherDirContents($dir));
   }

sub GatherDirContents
   {
   my ($dir) = @_;

   $dir = _FixDirSlash($dir);
   $dir = ".\\" if $dir eq "";
   
   return [] unless -d $dir;

   opendir(my $dh, $dir);
   my @all = readdir($dh);
   closedir($dh);

   my $filenames = [];
   push(@{$filenames}, (grep(!/^\.{1,2}$/, (grep{-d $dir.$_} @all))));
   push(@{$filenames}, (grep{-f $dir.$_} @all));
   return $filenames;
   }
   
   
sub _PrepSpec
   {
   my ($rootdir, $search) = @_;

   my $root = _FixDirSlash($rootdir);
   my $spec = $root . $search;

   my (undef,$trimdir) = fileparse($search);
   $trimdir = '' if $trimdir eq ".\\";

   my ($name,$dir) = fileparse($spec);
   $dir = '' if $dir eq ".\\";

   return ($dir, $trimdir, $name);
   }

   


#############################################################################
#
# search type C internals
# finding nodes
#
# option       value  def
# ---------------------------------------------------
# pre_str      str    ""   string before search_str to provide context
# start        #      0    starting search pos for match set
# direction    1,-1   1    direction of search
# allowregex   0,1         $search_str is actually a regex
# exact        0,1         match must match /^$search_str$/
#
sub Ex_FindMatchNode
   {
   my ($search_str, %opt) = @_;

   my $startpos  = $opt{start    } ||= 0;
   my $direction = $opt{direction} ||= 1;
   my $pre_str   = $opt{pre_str  } ||= "";
   my $setnode   = Ex_FindSetNode($pre_str);
   my $atbegin   = !$setnode->{level} && !$pre_str;
   my $target    = $opt{allowregex} ? $search_str : quotemeta $search_str;
   my $pattern   = $opt{exact     } ? qr/^$target$/ : qr/^$target/;
   my $set       = Ex_NodeKids($setnode,prep=>1);
   my $setsize   = scalar @{$set} || return (undef, 0);
   
   
   my $searchsize = $setsize*2;
      
   foreach my $i (0..$searchsize-1)
      {
      my $pos    = ($startpos + ($i * $direction)) % $searchsize;
      my $setidx = $pos % $setsize;
      my $mkind  = $pos >= $setsize ? 1 : 0; # regular ients come first
      my $node   = $set->[$setidx];
      
      next if $node->{begin} && !$atbegin;
      
      my $found = $mkind == 0 ? $node->{str} =~ /$pattern/i : # ident
                                $node->{nodetype} > 1;        # {exfiles} && {any}
                                
      return ($node, $pos) if $found;
      }
   return (undef, 0);
   }


# always finds a node with a kidset
#
sub Ex_FindSetNode
   {
   my ($pre_str) = @_;

   my $setnode = _Ex_CachedSetNode($pre_str);
   return $setnode if $setnode;

   my $exdata  = Ex_Data(type=>"cdata");
   my $chain   = Ex_MakeChain($pre_str);
   
      $setnode = Ex_ChainEnd($exdata,$chain);

   my $kidcount = Ex_NodeKidCount($setnode, prep=>1);
   
   _Ex_CachedSetNode($pre_str, $kidcount ? $setnode : 0);
   return $kidcount ? $setnode : $exdata;
   }


sub _Ex_CachedSetNode
   {
   my ($pre_str, $setnode) = @_;

   my $cache = TVarInit(_ex_matchset_cache=>{});
   $cache->{"$pre_str"} = $setnode if scalar @_ > 1;
   return $cache->{"$pre_str"};
   }


# uses chain to traverse context nodes
# resets to root whenever no match is found
# always returns a node
#
# in: 
#    $exdata,     (Ex_Data(type=>"cdata"))
#    $chain       chain to follow
# out:
#    $node
#
sub Ex_ChainEnd
   {
   my ($exdata, $chain) = @_;
   
   $exdata ||= Ex_Data(type=>"cdata");

   my @chain = @{$chain};
   my $atstart = 1;
   while (scalar @chain)
      {
      my $node = Ex_FollowChain($exdata, $atstart, @chain);
      return $node if $node;
      shift @chain;
      $atstart = 0;
      }
   return $exdata;
   }


   
# uses chain to traverse context nodes
# returns undef if chain cannot be followed
#
# in:
#    $node        starting node
#    $atstart     true if at start of chain
#    @chain       chain to follow <not chain ref>
# out:
#    $node or undef
#
sub Ex_FollowChain
   {
   my ($node, $atstart, $entry, @chain) = @_;
   
   return $node unless $node && $entry;
   
   my $word = $entry->{word};
   my $info = Ex_InitNextNodeKid($node, $word, prep=>1);
   
   while ($info = Ex_NextNodeKid($info, $atstart))
      {
      $entry->{node} = $info->{kid};
      my $endnode = Ex_FollowChain($info->{kid}, 0, @chain);
      return $endnode if $endnode;
      }
   return undef;
   }
   
   
sub Ex_InitNextNodeKid
   {
   my ($node, $match, %opt) = @_;
   
   my $nodekids = Ex_NodeKids($node, %opt);
   my $count    = scalar @{$nodekids};
   
   return {node=>$node, kids=>$nodekids, kid=>0, idx=>-1, count=>$count, match=>$match};
   }
   
   
sub Ex_NextNodeKid
   {
   my ($info, $atstart) = @_;
   
   while (1)
      {
      $info->{idx} += 1;
      return undef if $info->{idx} >= $info->{count};
      $info->{kid} = $info->{kids}->[$info->{idx}];
      
      next if $info->{kid}->{begin} && !$atstart;
      return $info if $info->{kid}->{nodetype} > 0;
      return $info if $info->{kid}->{str} eq $info->{match};
      }
   return undef;
   }
   
   
sub _Ex_WipeNodeKids
   {
   my ($node, %opt) = @_;
   
   @{$node}{qw(prepped hasexpand expanded kids kidmap xkids xkidmap)}  =
    (0, 0, 0, [], {}, [], {});
    
   return $node;
   }
   
#########################################################################

sub _ex_checkbegin
   {
   my ($node, $atstart, $word) = @_;

   return $atstart || !Ex_NodeKidField($node, $word, "begin", prep=>1);
   }


#########################################################################
#
# search type C internals
# node access / prep
#

sub Ex_PrepNode
   {
   my ($node) = @_;

   return $node if Ex_NodePrepped($node); 
   Ex_ResetNode($node,do_hasexpand=>1);
   Ex_ExpandMatchSet($node);
   Ex_NodePrepped($node,1);
   return $node;
   }

sub Ex_NodePrepped
   {
   my ($node, $val) = @_;

   $node->{prepped} = $val if scalar @_ > 1;
   return $node->{prepped};
   }

sub Ex_ResetNodes
   {
   my ($node, %opt) = @_;

   $node ||= Ex_Data(type=>"cdata");
   Ex_ResetNode($node, %opt, do_kids=>1);
   return $node;
   }

# opt
#   do_hasexpand
#   do_kids (recurse subtree)
#
sub Ex_ResetNode
   {
   my ($node, %opt) = @_;

   return unless $node;
   @{$node}{qw(xkids xkidmap expanded prepped)} = ([],{},0, 0);

   #$node->{hasexpand} = _ex_kid_callback_count($node) if $opt{do_hasexpand};
   $node->{hasexpand} = Ex_NodeKidCount($node, withcallbacks=>1) if $opt{do_hasexpand};

   map{Ex_ResetNode($_, %opt)}(@{$node->{kids} || []}) if $opt{do_kids};
   }


# opt
#   prep=>1
#   noexpanded=>1
#
sub Ex_NodeKids       #_ex_nkids
   {
   my ($node, %opt) = @_;

   return undef unless $node;
   return $node->{kids} if $opt{noexpanded};

   Ex_PrepNode($node) if $opt{prep};
   return $node->{expanded} ? $node->{xkids}: $node->{kids};
   }

# opt
#   prep=>1
#   noexpanded=>1
#
sub Ex_NodeKidMap     #_ex_nkidmap
   {
   my ($node, %opt) = @_;

   return undef unless $node;
   return $node->{kidmap} if $opt{noexpanded};

   Ex_PrepNode($node) if $opt{prep};
   return $node->{expanded} ? $node->{xkidmap}: $node->{kidmap};
   }


# opt
#   prep=>1
#   noexpanded=>1
#
sub Ex_NodeKid       #_ex_nkid
   {
   my ($node, $word, %opt) = @_;

   my $kidmap = Ex_NodeKidMap($node, %opt) || return undef;
   return $kidmap->{$word};
   }


# opt
#   prep=>1
#   noexpanded=>1
#
sub Ex_NodeKidField  #_ex_nkid_field
   {
   my ($node, $word, $field, %opt) = @_;

   my $knode = Ex_NodeKid($node,$word,%opt) || return undef;
   return $knode->{$field};
   }

#
# opt
#   prep=>1
#   noexpanded=>1
#   withcallbacks=>1
#
sub Ex_NodeKidCount   #_ex_knct
   {
   my ($node, %opt) = @_;

   my $cbcount = $opt{withcallbacks};
   $opt{noexpanded} = 1 if $cbcount;

   my $kids = Ex_NodeKids($node,%opt) || [];

   return sum(map{$_->{cname} ? 1:0}@{$kids}) if $cbcount;

   return scalar @{$kids};
   }
   
   

# opt:
#   top => undef           - top node (all data)        _
#   top => $node           - node top of tree           "h"
#   top => "word word"     - context string to top      ""
#   top => ["word","word"] - context word list to top   "a"
#      buildctx=>1         - (string,lst)
#
sub _ex_ParentFromTopOption
   {
   my ($exdata, $top, %opt) = @_;

   return $exdata unless $top;    # undef/null
   
   my $type = _reftype($top);

   return $exdata if $type eq "h"; # a node
   
#todo:
die "unsupported top type [aref] in _ex_ParentFromTopOption" if $type eq "a";
#todo:
#
#   my $chain = $type eq "a" ? $top              :
#               $type eq ""  ? Ex_MakeChain($top): 0;
   my $chain = Ex_MakeChain($top);

   return $exdata unless $chain && scalar @{$chain};

   return Ex_BuildChain($exdata, $chain) if $opt{buildctx};

   return Ex_ChainEnd($exdata, $chain);
   }

   
# opt
#   top => undef           - returns $exdata
#       => $node           - returns $node
#       => "word word ..." - returns last node of word chain
#   
#   (if top=>"word word ...")
#     buildtop => 1        - create nodes as needed to make top
#              => 0        - just follow chain
sub _Ex_Top
   {
   my ($exdata, %opt) = @_;
   
   my $top = $opt{top} or return $exdata;
   return $top if _reftype($top) eq "h"; # a node
   
   return $opt{buildtop} ? Ex_BuildContextChain($top, %opt)        :
                           Ex_ChainEnd($exdata,Ex_MakeChain($top)) ;
   }


#########################################################################
#
# search type C internals
# node callback/expansion
#

sub Ex_ExpandMatchSet
   {
   my ($node) = @_;

   return unless $node && $node->{hasexpand};

   my @xkids   = map{_ex_DoCallback($_)} @{$node->{kids}};
   my %xkidmap = map{$_->{str} => $_} @xkids;

   @{$node}{qw(xkids xkidmap expanded)} = ([@xkids],{%xkidmap},1);
   return $node;
   }


# if callback
#
#
sub _ex_DoCallback
   {
   my ($node) = @_;

   return () unless $node;
   my $cname = $node->{cname};
   return ($node) unless $cname;

   my $callback = SIExternCallback($cname) || return ($node);
   #my $aref = (ref($callback) eq "CODE") ? $callback->($cname,$node) : $callback;
   my $aref = _reftype($callback) eq "c" ? $callback->($cname,$node) : $callback;
   return ($node) unless $aref;
   $aref = [$aref] unless _reftype($aref) eq "a";

   my @def_keys = qw(begin kids kidmap); # these fields defaulted from creating node 
   my @req_keys = qw(parent level)     ; # these fields required to be from creating node 
   my @set = ();
   foreach my $entry (@{$aref})
      {
      next unless $entry;
      my $ishash = _reftype($entry) eq "h" ;

      my %nodeinfo = (xnode=>1);
      @nodeinfo{@def_keys} = @{$node}{@def_keys};
      %nodeinfo = (%nodeinfo, %{$entry}              ) if  $ishash;
      %nodeinfo = (%nodeinfo, (_Ex_ParseName($entry))) if !$ishash;
      @nodeinfo{@req_keys} = @{$node}{@req_keys};

      my $newnode = Ex_CreateNode($nodeinfo{str}, {%nodeinfo});
      push @set, $newnode;
      }
   return @set;
   }


# get/set a callback for expanding {callback} strings
#
# Callbacks are called when an external entry is of the form {cname}
# when evaluated, the entry is replaced with the entrys provided by the
# callback. 
#
# $cname ......... the name of the callback are entries 
# $value ......... the callback reference value
#
#     a callback value can be 
#      a: a string
#      b: an arrayref of strings
#      c: an arrayref of hashes
#      d: a coderef that returns a: b: or c: (fn($cname,$node))
#
#     Strings are parsed for beginmark,cname,and escapes.
#     Hashes are not parsed and must have str,begin,cname set
#       and must not have parent.
#
#   set var  is set in specified context, or current context
#   get var  uses var resolution (temp->current->global) unless
#              a context is specified
#
# %opt
#   context=>ctx .... specify context
#   global=>1 ....... returned value is restricted to specified
#   temp=>1 ......... context if one of these is defined
#   current=>1 ...... if none are defined  we use 
#                       resolution (temp->current->global)
#   resolve=>1 ...... (get) force resolution (temp->current->global)
#   delete=>1 ....... delete the callback
#   default=>ref .... provide val if callback not found
#
sub SIExternCallback
   {
   my ($cname, $value, %opt) = @_;

   return undef unless $cname;
   my $varname = "_ext_cb_" . $cname;

   my $resolve = $opt{resolve} || !AnyHasVal(@opt{qw(temp global current context)});
   my $context = $opt{context} ? $opt{context}:
                 $opt{temp   } ? "temp"       :
                 $opt{global } ? "global"     :
                                 SIContext()  ;
                 
   return _VarDelete($context, $varname => 1) if $opt{delete};
   _VarSet($context, $varname => $value     ) if $value;
   
   return V($varname=>$opt{default}) if $resolve;
   return _VarDefault($context, $varname=>$opt{default});
   }


#########################################################################
#
# external output
#
#  Ex_DataOut
# opt:
#   otype   => 1,2,3    (1=view,2=export,3=stream)
#   filespec=> 1        return as buffer
#   filename write to file
###########################################################
# -new-
# opt
#   format   => 1      # view
#            => 2      # export
#            => 3      # stream
#
#   filespec => undef | 1 # just return as buffer
#            => file      # write ro named file    
#
sub Ex_DataOut
   {
   my (%opt) = @_;
   
   $opt{format} ||= 1;
   
   my $data = Ex_TypeRoute([\&Ex_DataOutA,\&Ex_DataOutC,\&Ex_DataOutF],[%opt],%opt,no_route_val=>"");
   
   my $spec = $opt{filespec};
   
   SpillFile($spec, $data, 0) if $spec && !($spec =~ /^1$/);
   
   return $data;
   }
   
   
# opt
#   format => 1,2,3
#   
sub Ex_DataOutA
   {
   my (%opt) = @_;
   
   return CreateContextExternalStream(SIContext(),%opt) if $opt{format} == 3;
 
   # export and view are the same  
   my $exdata = Ex_Data(type=>"adata");
#   return "#adata#\n" . join("\n", @{$exdata}) . "\n";
   return join("\n", @{$exdata}) . "\n";
   }

# opt
#   format => 1,2,3
#   
sub Ex_DataOutF
   {
   my (%opt) = @_;
   
   return CreateContextExternalStream(SIContext(),%opt) if $opt{format} == 3;
 
   # export and view are the same  
   my $cwd = Ex_Data(type=>"fdata") || "";
#   return "#fdata#\n$cwd\n";
   return "$cwd\n";
   }


   
# opt:
#   format => 1,2,3
#
#   top    => undef        - top node (all data)
#          => $node        - node top of tree
#          => "word word"  - context string to top
#
#   + all Ex_NodeInfo options
#
sub Ex_DataOutC
   {
   my (%opt) = @_;
   
   return CreateContextExternalStream(SIContext(),%opt) if $opt{format} == 3;
   
   my $exdata = Ex_Data(%opt);
   my $top    = _Ex_Top($exdata, buildtop=>0, %opt);
   
#   return "#cdata#\n" . Ex_NodeInfo($top, %opt);
   return Ex_NodeInfo($top, %opt);
   }


# generates/returns a buff or extern data
#
#
# node  - top of tree  (def: all)
# opt
#   otype      => 1,2,3 - view,export,stream  (def: 1  )
#   indent     => "   " - string for indenting
#   indents    => 0     - starting indent level
#   levels     => 99    - # levels to traverse
#   lineprefix => ""    - string at start of each line
#   linesuffix => ""    - string at end of each line
#   infocol    => 45    - column for node details
#   noexpanded => 1     - exclude entries created via macro callback (def: 1 unless otype is 1)
#   prep       => 1     - expand nodes with macros
#
sub Ex_NodeInfo
   {
   my ($node, %opt) = @_;

   $node ||= Ex_Data(%opt,type=>"cdata");
   my $format  = $opt{format} || 1;
   my $nox     = $format ==1 ? 0 : 1;
   my $printfn = $format ==3 ? \&_ex_NodeStream :
                 $format ==2 ? \&_ex_NodeExport :
                               \&_ex_NodeView   ;

   %opt = ("format"   => $format ,
           noexpanded => $nox    ,
           printfn    => $printfn,
           indent     => "   "   ,
           indents    => 0       ,
           levels     => 20      ,
           lineprefix => ""      ,
           linesuffix => "\n"    ,
           infocol    => 45      ,
           prep       => 1       ,
           %opt);

   return _ex_NodeInfo($node, %opt);
   }

   
sub _ex_NodeInfo
   {
   my ($node, %opt) = @_;

   my $str = $opt{printfn}->($node, %opt);
   $opt{indents} += 1;
   $opt{levels}  -= 1;
   return $str unless $opt{levels}>0;

   my $kids = Ex_NodeKids($node,%opt);
   map{$str .= _ex_NodeInfo($_, %opt)}(@{$kids});
   return $str;
   }


#  not used. see CreateContextExternalStream()
#
sub _ex_NodeStream
   {
   my ($node, %opt) = @_;

   return "" unless $node && $node->{level};
   my $str = "";
   while ($node)
      {
      last if !$node->{level};
      my $name .= ($node->{begin} ? "^" : "") . $node->{str};
      $str = $name . ' -> ' . $str;
      $node = $node->{parent};
      }
   $str .= "\n";
   return $str;
   }


sub _ex_NodeExport
   {
   my ($node, %opt) = @_;

   return "" unless $node && $node->{level};
   my $ni   = $opt{indents} - 1;
   my $ndnt = $ni > 0 ? ($opt{indent} x $ni) : "";

   return $opt{lineprefix}               .
          $ndnt                          .
          ($node->{begin} ? "^" : "")    .
          $node->{str}                   .
          $opt{linesuffix}               ;
   }
   

sub _ex_NodeView  
   {
   my ($node, %opt) = @_;

   my ($px, $sx, $i, $ni, $icol) = @opt{qw(lineprefix linesuffix indent indents infocol)};
   my $id = $i x $ni;

   my $str = $px . $id;
   return $str . "*undef*" . $sx unless $node;
   $str .=  "^" if $node->{begin};
   $str .=  $node->{str};

   my $dots ="." x (max(3, $icol-length($str)));
   my($p,$hx,$ix,$x) = ABList("Y","N",@{$node}{qw(prepped hasexpand expanded xnode)});
   my $kct  = Ex_NodeKidCount($node);
   my $lvl  = $node->{level};
   my $typ  = $node->{nodetype};

   my $info = "prep:$p, hasx:$hx, isx:$ix, tmp:$x, lvl:$lvl kids:$kct typ:$typ";

   return $str . $dots . $info . $sx;
   }


#########################################################################
#########################################################################
#########################################################################
#########################################################################
#####
#####
#####my $sroot = Ex_Data(type=>"sdata");
#####my $node =   $sroot->{words}->{$word} 
#####   $node ||= $sroot->{words}->{$word} = Es_NewNode($word, $pre);
#####
#####   $node =   = ;
#####
#####
#####
#####sub Es_CreateInitialNode
#####   {
#####   return Es_CreateNode("--extern--");
#####   }
#####   
#####sub Es_CreateNode
#####   {
#####   my ($word) = @_'
#####   return {word=>$word, pre=>{}, post={}};
#####   }
#####
#####sub Es_FollowPath
#####
######  opt fromstart
######      last
######
#####sub Es_CreatePath
#####   {
#####   my ($str, %opt) = @_;
#####   
#####   my $sroot = Ex_Data(type=>"sdata");
#####   my $nodes = $sroot->{nodes}
#####   
#####   my $start = %opt{start} ? $sroot->{nodes} :
#####               %opt{last}  ? %opt{last}      :
#####                             $sroot->{end}   ;
#####                             
#####   $chain = Gnu::StringInput::Ex_MakeChain($str);
#####   
#####   my $pre = $start;
#####   foreach my $cnode (@{$chain})
#####      {
#####      my $node = Get_Or_Make_SNode($cnode->{word},$sroot);
#####      $pre = AddPre($node, $sroot, $pre);
#####      }
#####   }   
#####   
#####   
#####sub Get_Or_Make_SNode
#####   {
#####   ($word, $sroot) = @;
#####   
#####   return    $sroot->{nodes}->{$word}
#####          || $sroot->{nodes}->{$word} = Es_CreateNode();
#####   }
#####   
#####sub AddPre
#####   {
#####   my ($node, $sroot, $pre) = @;
#####   
#####   my $word  = $node->{word};
#####   my $pword = $pnode : $pnode->{word} : "*begin*";
#####   
#####   $node->{pre}->{$pword} = $pnode
#####   $pre->{post}->{$word}  = $node;
#####   
#####   $sroot->{end} = $node;
#####   
#####   }
#####   
########   
########sub Es_Add_Nodes
########   {
########   my ($top, $chain) = $_
########   
########   foreach my $cnode ($chain)
########      {
########      my $cword = $cnode->{word};
########      my $node = $top->{next}->{$cword} ||
########                 ($top->{next}->{$cword} = {word=>$cword, next=>{}});
########                 
########      my $preword = $pnode : $pnode->{word} : "*begin*";
########      $preword
########      
########      
########      $pre->{next}->{$cword} = $node;
########      $node->{pre}->{$preword} = $node;
########                       
########      }
########      
########      
#####sub Es_MakeNodes
#####   {
#####   my ($wordhash, $wordlist) = @_;
#####   
#####   my $start = {word=>"*start*", prevnodes=>{}, nextnodes=>{}};
#####   my $prevnode = $start;
#####   
#####   foreach my $word (@{$wordlist})
#####      {
#####      my $node = $wordhash->{$word} ||
#####                 ($wordhash->{$word} = {word=>$word});
#####      $prevnode=>{nextnodes}->{$word} = $node;
#####      $node=>{prevnodes}->{$prevword} = $prevnode
#####      $prevnode = $node;
#####      }
#####      }
#####      
#####   }      
#####   
########   
########   
########   
########   foreach my $cnode ($chain)
########      {   
########      my $word = $cnode->{word};
########     
########      my $node = $sroot->{nodes}->{$word} || Es_CreateNode($cnode);
########      
########      my $pword = $pnode ? $pnode->{word} : "*begin*";
########      
########      
########      
########      
########      }
########   
########   my $nodes = $sroot->{nodes}
########   }   
########   
########   
########   
########   
########   
########   
########   
########   
########   
########   
########   my $pre = undef;
########   foreach my $node(@{$chain})
########      {
########      Es_CreateNode($node->{word}, $pre);
########      }
########   
########   
########   
########   }
########
########   
########   
########
##############################################################################
##############################################################################
##############################################################################
##############################################################################


##############################################################################
# input
#
#


# opt:
#
#   data       => "" | []     data in opt{data}
#   filespec   => filename    data in external file
#   add        => 1           add new data to existing data
#   replace    => 1           new entries replace old ones
#   duplicates => 1           new entries dont replace old ones
#
#   type       => adata       specify type of extern data being loaded
#              => cdata       (default is context's extern type)
#              => fdata
#
#     (type cdata only)
#     format     => 2           data in export format
#                => 3           data in stream format
#                => 4           data in ctxdata format
#
#     indent     => "   "       provide indent for format 2 data
#     top        => node        specify root node for loading
#                => "word word" specify root node for loading
#
# returns    1 = ok
#            0 = nope
#
#
sub Ex_DataIn
   {
   my (%opt) = @_;

   my $root    = $opt{root}|| Ex_Root(%opt);
   my $spec    = $opt{filespec} || "1";
   my $spec_c  = $spec =~ /\.c(e)?(xt)?$/i;
   my $anycopt = $opt{indent} || $opt{format} || $opt{top} || $spec_c;
   
   my $data = $opt{data};
   delete $opt{data};
   ($data = SlurpFile($spec) || return _SetMessage(0,1,"could no read import file '$spec'"))
      unless $spec =~ /^1$/;
   
   my @counters = qw(ex_entry_added ex_entry_replaced ex_entry_skipped);
   TSetCounters(@counters); 

   my $type = $opt{type   } ? $opt{type}    : # extern type specified in opt
              $opt{settype} ? $opt{settype} : # extern type specified in opt
              $anycopt      ? "cdata"       : # type cdata implied by opt or by '.cext' file extension
                              $root->{type} ; # default to existing ctx type
                              
   my $ok = $type eq "adata" ? Ex_DataInA($data, %opt) :
            $type eq "cdata" ? Ex_DataInC($data, %opt) :
            $type eq "fdata" ? Ex_DataInF($data, %opt) :
                               0;

   my ($add,$repl,$skip) = TGetCounters(@counters);
   _SetMsg(1,1,0,"externals loaded: $add added, $repl replaced, $skip skipped");
   return $ok;
   }


# add=>1
# duplicates=>1
#
sub Ex_DataInA
   {
   my ($newdata, %opt) = @_;

   my $root   = Ex_Root(%opt);
   my $data   = $opt{add} ? $root->{adata} : [];
   my $nodups = $opt{duplicates} ? 0 : 1;
   my %here   = (map{$_=>1}@{$data});

   my $lines = ref($newdata) eq "ARRAY" ? $newdata : [split(/^/, $newdata)];

   foreach my $line (@{$lines})
      {
      chomp $line;
      my $skip = $nodups && $here{"$line"};
      TCounter("ex_entry_skipped") if $skip;
      next if $skip;
      push @{$data}, $line;
      TCounter("ex_entry_added");
      }
   $root->{adata} = $data;
   Ex_ExType("adata", %opt);
   return 1;
   }
   

#
#
#   
sub Ex_DataInF
   {
   my ($newdata, %opt) = @_;
   
   my $root = Ex_Root(%opt);
   my $data = !$newdata                 ? []      :
               ref($newdata) eq "ARRAY" ? $newdata:
               [split(/^/, $newdata)]             ;

   # todo: unsymmetric: fdata data (cwd) is set by Ex_ExType
   $opt{cwd} ||= (scalar(@{$data}) ? $data->[0] : "");
   Ex_ExType("fdata", %opt);
   return 1;
   }
   
   
   

# opt
#   indent
#   add
#      ctx     =>"word word"
#      chain   =>["word","word"]
#      replace =>1
#
#      inctx   =>1
#      buildctx=>1
#
# SIExternal(data=>"foo", add=>1                    ) 
# SIExternal(data=>"foo", add=>1, ctx=>"this is"    ) 
# SIExternal(data=>"foo", add=>1, chain=>["this","is"]) 
# SIExternal(data=>"this is foo", add=>1, inctx=>1) # single line only
#xxx SIExtern(data=>"foo", add=>1, parent=>$node) 
#
# opt
#   indent
#   add
#     top => undef           - top node (all data)        _
#     top => $node           - node top of tree           "h"
#     top => "word word"     - context string to top      ""
#     top => ["word","word"] - context word list to top   "a"
#         buildctx=>1         - (string,lst)
#     replace =>1
#     inctx   =>1
#     buildctx=>1
#
# SIExternal(data=>"foo", add=>1                    ) 
# SIExternal(data=>"foo", add=>1, top=>"this is"    ) 
# SIExternal(data=>"foo", add=>1, top=>["this","is"]) 
# SIExternal(data=>"this is foo", add=>1, inctx=>1) # single line only
#xxx SIExtern(data=>"foo", add=>1,top=>$node) 
#
#sub Ex_DataInC
#   {
#   my ($newdata, %opt) = @_;
#
#   my $root = Ex_Root(%opt);
#   my $exdata  = Ex_Data(type=>"cdata");
#
#   if (!$opt{add})
#      {
#      $root->{cdata} = _Ex_ParseDataC($exdata, $newdata, %opt);
#      Ex_ExType("cdata",%opt);
#      }
#   
#   if ($opt{inctx})
#      {
#      my $chain      = Ex_MakeChain($newdata, wordregex=>qr/(\w|\\|\:|\.)+|(\{[^\}]*\})/);
#      
#      my @chainwords = map{$_->{word}} @{$chain};
#      $newdata       = pop @chainwords        if scalar @chainwords;
#      $opt{top}      = join(" ", @chainwords) if scalar @chainwords;
#      $opt{buildctx} = 1;
#      
#      }
#
#   $exdata = $root->{cdata} = Ex_CreateInitialNode() unless $exdata;
#   
#  
#   my $top = _ex_ParentFromTopOption($exdata, $opt{top}, %opt);
#   
#   $root->{cdata} = _Ex_ParseDataC($top, $newdata, %opt);
#
#   Ex_ExType("cdata",%opt);
#   return 1;
#   }


# opts
#   indent => "   "         - provide indent format for cdata data in delimited (export)
#   inctx  =>1              - new data is lines of words, strings, all words are added, building out context
#   top  => undef        - start at top of cdata
#        => "word word .."  - provide word list to parent of new data
#        => $node        - provide parent of new data
#   add  => 0            - clears from parent down
#        => 1            - adds to data
#   replace => 0       - new data words matching existing words are skipped
#           => 1       - new data words replace matching existing words
#
# example uses (called thru SIExternal):
#     SIExternal(import=>"a.cext");
#     SIExternal(import=>"b.cext", add=>1, type=>"cdata");
#     SIExternal(data=>"list opt", top=>"help", inctx=>1)
#
# format => 2   - export
#        => 3   - stream
#        => 4   - ctxdata
#
sub Ex_DataInC
   {
   my ($newdata, %opt) = @_;

   my $root   = Ex_Root(%opt);
   my $exdata = $root->{cdata};
   my $top    = _Ex_Top($exdata, buildtop=>1, %opt);
   my $deff   = $opt{ctxdata} ? 4 : 2;
   
   _Ex_WipeNodeKids($top) unless $opt{add};
   
   $root->{cdata} = _Ex_ParseDataC($top, $newdata, format=>$deff, %opt);
   Ex_ExType("cdata",%opt);
   return 1;
   }

   

## opts:
##  indent
##  
##
#sub _Ex_ParseDataC
#   {
#   my ($top, $data, %opt) = @_;
#
#   my $indenter = $opt{indent} || "   ";
#   my $linetype = $indenter =~ /^stream/ ? 1 : 0;
##  my $ndntlen  = length $indenter;
#   my $ndnt     = quotemeta($indenter);
#
#   my @curr     = _Ex_MakeCurrentMap($top);
#   my $toplevel = $top->{level};
#   my $parsefn  = $linetype ? \&_Ex_ParseStreamLine : \&_Ex_ParseIndentLine;
#   my $lines    = ref($data) eq "ARRAY" ? $data : [split(/^/, $data)];
#   my %common   = (insert=>1, replace=>$opt{replace});
#
#   foreach my $line (@{$lines})
#      {
#      chomp $line;
#      my $defs = $parsefn->($line, $ndnt);
#      foreach my $fields (@{$defs})
#         {
#         next unless $fields->{str};
#         $fields->{level } = $fields->{level} + $toplevel; # for additions
#         $fields->{parent} = $fields->{level} ? $curr[$fields->{level}-1] : 0;
#         my $newnode = Ex_CreateNode($fields->{str}, {%{$fields}}, %common);
#         $curr[$fields->{level}] = $newnode if $fields->{level};
#         }
#      }
#
#   return $curr[0];
#   }
   
#   
#   
# dataformat=>undef      (use opt $opt{indent})
#           =>incontext
#           =>stream
#           =>indented
#   
# indent
# replace  
#   
sub _Ex_ParseDataC
   {
   my ($top, $data, %opt) = @_;

   my $indenter = $opt{indent} || "   ";
   my $format   = $opt{format};
                                            
   my $parsefn = $format == 4 ? \&_Ex_ParseInContextLine : 
                 $format == 3 ? \&_Ex_ParseStreamLine    : 
                                \&_Ex_ParseIndentLine    ;
                                              
   my $ndnt     = quotemeta($indenter);
   my @curr     = _Ex_MakeCurrentMap($top);
   my $toplevel = $top->{level};
   my $lines    = ref($data) eq "ARRAY" ? $data : [split(/^/, $data)];
   
   my %common   = (insert=>1, replace=>$opt{replace});

   foreach my $line (@{$lines})
      {
      chomp $line;
      my $defs = $parsefn->($line, $ndnt);
      foreach my $fields (@{$defs})
         {
         next unless $fields->{str};
         $fields->{level } = $fields->{level} + $toplevel; # for additions
         $fields->{parent} = $fields->{level} ? $curr[$fields->{level}-1] : 0;
         my $newnode = Ex_CreateNode($fields->{str}, {%{$fields}}, %common);
         $curr[$fields->{level}] = $newnode if $fields->{level};
         }
      }
   return $curr[0];
   }

   

sub _Ex_MakeCurrentMap
   {
   my ($node) = @_;

   my @curr = map{0}(1..50);
   while ($node)
      {
      $curr[$node->{level}] = $node;
      $node = $node->{parent};
      }
   return @curr;
   }


sub _Ex_ParseStreamLine
   {
   my ($line) = @_;

   my ($begin, $level, $entry) = $line =~ /^(0|1):(\d+):(.*)$/;
   return (0,0,"") unless $entry;
   $entry = TrimNS($entry, 0, 1);
   my %ret = _Ex_ParseName($entry, nameonly=>1);
   return [{%ret,level=>$level,begin=>$begin}];
   }


sub _Ex_ParseIndentLine
   {
   my ($line, $ndnt) = @_;

   $line = TrimNS($line, 0, 1);

   return [{_Ex_ParseName($line, indenter=>$ndnt)}];
   }
   
sub _Ex_ParseInContextLine
   {
   my ($line) = @_;
   
   state $rx = qr/(\w|\\|\:|\.)+|(\{[^\}]*\})/;
   
   my $defs = [];
   my $chain = Ex_MakeChain($line, nousecache=>1, nosavecache=>1, wordregex=>$rx);
   for my $i (0.. scalar(@{$chain})-1)
      {
      my $entry = $chain->[$i];
      my %fields = _Ex_ParseName($entry->{word}, nameonly=>1);
      push @{$defs}, {%fields,level=>$i+1,begin=>0};
      }
   return $defs;
   }   
   
#   my ($begin, $level, $entry) = $line =~ /^(0|1):(\d+):(.*)$/;
#   return (0,0,"") unless $entry;
#   $entry = TrimNS($entry, 0, 1);
#   my %ret = _Ex_ParseName($entry, nameonly=>1);
#   return [(%ret,level=>$level,begin=>$begin)];
#   }




#
sub Ex_BuildChain
   {
   my ($parent, $chain) = @_;
   
   my $node = $parent;
   foreach my $entry (@{$chain})
      {
      my $word = $entry->{word};
      $node = $node->{kidmap}->{$word} || Ex_CreateNode($word, {parent=>$node}, insert=>1);
      }
   return $node;
   }
   
   
sub Ex_BuildContextChain
   {
   my ($str, %opt)  = @_;
   
   my $top   = Ex_Data(type=>"cdata");
   my $chain = Ex_MakeChain($str);
   my $node  = Ex_BuildChain($top, $chain);
   return $node;
   }
   


# parent, begin, 
#
# nodestr .......node's string
#
# fields ....... fields that may be set:
#     parent ..... parent node
#     level ...... node level
#     begin ...... extern at beginning of line only
#     cname ...... callback name
#     kids ....... kids array
#     kidmap ..... kids hash
# %opt ......... create options:
#     insert=>1..... add node to extern tree (adds to parents child lists)
#                     needs parent to be passed, sets node level.
#     replace=>1.... replace if its in tree already (with insert)
#     parsename=>1.. parse nodestr (extract begin, cname, str, and unescapes)
#
# new::::::::::
# fields ....... fields that may be set:
#     nodetype .... type if identifier
# %opt <for now>
#     nodetype=0 regular ident  
#              1 match any
#              #2 match regex
#
sub Ex_CreateNode
   {
   my ($nodestr, $fields, %opt) = @_;

   $fields ||= {};

   my %defaults = (parent => 0 , prepped   => 0 , # todo: 
                   level  => 0 , hasexpand => 0 , # move state flags 
                   cname  => "", expanded  => 0 , # to TVar(node_id) ...
                   begin  => 0 , xnode     => 0 , 
                   kids   => [], kidmap    => {},
                   exdir  => "", nodetype  =>0  ,);
   my %nameinfo = $opt{parsename} ? (_Ex_ParseName($nodestr)) : (str=>$nodestr);

   my $id = _Ex_MakeNodeID();

   # passed fields override defaults, parsed vals overrride passed fields
   my $node = {%defaults, %{$fields}, %nameinfo, id => $id};

   TCounter("ex_node_created");

   return $node unless $opt{insert};

   # last is adding to parent
   return Ex_InsertNode($node, %opt);
   }


sub Ex_CreateInitialNode
   {
   return Ex_CreateNode("--extern--");
   }


# returns child
#
sub Ex_InsertNode
   {
   my ($node, %opt) = @_;

   return unless $node && $node->{parent};

   my $str    = $node->{str};
   my $parent = $node->{parent};
   my $setk   = !$node->{xnode};     # dont add to reg matchset if a tmp node
   my $setx   = $parent->{expanded}; # add to exp matchset if it exists

   if (my $old = $parent->{kidmap}->{$str})
      {
      map{$old->{$_}=$node->{$_}}(keys %{$node}) if $opt{replace};
      TCounter("ex_entry_replaced") if $opt{replace};
      TCounter("ex_entry_skipped") if !$opt{replace};
      return $old;
      }
   $node->{level} = $parent->{level} + 1;
   push(@{$parent->{kids }}, $node)    if $setk; 
   push(@{$parent->{xkids}}, $node)    if $setx;
   $parent->{kidmap }->{$str} = $node  if $setk;
   $parent->{xkidmap}->{$str} = $node  if $setx;

   Ex_NodePrepped($parent,0) if ($setk && $node->{cname});

   TCounter("ex_entry_added");
   return $node;
   }

# parse a nodestring of the form
#
#(indent)(beginmark)(string)
#(indent)    : (indenter)*
#(beginmark) : '^'?
#(string)    : ident          -or-  # an identifier                nodetype 0 exact match
#              {ident}        -or-  # a callback                   nodetype 1 expanded out
#              {exfiles}      -or-  # extern file                  nodetype 2 matches any
#              {exfiles:dir}  -or-  # extern file with a start dir nodetype 2 matches any
#              {any}          -or-  # match any ident              nodetype 3 matches any
#
# options:
#     nameonly => 1  .... dont parse indent or begin        (ex: from stream)
#     indenter => str ... indent string. default is "   "   (ex: from export)
#
# return:
#     {str     =>str ,   # str            (without indent or beginmark unless 'nameonly')
#      level   =>int ,   # indent level   (present unless 'nameonly')
#      begin   =>bool,   # had begin mark (present unless 'nameonly')
#      cname   =>str ,   # ident          (present if nodetype > 0)
#      exdir   =>dir ,   # external dir   (present if nodetype = 2)
#      nodetype=>int }   # type of node   0..3 see above
#
# old stuff:
#      xxxxindent=>1 ..... if any are specified, only those 
#      xxxxbegin =>1 ..... specified are done. if none speced
#      xxxxcname =>1 ..... all are done
#      xxxxescapes=>1 .... parse char escapes
#
sub _Ex_ParseName
   {
   my ($str, %opt) = @_;
   
   my $info = {str => $str};
   my $i    = $opt{indenter} || "   ";
   
   _Ex_ParseIndent($info,$i) unless $opt{nameonly};
   _Ex_ParseBegin ($info   ) unless $opt{nameonly};
   _Ex_ParseCName ($info   ); 
   
   return %{$info};
   }


sub _Ex_ParseIndent
   {
   my ($info, $indenter) = @_;

   return unless $indenter && length $indenter;
   $info->{level} = 1;

   while(1)
      {
      my ($newstr) = $info->{str} =~ /^$indenter(.*)$/;
      return unless $newstr && length $newstr;
      $info->{str  }  = $newstr;
      $info->{level} += 1;
      }
   }


sub _Ex_ParseBegin
   {
   my ($info) = @_;
   
   @{$info}{"begin","str"} = $info->{str} =~ /^(\^?)(.*)$/;
   
   $info->{begin} = $info->{begin} ? 1 : 0;
   }


sub _Ex_ParseCName
   {
   my ($info) = @_;
   
   @{$info}{qw(cname nodetype exdir)} = ("", 0, "");
   
   my ($cname, undef, $exdir) = $info->{str} =~ /^\{([^:]+)(:(.*))?\}$/;
   return unless $cname;
   
   $info->{cname   }  = $cname;
   $info->{exdir   }  = $exdir || "";
   $info->{nodetype}  = $cname =~ /^exfiles/i ? 2 : $cname =~ /^any/i ? 3 : 1;
   }



sub _Ex_MakeNodeID
   {
   return GVar(ecnodeid => GVarInit(ecnodeid => 0) + 1);
   }


# no_route_val
# no_route_msg
#
sub Ex_TypeRoute
   {
   my ($fns,$params,%opt) = @_;

   my $type = SIExternal(gettype=>1, %opt) || "";

   my @types = qw(adata cdata fdata);
   foreach my $i (0..2)
      {
      next unless $type eq $types[$i];
      my $fn = $fns->[$i];
      return $fn ? $fn->(@{$params}) : _Ex_NoTypeRoute($type,$params,%opt);
      }
   return _Ex_NoTypeRoute($type,$params,%opt);
   }

sub _Ex_NoTypeRoute
   {
   my ($type,$params,%opt) = @_;

   my $ret = exists $opt{no_route_val} ? $opt{no_route_val} : undef;
   return $ret unless $opt{no_route_msg};
   print "\n", "Err: no route '$type': $opt{no_route_msg}\n";
   return $ret;
   }

################################################################################
################################################################################
################################################################################



# -internal-
#
sub Ex_CreateStream
   {
   my (%opt) = @_;

   return "" if SkipStream(0, "external", %opt);
   
   SIContext({push=>1});
   my $stream = "";
   foreach my $context (SIContext({ctxlist=>1,all=>1}))
      {
      $stream .= CreateContextExternalStream($context, %opt);
      }
   SIContext({pop=>1});
   return $stream;
   }

sub CreateContextExternalStream
   {
   my ($context, %opt) = @_;

   SIContext($context);
   return "" if SkipStream($context, "external", %opt);
   
   my ($exdata, $refctx) = (Ex_Data(noref=>1), SIExternal(getref=>1,noref=>1));
   return "siextr:$refctx\n" if $refctx;
   return Ex_TypeRoute([\&Ex_GenStreamA,\&Ex_GenStreamC,\&Ex_GenStreamF],[$exdata,$context],%opt,no_route_val=>"");
   }

sub Ex_GenStreamA
   {
   my ($exdata, $context) = @_;

   my $buff = "";
   map{$buff .= "siexta:$context:$_\n"} (@{$exdata});
   return $buff;
   }

sub Ex_GenStreamC
   {
   my ($node, $context) = @_;

   return "" unless $node;
   my $buff = "siextc:$context:$node->{begin}:$node->{level}:$node->{str}\n";
   my $kids = $node->{kids} || [];
   map{$buff .= Ex_GenStreamC($_, $context)}(@{$kids});
   return $buff;
   }

sub Ex_GenStreamF
   {
   my ($exdata, $context) = @_;
   return "siextf:$context:$exdata\n";
   }



# todo: change e: ce:  to exta: extc:
#
sub Ex_LoadStream
   {
   my ($stream, %opt) = @_;

   return 0 if SkipStream(0, "external", %opt);
   
   my $data = {a=>{},c=>{},f=>{},r=>{}};

   foreach my $line(split(/\n/, $stream)) 
      {
      $line = CleanInputLine($line,1,0);
      my ($type,$context,$entry) = $line =~ /^siext([acfr]):([^:]+):(.*)$/;

      next unless $type && $context;
      $entry = "" unless defined $entry;
      $data->{$type}->{$context} = [] if !exists $data->{$type}->{$context};
      push(@{$data->{$type}->{$context}}, $entry);
      }
   SIContext({push=>1});

   foreach my $type (qw(a c f r))
      {
      my $set = $data->{$type};
      foreach my $context (keys %{$set})
         {
         SIContext($context);
         
         next if SkipStream($context, "external", %opt);
         
         my $exdata = $set->{$context};

         $type =~ /^a$/  ? SIExternal(data=>$exdata,settype=>"adata",noref=>1)              :
         $type =~ /^c$/  ? SIExternal(data=>$exdata,settype=>"cdata",noref=>1,format=>3)    :
         $type =~ /^f$/  ? SIExternal(data=>$exdata,settype=>"fdata",noref=>1,cwd=>$exdata) :
         $type =~ /^r$/  ? SIExternal(setref=>$exdata)                                      :
                           0;#noop
         }
     }
   SIContext({pop=>1});
   return 1;
   }
   

1;

# extern view [options] 'context'
#
# Where:
#    'context' (undef | ctxname | global | all) # current context is used as default
#    [options] are 0 or more of:
#
#
#
#
#
# is name of context to view or empty for current context i
#
#
#
#
# extern info 
#   (shows: root, type, externcount, options, cwd, etc...)
#
# extern import [options] {filespec}
#
#    where [options] are 0 or more of
#      /type   ="cdata"
#      /top    ="aaa bbb" 
#      /format = 0-4 
#      /indent = "   "
#      /levels
#
#
#
#
#
#
#
#
# extern export  [/top="aaa bbb"]
# extern settype
# extern clear
# extern getref
# extern setref
#
#
#
#
# extern show

# extern add str
# extern addc str
# extern clear
# extern load  file
# extern loadc file
# extern addf  file
# extern addfc file
# extern setref ctx
# extern setf dir
# extern settype dtype

#
#
# extern show    /format=n /top=""
# extern import  /top=""
# extern export  /top=""
# extern clear
#
#
#
#
#