//Written by Colton Arnold Fall 2025


@import "../OSC/globalOSCReceiveClass.ck";
@import "../OSC/globalOSCSendClass.ck";
@import "../midi/midiInstrumentClass.ck"

OscMsg msg;
OscIn in;

oscReceive receive;
oscSends send;
midiInstrumentSends midiSendBreak;
midiInstrumentSends midiSendRattle;
midiInstrumentSends midiSendTammy;
midiInstrumentSends midiSendGuna;


string instrument;
int note;
int vel;
string values[3];

// [8000, 8001, 8002, 8003, 8004, 8005, 8006, 8007, 8008, 8009] @=> int clientRecievePorts[];

// for(0 => int i; i < clientRecievePorts.size(); i++){
//     receive.init(clientRecievePorts[i]);
//     <<<"port ", clientRecievePorts[i], " open">>>;
// }

receive.init(8001);
send.init("localhost", 50000);

midiSendBreak.init(1); // breakBot
midiSendRattle.init(4); // rattleTron
midiSendTammy.init(3); // tammy
midiSendGala.init(0); // gunaPati


while(true){

    //1::ms => now;
    //<<<values, "AHHHHHH">>>;

    receive.receive() @=> values;

    values[0] => instrument;
    values[1] => string noteString;
    values[2] => string velString;

    Std.atoi(noteString) => note;
    Std.atoi(velString) => vel;

    
    //<<<("instrument:", instrument, "note: ", note, "vel: ", vel)>>>;

    if(instrument == "/breakBot"){

        midiSendBreak.messageSend(note, vel, 0);
        
        values.clear();

    }

    else if(instrument == "/gunaPati"){

        midiSendGuna.messageSend(note, vel, 0);
        // for(0 => int i; i < values.size(); i++){
        //     chout <= values[i] <= " ";
        // }
        // chout <= IO.newline();
        values.clear();

    }
    
    else if(instrument == "/tammy"){

        midiSendTammy.messageSend(note, vel, 0);
        // for(0 => int i; i < values.size(); i++){
        //     chout <= values[i] <= " ";
        // }
        // chout <= IO.newline();       
        values.clear();

    }

    else if(instrument == "/rattleTron"){

        midiSendRattle.messageSend(note, vel, 0);
        // for(0 => int i; i < values.size(); i++){
        //     chout <= values[i] <= " ";
        // }
        // chout <= IO.newline();
        values.clear();

    }    

    else if(instrument == "/marimba"){

        send.send(instrument, note, vel);
        // for(0 => int i; i < values.size(); i++){
        //     chout <= values[i] <= " ";
        // }
        // chout <= IO.newline();
        values.clear();

    }


    else if(instrument == "/trimpbeat"){

        send.send(instrument, note, vel);
<<<<<<< Updated upstream
        // for(0 => int i; i < values.size(); i++){
        //     chout <= values[i] <= " ";
        // }
        // chout <= IO.newline();
=======
        100::ms => now;
        send.send(instrument, note, 0);
>>>>>>> Stashed changes
        values.clear();

    }
}