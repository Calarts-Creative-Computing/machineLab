@import "../machineLab/signalSendClasses/OSC/globalOSCSendClass.ck";
OscOut out;

oscSends send;

// Trimpbeat MIDI notes
[60, 61, 62, 63, 64, 65, 66, 67, 68, 69,
70, 71, 72, 73, 74, 75, 76, 77, 78, 79] @=> int tbScl[];

send.init("192.168.1.145", 50000);

fun void tbSend(int note, int vel){
    send.send("/trimpbeat", note, vel);
}

fun void tbPlay(int note, int vel, int msDelay){
    tbSend(note, vel);
    msDelay::ms => now;
    tbSend(note, 0);
}

fun void testBeaters(int speed) {
    <<<"Playing all beaters">>>;
    // Trimpbeat test
    // 60 (0)  is the backboard beater
    // 79 (19) is the woodblock beater
    // 61 - 68 are notes 
    
    // C, G, B, C, F#, G, B, C, E, F, G,  B,  C,  E,  G,  C,  G,  C
    // 1, 2, 3, 4, 5,  6, 7, 8, 9, 10 11, 12, 13, 14, 15, 16, 17, 18
    for(0 => int i; i<tbScl.size(); i++){
        100 => int vel;
        tbPlay(tbScl[i], vel, speed);
    }    
}

testBeaters(100);