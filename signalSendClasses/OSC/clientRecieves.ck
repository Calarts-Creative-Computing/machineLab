OscIn in;
OscMsg msg;

in.port(8005);

while(true){
    in.addAddress("/bpm");
    
    while(in.recv(msg)){
        
    }

}