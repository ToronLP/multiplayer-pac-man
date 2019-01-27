#define client_connect
///client_connect(ip, port, name)

var
ip = argument0,                                             //Die IP zu der der Client versucht zu connecten
port = argument1,                                           //Der Port aud dem der Server ereichbar ist
name = argument2;                                           //Der name das Spielers

socket = network_create_socket(network_socket_tcp);         //Das Client socket erstellen
var connect = network_connect_raw(socket, ip, port);        //Eine connection mit dem socket zum Server aufbauen

send_buffer = buffer_create(256, buffer_fixed, 1);          //Der buffer für die zu sendenden sachen.

clientmap = ds_map_create();                                //Eine Clientmap zum speichern der anderen Clients
//Abfrage ob eine Connection hergestellt werden konnte.
if(connect < 0){
    show_error("Could not connect to Server!", true);
}

buffer_seek(send_buffer, buffer_seek_start, 0);             //Das Schreiben wird am anfang des buffers geschehen.
buffer_write(send_buffer, buffer_u8, MESSAGE_JOIN);         //Der Buffer bekommt den status JOIN damit Server und Client wissen was sie machen müssen.
buffer_write(send_buffer, buffer_string, name);             //Der Buffer bekommt den name des neuen Clients
network_send_raw(socket,                                    //Die neue Soket wird gesendet
                 send_buffer,                               //Der send_buffer wird gesendet
                 buffer_tell(send_buffer));                 //Die länge des send_buffer wird ermittelt

#define client_handle_message
///client_handle_message(buffer)

var
buffer = argument0;                                                     //Der buffer aus dem die infos gelesen werden

while(true){
    var
    message_id = buffer_read(buffer, buffer_u8);                        //Es wird geladen was Passiert ist ob sich ein Client verbunden hat oder ob ein Client sich bewegt hat
    
    switch(message_id){
        case MESSAGE_MOVE:
            var                                                         //Der Buffer der gesendet wurde muss in der gleichen Reihenfolge ausgelesen werden wie er geschrieben wurde.
            client = buffer_read(buffer, buffer_u16);                   //Den Client aus dem buffer holen
            xx = buffer_read(buffer, buffer_u16);                       //Die x position des Clients holen
            yy = buffer_read(buffer, buffer_u16);                       //Die y position des Clients holen
            //actsprite = buffer_read(buffer, buffer_string);             //Den Sprite aus dem buffer holen
            clientObject = client_get_object(client);                   //Script zur bestimmung welcher client gemeint ist
            
            clientObject.tim = 0;                                       //
            clientObject.prx = clientObject.x;                          //
            clientObject.pry = clientObject.y;                          //
            clientObject.tox = xx;                                      //Setzen der x position des bewegten clients
            clientObject.toy = yy;                                      //Setzen der y position des bewegten clients
            //clientObject.sprite = actsprite;                            //Den sprite des Clients setzen
            //clientObject.sprite = actsprite;
            
            with(oServerClient){
                if(client_id != client_is_current){
                    network_send_raw(self.socket_id,                    //Die socket_ids werden vom Server Client genommen da er diese schon hat.
                                     other.send_buffer,                 //Der send_buffer des aktuellen Clients wird gesendet.
                                     buffer_tell(other.send_buffer));   //Die länge des send_buffers.
                }
            }
        break;
        case MESSAGE_JOIN:
            var
            client = buffer_read(buffer, buffer_u16);                   //Den Client aus dem buffer holen
            username = buffer_read(buffer, buffer_string);              //Den username aus dem buffer holen
            yoursprite = buffer_read(buffer, buffer_string);            //Den sprite aus dem buffer hoeln
            clientObject = client_get_object(client);                   //Script zur bestimmung welcher client gemeint ist
            
            
            clientObject.name = username;                               //Den namen des Clients setzen
            if(yoursprite != ""){
                clientObject.sprite_index = yoursprite;                     //Den sprite des Clients setzen
            }
        break;
        case MESSAGE_LEAVE:
            var
            client = buffer_read(buffer, buffer_u16);                   //Den Client aus dem buffer holen
            tempObject = client_get_object(client);                     //Script zur bestimmung welcher client gemeint ist
            
            with(tempObject){
                instance_destroy();                                     //Das Object welches Disconnected löschen
            }
        break;
    }
    
    if(buffer_tell(buffer) == buffer_get_size(buffer)){
        break;
    }
}

#define client_disconnect
///client_disconnect()

ds_map_destroy(clientmap);  //Löschen der Map
network_destroy(socket);    //Löschen der socket

#define client_send_movement
///client_send_movement()

buffer_seek(send_buffer, buffer_seek_start, 0);                     //Das Schreiben wird am anfang des buffers geschehen.

buffer_write(send_buffer, buffer_u8, MESSAGE_MOVE);                 //Welche Aktion durchgeführt wird.
buffer_write(send_buffer, buffer_u16, round(oPlayer.x));            //Die Spieler x position
buffer_write(send_buffer, buffer_u16, round(oPlayer.y));            //Die Spieler y position

network_send_raw(socket, send_buffer, buffer_tell(send_buffer));    //Das eigene socket wird benutzt zum identifizieren, der send_buffer wird gesendet mit der länge.

#define client_get_object
///client_get_object(client_id)

var
client_id = argument0;

if(ds_map_exists(clientmap, string(client_id))){        //Wenn der Client schon ein mal eine message vom anderen Client bekommen hat.
    return clientmap[? string(client_id)];              //Die map des Clients zurück geben
}else{
    var l = instance_create(0, 0, oOtherClient);        //Ein neues Object erzäugen für den anderen Client
    clientmap[? string(client_id)] = l;                 //Dem neuen Client eine map zuweisen
    return l;                                           //Den neuen Client zurückgeben
}
