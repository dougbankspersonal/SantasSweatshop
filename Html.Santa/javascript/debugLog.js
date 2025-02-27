define([
	'dojo/domReady!'
], function(){
    var debugFlags = {
        "Summary": "on",
        "Cards": "off",
    }

    function debugLog(flag, statement) {
        if (debugFlags[flag] == "on") {
            console.log(statement)
        }
    }

    return {
        debugLog: debugLog,
    };
});