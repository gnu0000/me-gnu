#
# CGIUtil.pm -- handle CGI routing & misc
#
# This handles url's of the form:
#    http://craig/cgi-bin/test.pl/resource
#    http://craig/cgi-bin/test.pl/resource/
#    http://craig/cgi-bin/test.pl/resource/99
#    http://craig/cgi-bin/test.pl/resource/99?date=11-11-11
#    http://craig/cgi-bin/test.pl/resource/99?date=11-11-11&fred&barny
#
# Expected routes input:
#    my @routes = (
#       {method => "GET", resource => "stops"    , fn => \&GetStops     },
#       {method => "GET", resource => "positions", fn => \&PostPositions},
#    );
#
# You can also use regexes such as ".*" for method or resource values
#
# fn handlers get the following:
#   my ($id, $params, $resource) = @_;
#
# $id       - return the resource id if present, otherwise it's undef
# $params   - a hashref of the cgi params, if no value is given it is assigned a TRUE value
# $resource - the name of the resource being queried
#

package Gnu::CGIUtil;

use warnings;
use strict;
require Exporter;
use JSON;

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();
our @EXPORT      = qw(Route ReturnText ReturnJSON);
our $VERSION     = 0.20;

sub Route {
   my (@routes) = @_;

   my $method = $ENV{REQUEST_METHOD} || "";
   my $path   = $ENV{PATH_INFO     } || "";

   foreach my $route (@routes) {
      my ($resource, $id) = $path =~ /^\/(\w+)\/?(\d+)?/;
      next unless $resource =~ /$route->{resource}/i;
      next unless $method   =~ /$route->{method}/i;
      my $params = GetParams();
      return &{$route->{fn}}($id, $params, $resource);
   }
   print ReturnText("Unknown Route $method $path");
}


sub GetParams {
   my $query  = $ENV{QUERY_STRING  } || "";
   my $params = {};
   foreach my $paramset (split('&', $query)) {
      my ($name, $val) = split("=", $paramset);
      $val = 1 unless defined $val;
      $params->{$name} = $val;
   }
   return $params;
}


sub ReturnText {
   my ($content) = @_;

   return "Content-type: text/plain\n\n" . $content . "\n";
}


sub ReturnJSON {
   my ($content) = @_;
   print "Content-type: text/json\n\n";
   print to_json($content);
}


1; # two
  
__END__   
