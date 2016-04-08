#define scr_juju_twitter_init
///scr_juju_twitter_init( consumer key, consumer secret )
//  
//  Establishes the data required for sending HTTP requests to Twitter.
//  These are obtained after registering as a developer with Twitter - https://apps.twitter.com/app/xxxxxxx/keys
//  Do not share your consumer key and consumer secret with anyone.
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

global.juju_twitter_consumerKey = argument0;
global.juju_twitter_consumerSecret = argument1;
global.juju_twitter_token = "";

global.juju_twitter_httpMap = ds_map_create();
global.juju_twitter_callbackMap = ds_map_create();
scr_juju_twitter_request_token();

#define scr_juju_twitter_http_async
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

#define scr_juju_twitter_add_request
///scr_juju_twitter_add_request( id, name )
//  
//  Logs a request id with the Twitter handler system.
//  This is used to process different HTTP packets in different ways within scr_juju_twitter_http_async().
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

var val = ds_map_find_value( global.juju_twitter_httpMap, argument0 );
if ( !is_undefined( val ) ) ds_map_delete( global.juju_twitter_httpMap, argument0 );
ds_map_add( global.juju_twitter_httpMap, argument0, argument1 );

#define scr_juju_twitter_add_callback
///scr_juju_twitter_add_callback( request, script )
//  
//  Adds a GM callback script for a particular Twitter request.
//  Note that you do not need to (and should not) destroy the JSON after your callback scripts are finished using it.
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

var request = argument0;
var scr = argument1;

var name = scr_juju_twitter_request_to_name( request );

var val = ds_map_find_value( global.juju_twitter_callbackMap, name );
if ( !is_undefined( val ) ) ds_map_delete( global.juju_twitter_callbackMap, name );
ds_map_add( global.juju_twitter_callbackMap, name, scr );

#define scr_juju_twitter_request_token
///scr_juju_twitter_request_token()
//  
//  Sends a request for an application-authorisation token to Twitter.
//  This token is required for most read-only operations.
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

var map = ds_map_create();
ds_map_add( map, "Authorization", "Basic " + base64_encode( global.juju_twitter_consumerKey + ":" + global.juju_twitter_consumerSecret ) );
ds_map_add( map, "Content-Type", "application/x-www-form-urlencoded;charset=UTF-8." );
var ID = http_request( "https://api.twitter.com/oauth2/token/", "POST", map, "grant_type=client_credentials" );
ds_map_destroy( map );

scr_juju_twitter_add_request( ID, scr_juju_twitter_request_to_name( "oauth2/token/" ) );

return ID;

#define scr_juju_twitter_request_general
///scr_juju_twitter_request_general( request, string, method )
//  
//  Sends a request to Twitter's REST API. For more commands, see https://dev.twitter.com/rest/public
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

var request = argument0;
var str = argument1;
var method = argument2;

request = string_replace_all( request, "?", "" );
str = string_replace_all( str, "?", "" );
method = string_upper( method );

var map = ds_map_create();
ds_map_add( map, "Authorization", "Bearer " + global.juju_twitter_token );
var ID = http_request( "https://api.twitter.com/1.1/" + request + "?" + str, method, map, "" );
ds_map_destroy( map );

scr_juju_twitter_add_request( ID, scr_juju_twitter_request_to_name( request ) );
return ID;

#define scr_juju_twitter_request_to_name
///scr_juju_twitter_request_to_name( request )
//  
//  Sanitises developer input to the Twitter handling system.
//  Deals with different people adding slashes and question marks in unexpected places.
//  This is hardly exhaustive but will catch most problems.
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

var str = argument0;
str = string_replace_all( str, "?", "" );
str = string_replace_all( str, "/", "" );
str = string_replace_all( str, "\", "" )
return string_lower( str );

#define scr_tweet_readout
///scr_tweet_readout( json )
//  
//  Ugly and unstable string-based readout of Twitter's tweet JSON.
//  Note that you do not need to (and should not) destroy the JSON after your callback scripts are finished using it.
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

var json = argument0;

var list = ds_map_find_value( json, "default" );

var size = ds_list_size( list );
var str = "Tweets from @" + twitterUser + ":";
for( var i = 0; i < size; i++ ) str += "#---#" + ds_map_find_value( ds_list_find_value( list, i ), "text" );

show_message( str );

#define ds_map_readout
///ds_map_readout( map )
//  
//  A tool for reading out map keys. Useful for sanity checking JSON output.
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

var map = argument0;

if ( ds_map_empty( map ) ) return "<empty>";

var str = "";
var key = ds_map_find_first( map );
str += string( key ) + ",";

while( key != ds_map_find_last( map ) ) {
    key = ds_map_find_next( map, key );
    str += string( key ) + ",";
}

return str;

#define scr_search_readout
///scr_search_readout( json )
//  
//  Ugly and unstable string-based readout of Twitter's search JSON.
//  Note that you do not need to (and should not) destroy the JSON after your callback scripts are finished using it.
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

var json = argument0;

var list = ds_map_find_value( json, "statuses" );

var size = ds_list_size( list );
var str = "Tweets from " + string_replace_all( twitterHashtag, "%23", "\#" ) + ":";
for( var i = 0; i < size; i++ ) str += "#---#" + string_replace_all( ds_map_find_value( ds_list_find_value( list, i ), "text" ), "#", "\#" );

show_message( str );

