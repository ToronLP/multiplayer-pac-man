#define client_connect
///client_connect(ip, port, name)

var
ip = argument0,
port = argument1,
name = argument2;

socket = network_create_socket(network_socket_tcp);
var connect = network_connect_raw(socket, ip, port);

send_buffer = buffer_create(256, buffer_fixed, 1);

clientmap = ds_map_create();

if(connect < 0){
    show_error("Could not connect to Server!", true);
}

buffer_seek(send_buffer, buffer_seek_start, 0);
buffer_write(send_buffer, buffer_u8, MESSAGE_JOIN);
buffer_write(send_buffer, buffer_string, name);
network_send_raw(socket, send_buffer, buffer_tell(send_buffer));

#define client_disconnect
///client_disconnect()

ds_map_destroy(clientmap);
network_destroy(socket);

#define client_handle_message
///client_handle_message(buffer)

var
buffer = argument0;

while(true){
    var
    message_id = buffer_read(buffer, buffer_u8);
    
    switch(message_id){
        case MESSAGE_MOVE:
            var
            client = buffer_read(buffer, buffer_u16);
            xx = buffer_read(buffer, buffer_u16);
            yy = buffer_read(buffer, buffer_u16);
            clientObject = client_get_object(client);
            
            clientObject.tim = 0;
            clientObject.prx = clientObject.x;
            clientObject.pry = clientObject.y;
            clientObject.tox = xx;
            clientObject.toy = yy;
            
            with(oServerClient){
                if(client_id != client_is_current){
                    network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));
                }
            }
        break;
        case MESSAGE_JOIN:
            var
            client = buffer_read(buffer, buffer_u16);
            username = buffer_read(buffer, buffer_string);
            clientObject = client_get_object(client);
            
            clientObject.name = username;
        break;
        case MESSAGE_LEAVE:
            var
            client = buffer_read(buffer, buffer_u16);
            tempObject = client_get_object(client);
            
            with(tempObject){
                instance_destroy();
            }
        break;
    }
    
    if(buffer_tell(buffer) == buffer_get_size(buffer)){
        break;
    }
}

#define client_send_movement
///client_send_movement()

buffer_seek(send_buffer, buffer_seek_start, 0);

buffer_write(send_buffer, buffer_u8, MESSAGE_MOVE);
buffer_write(send_buffer, buffer_u16, round(oPlayer.x));
buffer_write(send_buffer, buffer_u16, round(oPlayer.y));

network_send_raw(socket, send_buffer, buffer_tell(send_buffer));
#define client_get_object
///client_get_object(client_id)

var
client_id = argument0;

//if we've recieved a message from this client before
if(ds_map_exists(clientmap, string(client_id))){
    return clientmap[? string(client_id)];
}else{
    var l = instance_create(0, 0, oOtherClient);
    clientmap[? string(client_id)] = l;
    return l;
}