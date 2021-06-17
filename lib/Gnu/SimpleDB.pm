#
# SimpleDB.pm 
# 

package Gnu::SimpleDB;

use warnings;
use strict;
require Exporter;
use DBI;
use DBD::mysql;
use Gnu::ArgParse;

our $VERSION   = 0.10;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw();
our @EXPORT    = qw(Connect
                    ConnectMSSQL
                    FetchColumn
                    FetchRow
                    FetchArray
                    FetchHash
                    ExecSQL
                    FetchRowAsArray
                    GetInsertId);
our %EXPORT_TAGS = (ALL=>[@EXPORT_OK]);

###############################################################################

# all params have defaults except $database
#
sub Connect
   {
   my ($database,$host,$username,$password) = @_;

   $host     ||= ArgGet("host"    ) || "localhost";
   $username ||= ArgGet("username") || "craig"    ;
   $password ||= ArgGet("password") || "a"        ;

#   return DBI->connect("DBI:mysql:host=$host;database=$database;user=$username;password=$password") or die "cant connect to $database";

   my $dbh = DBI->connect(
    "dbi:mysql:dbname=$database", 
    $username, $password,
     {RaiseError => 0, PrintError => 0, mysql_enable_utf8 => 1}
    ) or die "Connect to database failed [dbname=$database,username=$username,password=$password].";
    return $dbh;
   }

sub ConnectMSSQL
   {
   my ($server, $database) = @_;  # ($database) also valid

   if (scalar @_ < 2) # single param means a db was provided
      {
      $database = $server;
      $server   = "adepttrunk";
      }
   print "Connection to server:$server, database:$database\n";
   #my $DSN = "driver={SQL Server};Server=$server;database=$database;TrustedConnection=Yes";
   my $DSN = "driver={SQL Server};Server=$server;UID=ieuser;PWD=XXXXXXX;database=$database;TrustedConnection=Yes";
   my $dbh = DBI->connect("dbi:ODBC:$DSN") or die "Connect to database failed.";

   return $dbh;
   }

# get a single row as a hashref
#
sub FetchRow
   {
   my ($db, $sql, @bindparams) = @_;

   my $results = $db->selectrow_hashref($sql, {}, @bindparams);
   return $results;
   }

# get an array of row hashrefs
#
sub FetchArray
   {
   my ($db, $sql, @bindparams) = @_;

   my $sth = $db->prepare ($sql) or return undef;

   $sth->{'LongReadLen'} = 50000; # sqlserver

   $sth->execute (@bindparams);
   my $results = $sth->fetchall_arrayref({});
   $sth->finish();
   #my $results = $db->selectall_arrayref($sql, {}, @bindparams);

   return $results;
   }


# get a hashref (keyed by field $key) of row hashrefs
#
sub FetchHash
   {
   my ($db, $key, $sql, @bindparams) = @_;

   my $sth = $db->prepare ($sql) or return undef;

   $sth->{'LongReadLen'} = 50000; # sqlserver

   $sth->execute (@bindparams);
   my $results = $sth->fetchall_hashref($key);
   $sth->finish();

   #my $results = $db->selectall_hashref($sql, $key, {}, @bindparams);

   return $results;
   }


# get a single row as an array
#
sub FetchRowAsArray
   {
   my ($db, $sql, @bindparams) = @_;

   my @row = $db->selectrow_array ($sql, {}, @bindparams);
   return @row;
   }


# get a single field from a row
#
sub FetchColumn
   {
   my ($db, $sql, @bindparams) = @_;

   my @row = FetchRowAsArray($db, $sql, @bindparams);
   return $row[0];
   }

#
# general exec
#
sub ExecSQL
   {
   my ($db, $sql, @bindparams) = @_;

   my $sth = $db->prepare ($sql) or return undef;
   $sth->execute (@bindparams) or die $sth->errstr;
   $sth->finish();
   }


#
# get last insert id
#
sub GetInsertId
   {
   my ($db) = @_;

   return $db->{mysql_insertid};
   }


1; # two
  
__END__   
