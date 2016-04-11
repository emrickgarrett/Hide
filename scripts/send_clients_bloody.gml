//send_clients_bloody(socket, id);

socket_list = argument[0];
p_id = argument[1];

//Create buffer 
var buffer = buffer_create(256, buffer_grow, 1);
buffer_seek(buffer, buffer_seek_start, 0);
buffer_write(buffer, buffer_u16, BLOODY);
buffer_write(buffer, buffer_u16, p_id);

show_debug_message("Player is bloody!");

//Send buffer to clients
snd_packet_clients(socket_list, buffer);

buffer_delete(buffer);
