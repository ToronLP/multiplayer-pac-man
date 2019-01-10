#define server_create
///server_create(port)

var 
port = argument0,
server = 0;

server = network_create_server_raw(network_socket_tcp, port, 20);
clientmap = ds_map_create();
client_id_counter = 0;

send_buffer = buffer_create(256, buffer_fixed, 1);

if(server < 0) show_error("Could not Create Server!", true);

return server;

#define server_handle_connect
///server_handle_connect(socket_id);

var
socket_id = argument0;

l = instance_create(0, 0, oServerClient);
l.socket_id = socket_id;
l.client_id = client_id_counter++;

if(client_id_counter >= 65000){
    client_id_counter = 0;
}

clientmap[? string(socket_id)] = l;

#define server_handle_message
///server_handle_message(socket_id, buffer);

var
socket_id = argument0,
buffer = argument1,
clientObject = clientmap[? string(socket_id)],
client_id_current = clientObject.client_id;

while(true){
    var
    message_id = buffer_read(buffer, buffer_u8);
    
    switch(message_id){
        case MESSAGE_MOVE:
            var
            xx = buffer_read(buffer, buffer_u16);
            yy = buffer_read(buffer, buffer_u16);
            
            buffer_seek(send_buffer, buffer_seek_start, 0);
            buffer_write(send_buffer, buffer_u8, MESSAGE_MOVE);
            buffer_write(send_buffer, buffer_u16, client_id_current);
            buffer_write(send_buffer, buffer_u16, xx);
            buffer_write(send_buffer, buffer_u16, yy);
            
            with(oServerClient){
                if(client_id != client_id_current){
                    network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer)); //self and other
                }
            }
        break;
        case MESSAGE_JOIN:
            username = buffer_read(buffer, buffer_string);
            clientObject.name = username;
            
            buffer_seek(send_buffer, buffer_seek_start, 0);
            buffer_write(send_buffer, buffer_u8, MESSAGE_JOIN);
            buffer_write(send_buffer, buffer_u16, client_id_current);
            buffer_write(send_buffer, buffer_string, username);
            
            //sending the newly joining name to all other clients
            with(oServerClient){
                if(client_id != client_id_current){
                    network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));
                }
            }
            
            //send the newly joined client the name of all other clients
            with(oServerClient){
                if(client_id != client_id_current){
                    buffer_seek(other.send_buffer, buffer_seek_start, 0);
                    buffer_write(other.send_buffer, buffer_u8, MESSAGE_JOIN);
                    buffer_write(other.send_buffer, buffer_u16, client_id);
                    buffer_write(other.send_buffer, buffer_string, name);
                    network_send_raw(socket_id, other.send_buffer, buffer_tell(other.send_buffer));
                }
            }
        break;
    }
    
    if(buffer_tell(buffer) == buffer_get_size(buffer)){
        break;
    }
}

#define server_handle_disconnect
///server_handle_disconnect(socket_id);

var
socket_id = argument0;

buffer_seek(send_buffer, buffer_seek_start, 0);
buffer_write(send_buffer, buffer_u8, MESSAGE_LEAVE);
buffer_write(send_buffer, buffer_u16, clientmap[? string(socket_id)].client_id);

with(clientmap[? (string(socket_id))]){
    instance_destroy();
}

ds_map_delete(clientmap, string(socket_id));

with(oServerClient){
    network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));
}
