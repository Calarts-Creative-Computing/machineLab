//Written by Colton Arnold Fall 2025

@import "../machineLabCode/midiInstrumentClass.ck";
@import "../machineLabCode/bpmSetClass.ck";
@import "../machineLabCode/globalOSCSendClass.ck";

oscSends osc;
midiInstrumentSends midiSend;
bpmSet bpmTime;

120 => int tempo;

<<<bpmTime.bpm(tempo)>>>;

bpmTime.bpm(tempo)::ms => dur beat;

//notes for breakBot
[0, 1, 3, 5, 11] @=> int breakBotArray[];

//notes for gunapati
[1, 2, 3, 7, 8, 10, 12, 13, 14] @=> int gunaPatiArray[];

//notes for tammy
[2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 14] @=> int tammyArray[];

//notes for rattleTron
[0, 1, 2, 3, 16] @=> int rattleArray[];


fun breakBot(){
    midiSend.init(1);
    for(int i; i < 4; i++){
        midiSend.messageSend(breakBotArray[i], 127, 1);
        beat => now; 
    } 
}

fun gunapati(){
    midiSend.init(0);
    for(int i; i < 8; i++){
        midiSend.messageSend(gunaPatiArray[i], 127, 1);
        beat => now;
    } 
} 

fun tammyMyLove(){
    midiSend.init(3);
    for(int i; i < 10; i++){
        midiSend.messageSend(tammyArray[i], 127, 1);
        beat => now;
    }
}

fun rattleTron(){
    midiSend.init(4);
    for(int i; i < 4; i++){
        midiSend.messageSend(rattleArray[i], 127, 1);
        beat => now;
    }
}

gunapati();
//breakBot();
//tammyMyLove();
//rattleTron();
