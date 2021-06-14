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
      $.getJSON( "data.json", function(result){
         self.AddMessage(result.name);
      });
   };

   this.AddMessage = function(){
      self.messageDiv.append("<p>Hello there</p>");
   };

   this.Init(options);
};