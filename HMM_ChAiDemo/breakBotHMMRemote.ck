// Created by Colton Arnold Fall 2025

@import "../signalSendClasses/midi/midiInstrumentClass.ck";
@import "../bpmSetClass.ck";
@import "../signalSendClasses/OSC/globalOSCSendClass.ck";

HMM hmm;
oscSends osc;
midiInstrumentSends midiSend;
bpmSet bpmTime;

"192.168.1.145" => string ipAddress;
8001 => int port;

<<<bpmTime.bpm(120)>>>;


float durArray[0];
bpmTime.bpm(120)::ms => dur beat;

fun void noteDur() {
    32 => int length;

    [0,0,0,0,1,2,1,2,] @=> int observations[];
    hmm.train(2, 3, observations);

    int results1[length];
    hmm.generate(length, results1);

    0.0 => float counter;

    for (0 => int i; counter < 16 && i < length; i++) {
        float dur;

        if (results1[i] == 0) { 0.5 => dur; }
        else if (results1[i] == 1) { 1.0 => dur; }
        else if (results1[i] == 2) { 2.0 => dur; }
        else { continue; }

        counter + dur => counter;
        durArray << dur;
        chout <= results1[i] <= " ";
    }

    chout <= IO.newline();

    if (counter > 16.0) {
        counter - 16.0 => float remainder;
        <<<"Over by:", remainder>>>;

        // Remove last duration
        durArray[durArray.size() - 1]=> float lastDur;
        counter - lastDur => counter;

        // Add back trimmed duration if remainder is less than the last duration
        if (lastDur - remainder > 0.0) {
            durArray << (lastDur - remainder);
            counter + (lastDur - remainder) => counter;
        }
    }

    <<<"Final duration sum:", counter>>>;

}

// it does not need note offs, but its a good habit
// to get used to sending them
fun void drumbotPlay(int note, int vel, dur long){
    drumbotSend(note, vel);   
    long => now;
    drumbotSend(note, 0);
}

fun void drumbotSend(int note, int vel){
    osc.init(ipAddress, port);
    osc.send("/breakBot", note, vel);

    
}

fun void drumBotOut(){

    noteDur();

    [0, 0, 1, 0, 0, 1, 1] @=> int observations2[];
    hmm.train( 2, 2, observations2 );
    int results2[16];
    hmm.generate( 16, results2 );

    

    // output
    for ( 0 => int i; i < results2.size(); i++ )
    {
        
        //chout <= results2[i] <= " ";
        drumbotPlay(results2[i], 127, durArray[i] * beat);

        chout <= results2[i] <= " ";
        
    }
    <<<"Slices">>>;
    chout <= IO.newline();
    durArray.reset();
    chout <= IO.newline();

}


// drumbot accepts 0-12
// as of 02/10/2017 BreakBot is in the following state ...
// 0-1 - Kick, working well
// 2   - XXXXXX - Does Nothing
// 3   - Snare - missing beater - nice actuator sound
// 4   - XXXXXX - Does nothing
// 5   - Brush on Snare - use many quick pulses to move smoothly
// 6   - Ride Beater #1- Broken - Quiet Clicking Sound 
// 7   - Ride Dampener #1, out of position, makes mechanical sound
// 8   - Ride Beater #2 - Needs high velocity to actuate
// 9   - Ride Dampener #2, out of position, makes mechanical sound
// 10  - Crash Single Beater - Broken Stick - some mechanical sound on high velocitites
// 11  - Crash Double Beater #1 - works well
// 12  - Crash Double Beater #2 - works well
while (true) {
    drumBotOut();
}