/// ReceivedPacket(buffer, socket, inst)

show_debug_message("Received");

// CONSTANTS
TEST = 0;
KEY = 1;
MOUSE_X = 2;
MOUSE_Y = 3;

var buffer = argument[0];
var socket = argument[1];
var inst = argument[2];
    
//if(buffer >= 0){
    var msgid = buffer_read(buffer, buffer_u16);
    show_debug_message(inst);
    switch(msgid){
        case KEY:
        //A key has been pressed so read the keypress data from the buffer
        break;
        case TEST:
            show_debug_message("Packet received");
            show_debug_message(buffer_read(buffer, buffer_string));
        break;
        }
//}
