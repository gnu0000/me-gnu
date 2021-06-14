
use strict;
use warnings;
use feature 'state';



sub SIMsg
   {
   my ($code, $msg) = GVarDefault(_si_errorcode=>0,_si_msg=>"");
   return ($msg,$code) if wantarray;
   return $msg;
   }

sub _SetMsg
   {
   my ($ret, $noreplace, $code, $msg) = @_;
   $ret  ||= 0 ;
   $code ||= 0 ; 
   $msg  ||= "";
   return $ret if ($noreplace && GVarInit(_si_errorcode=>0));
      
   GVar(_si_errorcode=>$code, _si_msg=>$msg);
   return $ret;
   }


1;