use File::Basename;
use lib dirname(__FILE__) . "/lib";
use Gnu::ArgParse;
use Gnu::Template  qw(Template Usage);
use Gnu::DebugUtil qw(DumpRef);
use Gnu::FileUtil  qw(SlurpFile SpillFile);
use Gnu::Gscript   qw(:ALL);

my @TokenCases = (
   "55", " 66 ", "61.5", ".75 + fred", "9.", "77B", "bob",
   "fred", "ne", "ne0", "near", "cmp", "Cmp", "fred ne", "ne cmp", 
   "ne0 ne", "near 4", "cmp fred", "Cmp bob", " fred", " ne",
   " fred", " fred is", " fred +", " 0fred +", " f012", " f012 +", " f012()", " f012() 6",
   "\"a string\"", '"a string" + 50', '"\"a string\"" + 50', 
   '"yo \"a string\" man" + 50', ' "yo \"a string\" man" + 50', 'not a string',
   "++", "--", "&&", "||", "==", "++bob", "-- bob", "&& bart", 
   "|| ", "== 6", "+7", "| red", " & ", "<=>",
   "==", "!=", "<=", ">=", "<>", "=", "<=>", "** 6",
   "+ 6", "- 0", "*8", "< 8", ">", "&", "|", "!6", 
   "?", ":", "%", "(", ")", "(7)",
   "fred * (1 - bob / 77.7) % i**2",
   "{", "}", "{1,x}"
);

my @ParseCases = (
   "fred - bob"  ,   "1 + 2",
   "++fred"      ,   "fred++",
   "(fred + bob)",   "(1 - 2)",
   "(fred)"      ,   "a = 3",
   "a = 3 < 6",
   "fred * (1 - bob / 77.7) % i**2",
   "a = 3>5 ? Val1 : val2",
);

my @EvalCases = (
   {expr=> ''                    , val=>undef  },
   {expr=> '0'                   , val=>0      },
   {expr=> '1'                   , val=>1      },
   {expr=> '1 + 2'               , val=>3      },
   {expr=> '1 + 2 + 3'           , val=>6      },
   {expr=> '10 - 6'              , val=>4      },
   {expr=> '10 - 6 - 1'          , val=>3      },
   {expr=> '10 * 9'              , val=>90     },
   {expr=> '10 * 9 * 2'          , val=>180    },
   {expr=> '15 / 5'              , val=>3      },
   {expr=> '15 / 5 / 2'          , val=>1.5    },
   {expr=> '33 % 10'             , val=>3      },
   {expr=> '-7'                  , val=>-7     },
   {expr=> '+7'                  , val=>7      },
   {expr=> '6 - -6'              , val=>12     },
   {expr=> '5 + 4 * 3'           , val=>17     },
   {expr=> '5 + 5 + 5'           , val=>15     },
   {expr=> '5 - 5 - 5'           , val=>-5     },
   {expr=> '(5 - 5) - 5'         , val=>-5     },
   {expr=> '5 - (5 - 5)'         , val=>5      },
   {expr=> 'x = 8'               , val=>8      },
   {expr=> 'y = 9'               , val=>9      },
   {expr=> 'x < y'               , val=>1      },
   {expr=> 'x > y'               , val=>0      },
   {expr=> 'x >= y'              , val=>0      },
   {expr=> 'x <= y'              , val=>1      },
   {expr=> 'x == y'              , val=>0      },
   {expr=> 'x ,  y'              , val=>8      },
   {expr=> 'x ;  y'              , val=>9      },
   {expr=> 'true'                , val=>1      },
   {expr=> 'false'               , val=>0      },
   {expr=> 'true || false'       , val=>1      },
   {expr=> 'true && false'       , val=>0      },
   {expr=> '"fred" eq "fred"'    , val=>1      },
   {expr=> '"fred" eq "barney"'  , val=>0      },
   {expr=> '"fred" lt "barney"'  , val=>0      },
   {expr=> '"fred" gt "barney"'  , val=>1      },
   {expr=> '"fred" ne "barney"'  , val=>1      },
   {expr=> '"fred" cmp "barney"' , val=>1      },
   {expr=> '7 <=> 9'             , val=>-1     },
   {expr=> '9 <=> 7'             , val=>1      },
   {expr=> 'true ? x : y'        , val=>8      },
   {expr=> 'false ? x : y'       , val=>9      },
   {expr=> '"a" eq "b" ? 1:false', val=>0      },
   {expr=> '"a" eq "a" ? 1:0'    , val=>1      },
   {expr=> 'y**2'                , val=>81     },
   {expr=> 'a1 = 876'            , val=>876    },
   {expr=> 'a2 = 123.456'        , val=>123.456},
   {expr=> 'a4 = sin(0.81)'      , val=>undef  },
   {expr=> 'y=9'                 , val=>9      },
   {expr=> '++y'                 , val=>10     },
   {expr=> 'y=9'                 , val=>9      },
   {expr=> 'y++'                 , val=>9      },
   {expr=> 'y'                   , val=>10     },
   {expr=> 'a3 = "joe"'          , val=>"joe"    , str=>1},
   {expr=> 'a3 = "joe"."bob"'    , val=>"joebob" , str=>1},
   {expr=> 'Test1'               , val=>1        },
   {expr=> 'Test2'               , val=>2        },
   {expr=> 'Test3'               , val=>8        },
   {expr=> 'Test4'               , val=>"jose"   , str=>1},
   {expr=> 'Test5'               , val=>"bill"   , str=>1},
   {expr=> 'Test6'               , val=>66.66    },
   {expr=> 'Test7'               , val=>-124.6   },
   {expr=> 'Test5 . Test2'       , val=>"bill2"  , str=>1},
   {expr=> 'Func1(6)'            , val=>28       },
   {expr=> 'Func2(2)'            , val=>44       },
   {expr=> 'Func3(x) => {99}'    , val=>0        },
   {expr=> 'x = 8'                  , val=>8       },
   {expr=> 'Func3(x) => {99}'       , val=>0       },
   {expr=> 'z1(x)=>{x*3}; z1(4)'    , val=>12      },
   {expr=> 'z2(x)=>{z1(x)*2}; z2(3)', val=>18      },
   {expr=> 'x'                      , val=>8       },
   {expr=> 'R(x) => {x + Q + (x > 1 ? R(x-1) : 0)}', val=>0    },
   {expr=> 'Q = 3'                                 , val=>3    },
   {expr=> 'R(5)'                                  , val=>30   },
   {expr=> 'Q = 6'                                 , val=>6    },
   {expr=> 'R(5)'                                  , val=>45   },
   {expr=> 'R(R(3))'                               , val=>444  },
   {expr=> 'S(x) => {x < 1 ? 1 : (x % 2 ? S(x-1)+S(x-2) : S(x-3)+S(x-4))}', val=>0}, 
   {expr=> 'S(7)'                                  , val=>13   },
   {expr=> 'S(20)'                                 , val=>352  },
);


MAIN:
   $| = 1;
   ArgBuild("*^eval *^call= *^show *^echo *^debug *^help ? " .
            "*^testeval *^testparse *^testtoken " .
            "*^elevel= *^plevel= *^tlevel= *^alevel=");

   ArgParse(@ARGV) or die ArgGetError();
   ArgDump() if ArgGet("alevel");

   SetTokenLogLevel(ArgGet("tlevel")) if ArgIs("tlevel");
   SetParseLogLevel(ArgGet("plevel")) if ArgIs("plevel");
   SetEvalLogLevel (ArgGet("elevel")) if ArgIs("elevel");

   Usage() if ArgIs("help") || !ArgIsAny("", "eval", "testeval", "testparse", "testtoken");

   RunEvalTests()  if ArgIs("testeval");
   RunParseTests() if ArgIs("testparse");
   RunTokenTests() if ArgIs("testtoken");
   RunFile(ArgGet()) if ArgIs();
   RunEval() if ArgIs("eval");
   exit(0);

sub RunFile
   {
   my ($spec) = @_;

   SetVars();
   SetFns();
   my $data = SlurpFile($spec);

   print "----- file ----\n$data\n" if ArgIs("echo");
   print "----- results ----\n" if ArgIs("echo");
   my $result = Eval($data);
   print GetError() . "\n" if IsError();

   if (ArgIs("call"))
      {
      my $call = ArgGet("call");
      my @args = split(",", $call);
      print "----- calling ----\n$call\n" if ArgIs("echo");
      print "----- results ----\n" if ArgIs("echo");
      $result = CallFn(@args);
      print GetError() . "\n" if IsError();
      }
   print "\nfinal val: $result\n" if ArgIs("echo");
   exit($result);
   }

sub RunEval
   {
   SetVars();
   SetFns();
   my $expr = join(" ", ArgGetAll());
   print "$expr => ";
   my $result = Eval($expr);
   print GetError() . "\n" if IsError();
   print "$result\n";
   }

sub RunEvalTests
   {
   #SetEvalLogLevel(1) unless ArgIs("elevel");
   SetVars();
   SetFns();
   my $passct = 0;

   foreach my $case (@EvalCases)
      {
      my $result = Eval($case->{expr});
      my $err = IsError();
      my $pass = $case->{str} ? ($result eq $case->{val}) : ($result == $case->{val});
      $passct++ if $pass;
      next if $pass && !$err && !ArgIs("show");

      print "$case->{expr}  -->  ";
      print "nope: " . GetError() . "\n" if $err;
      next if $err;
      print "$result";
      print " (pass)\n" if $pass;
      print "\n" unless defined $case->{val};
      next unless defined $case->{val};
      print " (fail [$case->{val}])\n" unless $pass;
      }
   print "$passct of " . scalar @EvalCases . " tests passed\n";
   }

sub RunParseTests
   {
   SetParseLogLevel(1) unless ArgIs("plevel");

   foreach my $case (@ParseCases)
      {
      print "$case => \n";
      my $tree = Parse($case);
      print "nope: " . GetParseError() . "\n" unless $tree;
      print "-----\n";
      }
   }

sub RunTokenTests
   {
   SetTokenLogLevel(1) unless ArgIs("tlevel");
   foreach my $case (@TokenCases)
      {
      print "$case => \n";
      my $tokens = Tokenize($case);
      print "nope: " . GetTokenError() . "\n"  unless $tokens;
      }
   }

sub SetVars
   {
   SetEvalVars({
      %{GetEvalVars()},
      Test1 => 1     ,
      Test2 => 2     ,
      Test3 => 8     ,
      Test4 => "jose",
      Test5 => "bill",
      Test6 => 66.66 ,
      Test7 => -124.6,
      });
   my $x = GetEvalVars();
   $x->{Fuzzy} = "Wuzzy";

   }

sub SetFns
   {
   SetEvalFns
      ({
      %{GetEvalFns()},
      Func1 => sub{$_[0]*5-2},
      Func2 => \&Func2,
      Prn   => \&Prnt,
      sin2  => \&sin2,
      sin3  => \&sin3,
      });
   }

sub Func2
   {
   my ($x) = @_;
   $x * 22;
   }

sub Prnt
   {
   print "Prnt: ";
   print @_;
   #print "print: ". join("", @_) ."\n";
   #return 3;
   }

sub sin2
   {
   print "[arg2:$_[0]]\n";
   sin ($_[0]);
   }

sub sin3
   {
   print "[arg3:",@_, ", ". scalar @_ ."args]\n";
   sin (@_);
   }


__DATA__

[usage]
gscript_tests.pl  -  Test the Gnu::Expr module (and Tokenize & Parse)

USAGE: gscript_tests.pl [options] (expression | scriptfile)

WHERE: 
   expression ... something like x=5; sqrt(x)
   [options] are 0 or more of:
      -eval ........... Run this expression
      -testeval ....... Run Eval tests
      -testparse ...... Run Parser tests
      -testtoken ...... Run Tokenizer tests
      -elevel ......... Set logging level for Eval
      -plevel ......... Set logging level for Parser
      -alevel ......... Set logging level for Tokenizer 
      -echo ........... Echo lines of script file
      -show ........... Show even passing tests

EXAMPLES:
   gscript_tests.pl -eval
   gscript_tests.pl -eval -show
   gscript_tests.pl -file=samples.scr
   gscript_tests.pl  sin(0.001) * 899
   gscript_tests.pl -parse
   gscript_tests.pl -token
   gscript_tests.pl -file=samples.scr -show

   samples.scr contents:
      x = true ? 12 : 3
      a1 = 1
      a2 = 22
      a3 = 33
      a4 = a1 ? ++a2 : ++a3
      F1(x)=>{x**2/(x+x)}; F2(x)=>{F1(x)/3}; F2(5)
      S(x) => {x < 1 ? 1 : (x % 2 ? S(x-1)+S(x-2) : S(x-3)+S(x-4))}
      S(7)
      print(S(20) + F2(5))
   
   