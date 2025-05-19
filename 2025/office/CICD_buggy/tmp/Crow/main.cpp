#include <crow/app.h>

#include <crow.h>
#include <crow/mustache.h>

int main () {
  
   //Step 1: define the crow application 
   crow::SimpleApp app;

   //step 2: define endpoint at the root directory
   CROW_ROUTE(app, "/<string>") ([](std::string name){
         //return "Hello World";
         auto page = crow::mustache::load("myindex.html");
         crow::mustache::context ctx ({{"person", name}});
         return page.render(ctx); //
   });

   //Step 3: set the port, set the app to run on multiple threads, and run the app 
   app.port(18080).multithreaded().run();

}
