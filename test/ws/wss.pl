use Net::WebSocket::Server;

my $ws = Net::WebSocket::Server->new(
   listen => 8090,
   tick_period => 1,
   on_connect => sub {
      print("on connect\n");
   },
   on_tick => sub {
      my ($serv) = @_;
      $_->send_utf8(time) for $serv->connections;
      print("sent msg\n");
   },
)->start;