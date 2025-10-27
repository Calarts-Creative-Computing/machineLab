@import "/templateFiles/bpmSetClass.ck";

oscSends send;

OscOut toClient1;
OscOut toClient2;
OscOut toClient3;
//add more clients as needed and just copy code below


//IP Address of clients will need put into this array
string ipAddress[];
string clientSend[toClient1, toClient2, toClient3] // add clients as needed
[8005, 8006, 8007] => int port[];

string data[];


for(0 => int i; i < ipAddress.size()-1; i++){
    toClient.dest(ipAddress[i], port[i]);
}



"120" => string bpm;

while(true){
    //copy this code for the number of clients
    //can also add other types of messages, just need to change address
    for(0 => int i; i < clientSend.size() - 1; i++){
        clientSend[i].start("/toClient");
        clentSend[i].add(bpm);
        clientSend[i].send();
    }
}

