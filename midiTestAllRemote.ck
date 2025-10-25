//Written by Colton Arnold Fall 2025
@import "../machineLab/signalSendClasses/OSC/globalOSCSendClass.ck";
@import "../machineLab/templateFiles/bpmSetClass.ck";

oscSends osc;
bpmSet bpmTime;

10 => int tempo;

<<<bpmTime.bpm(tempo)>>>;

bpmTime.bpm(tempo)::ms => dur beat;

//notes for breakBot
[0, 1, 3, 5, 11] @=> int breakBotArray[];

//notes for galapati
[1, 2, 3, 7, 8, 10, 12, 13, 14] @=> int galaPatiArray[];

//notes for tammy
[2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 14] @=> int tammyArray[];

//notes for rattleTron
[0, 1, 2, 3, 16] @=> int rattleArray[];


osc.init("192.168.1.145", 8001);

fun breakBot(){

    for(int i; i < 4; i++){
        osc.send("/breakBot", breakBotArray[i], 127);
        beat => now; 
    } 
}

fun galaPati(){
    for(int i; i < 8; 
    i++){
        osc.send("/galaPati", galaPatiArray[i], 127);
        beat => now;
    } 
} 

fun tammyMyLove(){
    for(1 => int i; i > 0; i--){
        osc.send("/tammy", tammyArray[i], 127);
        7::second => now;
    }
}

fun rattleTron(){
    for(int i; i < 4; i++){
        osc.send("/rattletron", rattleArray[i], 127);
        beat => now;
    }
}
1000::ms => now;

//galaPati();
//breakBot();
tammyMyLove();
//rattleTron();
