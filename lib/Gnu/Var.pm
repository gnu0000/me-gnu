##
## Var.pm - variables storage
##
##
## synopsis:
##
##
## fns:
##    VarContext
##    Var
##    Vars
##    VarGet
##    VarExists 
##    VarDelete 
##    VarSet
##    VarDefault
##    VarInit   
##    VarMake   
##    InitVars
##    ResolveVar    (V)
##    ResolveVars   (VV)
##    ResolveVarsd  (VVd)
##    InitVarContext
##
## use:
#
# VarContext()                         get current ctx name
# VarContext(new_ctx)                  set current ctx name
# VarContext({option =>val})           various
# VarContext({option =>val},new_ctx)   various (currently, only push needs a new ctx)
# VarContext({push   =>1  },new_ctx)   push ctx name
# VarContext({pop    =>1  })           pop  ctx name
# VarContext({ctxlist=>1  })           return array of ctx names
# VarContext({varlist=>1  })           return list of var names in context
# VarContext({ctxdata=>1  })           return map of var names/vals in context
# VarContext({clear  =>1  })           delete everything from context
# VarContext({delete =>1  })           delete everything from context
# VarContext({reset  =>{} })           delete everything from context, add ref elements
#
#
#
#
#
# (name               )      val         [get val)
# (name=>val          )      val         [set, create if needed)
# (name=>val,..       )      (val,...)   [set, returns array)
# (_delete_name=>1    )      1|0         [delete, returns 1 or 0 in scalar ctxt]
# (_exists_name=>1    )      1|0         [existance check]
# (_init_name=>initval)      val|initval [create set, return initval if new, or ret val]
# (_default_name=>defval)    val|defval  [return val if exists, or ret defval]
#
# possible modifiers (prefix in var identifier):
#  _delete_
#  _exists_
#  _init_
#  _default_
##
##
##
##
## *level 0*
##
## VarContext()                      get current ctx name
## VarContext(ident)                 set current ctx name
## VarContext({},ident)              various: options: clear=>1, init=>{}, getlist=>1, push=>1, pop=>1
## VarContext({list   =>1}       )   return array of ctx names                                       
## VarContext({push   =>1}, ident)   push ctx name
## VarContext({pop    =>1}       )   pop  ctx name
## VarContext({clear  =>1}       )   delete everything from context
## VarContext({varlist=>1}       )   return list of var names in context
## VarContext({varmap =>1}       )   return map of var names/vals in context
##
##                                            
##                                            
##  fn       params                   return  
## ---------------------------------------------------------------------------------
## Var()                      #  undef                           scalar   # (_exists_ident, _delete_ident)
## Var(ident)                 #  ident val                       scalar   # (_exists_ident, _delete_ident)
## Var(ident=>val)            #  set var,  return val            scalar   # (_default_ident=>val, _init_ident=>val, _exists_ident=>1, _delete_ident=>1) 
## Var(ident=>val,ident=>val) #  set vars, return array          array   
## Var({opt},)                #  undef                           scalar   # (_exists_ident, _delete_ident)
## Var({opt},ident)           #  ident val                       scalar   # (_exists_ident, _delete_ident)
## Var({opt},ident=>val)      #  set var,  return val            scalar   # (_default_ident=>val, _init_ident=>val, _exists_ident=>1, _delete_ident=>1) 
## Var({opt},ident=>val...)   #  set vars, return array          array   
#  Var({opt},ident)           #  set vars, return hash           href
#
## Vars      ()                               
## Vars      (name)                           
## Vars      (name,name,name)                 
#                                             
#                                             
## VarGet    ()                               
## VarSet    (name                            
## Vars      (name                            
##           (name                            
##           (name                            
##           (name                            
## Vars      (                                
## VarGet    (                                
## VarSet    (                                
## VarDefault(                                
## VarInit   (                                
## VarExists (                                
## VarDelete (                                
## VarMake   (                                
##                                            
#                                             
#
#
#
# DelContext (context);
# InitContext(context,ref)   (context,name=>val,name=>val,name=>val)
#
# Var    (context,name               )      val         [get val)
#        (context,name=>val          )      val         [set, create if needed)
#        (context,name=>val,..       )      (val,...)   [set, returns array)
#        (context,_exists_name=>1    )      1|0         [existance check]
#        (context,_delete_name=>1    )      1|0         [delete, returns 1 or 0 in scalar ctxt]
#        (context,_default_name=>defval)    val|defval  [return val if exists, or ret defval]
#        (context,_init_name=>initval)      val|initval [create set, return initval if new, or ret val]
#
#x Vars  (context)                          {}          [hashref of all ctx vars]
#x Vars  (context,name,name...)             (val,val)   [array og get vals]
#
# VarGet    
#           (context,name,name...)           (val,val...)
# VarExists 
#           (context,name,name...)           (1|0,1|0...)
# VarDelete 
#           (context,name,name...)           (1|0,1|0...)
# VarSet    
#           (context,name=>val,name=>val...) (val,val...)
#           (context,{href})
# VarDefault
#           (context,name=>val,name=>val...) (val,val...)
# VarInit   
#           (context,name=>val,name=>val...) (val,val...)
# VarMake   
#           (context,val...)                 (name,name...)

#x SaveVars(%options)         {context=>ctx,skip=>ctx}
#x LoadVars(data,%options)    {context=>ctx,skip=>ctx
#
#
#
#--------------------------------------------------------------------------
# *level 1*
#
# VarContext()                  (context)
# xPushContext(context)  
# xPopContext()
#
# GVar () (context=global)
# CVar () (context=current)
# TVar () (context=temp)
#
#
package Gnu::Var;

use warnings;
use strict;
use feature 'state';
use Gnu::ListUtil qw(Tuples);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(VarContext InitVars InitGVars InitTVars InitCVars
                    _Var _Vars _VarGet _VarSet _VarDefault _VarInit _VarExists _VarDelete _VarGen
                     Var  Vars  VarGet  VarSet  VarDefault  VarInit  VarExists  VarDelete  VarGen
                    GVar GVars GVarGet GVarSet GVarDefault GVarInit GVarExists GVarDelete GVarGen
                    TVar TVars TVarGet TVarSet TVarDefault TVarInit TVarExists TVarDelete TVarGen
                    CVar CVars CVarGet CVarSet CVarDefault CVarInit CVarExists CVarDelete CVarGen
                    ResolveVar   V
                    ResolveVars  VV
                    ResolveVarsd VVd);

our %EXPORT_TAGS = (MIN   =>[qw(VarContext Var  Vars  VarGet  VarSet VarExists ResolveVar ResolveVars        )],
                    BASE  =>[qw(VarContext InitVars InitGVars InitTVars InitCVars
                                Var  Vars  VarGet  VarSet  VarDefault  VarInit  
                                VarExists  VarDelete  VarGen ResolveVar  ResolveVars ResolveVarsd            )],
                    SYS   =>[qw(_Var _Vars _VarGet _VarSet _VarDefault _VarInit _VarExists _VarDelete _VarGen)],
                    V     =>[qw( Var  Vars  VarGet  VarSet  VarDefault  VarInit  VarExists  VarDelete  VarGen)],
                    G     =>[qw(GVar GVars GVarGet GVarSet GVarDefault GVarInit GVarExists GVarDelete GVarGen)],
                    T     =>[qw(TVar TVars TVarGet TVarSet TVarDefault TVarInit TVarExists TVarDelete TVarGen)],
                    C     =>[qw(CVar CVars CVarGet CVarSet CVarDefault CVarInit CVarExists CVarDelete CVarGen)],
                    SHORTS=>[qw(V VV VVd                                                                     )],
                    ALL   =>[@EXPORT_OK                                                                       ],
                  );
                    

our $VERSION   = 0.10;

# constants
my $CTX_DEFAULT = "default"   ;
my $CTX_GLOBAL  = "global"    ;
my $CTX_TEMP    = "temp"      ;

my $MOD_NONE    = 0;
my $MOD_DEFAULT = 1;
my $MOD_INIT    = 2;
my $MOD_EXISTS  = 3;
my $MOD_DELETE  = 4;
my $MOD_GEN     = 5;

my $TYPE_N  = 1;
my $TYPE_NV = 2;


#
# context
#
###############################################################################


# VarContext()                         get current ctx name
# VarContext(new_ctx)                  set current ctx name
# VarContext({option =>val})           various
# VarContext({option =>val},new_ctx)   various (currently, only push needs a new ctx)
# VarContext({push   =>1  },new_ctx)   push ctx name
# VarContext({pop    =>1  })           pop  ctx name
# VarContext({ctxlist=>1  })           return array of ctx names
# VarContext({varlist=>1  })           return list of var names in context
# VarContext({ctxdata=>1  })           return map of var names/vals in context
# VarContext({clear  =>1  })           delete everything from context
# VarContext({delete =>1  })           delete everything from context
# VarContext({reset  =>{} })           delete everything from context, add ref elements
#
sub VarContext
   {
   my ($opt, $o_ct, $p_ct, $new_ctx) = _ctx_prep_params(@_);

   state $ctx   = $CTX_DEFAULT;
   state $stack = [];
   my $old_ctx = $ctx;
  
   return $ctx                                  unless $o_ct || $p_ct; #VarContext()                   get current ctx name
   push(@{$stack}, $ctx)                        if $opt->{push};       #VarContext({push=>1}, newctx)  push ctx name, change to newctx
   $ctx = $new_ctx                              if $new_ctx;           #VarContext(ident)              set current ctx name

   $ctx = pop(@{$stack})   if scalar @{$stack}  && $opt->{pop};        #VarContext({pop=>1})           pop  ctx name
   return _InitContext($ctx)                    if $opt->{clear};      #VarContext({clear  =>1  })     delete everything from context
   return _InitContext($ctx,$opt->{reset})      if $opt->{reset};      #VarContext({reset  =>{} })     delete everything from context, add ref elements

   return (sort keys %{_cdata($ctx)})     if $opt->{varlist};    #VarContext({varlist=>1  })     list of var names in context
   return _cdata($ctx)                    if $opt->{ctxdata};    #VarContext({=>1  }) actual     data of context
   return _ContextList($opt->{all})       if $opt->{ctxlist};    #VarContext({ctxlist=>1  })     return array of ctx names
   return _DeleteContext($ctx)            if $opt->{delete};     #VarContext({delete=>1})        eradicate context
   return $ctx;
   }


sub _ContextList
   {
   my ($include_all) = @_;

   #my @ctxs = sort keys %{_adata()};
   #return @ctxs if $include_all;
   #return grep{!/^($CTX_GLOBAL)|($CTX_TEMP)$/} @ctxs;

   my @ctxs = grep{!/^($CTX_GLOBAL)|($CTX_TEMP)$/} (sort keys %{_adata()});
   push @ctxs, ($CTX_GLOBAL, $CTX_TEMP) if $include_all;
   return @ctxs;
   }


sub InitVarContext{_InitContext(@_)}
sub _InitContext
   {
   my $ctx    = shift;
   my ($href) = @_;
   my $parmct = scalar @_;

   my $all = _adata();
   my $hash_init = $parmct == 1 && $href && ref($href) eq "HASH";
   $all->{$ctx}  = $hash_init ? {%{$href}} : {}; # {%{$href}}
   _ident_nvl($all->{$ctx},@_)  if $parmct > 1;
   return $all->{$ctx};
   }


# params:
#  (ctx)
# ret:
#  bool  was there a ctx to delete
#
sub _DelContext
   {
   my ($ctx) = @_;

   my $all = _adata();
   my $here = exists $all->{$ctx};
   delete $all->{$ctx} if $here;
   return $here;
   }



sub _ctx_prep_params
   {
   my ($opts,@plist) = @_;

   if (scalar @_ && $opts && ref ($opts) eq "HASH")
      {
      my $oct = scalar (keys %{$opts});
      return ($opts, $oct, scalar @plist, @plist);
      }
   return ({}, 0, scalar @_, @_);
   }


# 
#
###############################################################################


# _Var(context,name               )      val         [get val)
# _Var(context,name=>val          )      val         [set, create if needed)
# _Var(context,name=>val,..       )      (val,...)   [set, returns array)
# _Var(context,_delete_name=>1    )      1|0         [delete, returns 1 or 0 in scalar ctxt]
# _Var(context,_exists_name=>1    )      1|0         [existance check]
# _Var(context,_init_name=>initval)      val|initval [create set, return initval if new, or ret val]
# _Var(context,_default_name=>defval)    val|defval  [return val if exists, or ret defval]
#
# possible modifiers (prefix in var identifier):  _delete_name  _exists_name  _init_name  _default_name
#
sub _Var
   {
   my ($vars, $opt, $optct, $parmct, @params) = _var_prep_params(@_);

   return $parmct == 0 ? undef                     :
          $parmct == 1 ? _ident_n  ($vars,@params) :
          $parmct == 2 ? _ident_nv ($vars,@params) :
                         _ident_nvl($vars,@params) ;
   }

# Vars   (context)               {}          [hashref of all ctx vars]
# Vars   (context,name,name...)  (val,val)   [array of get vals]
# modifiers ok
#
sub _Vars{_VarGet(@_)};
sub _VarGet
   {
   my ($vars, $opt, $optct, $parmct, @params) = _var_prep_params(@_);

   return $parmct == 0 ? $vars               :
          $parmct == 1 ? _ident_n ($vars,@params) :
                         _ident_nl($vars,@params) ;
   }


#  (context,name...)
#  no modifiers on name
#
sub _VarExists
   {
   my ($vars, $opt, $optct, $parmct, @params) = _var_prep_params(@_);

   return $parmct == 0 ? undef                                  :
          $parmct == 1 ? _var_exists($vars,@params)             :
                         _var_nl_mod($vars,$MOD_EXISTS,@params) ;
   }


#  (context,name...)
#  no modifiers on name
#
sub _VarDelete
   {
   my ($vars, $opt, $optct, $parmct, @params) = _var_prep_params(@_);

   return $parmct == 0 ? undef                             :
          $parmct == 1 ? _var_delete($vars,@params)             :
                         _var_nl_mod($vars,$MOD_DELETE,@params) ;
   }


# VarSet    (context,name=>val)              val
#           (context,name=>val,name=>val...) (val,val...)
#           (context,{href})
# modifiers ok
#
sub _VarSet
   {
   my ($vars, $opt, $optct, $parmct, @params) = _var_prep_params(@_);

   return $parmct == 0 ? undef                 :
          $parmct == 1 ? _ident_hr ($vars,@params)  :
          $parmct == 2 ? _ident_nv ($vars,@params)  :
                         _ident_nvl($vars,@params)  ;
   }


#  (context,name=>val...)
#  no modifiers on name
#
sub _VarDefault
   {
   my ($vars, $opt, $optct, $parmct, @params) = _var_prep_params(@_);

   return $parmct == 0 ? undef                               :
          $parmct == 1 ? undef                               :
          $parmct == 2 ? _var_default($vars,@params)              :
                         _var_nvl_mod($vars,$MOD_DEFAULT,@params) ;
   }


#  (context,name=>val...)
#  no modifiers on name
#
sub _VarInit
   {
   my ($vars, $opt, $optct, $parmct, @params) = _var_prep_params(@_);

   return $parmct == 0 ? undef                            :
          $parmct == 1 ? undef                            :
          $parmct == 2 ? _var_init   ($vars,@params)           :
                         _var_nvl_mod($vars,$MOD_INIT,@params) ;
   }


sub _VarGen
   {
   my ($vars, $opt, $optct, $parmct, @params) = _var_prep_params(@_);

   return $parmct == 0 ? _var_gen($vars,0 )                 :
          $parmct == 1 ? _var_gen($vars,@params)            :
                         _var_nl_mod($vars,$MOD_GEN,@params);
   }



sub _var_prep_params
   {
   my $ctx = shift;
   my ($opts,@plist) = @_;

   if (scalar @_ && $opts && ref ($opts) eq "HASH")
      {
      my $oct = scalar (keys %{$opts});
      $ctx = $opts->{context} || $opts->{ctx} || $ctx;
      $ctx = $CTX_GLOBAL if $opts->{global};
      $ctx = $CTX_TEMP   if $opts->{temp};

      return (_cdata($ctx), $opts, $oct, scalar @plist, @plist);
      }
   return (_cdata($ctx), {}, 0, scalar @_, @_);
   }


# externals - level 1
#
###############################################################################


sub Var        {_Var       (VarContext(), @_)}
sub Vars       {_Vars      (VarContext(), @_)}
sub VarGet     {_VarGet    (VarContext(), @_)}
sub VarExists  {_VarExists (VarContext(), @_)}
sub VarDelete  {_VarDelete (VarContext(), @_)}
sub VarSet     {_VarSet    (VarContext(), @_)}
sub VarDefault {_VarDefault(VarContext(), @_)}
sub VarInit    {_VarInit   (VarContext(), @_)}
sub VarGen     {_VarGen    (VarContext(), @_)}

sub GVar       {_Var       ($CTX_GLOBAL , @_)}
sub GVars      {_Vars      ($CTX_GLOBAL , @_)}
sub GVarGet    {_VarGet    ($CTX_GLOBAL , @_)}
sub GVarExists {_VarExists ($CTX_GLOBAL , @_)}
sub GVarDelete {_VarDelete ($CTX_GLOBAL , @_)}
sub GVarSet    {_VarSet    ($CTX_GLOBAL , @_)}
sub GVarDefault{_VarDefault($CTX_GLOBAL , @_)}
sub GVarInit   {_VarInit   ($CTX_GLOBAL , @_)}
sub GVarGen    {_VarGen    ($CTX_GLOBAL , @_)}

sub TVar       {_Var       ($CTX_TEMP   , @_)}
sub TVars      {_Vars      ($CTX_TEMP   , @_)}
sub TVarGet    {_VarGet    ($CTX_TEMP   , @_)}
sub TVarExists {_VarExists ($CTX_TEMP   , @_)}
sub TVarDelete {_VarDelete ($CTX_TEMP   , @_)}
sub TVarSet    {_VarSet    ($CTX_TEMP   , @_)}
sub TVarDefault{_VarDefault($CTX_TEMP   , @_)}
sub TVarInit   {_VarInit   ($CTX_TEMP   , @_)}
sub TVarGen    {_VarGen    ($CTX_TEMP   , @_)}


sub CVar       {_Var       (@_)}
sub CVars      {_Vars      (@_)}
sub CVarGet    {_VarGet    (@_)}
sub CVarExists {_VarExists (@_)}
sub CVarDelete {_VarDelete (@_)}
sub CVarSet    {_VarSet    (@_)}
sub CVarDefault{_VarDefault(@_)}
sub CVarInit   {_VarInit   (@_)}
sub CVarGen    {_VarGen    (@_)}



sub InitVars   {_InitContext(VarContext(), @_)}
sub InitGVars  {_InitContext($CTX_GLOBAL , @_)}
sub InitTVars  {_InitContext($CTX_TEMP   , @_)}
sub InitCVars  {_InitContext(@_              )}



# looks for name in temp, then persistent, then global space
#
# return value of variable that exists even if no value
#
sub V {ResolveVar(@_)}
sub ResolveVar # get option
   {
   my ($name, $default) = @_;

   $default = 0 if scalar @_ < 2;

   return TVarGet($name) if TVarExists($name);
   return  VarGet($name) if  VarExists($name);
   return GVarDefault($name=>$default);
   }

sub VV {ResolveVars(@_)}
sub ResolveVars{map{ResolveVar($_,0)} @_} # get list of options

sub VVd {ResolveVarsd(@_)}
sub ResolveVarsd
   {
   my (@id_vals) = @_;
   return map{ResolveVar(@{$_})} Tuples(@id_vals);
   }

#sub _tuples
#   {
#   my (@p) = @_;
#
#   push(@p, 0) if (scalar @p) % 2;
#   return map{[@p[$_*2,$_*2+1]]}(0..$#p/2);
#   }



# internals
#
###############################################################################

sub _adata
   {
   my ($new_data) = @_;

   state $all = {};
   $all = $new_data if $new_data;
   return $all;
   }


sub _cdata
   {
   my ($ctx) = @_;

   my $all = _adata();

   return $all if $ctx eq "*all*";
   my $here = exists $all->{$ctx};

   $all->{$ctx} = {} unless $here;
   return $all->{$ctx};
   }



# ident              ret
# --------------------------------------
# varname         -> val      
# default_varname -> val|0  
# init_varname    -> val|0 
# exists_varname  -> 0|1      
# delete_varname  -> 0|1      
sub _ident_n
   {
   my ($vars, $ident) = @_;

   my ($name, $mod) = _ident_parts($ident);
   return $mod == $MOD_DEFAULT ? _var_default($vars, $name, 0) :
          $mod == $MOD_INIT    ? _var_init   ($vars, $name, 0) :
          $mod == $MOD_EXISTS  ? _var_exists ($vars, $name)    : 
          $mod == $MOD_DELETE  ? _var_delete ($vars, $name)    : 
                                 _var_get    ($vars, $name)    ;
   }



# ident              ret
# --------------------------------------
# varname         -> val      
# default_varname -> varval|val  
# init_varname    -> varval|val 
# exists_varname  -> 0|1      
# delete_varname  -> 0|1      
sub _ident_nv
   {
   my ($vars, $ident, $val) = @_;

   my ($name, $mod) = _ident_parts($ident);

   return $mod == $MOD_DEFAULT ? _var_default($vars, $name, $val) :
          $mod == $MOD_INIT    ? _var_init   ($vars, $name, $val) :
          $mod == $MOD_EXISTS  ? _var_exists ($vars, $name)       : 
          $mod == $MOD_DELETE  ? _var_delete ($vars, $name)       : 
                                 _var_set    ($vars, $name, $val) ;
   }


sub _ident_nv2
   {
   my ($vars, $ident, $val) = @_;

   my ($name, $mod) = _ident_parts($ident);
   
   my $ret = $mod == $MOD_DEFAULT ? _var_default($vars, $name, $val) :
             $mod == $MOD_INIT    ? _var_init   ($vars, $name, $val) :
             $mod == $MOD_EXISTS  ? _var_exists ($vars, $name)       : 
             $mod == $MOD_DELETE  ? _var_delete ($vars, $name)       : 
                                    _var_set    ($vars, $name, $val) ;
   return ($name, $ret);
   }


sub _ident_nl
   {
   my ($vars, @idents) = @_;

   return map{_ident_n($vars, $_)} @idents;
   }


sub _ident_nvl
   {
   my ($vars, @id_vals) = @_;

   return map{_ident_nv($vars,@{$_})} Tuples(@id_vals);
   }



sub _ident_hr
   {
   my ($vars, $href) = @_;

   my %returns;
   return %returns unless $href && ref($href) eq "HASH";

   while(my($ident, $val) = each %{$href})
      {
      my ($var, $val) = _ident_nv2($vars, $ident, $val);
      $returns{$var} = $val;
      }
   return %returns;
   }


sub _ident_parts
   {
   my ($ident) = @_;

   my ($def, $init, $ex, $del, $name) = $ident =~ /^(_default_)?(_init_)?(_exists_)?(_delete_)?(.*)$/;

   my $mod = $def  ? $MOD_DEFAULT :
             $init ? $MOD_INIT    :
             $ex   ? $MOD_EXISTS  :
             $del  ? $MOD_DELETE  :
                     $MOD_NONE    ;

   return ($name, $mod); 
   }


# --------------------------------------

sub _var_get
   {
   my ($vars, $name) = @_;

   return $vars->{$name};
   }

sub _var_exists 
   {
   my ($vars, $name) = @_;

   my $here = exists $vars->{$name}; 
   return $here ? 1 : 0;
   }

sub _var_delete 
   {
   my ($vars, $name) = @_;

   my $here = _var_exists($vars, $name);
   delete $vars->{$name} if $here;
   return $here;

   }

sub _var_set    
   {
   my ($vars, $name, $val) = @_;

   return $vars->{$name} = $val;
   }

sub _var_default
   {
   my ($vars, $name, $val) = @_;

   my $here = _var_exists($vars, $name);
   return $here ? $vars->{$name} : $val;
   }

sub _var_init   
   {
   my ($vars, $name, $val) = @_;

   my $here = _var_exists($vars, $name);
   return $vars->{$name} = $val unless $here;
   return $vars->{$name};

   return $val;
   }


sub _var_gen
   {
   my ($vars, $val) = @_;

   my $name = _gen_name();
   $vars->{$name} = $val;
   return $name;
   }


sub _gen_name
   {
   state $genidx = 1;
   return sprintf("__gen__%05d", $genidx++);
   }



# type 
#      $TYPE_1 - 1 param, default to get
#      $TYPE_2 - 2 param, default to set
#
sub _var_mod_fn
   {
   my ($mod, $type) = @_;

   return $mod  == $MOD_DEFAULT ? \&_var_default:
          $mod  == $MOD_INIT    ? \&_var_init   :
          $mod  == $MOD_EXISTS  ? \&_var_exists :
          $mod  == $MOD_DELETE  ? \&_var_delete :
          $mod  == $MOD_GEN     ? \&_var_gen    :
          $type == $TYPE_N      ? \&_var_get    :
          $type == $TYPE_NV     ? \&_var_set    :
                                 undef          ;
   }


sub _var_nl_mod
   {
   my ($vars, $mod, @idents) = @_;

   my $fn = _var_mod_fn($mod, $TYPE_N);
   return map{&{$fn}($vars, $_, 0)} @idents;
   }


sub _var_nvl_mod
   {
   my ($vars, $mod, @id_vals) = @_;

   my $fn = _var_mod_fn($mod, $TYPE_NV);
   return map{&{$fn}($vars,@{$_})} Tuples(@id_vals);
   }


sub DebugDumpContextVarNames
   {
   my (@ctxlist) = @_;

   my $currctx = VarContext({push=>1});
   @ctxlist = _ContextList(1) unless @ctxlist && scalar @ctxlist;

   print "\nDEBUG: list of var names:\n";
   foreach my $context (@ctxlist)
      {
      my @names = VarContext({varlist=>1},$context);
      print "Context '$context' ", join(", ", @names), "\n";
      }
   print "\nCurrent Context: '$currctx'\n\n";
   }



### misc
###
#################################################################################
##
## options
##  load        =>1          |0| load stream, {stream} must exist
##  create      =>1          |1| create stream, returns data
##  exclude_ctx =>[ctxnames] |-| includes all ctxnames except these
##  include_ctx =>[ctxnames] |-| includes only these ctxnames
##  exclude_var =>[varnames] |-| includes all vars except these
##  include_var =>[varnames] |-| includes only these vars
##  global      =>0          |1| include global ctx
##  temp        =>0          |0| include temp ctx
##  stream      =>data       |-| needed for load
##
#sub VarStream
#   {
#   my (%options) = @_;
#
#   $options{create} = 1 unless        $options{load  };
#   $options{global} = 1 unless exists $options{global};
#   $options{temp  } = 0 unless exists $options{temp  };
#
#   return CreateVarStream(%options) if $options{create};
#   return LoadVarStream  (%options) if $options{load};
#   }
#
#
#
#
#sub CreateVarStream
#   {
#   my (%options) = @_;
#
#   my @ctxlist = _FilteredCtxList(%options);
#   my $vmap =_IncludeMap("var", %options);
#
#   my $data = "";
#   foreach my $ctx (@ctxlist)
#      {
#      $data .= _CreateCtxStream($ctx, %options, vmap=>$vmap);
#      }
#   return $data;
#   }
#   
#sub _CreateCtxStream
#   {
#   ($ctx, %options) = @_;
#
#   
#
#   my $vmap = $options{vmap};
#
#   }
#
#sub LoadVarStream  
#   {
#   my (%options) = @_;
#
#
#sub _FilteredCtxList
#   {
#   my (%options) = @_;
#
#   my @allctx = VarContextList();
#   my $imap =_IncludeMap("ctx", %options);
#   my @ctxlist;
#
#   foreach my $ctx (@allctx)
#      {
#      my $action = $imap->{$ctx} || $imap->{":default"};
#      push(@ctxlist, $ctx) if $action eq "i";
#      }
#   push(@ctxlist, $CTX_GLOBAL) if $options{global} || $default eq "i";
#   push(@ctxlist, $CTX_TEMP  ) if $options{temp  } || $default eq "i";
#   return @ctxlist;
#   }
#
#sub _IncludeMap
#   {
#   my ($type, %options) = @_;
#
#   my ($incl, $excl) = @options{"include_$type", "exclude_$type"};
#
#   my $default = $excl ? "i" : $incl ? "e" : "i";
#
#   return {(MapList($options{"include_$type"}, "i"),
#            MapList($options{"exclude_$type"}, "e"),
#            ":default" => $default
#          )};
#   }
#
#sub MapList
#   {
#   my ($aref, $val) = @_
#
#   return () unless $aref;
#   return map{$_=>1} @{$aref};
#   }


1; # two
  
__END__   





















