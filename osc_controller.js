// Do whatever you want
// initialize variables
// declare functions
// load modules
// etc

module.exports = {

    init: function(){
        // this will be executed once when the osc server starts
    },

    oscInFilter:function(data){
        // Filter incoming osc messages

        var {address, args, host, port} = data

        // do what you want

        // address = string
        // args = array of {value, type} objects
        // host = string
        // port = integer

        // return data if you want the message to be processed
        return {address, args, host, port}

    },

    oscOutFilter:function(data){
        // Filter outgoing osc messages

        var {address, args, host, port, clientId} = data

        // prevent sending /bass_line and /chord_line messages to client
        // the corresponding scripts will send a different message on completion of onTouch
        if (address === '/bass_line' || address === '/chord_line') {
            // bypass original osc message
            return
        }

        // return data if you want the message to be and sent
        return {address, args, host, port}
    },

    unload: function(){
        // this will be executed when the custom module is reloaded
    },

}
