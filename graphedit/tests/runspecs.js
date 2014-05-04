//runspecs.js
// thanks http://digitalbush.com/2011/03/29/testing-jquery-plugins-with-node-js-and-jasmine/

//fake browser window
global.document = require("jsdom").jsdom();
global.window = global.document
                .createWindow();
global.window.jQuery = require("jquery");
global.d3 = require("d3");

//Test framework
var jasmine=require('jasmine-node');
for(var key in jasmine) {
  global[key] = jasmine[key];
}

//What we're testing
require("../js/graphedit.js")
var options = {
	'specFolders':[__dirname + '/spec/js'], 
	'onComplete': function(runner, log){  
    	process.exit(runner.results().failedCount?1:0);
	},
	'useRequireJs': false, 
	'useColors':true,
	'isVerbose':true
} //options

jasmine.executeSpecsInFolder(options);
