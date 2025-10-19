@import "../machineLab/signalSendClasses/OSC/globalOSCSendClass.ck";


// Trimpbeat MIDI notes
[60, 61, 62, 63, 64, 65, 66, 67, 68, 69,
70, 71, 72, 73, 74, 75, 76, 77, 78, 79] @=> int tbScl[];

oscSends send;

fun void tbSend(int note, int vel){
    out.start("/trimpbeat");
    out.add(note);
    out.add(vel);
    out.send();
}

fun void tbPlay(int note, int vel, int msDelay){
    tbSend(note, vel);
    msDelay::ms => now;
    tbSend(note, 0);
}

// for(0 => int i; i < tbScl.size(); i++){
//     tbPlay(tbScl[i], 127, 100);
//     //100::ms => now;
// }

