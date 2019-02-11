#define server_create
///server_create(port)

var 
port = argument0,                                           //Variable wird gesetzt biem aufrufen des Scripts
server = 0;                                                 //Variable zum überprüfen ob ein Server erstellt wurde

//Erstellen des Servers
server = network_create_server_raw( network_socket_tcp,     //Protokoll TCP ODER UDP
                                    port,                   //Port auf dem der Server erichbar ist.
                                    MAX_ANZ_CLIENTS);       //Maximale anzhal an Clients auf dem Server
clientmap = ds_map_create();                                //Initialisieren der clientmap
client_id_counter[5] = 0;                                   //Der Counter der zur id vergebung benutzt wird
actual_connected_clients = 0;                               //Der Counter der Verwendet wird um an zu zeigen wie viele spieler auf dem Server sind

send_buffer = buffer_create(256, buffer_fixed, 1);          //Der buffer in den die sachen zum senden geschrieben werden

//Überprüfung ob ein Server erstellt wurde
if(server < 0){ 
    show_error("Could not Create Server!", true);           //Error Message ausgeben
}

return server;                                              //Server zurück geben

#define server_handle_connect
///server_handle_connect(socket_id);

var
socket_id = argument0;                          //Variable wird gesetzt biem aufrufen des Scripts

var
l = instance_create(0, 0, oServerClient);       //Erstellen eines ServerClient object

l.socket_id = socket_id;                        //Dien socket_id wird dem neuen ServerClient object zugewiesen
//l.client_id = client_id_counter++;              //Die Client_id wird benutzt um den client idenfizieren zu können da die Socket_id random ist.
/**/

/*Ein int ist 65000+ groß damit der int nicht überläuft wird er wieder zurückgesetzt
if(array_length_1d(client_id_counter)){                 
    client_id_counter = 0;                      //Zurücksetzen des ints
}*/
for(i = 0; i < array_length_1d(client_id_counter); i+=1){
    if(client_id_counter[i]==0){
        l.client_id = i;
        client_id_counter[i]=1;
        break;
    }
}

clientmap[? string(socket_id)] = l;             //erstellen einer Client Map um alle client Objecte zu speichern
actual_connected_clients++;                     //Bei einem Connect wird die Variable für schön hoch gezählt.

buffer_seek(send_buffer, buffer_seek_start, 0);
buffer_write(send_buffer, buffer_u8, MESSAGE_GETID);
buffer_write(send_buffer, buffer_u16, l.client_id);
network_send_raw(socket_id, send_buffer, buffer_tell(send_buffer));

#define server_handle_message
///server_handle_message(socket_id, buffer);

var
socket_id = argument0,                                                                  //Variable wird gesetzt biem aufrufen des Scripts zur identifizierung der Connection
buffer = argument1,                                                                     //Der übergebene buffer in dem die zu erledingenden dinge stehen
clientObject = clientmap[? string(socket_id)],                                          //Holen des Clients anhand der Socket_id
client_id_current = clientObject.client_id;                                             //Holen der Client_id aus dem Client
isGameOver = clientObject.game_over; 

while(true){
    var
    message_id = buffer_read(buffer, buffer_u8);                                        //Es wird geladen was Passiert ob sich ein Client verbindet oder ob ein Client sich bewegt
    
    //welcher status ist aktiv
    switch(message_id){
        //Wenn sich ein Client Bewegt
        case MESSAGE_MOVE:
            var
            xx = buffer_read(buffer,                                                    //Aus dem buffer "buffer" die x position auslesen
                             buffer_u16);                                               //Da der raum größer als 256 ist u16
            yy = buffer_read(buffer,                                                    //Aus dem buffer "buffer" die y position auslesen
                             buffer_u16);                                               //Da der raum größer als 256 ist u16
            
            buffer_seek(send_buffer, buffer_seek_start, 0);                             //Das Schreiben wird am anfang des buffers geschehen.
            buffer_write(send_buffer, buffer_u8, MESSAGE_MOVE);                         //Der status MOVE wird in den send_buffer gespeichert, damit der verarbeitende Client weis das es eine Bewegung/veränderung im Raum ist.
            buffer_write(send_buffer, buffer_u16, client_id_current);                   //Die Client_id wird in den send_buffer gespeichert, damit der Client der sich bewegt identifiziert werden kann.
            buffer_write(send_buffer, buffer_u16, xx);                                  //Die neue x position des Clients wird in den send_buffer gespeichert, damit der Client sich bewegt.
            buffer_write(send_buffer, buffer_u16, yy);                                  //Die neue y position des Clients wird in den send_buffer gespeichert, damit der Client sich bewegt.
            buffer_write(send_buffer, buffer_string, isGameOver);
            
            with(oServerClient){
                //Abfrage, damit nicht an sich selber gesendet wird.
                if(client_id != client_id_current){
                    network_send_raw(self.socket_id,                                    //Die socket_ids werden vom Server Client genommen da er diese schon hat.
                                     other.send_buffer,                                 //Der send_buffer des aktuellen Clients wird gesendet.
                                     buffer_tell(other.send_buffer));                   //Die länge des send_buffers.
                }
            }
        break;
        //Wenn ein Client Connected
        case MESSAGE_JOIN:
            username = buffer_read(buffer, buffer_string);                              //Den Benutzernamen aus dem buffer speichern
            clientObject.name = username;                                               //Den namen des Objektes setzen
            
            buffer_seek(send_buffer, buffer_seek_start, 0);                             //Das Schreiben wird am anfang des buffers geschehen.
            buffer_write(send_buffer, buffer_u8, MESSAGE_JOIN);                         //Der status JOIN wird in den send_buffer gespeichert, damit der verarbeitende Client weis das es eine Bewegung/veränderung im Raum ist.
            buffer_write(send_buffer, buffer_u16, client_id_current);                   //Die Client_id wird in den send_buffer gespeichert, damit der Client der dem Speil beitrit identifiziert werden kann.
            buffer_write(send_buffer, buffer_string, username);                         //Der Username wird in den send_buffer gespeichert, damit die anderen Clients den Benutzernamen das neuen Clients sehen können.
            
            //Den neuen Namen an alle anderen Clients senden
            with(oServerClient){
            //Abfrage, damit nicht an sich selber gesendet wird.
                if(client_id != client_id_current){
                    network_send_raw(self.socket_id,                                    //Die socket_ids werden vom Server Client genommen da er diese schon hat.
                                     other.send_buffer,                                 //Der send_buffer des aktuellen Clients wird gesendet. 
                                     buffer_tell(other.send_buffer));                   //Die länge des send_buffers.
                }
            }
            
            //Dem neuen Client die namen aller anderen senden.
            with(oServerClient){
                if(client_id != client_id_current){
                    buffer_seek(other.send_buffer, buffer_seek_start, 0);               //Das Schreiben wird am anfang des buffers geschehen.
                    buffer_write(other.send_buffer, buffer_u8, MESSAGE_JOIN);           //Der status JOIN wird in den send_buffer gespeichert, damit der verarbeitende Client weis das es eine Bewegung/veränderung im Raum ist.
                    buffer_write(other.send_buffer, buffer_u16, client_id);             //Die Client_ids der anderen Clients
                    buffer_write(other.send_buffer, buffer_string, name);               //Die namen der anderen Clients
                    network_send_raw(socket_id,                                         //Die socket_ids werden vom Server Client genommen da er diese schon hat.
                                     other.send_buffer,                                 //Der send_buffer des aktuellen Clients wird gesendet. 
                                     buffer_tell(other.send_buffer));                   //Die länge des send_buffers.
                }
            }
        break;
    }
    
    //sichert das alles aus dem buffer benutzt wird
    if(buffer_tell(buffer) == buffer_get_size(buffer)){
        break;
    }
}

#define server_handle_disconnect
///server_handle_disconnect(socket_id);

var
socket_id = argument0;                                                                          //Variable wird gesetzt biem aufrufen des Scripts

buffer_seek(send_buffer, buffer_seek_start, 0);
buffer_write(send_buffer, buffer_u8, MESSAGE_LEAVE);
buffer_write(send_buffer, buffer_u16, clientmap[? string(socket_id)].client_id);

client_id_counter[clientmap[? string(socket_id)].client_id]=0;

//Den Client mit der übergebenen socketid aus der Clientmap filtern und entfernen.
with(clientmap[? (string(socket_id))]){
    instance_destroy();                                                                         //Entfernen des Clients aus der Spielumgebung
}

//Den eintrag in der Map löschen
ds_map_delete(clientmap, string(socket_id));


with(oServerClient){
    network_send_raw(self.socket_id, other.send_buffer, buffer_tell(other.send_buffer));
}
actual_connected_clients--;