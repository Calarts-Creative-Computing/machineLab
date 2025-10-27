OscIn in;
OscMsg msg;
OscOut localSend

[8005, 8006, 8007] => int conductorReceive

//change the number of the array
in.port(conductorReceive[0]);

["/bpm"] => string address;

localSend.("localhost", 7001)

fun string[] receive() {
    in.listenAll();
    //in.addAddress(instrument);
    while( true )
    {
        // for(0 => int i; i < 3; i++){
        //     <<<data[i]>>>;
        // }
        // wait for event to arrive
        //in => now;
        data.clear();
        //<<<data, "data cleared">>>;

        // grab the next message from the queue. 
        while( in.recv(msg) )
        { 
            // expected datatypes
            //fetch Address
            msg.address => string address[0];


            msg.getString(0) => string bpmString;

            data << address[0];
            data << bpmString
            
            return data;
        }
        
    }
    return [""];
}

while(true){
    in.listenAll();
    
    receive() => string receivedMsg[];

    Std.atoi(receivedMsg[1]) => int recievedBpm

    while( in.recv(msg) )
    { 
        localSend.start("/fromConductor");
        localSend.add(recievedBPM);
        localSend.send();
            
    }
        
}


    




