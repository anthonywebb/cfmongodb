<cfcomponent accessors="true">

	<cfproperty name="mongoFactory">

<cfscript>

	function init(mongoFactory=""){
		if(isSimpleValue(mongoFactory)){
			arguments.mongoFactory = createObject("component", "DefaultFactory");
		}
		variables.mongoFactory = arguments.mongoFactory;
	}

	function newDBObject(){
		var dbo = mongoFactory.getObject('com.mongodb.BasicDBObject');
		dbo.init();
		return dbo;
	}

	function toMongo(any data){
		//for now, assume it's a struct to DBO conversion
		return newDBObjectFromStruct( data );
	}

	function newDBObjectFromStruct(Struct data){
		var key = "";
		var dbo = newDBObject();
		for(key in data){
			dbo.put(key,toJavaType(data[key]));
		}
		return dbo;
	}

	function newObjectIDFromID(String id){
		return mongoFactory.getObject("org.bson.types.ObjectId").init(id);
	}

	function newIDCriteriaObject(String id){
		return newDBObject().init("_id",newObjectIDFromID(id));
	}

	function dbObjectToStruct(BasicDBObject){
		var s = {};
		s.putAll(BasicDBObject);
		return s;
	}

	function toJavaType(value){
		if(isNull(value)) return "";
		if(not isNumeric(value) AND isBoolean(value)) return javacast("boolean",value);
		if(isNumeric(value) and find(".",value)) return javacast("double",value);
		if(isNumeric(value)) return javacast("long",value);
		return value;
	}

</cfscript>
</cfcomponent>