
<cfcomponent output="false" extends="mxunit.framework.TestCase">
<cfscript>
import cfmongodb.core.*;

function setUp(){
	mongoConfig = createObject('component','cfmongodb.core.MongoConfig');
	mongoConfig.setDefaults(db_name="cfmongodb_tests");
	javaloader = createObject('component','javaloader.javaloader').init([ expandPath("/cfmongodb/lib/mongo-2.1.jar") ]);
	javaloaderFactory = createObject('component','cfmongodb.core.JavaloaderFactory').init(javaloader);
	mongo = createObject('component','cfmongodb.core.Mongo').init(mongoConfig, javaloaderFactory);

	col = 'people';
	atomicCol = 'atomictests';

	doc = {
	    'name'='joe-joe',
	    'address' =  {
	       'street'='123 big top lane',
	       'city'='anytowne',
	       'state'='??',
	       'country'='USA'
	    },
	    'favorite-foods'=['popcicles','hot-dogs','ice-cream','cotton candy']
	  };
}

function tearDown(){
	var delete = {"name"="unittest"};
	var atomicDelete = {};
	mongo.remove( delete, col );
	//mongo.remove(atomicDelete, atomicCol);
}



function deleteTest(){
  mongo.ensureIndex(["somenumber"], col);
  mongo.ensureIndex(["name"], col);
  var doc = {
    'name'='delete me',
    'address' =  {
       'street'='123 bye bye ln',
       'city'='where-ever',
       'state'='??',
       'country'='USA'
    },
	'somenumber' = 1
  };

  doc['_id'] = mongo.save( doc, col );
  debug(doc);

  results = mongo.query(col).$eq('somenumber',1).search();
  debug(results.getQuery().toString());
  debug(results.asArray());


  mongo.remove( doc, col );
  results = mongo.query(col).$eq('name','delete me').search();
  debug(results.getQuery().toString());
  assertEquals( 0, results.size() );
}



function updateTest(){

  var doc = {
    'name'='jabber-walkie',
    'address' =  {
       'street'='456 boom boom',
       'city'='anytowne',
       'state'='??',
       'country'='USA'
    },
    'favorite-foods'=['munchies']
  };
  mongo.save(doc,col);
  results = mongo.query(col).startsWith('name','jabber').search();

  //debug(results.getQuery());


  replace_this = results.asArray()[1];
  replace_this['name'] = 'bill';
  mongo.update( replace_this, col );
  results = mongo.query(col).$eq('name', 'bill' ).search().size();
  mongo.remove( replace_this, col );
  assert( results == 1, "results should have been 1 but was #results#" );
}


function testSearch(){
  var initial = mongo.query(col).startsWith('name','unittest').search().asArray();
  debug(initial);

  var addNew = 5;
  var people = createPeople( addNew, true );
  var afterSave = mongo.query(col).startsWith('name','unittest').search().asArray();

  assertEquals( arrayLen(afterSave), arrayLen(initial) + addNew );
}


function testStoreDoc(){
  debug(doc);
  id = mongo.save( doc, col );
  assert( id is not '' );
  mongo.remove( doc, col );
}

function search_sort_should_be_applied(){
	var people = createPeople(5, true);
	var asc = mongo.query(col).$eq("name","unittest").search();
	var desc = mongo.query(col).$eq("name","unittest").search(sort={"name"=-1});

	var ascResults = asc.asArray();
	var descResults = desc.asArray();
	debug( desc.getQuery().toString() );

	debug(ascResults);
	debug(descResults);

	assertEquals( ascResults[1].age, descResults[ desc.size() ].age  );
}

function search_limit_should_be_applied(){
	var people = createPeople(5, true);
	var limit = 2;

	var full = mongo.query(col).$eq("name","unittest").search();
	var limited = mongo.query(col).$eq("name","unittest").search(limit=limit);
	assertEquals(limit, limited.size());
	assertTrue( full.size() GT limited.size() );
}

function search_skip_should_be_applied(){
	var people = createPeople(5, true);
	var skip = 1;
	var full = mongo.query(col).$eq("name","unittest").search();
	var skipped = mongo.query(col).$eq("name","unittest").search(skip=skip);

	assertEquals(full.asArray()[2] , skipped.asArray()[1], "lemme splain, Lucy: since we're skipping 1, then the first element of skipped should be the second element of full" );
}

private function createPeople( count=5, save="true" ){
	var i = 1;
	var people = [];
	for(i = 1; i LTE count; i++){
		var person = {
			"name"="unittest",
			"age"=randRange(10,100),
			"now"=getTickCount(),
			"counter"=i,
			inprocess=false
		};
		arrayAppend(people, person);
	}
	if(save){
		mongo.saveAll(people, col);
	}
	return people;
}

function findAndModify_should_atomically_update_and_return_new(){
	var collection = "atomictests";
	var count = 5;
	var people = createPeople(count=count, save="false");
	mongo.ensureIndex(["INPROCESS"], atomicCol);
	mongo.saveAll(people, atomicCol);

	flush();


	//get total inprocess count
	var inprocess = mongo.query(atomicCol).$eq("INPROCESS",false).search().size();


	//guard
	assertEquals(count, arrayLen(people));
	var query = {inprocess=false};
	var update = {inprocess=true, started=now(),owner=cgi.SERVER_NAME};
	var new = mongo.findAndModify(query=query, update=update, collectionName=atomicCol);
	flush();
	debug(new);

	assertTrue( structKeyExists(new, "age") );
	assertTrue( structKeyExists(new, "name") );
	assertTrue( structKeyExists(new, "now") );
	assertTrue( structKeyExists(new, "started") );
	assertEquals( true, new.inprocess );
	assertEquals( cgi.SERVER_NAME, new.owner );


	var newinprocess = mongo.query(atomicCol).$eq("INPROCESS",false).search().size();


	assertEquals(inprocess-1, newinprocess);
}


function testGetIndexes(){
	var result = mongo.dropIndexes(collectionName=col);
	//guard
	assertEquals( 1, arrayLen(result), "always an index on _id" );

	mongo.ensureIndex( collectionName=col, fields=["name"]);
	mongo.ensureIndex( collectionName=col, fields=[{"name"=1},{"address.state"=-1}]);
	result = mongo.getIndexes( col );
	debug(result);

	assertTrue( arrayLen(result) GT 1, "Should be at least 2: 1 for the _id, and one for the index we just added");
}

function testListCommandsViaMongoDriver(){
	var result = mongo.getMongoDB().command("listCommands");
	debug(result);
	assertTrue( structKeyExists(result, "commands") );
	//NOTE: this is not a true CF struct, but a regular java hashmap; consequently, it is case sensitive!
	assertTrue( structCount(result["commands"]) GT 1);
}


/** test java getters */
function testGetMongo(){
  assertIsTypeOf( mongo, "cfmongodb.core.Mongo" );
}

function getMongo_should_return_underlying_java_Mongo(){
	var jMongo = mongo.getMongo();
	assertEquals("com.mongodb.Mongo",jMongo.getClass().getCanonicalName());
}

function getMongoDB_should_return_underlying_java_MongoDB(){

	var jMongoDB = mongo.getMongoDB(mongoConfig);
	assertEquals("com.mongodb.DBApiLayer",jMongoDB.getClass().getCanonicalName());
}

function getMongoDBCollection_should_return_underlying_java_DBCollection(){
	var jColl = mongo.getMongoDBCollection(col, mongoConfig);
	assertEquals("com.mongodb.DBApiLayer.mycollection",jColl.getClass().getCanonicalName());
}


/** dumping grounnd for proof of concept tests */

function poc_profiling(){
	u = mongo.getMongoUtil();
	var command = u.newDBObjectFromStruct({"profile"=2});
	var result = mongo.getMongoDB().command( command );
	debug(result);

	var result = mongo.query("system.profile").search(limit=50,sort={"ts"=-1}).asArray();
	debug(result);

	command = u.newDBObjectFromStruct({"profile"=0});
	result = mongo.getMongoDB().command( command );
	debug(result);
}

private function flush(){
	//forces mongo to flush
	mongo.getMongoDB().getLastError();
}


function cheapJavaloaderBenchmark(){
	var i = 1;
	var startTS = getTickCount();
	var jdbo = "";
	var dbo = "";

	for(i=1; i LTE 100; i++){
		jdbo = javaloaderFactory.getObject("com.mongodb.BasicDBObject");
	}
	var total = getTickCount() - startTS;
	debug("javaloader total: #total#");

	var defaultFactory = createObject("cfmongodb.core.DefaultFactory");

	startTS = getTickCount();
	for(i=1; i LTE 100; i++){
		dbo = defaultFactory.getObject("com.mongodb.BasicDBObject");
	}
	var total = getTickCount() - startTS;
	debug("default total: #total#");

	//clone the last javaloader dbo
	startTS = getTickCount();
	for(i=1; i LTE 100; i++){
		jdboc = jdbo.clone();
	}
	var total = getTickCount() - startTS;
	debug("jdbo clone total: #total#");

	//clone the last cf dbo
	startTS = getTickCount();
	for(i=1; i LTE 100; i++){
		jdboc = dbo.clone();
	}
	var total = getTickCount() - startTS;
	debug("dbo clone total: #total#");

	debug(getMetadata(jdbo));
	debug(getMetadata(dbo));

	var dmethods = jdbo.getClass().getMethods();
	//debug(dmethods);
	var allMethods = {};
	for(i = 1; i LTE arrayLen(dmethods); i++){
		allMethods[dMethods[i].getName()] = true;
	}

	debug(allMethods);

}

 </cfscript>
</cfcomponent>

