///snd_clients_id();

for(var i = 0; i < ds_list_size(socket_list); i++){
    sock = ds_list_find_value(socket_list, i);
    
    var buffer = buffer_create(256, buffer_grow, 1);
    buffer_seek(buffer, buffer_seek_start, 0);
    buffer_write(buffer, buffer_u16, CHAR);
    buffer_write(buffer, buffer_u16, i);
    
    network_send_packet(sock, buffer, buffer_tell(buffer));
    
    buffer_delete(buffer);
}
