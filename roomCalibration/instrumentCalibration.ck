// Created by Colton Arnold Fall 2025

@import "../roomCalibration/Classes/checkVolumeClass.ck";
@import "../machineLabCode/midiInstrumentClass.ck";
@import "../machineLabCode/bpmSetClass.ck";
@import "../machineLabCode/globalOSCSendClass.ck";

oscSends osc;
midiInstrumentSends midiSend;
bpmSet bpmTime;
volumeCheck volCheck;

MidiIn min;
MidiMsg msg;


float volume;
int testVal;
44100 => int sampleRate;
0::second => dur elapsed;

120 => int tempo;
0::second => dur elapsed;

bpmTime.bpm(tempo)::ms => dur beat;

//notes for breakBot
[0, 1, 3, 5, 11] @=> int breakBotArray[];
float breakBotThreshArray[];
int nonFunctionalBreakBot[];

//notes for gunapati
[1, 2, 3, 7, 8, 10, 12, 13, 14] @=> int gunapatiArray[];
float gunapatiThreshArray[];
int nonFunctionalgunapati[];

//notes for tammy
[2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 14] @=> int tammyArray[];
float tammyThreshArray[];
int nonFunctionalTammy[];

//notes for rattleTron
[0, 1, 2, 3, 16] @=> int rattleArray[];
float rattleThreshArray[];
int nonFunctionalRattle[];

fun void breakBot() {
    midiSend.init(1);
    int testVal;
    0::second => dur elapsed;

    for (int i; i < breakBotArray.size(); i++) {
        midiSend.messageSend(breakBotArray[i], 127, 1);
        beat => now;

        while(min.recv(msg)) {
            volCheck.threshHoldCheck("/breakBot", breakBotArray[i], breakBotThreshArray[i]) => testVal;
            if (testVal == 1) {
                now => time start;
                1::ms => now;
                now - start => elapsed;
                <<< "breakBot timelapse (s):", elapsed/second >>>;
            }

            if else(testVal == 0){

                <<<breakBotArray[i], " note does not work">>>;

                nonFunctionalBreakBot << breakBotArray[i];
            }
        }
    }

    for ( 0 => int i; i < nonFunctionalBreakBot.size(); i++ ){
        
        //chout <= results2[i] <= " ";

        chout <= nonFunctionalBreakBot[i] <= " ";
    }
    chout <= IO.newline();
}


fun void gunapati(){

    midiSend.init(0);
    min => now;    
    for(int i; i < 8; i++){
        midiSend.messageSend(gunapatiArray[i], 127, 1);
        beat => now;

        volCheck.threshHoldCheck("/gunaPati", gunapatiArray[i], gunapatiThreshArray[i]);

         if(testVal == 1){
            //...
        } 

    } 
} 

fun void tammyMyLove(){

    midiSend.init(3);
    min => now;
    for(int i; i < 10; i++){
        midiSend.messageSend(tammyArray[i], 127, 1);
        beat => now;

        volCheck.threshHoldCheck("/tammy", tammyArray[i], tammyThreshArrayArray[i]);

        if(testVal == 1){
            //...
        } 

    }
}

fun void rattleTron(){

    midiSend.init(4);
    min => now;
    for(int i; i < 4; i++){
        midiSend.messageSend(rattleArray[i], 127, 1);
        beat => now;

        volCheck.threshHoldCheck("/rattleTron", rattleArray[i], rattleThreshArray[i]);

        if(testVal == 1){
            //...
        } 
        
    }
}
while(true){
    gunapati();
    breakBot();
    tammyMyLove();
    rattleTron();
    1::week => now;

}