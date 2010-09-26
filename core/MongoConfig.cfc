<cfcomponent output="false" hint="Main configuration information for MongoDb connections. Defaults are provided, but should be changed as needed. ">
<cfscript>
 variables.conf = {};
 
 public struct function init(server_name='localhost',server_port='27017',db_name='default_db'){
 	setDefaults( argumentcollection = arguments );
 	return this;
 }
 
 public struct function setDefaults(server_name='localhost',server_port='27017',db_name='default_db'){
 	structAppend(conf.defaults,arguments);
 	return conf.defaults;
 }
 
 public struct function getDefaults(){ return conf.defaults; }
 
 
 public struct function getDevDefaults(){ return conf.dev_defaults; }
 public struct function getUATDefaults(){ return conf.uat_defaults; }
 public struct function getProductionDefaults(){ return conf.prod_defaults; }
 

 
 //Default values for server, port, database, and collection
 conf.defaults = {
  server_name = 'localhost',
  server_port = 27017,
  db_name = 'default_db'
 };

//Default props for dev
conf.dev_defaults = {
  server_name = 'localhost',
  server_port = 27017,
  db_name = 'default_db'
 };


//Default props for production
conf.prod_defaults = {
  server_name = 'localhost',
  server_port = 27017,
  db_name = 'default_db'
 };
 
 
 //Default props for staging
conf.uat_defaults = {
  server_name = 'localhost',
  server_port = 27017,
  db_name = 'default_db'
 };
 
</cfscript>
</cfcomponent>