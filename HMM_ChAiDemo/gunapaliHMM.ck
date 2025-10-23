//Written by Colton Arnold Fall 2025

HMM hmm;
@import "../signalSendClasses/OSC/globalOSCSendClass.ck"; //osc send for monitor
oscSends osc;

MidiOut mout;

if( !mout.open(0) ) me.exit();

MidiMsg  msg;

float durArray[0];
500::ms => dur beat;

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
 // MIDI note on message
    // 0x90 + channel (0 in this case)
    0x90 => msg.data1;
    // pitch
    note => msg.data2;
    // velocity
    45 => msg.data3;
    // print
    <<< "sending NOTE ON message...", "" >>>;
    // send MIDI message
    mout.send( msg );

    // let time pass
    
    // MIDI note off message
    // 0x80 + channel (0 in this case)
    0x80 => msg.data1;
    // pitch
    note => msg.data2;
    // velocity
    0 => msg.data3;
    // print
    <<< "sending NOTE OFF message...", "" >>>;
    // send MIDI message
    mout.send( msg );
}

fun void drumBotOut(){

    noteDur();

    [2, 4, 1, 3, 3, 1, 1] @=> int observations2[];
    hmm.train( 2, 6, observations2 );
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