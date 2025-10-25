@import "/templateFiles/bpmSetClass.ck";

oscSends send;

OscOut toClient;

//IP Address of clients will need put into this array
string ipAddress[];
8005 => int port;

for(0 => int i; i < ipAddress.size()-1; i++){
    toClient.dest(ipAddress[i], port);
}

120 => int bpm;

while(true){
    toClient.start("/bpm");
    toClient.add(bpm);
    toClient.send();
}

