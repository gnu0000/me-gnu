$(function() {
   var scene = new PageHandler($("#petridish"));
});

function PageHandler(options){
   var self = this;

   this.Init = function(options){
      self.InitAttributes(options);
      self.InitEvents();
      self.InitState ();
   };

   this.InitAttributes = function(options){
      self.messageDiv = $("#messages");
   };
   
   this.InitEvents = function(){
   };

   this.InitState = function(){
      //self.interval = setInterval(self.AddMessage, 3000);

      self.SetupSocket();
   };

   this.AddMessage = function(){
      self.messageDiv.append("<p>Hello there</p>");
   };


   this.SetupSocket = function(){
      console.log("setting up");
      self.ws = new WebSocket('ws://localhost:8090');
      console.log("ws is ", self.ws);
      
      self.ws.onopen = function () {
         console.log('WebSocket Opened');

         self.ws.send("client generated message");
         console.log('message sent');
      };

      self.ws.onerror = function (error) {
         console.log('WebSocket Error ' + error);
      };

      self.ws.onmessage = function (e) {
         console.log('Server: ' + e.data);
         self.messageDiv.append("<p>Got: "+e.data+"</p>");

      };

      self.ws.onclose = function() { 
         alert("Connection is closed..."); 
      };

      console.log("added ws events", self.ws);
   };

   this.Init(options);
};