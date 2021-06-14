use Net::WebSocket::Server;
use Gnu::KeyInput  qw(GetKey);

print("init\n");

my $ws = Net::WebSocket::Server->new(
   listen => 8090,
   tick_period => 5,

   on_connect => sub {
      my ($serv, $conn) = @_;

      $conn->on(
         utf8 => sub {
            my ($conn, $msg) = @_;
            #$conn->send_utf8($msg);
            #print("sending a message\n");

            $conn->send_utf8("loop start...");
            print "loop start...";

            while (my $ct=0, $ct<5, $ct++)
               {
               my $key = GetKey(ignore_ctl_keys=>1, noisy=>1);
               $conn->send_utf8("This is message $ct");
               print "sent a message\n";
               }
            print "loop end...";
         },
      );
      print("on connect\n");
   },

   on_tick => sub {
       my ($serv) = @_;
       #$_->send_utf8(time) for $serv->connections;
       $_->send_utf8("server message") for $serv->connections;
   },

)->start;

#while (my $ct=0, $ct<20, $ct++)
#   {
#   my $key = GetKey(ignore_ctl_keys=>1, noisy=>1);
#
#   $ws->send_utf8("This is message $ct");
#
#   print "sent a message\n";
#   }
#
#print("continue\n");
