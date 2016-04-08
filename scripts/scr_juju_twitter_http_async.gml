///scr_juju_twitter_http_async( [report level] )
//  
//  Processes HTTP responses from Twitter, directing them towards callback scripts if necessary.
//  
//  "report level" is an optional argument that controls how much information is sent to the compile form:
//    0:  No reporting, not even errors
//    1:  Report only errors. (Default)
//    2:  Reports errors and the result of most recieved data.
//    3:  Reports all information, including potentially sensitive information.
//  
//  Copyright (c) 2016 Julian T. Adams / @jujuadams
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the //  Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the //  Software,
//  and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in allcopies or substantial portions of the
//  Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A //  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

var asyncLoad = async_load;

if ( argument_count > 0 ) var reporting = argument[0] else reporting = 1;

//Grab the contents of the async_load map
var ID          = ds_map_find_value( asyncLoad, "id" );
var status      = ds_map_find_value( asyncLoad, "status" );
var result      = ds_map_find_value( asyncLoad, "result" );
var url         = ds_map_find_value( asyncLoad, "url" );
var http_status = ds_map_find_value( asyncLoad, "http_status" );

//Try to find this request id in the HTTP request log
var name = ds_map_find_value( global.juju_twitter_httpMap, ID );

if ( is_undefined( name ) ) {
    
    //If we can't find the HTTP request
    if ( reporting >= 2 ) show_debug_message( "scr_juju_twitter_http_async: Error! Unrecognised request id (" + string( name ) + ")" );
    
} else {
    
    if ( status < 0 ) {
        
        //If there's been some kind of error
        if ( reporting >= 1 ) show_debug_message( "scr_juju_twitter_http_async [" + string( name ) + "]: Error! HTTP request failed " + string( url ) + ": " + string( status ) + "/" + string( http_status ) );
        
    } else {
        
        if ( reporting >= 2 ) and ( status == 0 ) show_debug_message( "scr_juju_twitter_http_async: " + string( name ) );
        
        clipboard_set_text( result );
        
        //Decode the JSON
        
        if ( is_undefined( result ) ) result = "{}";
        var json = json_decode( result );
        
        switch( name ) {
            
            //Handle authorisation token receipt
            case "oauth2token":
                var tokenType = ds_map_find_value( json, "token_type" );
                if ( !is_undefined( tokenType ) ) {
                    if ( tokenType == "bearer" ) {
                        global.juju_twitter_token = ds_map_find_value( json, "access_token" );
                        if ( reporting >= 3 ) show_debug_message( "scr_juju_twitter_http_async [oauth2/token]: token received " + string( global.juju_twitter_token ) );
                    } else {
                        global.juju_twitter_token = "";
                        if ( reporting >= 1 ) show_debug_message( "scr_juju_twitter_http_async [oauth2/token]: Error! Unrecognised token_type " + string( tokenType ) );
                    }
                } else {
                    global.juju_twitter_token = "";
                    if ( reporting >= 1 ) show_debug_message( "scr_juju_twitter_http_async [oauth2/token]: Error! No token found" );
                }
            break;
            
            //---
            //Expansion room to include other features
            //---
            
            //Catch all other names
            default:
                
                if ( status == 0 ) {
                    var scr = ds_map_find_value( global.juju_twitter_callbackMap, name );
                    if ( !is_undefined( scr ) ) {
                        script_execute( scr, json );
                    } else {
                        if ( reporting >= 1 ) show_debug_message( "scr_juju_twitter_http_async: Error! No callback found for " + string( name ) );
                    }
                } else {
                    if ( reporting >= 2 ) show_debug_message( "scr_juju_twitter_http_async [" + string( name ) + "]: Waiting... (" + string( status ) + ")" );
                }
                
            break;
            
        }
        
        //Destroy the JSON
        if ( ds_exists( json, ds_type_map ) ) ds_map_destroy( json );
        
    }
}

