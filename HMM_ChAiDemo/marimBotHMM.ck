//Written by Colton Arnold Fall 2025

@import "../signalSendClasses/OSC/globalOSCSendClass.ck";


oscSends osc;
// Marimba MIDI notes
[45, 47, 48, 50, 52, 53, 54, 55, 57, 59, 
60, 62, 64, 65, 66, 67, 69, 71, 72, 74, 
76, 77, 78, 79, 81, 83, 84, 86, 88, 89, 
90, 91, 93, 95, 96] @=> int mScl[];

HMM hmm;

float durArray[0];
500::ms => dur beat;

// Note Duration HMM
fun void noteDur() {
    32 => int length;

    [0, 1, 0, 2, 1, 1, 1, 1, 2, 1, 1, 1] @=> int observations[];
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

fun void marimbotSend(int note, int vel){

    osc.init("192.168.1.145", 50000);
    osc.send("/marimba", note, vel);

}

fun void marimbotPlay(int note, int vel, dur long){
   marimbotSend(note, vel);
   long => now;
   marimbotSend(note, 0);
}

fun void marimBotOut(){

    noteDur();

    [10, 21, 28, 2, 32, 5, 34, 22, 15, 4] @=> int observations2[];
    hmm.train( 2, 36, observations2 );
    int results2[16];
    hmm.generate( 16, results2 );

    

    // output
    for ( 0 => int i; i < results2.size(); i++ )
    {
        
        //chout <= results2[i] <= " ";
        marimbotPlay( mScl[results2[i]], 127, durArray[i] * beat);

        chout <= results2[i] <= " ";
        
    }
    <<<"Slices">>>;
    chout <= IO.newline();
    durArray.reset();
    chout <= IO.newline();

}


while(true) {
    marimBotOut();
    // shakeShake(1000, 20);
}