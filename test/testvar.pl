#!perl
#
# Craig Fitzgerald
#

use lib "lib";
use warnings;
use strict;
use List::Util       qw(max min);
use List::MoreUtils  qw(uniq);
use Gnu::Var         qw(:ALL);
use Gnu::StringUtil  qw(LineString);

my $VERBOSE = 0;

my $RESULTS = {testcount => 0,
               pass      => 0,
               fail      => 0};


MAIN:
   print "An internal unit test for Gnu::Var\n\n";

   Tests();
   printresult();
   exit(0);

sub Tests
   {
   TestContext   ();
   TestVar       ();
   TestVars      ();
   TestVarGet    ();
   TestVarExists ();
   TestVarDelete ();
   TestVarSet    ();
   TestVarDefault();
   TestVarInit   ();
   TestVarGen    ();
   TestV         ();
   TestVV        ();
   TestVVd       ();
   }

######################################################################################


sub TestContext  
   {
   my ($ctx, @r);

   $ctx = VarContext("foo");            SIss("set ctx     ", $ctx, "foo"  );
   $ctx = VarContext(     );            SIss("get ctx     ", $ctx, "foo"  );
   $ctx = VarContext("foo");            SIss("set ctx     ", $ctx, "foo"  );
   
   VarContext({reset=>{v1=>1}}, "bar");

   $ctx = VarContext(     );            SIss("get ctx     ", $ctx, "bar"  );
                                        CIs ("initial ctx ", $ctx, {v1=>1});

   $ctx = VarContext({push=>1}, "foo2");SIss("push ctx    ", $ctx, "foo2" );
                                        CIs ("foo2 ctx    ", $ctx, {}     );

   $ctx = VarContext({pop=>1});         SIss("pop ctx     ", $ctx, "bar"  );
                                        CIs ("ctx         ", $ctx, {v1=>1});

   @r = VarContext({varlist=>1  });     AIsv("bar varlist ", \@r , ["v1"] );
   }


# (name               )      val         [get val)
# (name=>val          )      val         [set, create if needed)
# (name=>val,..       )      (val,...)   [set, returns array)
# (_delete_name=>1    )      1|0         [delete, returns 1 or 0 in scalar ctxt]
# (_exists_name=>1    )      1|0         [existance check]
# (_init_name=>initval)      val|initval [create set, return initval if new, or ret val]
# (_default_name=>defval)    val|defval  [return val if exists, or ret defval]
#
# possible modifiers (prefix in var identifier):
#
#  _delete_
#  _exists_
#  _init_
#  _default_
#
sub TestVar       
   {
   my ($ctx, $r, @a);

   $ctx = VarContext("foo3");

   $r = Var("v1"          );  SUn ("get v1     ", $r      );
   $r = Var(v2=>1         );  SIsv("set v2     ", $r ,  1 );
   $r = Var("v2"          );  SIsv("get v2     ", $r ,  1 );
   $r = Var("_exists_v2"  );  SIsv("exists v2  ", $r ,  1 );
   $r = Var("_exists_v3"  );  SIsv("exists v3  ", $r ,  0 );
   $r = Var(v3=>0         );  SIsv("set v3     ", $r ,  0 );
   $r = Var("v3"          );  SIsv("get v3     ", $r ,  0 );
   $r = Var("_exists_v3"  );  SIsv("exists v3  ", $r ,  1 );
   $r = Var("_delete_v3"  );  SIsv("delete v3  ", $r ,  1 );
   $r = Var("_delete_v4"  );  SIsv("delete v4  ", $r ,  0 );
   $r = Var("_exists_v3"  );  SIsv("exists v3  ", $r ,  0 );
   $r = Var(_init_v5=>5   );  SIsv("_init_v5   ", $r ,  5 );
   $r = Var("v5"          );  SIsv("get v5     ", $r ,  5 );
   $r = Var(_default_v5=>6);  SIsv("deflt v5   ", $r ,  5 );
   $r = Var(_default_v6=>7);  SIsv("deflt v6   ", $r ,  7 );
   $r = Var("_exists_v6"  );  SIsv("exists v6  ", $r ,  0 );

   $ctx = VarContext("foo4");

   $r = Var(v2=>3         );  SIsv("set v2     ", $r ,  3 );
   $r = Var("v2"          );  SIsv("get v2     ", $r ,  3 );
   $r = Var("_exists_v2"  );  SIsv("exists v2  ", $r ,  1 );
   $r = Var("_exists_v3"  );  SIsv("exists v3  ", $r ,  0 );
   $r = Var("_exists_v3"  );  SIsv("exists v3  ", $r ,  0 );
   $r = Var("_exists_v5"  );  SIsv("exists v5  ", $r ,  0 );
   $r = Var("_exists_v6"  );  SIsv("exists v6  ", $r ,  0 );
   $r = Var(v9=>9         );  
   $r = Var("_exists_v9"  );  SIsv("exists v9  ", $r ,  1 );

   $ctx = VarContext("foo3");
   $r = Var("v2"          );  SIsv("get v2     ", $r ,  1 );
   $r = Var("_exists_v5"  );  SIsv("exists v5  ", $r ,  1 );
   $r = Var("_exists_v9"  );  SIsv("exists v9  ", $r ,  0 );


   $ctx = VarContext("foo5");

   @a = Var(a=>1, b=>2, c=>3);   AIsv("set abc   ", \@a, [1,2,3]          );
   @a = Vars(qw(a b c));         AIsv("get abc   ", \@a, [1,2,3]          );
   @a = Var (a=>11, _init_b=>44, _default_d=>55, _exists_c=>1, _exists_d=>1, _init_e=>55);
                                 AIsv("multiset  ", \@a, [11,2,55,1,0,55]);
   @a = Vars(qw(a b c e));       AIsv("multiget  ", \@a, [11,2,3,55]      );
                                 CIs ("ctx $ctx  ", $ctx, {a=>11, b=>2, c=>3, e=>55});
   }


sub TestVars      
   {
   }

sub TestVarGet    
   {
   }

sub TestVarExists 
   {
   }

sub TestVarDelete 
   {
   }

sub TestVarSet    
   {
   }

sub TestVarDefault
   {
   }

sub TestVarInit   
   {
   }

sub TestVarGen    
   {
   }

sub TestV
   {
   my ($ctx, $r, $a, @a);

   $ctx = VarContext("foo6");
   GVar(a=>100, b=>200, c=>300, d=>400, gx=>700, gy=>800, gz=>900);
    Var(a=>10 , b=>20 , c=>30 , d=>40 , cx=>70 , cy=>80 , cz=>90 );
   TVar(a=>1  , b=>2  , c=>3  , d=>4  , tx=>7  , ty=>8  , tz=>9  );

   $a = V("a")                                                        ; SIsv("V  #01 ",  $a, 1          );
   $a = V(a=>66)                                                      ; SIsv("V  #02 ",  $a, 1          );
   $a = V("f")                                                        ; SIsv("V  #03 ",  $a, 0          );
   $a = V(f=>77)                                                      ; SIsv("V  #04 ",  $a, 77         );
   @a = VV(qw(a b c d f gx cx tx))                                    ; AIsv("VV #05 ", \@a, [1,2,3,4,0,700,70,7 ]);
   @a = VVd(a=>41, b=>42, c=>43, d=>44, f=>48, gx=>45, cx=>46, tx=>47); AIsv("VVd#06 ", \@a, [1,2,3,4,48,700,70,7]);

   InitTVars();
   $a = V("a")                                                        ; SIsv("V  #07 ",  $a, 10          );
   $a = V(a=>66)                                                      ; SIsv("V  #08 ",  $a, 10          );
   $a = V("f")                                                        ; SIsv("V  #09 ",  $a, 0          );
   $a = V(f=>77)                                                      ; SIsv("V  #10 ",  $a, 77         );
   @a = VV(qw(a b c d f gx cx tx))                                    ; AIsv("VV #11 ", \@a, [10,20,30,40,0,700,70,0 ]);
   @a = VVd(a=>41, b=>42, c=>43, d=>44, f=>48, gx=>45, cx=>46, tx=>47); AIsv("VVd#12 ", \@a, [10,20,30,40,48,700,70,47]);

   $ctx = VarContext("foo7");
   $a = V("a")                                                        ; SIsv("V  #13 ",  $a, 100          );
   $a = V(a=>66)                                                      ; SIsv("V  #14 ",  $a, 100          );
   $a = V("f")                                                        ; SIsv("V  #15 ",  $a, 0          );
   $a = V(f=>77)                                                      ; SIsv("V  #16 ",  $a, 77         );
   @a = VV(qw(a b c d f gx cx tx))                                    ; AIsv("VV #17 ", \@a, [100,200,300,400,0, 700,0,0 ]);
   @a = VVd(a=>41, b=>42, c=>43, d=>44, f=>48, gx=>45, cx=>46, tx=>47); AIsv("VVd#18 ", \@a, [100,200,300,400,48,700,46,47]);

   }

sub TestVV        
   {
   }

sub TestVVd       
   {
   }


######################################################################################
sub SUn
   {
   my ($label, $got) = @_;

   my $ok = !defined $got;
   return addresult("undef test", $ok, $label, $got, "");
   }

sub SIss
   {
   my ($label, $got, $expect) = @_;

   my $ok = $got eq $expect;
   return addresult("string eq test", $ok, $label, $got, $expect);
   }

sub SIsv
   {
   my ($label, $got, $expect) = @_;

   my $ok = $got == $expect;
   return addresult("num eq test", $ok, $label, $got, $expect);
   }


sub AIsv
   {
   my ($label, $got, $expect) = @_;

   my ($gct, $ect) = (scalar @{$got}, scalar @{$expect});
   my $ok = $gct == $ect;

#   map{$ok &&= ($got->[$_] == $expect->[$_])} (0..$gct-1);
   map{$ok &&= ("$got->[$_]" eq "$expect->[$_]")} (0..$gct-1);

   return addresult("array eq test", $ok, $label, _astring($got), _astring($expect));
   }


sub CIs
   {
   my ($label, $ctx, $expect) = @_;

   my $cdata = _gctx($ctx);
   my ($gct, $ect) = (scalar keys %{$cdata}, scalar keys %{$expect});
   my $ok = $gct == $ect;
   map{$ok &&= ($cdata->{$_} == $expect->{$_})} keys %{$cdata};
      
   return addresult("context eq test", $ok, $label, _hstring($cdata), _hstring($expect));
   }


sub addresult
   {
   my ($testtype, $ok, $label, $got, $expect) = @_;

   $RESULTS->{testcount} += 1;
   $RESULTS->{pass     } += 1 if $ok;
   $RESULTS->{fail     } += 1 if !$ok;

   return unless $VERBOSE || !$ok;

   ($got, $expect) = (_safe($got), _safe($expect));
   my $status = $ok ? "PASS" : "FAIL";
   
   print LineString("$status: $testtype : $label : [$RESULTS->{testcount}]");
   print "'$got' vs '$expect'\n";
#   print LineString();
   }


sub printresult
   {
   print "tests: ", $RESULTS->{testcount},
         ", pass:", $RESULTS->{pass     },
         ", fail:", $RESULTS->{fail     },
         "\n";
   }



######################################################################################
######################################################################################


sub _safe
   {
   my ($val) = @_;

   return "(undef)" if !defined $val;
   return $val;
   }


sub _Vs
   {
   my ($name, $default) = @_;

   $default = "(default)" unless scalar @_ > 1;
   return _safe(V($name, $default));
   }


sub _gctx
   {
   my ($ctx) = @_;

   my $cdata = VarContext({push=>1, ctxdata=>1}, $ctx);
   VarContext({pop=>1});
   return $cdata;
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


######################################################################################



   
#
#   @a = Var ($ctx, a=>1, b=>2, c=>3);     AIs("set abc   ", \@a, [1,2,3]);
#
#
#   @a = Vars($ctx, qw(a b c));           AIs("get abc   ", \@a, [1,2,3]);
#   @a = Var ($ctx, a=>11, _init_b=>44, _default_d=>55, _exists_c=>1, _exists_d=>1, _init_e=>55);
#                                         AIs("multiset  ", \@a, [11,44,55,1,0,55]);
#   @a = Vars($ctx, qw(a b c e));         AIs("multiget  ", \@a, [11,2,3,55]);
#                                          CIs("ctx $ctx  ", $ctx, {a=>1, b=>2, c=>3, e=>55});
#
#
#
#
#
#
#
#   print LineString("Done");
#   }
#
#
#sub TestZ
#   {
#   my ($href) = @_;
#
#   my $a = $href->{a}      ? 1 : 0;
#   my $b = $href->{b} && $href->{b} == 2 ? 1 : 0;
#   my $c = $href->{c} && $href->{c} == 2 ? 1 : 0;
#   my $d = $href->{d} && $href->{d} == 2 ? 1 : 0;
#
#   print "[$a][$b][$c][$d]\n";
#   }
#
#
#sub Test0
#   {
#   my @a;
#
#   @a = CVar("foo", a=>1, b=>2, c=>3);
#   A_ArrayIs("set abc return", \@a, [1,2,3]);
#
#   @a = CVars("foo", qw(a b c));
#   A_ArrayIs("get abc", \@a, [1,2,3]);
#
#   @a = CVar("foo", a=>11, _init_b=>44, _default_d=>55, _exists_c=>1, _exists_d=>1, _init_e=>55);
#   A_ArrayIs("multiset", \@a, [11,44,55,1,0,55]);
#
#   @a = CVars("foo", qw(a b c e));
#   A_ArrayIs("multiget", \@a, [11,2,3,55]);
#
#   A_CtxIs("foo ctx", "foo", {a=>1, b=>2, c=>3, e=>55});
#   }
#
#
#sub Test1
#   {
#   my @a;
#
#   @a = CVar("bar", a=>1, b=>2, c=>3);
#   A_ArrayIs("set abc return", \@a, [1,2,3]);
#
#   @a = CVarExists("bar", qw(a b c d e));
#   A_ArrayIs("exists abcde", \@a, [1,1,1,0,0]);
#
#   @a = CVarDelete("bar", qw(a c z));
#   A_ArrayIs("delete ac", \@a, [1,1,0]);
#
#   A_CtxIs("bar ctx", "bar", {b=>2});
#   }
#
#
#sub Test2
#   {
#   my @a;
#   my $ctx = "baz";
#
#   VarContext($ctx);
#   @a = TVar(a=>1, b=>2, c=>3, d=>4, e=>5, ta=>6, tb=>7);
#   pa("TVar abcde ta tb", @a);
#
#   @a = Var(a=>10, b=>20, c=>30, d=>40, e=>50, ca=>60, cb=>70, cga=>80);
#   pa("Var abcde ca cb cga", @a);
#
#   @a = GVar(a=>100, b=>200, c=>300, d=>400, e=>500, ga=>600, gb=>700, cga=>800);
#   pa("GVar abcde ga gb cga", @a);
#
#   pv(qw(a b c d e ta ca ga cga zz));
#
##   pctx("temp");
##   pctx($ctx);
##   pctx("global");
#
#   @a = VV(qw(a b c d e ta ca ga cga zz));
#   pa("VV  a b c d e ta ca ga cga zz", @a);
#
#   @a = VVd(a=>"D", b=>"D", c=>"D", d=>"D", e=>"D", ta=>"D",ca=>"D", ga=>"D", cga=>"D", zz=>"D");
#   pa("VVd a b c d e ta ca ga cga zz", @a);
#
#
#   InitTVars();
#   print "wiped tmp\n";
#   @a = VV(qw(a b c d e ta ca ga cga zz));
#   pa("VV  a b c d e ta ca ga cga zz", @a);
#
#
##   $ctx = "buzz";
##   VarContext($ctx);
##   $ctx = PushVarContext("buzz");
#   $ctx = VarContext({push=>1}, "buzz");
#   print "changed ctx to $ctx\n";
#
#   @a = VV(qw(a b c d e ta ca ga cga zz));
#   pa("VV  a b c d e ta ca ga cga zz", @a);
#
#
#   $ctx = VarContext({pop=>1});
##  $ctx = PopVarContext();
#   print "changed ctx to $ctx\n";
#
#   @a = VV(qw(a b c d e ta ca ga cga zz));
#   pa("VV  a b c d e ta ca ga cga zz", @a);
#
#
#   pctx("temp");
#   pctx($ctx);
#   pctx("global");
#   }
#
#
#sub Test3
#   {
#   my $ctx = VarContext("myctx1");
#
#   InitVars ();
#   InitGVars(); 
#   InitTVars();
#
#   Var({global=>1}, Fred=>10);
#   Var({temp=>1},   Fred=>3);
#   Var(             Fred=>7);
#
#
#
#   pvctx("Fred");
#
#   VarDelete({temp=>1},   "Fred");
#   print "deleted tmp fred\n";
#   pvctx("Fred");
#
#   VarDelete("Fred");
#   print "deleted ctx fred\n";
#   pvctx("Fred");
#
#   }
#
#
#sub Test4
#   {
#   my $glb_opts = {escct=>4, clean=>1};
#   my $ctx_opts = {pdelim=>"abc", filextern=>1};
#   my $tmp_opts = {prompt=>"yo",  filextern=>0, trim=>1, clean=>0, dir1=>"foo\\bar\\baz"};
#
#   my $ctx = VarContext("myctx2");
#
#   InitTVars ();
#   InitVars ();
#   InitGVars(); 
#
#   GVarSet  ({},$glb_opts);
#    VarSet  ({},$ctx_opts);
#   InitTVars($tmp_opts);
#
#   Var(opt1=>"aaa", opt2=>1, dir1=>"foo\\bar");
#   TVar(opt1=>"bbb");
#   GVar(escct=>3);
#
#   pctx("temp");
#   pctx($ctx);
#   pctx("global");
#
#   print "\nCurrent Ctx: ", VarContext(), "\n\n";
#   my @vnames = qw(filextern prompt trim dir1 opt1 opt2 pdelim clean escct);
#   map{print sprintf("  resolve %8s: ", $_), _Vs($_), "\n"} (@vnames);
#
##   foreach my $vname (@vnames)
##      {
##      print sprintf("resolve %8s: ", $vname), _Vs($vname), "\n";
##      }
#
#
#   print "\n\tmp ctx cleared\n";
#   InitTVars();
#   map{print sprintf("  resolve %8s: ", $_), _Vs($_), "\n"} (@vnames);
#
#   }
#
#
#
#sub pa
#   {
#   my ($label, @vals) = @_;
#
#   print "$label: ", join(", ", @vals) . "\n";
#   }
#
#
#sub pctx
#   {
#   my ($ctx) = @_;
#
#   my $vars = VarContext({push=>1, ctxdata=>1}, $ctx);
#
#   print "context $ctx:\n";
#   foreach my $name (sort keys %{$vars})
#      {
#      print "  $name = $vars->{$name}\n";
#      }
#   print "\n";
#   VarContext({pop=>1});
#   }
#
#
#sub _gctx
#   {
#   my ($ctx) = @_;
#
#   my $cdata = VarContext({push=>1, ctxdata=>1}, $ctx);
#   VarContext({pop=>1});
#   return $cdata;
#   }
#
#
#
#sub pv
#   {
#   my (@names) = @_;
#
#   foreach my $name (@names)
#      {
#      my $val = V($name);
#      $val = "(undef)" if !defined $val;
#      print "var $name = $val\n";
#      }
#   }
#
#
#
#sub pvctx
#   {
#   my (@names) = @_;
#
#   foreach my $name (@names)
#      {
#      my $tv = TVarExists($name) ? _safe(TVar($name)) : "<no exist>";
#      my $vv =  VarExists($name) ? _safe( Var($name)) : "<no exist>";
#      my $gv = GVarExists($name) ? _safe(GVar($name)) : "<no exist>";
#      my $rv = _safe(V($name, "default val"));
#
#      print "Temp     Value of $name: $tv\n";
#      print "Context  Value of $name: $vv\n";
#      print "Global   Value of $name: $gv\n";
#      print "Resolved Value of $name: $rv\n";
#      }
#   }
#
#
#sub Test5
#   {
#   _ptuples("tuples (1param) :", _tuples(1));
#   _ptuples("tuples (2param) :", _tuples(1,2));
#   _ptuples("tuples (3param) :", _tuples(1,2,3));
#   _ptuples("tuples (4param) :", _tuples(1,2,3,4));
#   _ptuples("tuples (5param) :", _tuples(1,2,3,4,5));
#   _ptuples("tuples (6param) :", _tuples(1,2,3,4,5,6));
#   }
#
#
#
#
#sub _ptuples
#   {
#   my ($label, @tuples) = @_;
#
#   $label ||= "tuples:";
#   print $label;
#   foreach my $t (@tuples)
#      {
#      my ($l,$r) = @{$t}[0,1];
#      print " [$l,$r]"
#      }
#   print "\n";
#   }
#
#sub _tuples
#   {
#   my (@p) = @_;
#
#   push(@p, 0) if (scalar @p) % 2;
#   return map{[@p[$_*2,$_*2+1]]}(0..$#p/2);
#   }
#
#
#sub TestContext
#   {
#   my $ctx = "";
#   my @r, @g, @s;
#
#   my $ctx = VarContext("foo");         SIs("set ctx     ", $ctx, "foo"  );
#      $ctx = VarContext(     );         SIs("get ctx     ", $ctx, "foo"  );
#
#   my $ctx = VarContext("foo");         SIs("set ctx     ", $ctx, "foo"  );
#   
#   VarContext({reset=>{v1=>1}, "bar");
#   $ctx = VarContext(     );            SIs("get ctx     ", $ctx, "bar"  );
#                                        CIs("initial ctx ", $ctx, {v1=>1});
#
#   $ctx = VarContext({push=>1}, "foo2") SIs("push ctx    ", $ctx, "foo2" );
#                                        CIs("initial ctx ", $ctx, {}     );
#
#   $ctx = VarContext({pop=>1})          SIs("pop ctx     ", $ctx, "bar"  );
#                                        CIs("ctx         ", $ctx, {v1=>1});
#
#   @r = VarContext({varlist=>1  })      AIs("bar varlist ", \@r , ["v1"] );
#   }
#
#
#sub TestCVar
#   {
#   my $ctx = "foo";
#   my @a;
#
#   @a = CVar($ctx, a=>1, b=>2, c=>3);     AIs("set abc   ", \@a, [1,2,3]);
#   @a = CVars($ctx, qw(a b c));           AIs("get abc   ", \@a, [1,2,3]);
#   @a = CVar($ctx, a=>11, _init_b=>44, _default_d=>55, _exists_c=>1, _exists_d=>1, _init_e=>55);
#                                          AIs("multiset  ", \@a, [11,44,55,1,0,55]);
#   @a = CVars($ctx, qw(a b c e));         AIs("multiget  ", \@a, [11,2,3,55]);
#                                          CIs("ctx $ctx  ", $ctx, {a=>1, b=>2, c=>3, e=>55});
#   }
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#