#
# TinyDB.pm 
# 

package Gnu::TinyDB;

use warnings;
use strict;
use feature 'state';
require Exporter;
use DBI;
use DBD::mysql;
use Gnu::SimpleDB qw();

our @ISA         = qw(Exporter);
our @EXPORT      = qw(Connection
                      FetchColumn
                      FetchRow
                      FetchArray
                      FetchHash
                      ExecSQL
                      FetchRowAsArray
                      GetInsertId);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);
our $VERSION     = 0.10;

###############################################################################

# all params have defaults except $database
#
sub Connection # ($database,$host,$username,$password) 
   {
   state $db;
   $db = Gnu::SimpleDB::Connect(@_) if scalar @_;
   return $db;
   }

sub FetchRow # ($sql)
   {
   return Gnu::SimpleDB::FetchRow(Connection(), @_)
   }

sub FetchArray # ($sql)
   {
   return Gnu::SimpleDB::FetchArray(Connection(), @_)
   }

sub FetchHash # ($sql)
   {
   return Gnu::SimpleDB::FetchHash(Connection(), @_)
   }

sub ExecSQL # ($sql, @bindparams)
   {
   return Gnu::SimpleDB::ExecSQL(Connection(), @_)
   }

sub FetchRowAsArray # ($sql)
   {
   return Gnu::SimpleDB::FetchRowAsArray(Connection(), @_)
   }

sub FetchColumn # ($sql)
   {
   return Gnu::SimpleDB::FetchColumn(Connection(), @_)
   }

sub GetInsertId
   {
   return Gnu::SimpleDB::GetInsertId(Connection())
   }

1; # two
  
__END__   
