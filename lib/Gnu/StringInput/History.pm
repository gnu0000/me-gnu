#
# StringInput::History.pm - input history handling for StringInput
#  C Fitzgerald xx/xx/2013
#
# this module is required by Gnu::StringInput

use strict;
use warnings;
use feature 'state';


# constants
my $NAM_HISTORY      = "__history"    ;
my $NAM_HISTORY_REF  = "__history_ref";
my $MAX_HISTORY      = 1000;
my $MIN_SAVE_LENGTH  = 2;

#sub SIHistory  {v_isg($NAM_HISTORY  , 0, [], @_)}
#sub VHistory   {v_isg($NAM_HISTORY  , 1, [], @_)}


## SIHistory()
## SIHistory([data]
##
#sub SIHistory
#   {
#   my ($data) = @_;
#   return _SIGetHistory(0,$data);
#   }
#
#sub _SIGetHistory
#   {
#   my ($boundscheck,$data) = @_;
#   
#   $boundscheck ||= 0;
#   return undef if $boundscheck > 10;
#   
#   my $historyref = VarInit($NAM_HISTORY_REF=>0);
#   if ($historyref)
#      {
#      SIContext({push=>1}, $historyref);
#      my $hist = _SIGetHistory($boundscheck+1, $data);
#      SIContext({pop=>1});
#      return $hist;
#      }
#   return $data ? Var($NAM_HISTORY=>$data) : VarInit($NAM_HISTORY=>[]);
#   }

   
# SIHistory()    ..................... get internal history data
# SIHistory([data]) .................. load history data (arrayref)
# SIHistory(data=>[data]) ............ load history data (arrayref)
# SIHistory([data],add=>1) ........... add [data] to existing data
# SIHistory(import=>"foo.txt") ....... load history data (file)
# SIHistory(import=>"f",add=>1) ...... add history data from file
# SIHistory(export=>"foo.txt") ....... export to file
# SIHistory(getview=>1) .............. 
# SIHistory(clear=>1) ................ clear data
# SIHistory(getref=>1) ............... get reference contect name
# SIHistory(setref=>main) ............ set reference contect name

# SIHistory(minsavelen=>1) ........... min word len to auto add
# SIHistory(maxsaves=>500) ........... max hist size
# SIHistory(nohistmod=>1) ............ dont add to hist
#
sub SIHistory
   {
   my $argcount = scalar(@_) || return Hi_Data();
   my %setdata  = $argcount % 2 ? (data => shift(@_)) : ();
   my %opt = (%setdata, @_);
   
   Hi_RefCtx(%opt) if defined $opt{setref};
   
   map{Var($_=>$opt{$_}) if defined $opt{$_}} qw(minsavelen maxsaves nohistmod);
   
   return $opt{getref } ? Hi_RefCtx (%opt)                       :  
          $opt{import } ? Hi_Import (filespec=>$opt{import}, %opt) :
          $opt{export } ? Hi_Export (filespec=>$opt{export}, %opt) :
          $opt{clear  } ? Hi_Clear  (%opt)                         :
          $opt{data   } ? Hi_Import (%opt)                         :
                          Hi_Data   (%opt)                         ;
   }                       

   
sub Hi_Data
   {
   my (%opt) = @_;

   # check for circular reference pattern   
   $opt{redirects} ||= 0;
   return undef if $opt{redirects}++ > 10;;
   
   my $href = VarInit($NAM_HISTORY_REF=>0);
   if ($href)
      {
      SIContext({push=>1}, $href);
      my $hist = Hi_Data(%opt);
      SIContext({pop=>1});
      return $hist;
      }
   return VarSet ($NAM_HISTORY=>$opt{replacedata}) if $opt{replacedata};
   return VarInit($NAM_HISTORY=>[]);
   }   
      
   
sub Hi_RefCtx
   {
   my (%opt) = @_;
   
   return VarSet($NAM_HISTORY_REF=>$opt{setref}) if defined $opt{setref};
   
   return VarInit($NAM_HISTORY_REF=>0) ; #if $opt{getref};
   }
   

# data      => aref || text   - data from param
# filespec  => text           - data from file
# add       => 1              - dont clear old data
# duplicates=> 1              - allow duplicate entries
#   
sub Hi_Import    
   {
   my (%opt) = @_;
   
   my $data   = Hi_Data();
   @{$data}   = () unless $opt{add};
   my $nodups = $opt{duplicates} ? 0 : 1;
   
   my %here   = map{$_=>1} (@{$data});
   
   my $spec    = $opt{filespec} || "1";
   my $newdata = $opt{data};
   delete $opt{data};
   ($newdata = SlurpFile($spec) || return _SetMessage(0,1,"could no read import file '$spec'"))
      unless $spec =~ /^1$/;
      
   my @counters = qw(hi_entry_added hi_entry_skipped);
   TSetCounters(@counters); 
      
   my $lines = ref($newdata) eq "ARRAY" ? $newdata : [split(/^/, $newdata)];
      
   foreach my $line (@{$lines})
      {
      chomp $line;
      my $skip = $nodups && $here{"$line"};
      TCounter("hi_entry_skipped") if $skip;
      next if $skip;
      push @{$data}, $line;
      TCounter("hi_entry_added");
      }
   
   my ($add,$skip) = TGetCounters(@counters);
   _SetMsg(1,1,0,"history loaded: $add added, $skip skipped");
   }

   
#   
sub Hi_Export    
   {
   my (%opt) = @_;
   
   my $data   = Hi_Data();
   my $stream = join("\n", @{$data}) . "\n";
   my $spec   = $opt{filespec} || "1";
   SpillFile($spec, $stream, 0) if !($spec =~ /^1$/);
   return $stream;
   }

#
# local=>1   unref before clear
# 
sub Hi_Clear     
   {
   my (%opt) = @_;
   
   Hi_RefCtx(setref=>0) if $opt{local};
   
   my $data = Hi_Data();
   @{$data} = ();
   return $data;
   }
   
   
# SIGetHistorySize -external-
#
sub SIGetHistorySize
   {
   my $history = SIHistory();

   return scalar @{$history};
   }


# SIGetHistory -external-
#
sub SIGetHistory
   {
   my ($index) = @_;

   #return FindHistory("", 0) if $index == -1; #todo: ???

   my $history = SIHistory();

   return "" if $index >= SIGetHistorySize();
   return $history->[$index];
   }


# SIFindHistory  -external-
#
# opt
#   direction
#   start    
#   allowregex
#   exact     
#
#
sub SIFindHistory
   {
   my ($search_str, %opt) = @_; # ($search_str, $direction, $start, $exact)

   my $history  = SIHistory();
   my ($match, $newpos) = _FindInList($history, $search_str, %opt);
   return ($match, $newpos) if wantarray;
   return $match;
   }


# FindHistory -internal-
# keeps find state for multiple search matching
#
sub FindHistory
   {
   my ($search_str, $direction, $continue) = @_;

   return SIGetHistory(TVar(fh_lastidx=>0)) if !$direction;

   my ($last_idx, $target) = tv_is(!$continue, fh_lastidx=>0,fh_target=>$search_str);

   my $idx = $last_idx + $direction * $continue;
   $idx  = -1 if !$continue && $direction == -1;

   my ($str, $new_idx) = SIFindHistory ($target, direction=>$direction, start=>$idx);

   TVar(fh_lastidx=>$new_idx);

   return $str;
   }



## -internal-
##
#sub IsHistory
#   {
#   my ($string) = @_;
#
#   return 1 if $string eq SIGetHistory(0);
#   my ($entry, $pos) = SIFindHistory($string);
#   return length $entry ? 1 : 0;
#   }

# SISetHistory -external-
#
# adds/modifies/deletes a history string
#
# SISetHistory(-1, string)  # add a history string
# SISetHistory(#,  string)  # change a history string
# SISetHistory(-1, undef )  # delete latest history string
#
sub SISetHistory
   {
   my ($index, $string) = @_;

   # add
   return SIAddHistory($string) if $index == -1;
   return 0 if $index >= SIGetHistorySize();

   my $history = SIHistory();

   # delete
   splice(@{$history}, $index, 1) if $string == undef;

   # mod
   $history->[$index] = $string  if $string != undef;

   SIHistory($history);
   return 1; 
   }


sub SIAddHistory
   {
   my ($string, $allowdups) = @_;

#   return 0 unless $string && length($string) > $MIN_SAVE_LENGTH;
#
#   my $history      = SIHistory();
#   my $history_size = SIGetHistorySize();
#
#   while (!$allowdups)
#      {
#      my ($entry, $index) = SIFindHistory($string, exact=>1);
#      last unless length $entry;
#      splice(@{$history}, $index, 1);
#      }
#   unshift(@{$history}, $string);
#
#   pop(@{$history}) if $history_size > $MAX_HISTORY;
#   SIHistory($history);

#  Hi_Import(data=>[$string],add=>1,duplicates=>1);

   return 0 unless $string && length($string) > V(minsavelen=>1);

   my $history      = Hi_Data();
   my $history_size = SIGetHistorySize();

   while (!$allowdups)
      {
      my ($entry, $index) = SIFindHistory($string, exact=>1);
      last unless length $entry;
      splice(@{$history}, $index, 1);
      }
   unshift(@{$history}, $string);

   pop(@{$history}) if $history_size > $MAX_HISTORY;
   Hi_Data(replacedata=>$history);

   return 1;
   }


# -internal-
#  opt
#    skip_all_history
#    skip_{ctx}_history
#
sub Hi_CreateStream
   {
   my (%options) = @_;

   return "" if SkipStream(0, "history", %options);

   SIContext({push=>1});
   my $stream = "";
   foreach my $context (SIContext({ctxlist=>1,all=>1}))
      {
      $stream .= CreateContextHistoryStream($context, %options);
      }
   SIContext({pop=>1});
   return $stream;
   }


#  opt
#    skip_{ctx}_history
#
sub CreateContextHistoryStream
   {
   my ($context, %options) = @_;

   SIContext($context);
   return "" if SkipStream($context, "history", %options);
   
   my $href = VarDefault($NAM_HISTORY_REF=>0);
   return "sihistref:$context:$href\n" if ($href);
   
   my $history = SIHistory();
   my $stream = "";
   foreach my $entry (@{$history})
      {
      $stream .= "sihist:$context:$entry\n";
      }
   return $stream;
   }


#  opt
#    skip_all_history
#    skip_{ctx}_history
#
sub Hi_LoadStream
   {
   my ($stream, %options) = @_;

   return 0 if SkipStream(0, "history", %options);

   my $all_history = {};
   my $all_history_ref = {};
   foreach my $line(split(/\n/, $stream)) 
      {
      $line = CleanInputLine($line,1,0);
      my ($linetype,$context,$entry) = $line =~ /^(sihist|sihistref):([^:]+):(.*)$/;
      next unless $context && $entry;
      
      $all_history->{$context} = [] if !exists $all_history->{$context};
      
      if ($linetype eq "sihistref")
         {
         $all_history_ref->{$context} = $entry;
         }
      else
         {
         push(@{$all_history->{$context}}, $entry);
         }
      }
   SIContext({push=>1});
   foreach my $context (keys %{$all_history})
      {
      SIContext($context);
      next if SkipStream($context, "history", %options);
      VarSet($NAM_HISTORY=>$all_history->{$context});
      }
   foreach my $context (keys %{$all_history_ref})
      {
      SIContext($context);
      next if SkipStream($context, "history", %options);
      VarSet($NAM_HISTORY_REF=>$all_history_ref->{$context});
      }
   SIContext({pop=>1});

   #map{PVar($_,$all_history->{$_}) keys %{$all_history};
   #AllHistory($all_history);
   return 1;
   }



1;