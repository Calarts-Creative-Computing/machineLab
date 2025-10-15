//Conceptual Tick System

// --- SETTINGS ---
1::second / 20 => dur TICK_RATE; // 20 ticks per second
8000 => int IN_PORT;
50000 => int OUT_PORT;
"127.0.0.1" => string OUT_ADDR;

// --- OSC SETUP ---

// temporary message buffer
OscMsg msgQueue[0];

// --- GLOBAL EVENT ---
Event tickEvent;
OscRecv recv;
IN_PORT => recv.port;
recv.listen();

recv.event("/note, i f") @=> OscEvent noteEvent; // example message

OscSend send;
send.setHost(OUT_ADDR, OUT_PORT);

// tick loop

fun void ticker() {
    while(true) {
        tickEvent.broadcast(); // broadcast to all listeners
        TICK_RATE => now;      // wait for next tick
    }
}

fun void handleIncoming() {
    while(true) {
        // wait for any new message
        noteEvent => now;

        // when it arrives, copy data
        while(noteEvent.nextMsg()) {
            noteEvent.getInt() => int note;
            noteEvent.getFloat() => float vel;

            <<< "Queued incoming:", note, vel >>>;

            // make an OSC msg
            OscMsg m;
            m.address("/note");
            m.addInt(note);
            m.addFloat(vel);

            // store to queue
            msgQueue << m;
        }
    }
}

fun void sender() {
    while(true) {
        tickEvent => now; // wait for tick signal

        // on each tick, send queued messages
        for(0 => int i; i < msgQueue.size(); i++) {
            send.startMsg(msgQueue[i].address());
            for(0 => int j; j < msgQueue[i].numArgs(); j++) {
                if(msgQueue[i].argType(j) == TYPE_INT)
                    send.addInt(msgQueue[i].getInt(j));
                else if(msgQueue[i].argType(j) == TYPE_FLOAT)
                    send.addFloat(msgQueue[i].getFloat(j));
            }
            <<< "Sent OSC message at tick:", now >>>;
        }

        // clear queue after sending
        msgQueue.clear();
    }
}

// --- TICKER SHRED ---
spork ~ ticker();


// --- MESSAGE HANDLER SHRED ---
spork ~ handleIncoming();

// --- TICK SENDER SHRED ---
spork ~ sender();

 
