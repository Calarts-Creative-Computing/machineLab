//Written by Colton Arnold Fall 2025

public class oscReceive {
    OscIn in;
    OscOut inMonitor;
    OscMsg msg;

    string data[3];
    


    
    // fun void init(int inPort, int inMonitorPort) {
    //     in.port(inPort);
    //     inMonitor.dest("localhost", inMonitorPort);
    // }

        
    fun void init(int inPort) {
        in.port(inPort);
        inMonitor.dest("localhost", 7001);
    }


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
                msg.address => string instrument;
                // fetch note
                msg.getInt(0) => int note;
                // fetch velocity
                msg.getInt(1) => int vel;

                // print
                //<<< "got (via OSC):", instrument, note, vel >>>;
                inMonitor.start(instrument);
                inMonitor.add(note);
                inMonitor.add(vel);
                inMonitor.send(); 

                Std.itoa(note) => string noteString;
                Std.itoa(vel) => string velString;

                data << instrument;
                data << Std.itoa(note);
                data << Std.itoa(vel);
                
                return data;
            }
            
        }
        return [""];
    }
}