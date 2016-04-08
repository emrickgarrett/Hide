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

