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

