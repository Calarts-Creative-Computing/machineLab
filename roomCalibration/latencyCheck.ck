@import "../signalSendClasses/midi/midiInstrumentClass.ck";
@import "../signalSendClasses/OSC/globalOSCSendClass.ck";

HMM hmm;
oscSends osc;
midiInstrumentSends midiSend;

[6, 2, 5, 1, 8, 4, 1, 10, 15] => int numMessages;
[60, 90, 127, 20, 80] => int vel;

"/marimba" => string marimba;
"/rattleTron" => string rattleTron;
"/tammy" => string tammy;
"/breakBot" => string breakBot;
"/galaPati" => string galaPati;

[marimba, rattleTron, tammy, breakBot, galapati] => string address[];


//[[marimba[[note, vel]]], [rattleTron[[note, vel]]], [tammy[note, vel]], [breakBot[note, vel]], [galaPati[note, vel]]] => string goodLuckInst[];

fun void notesMakeHMM(){

}

fun void velMakeHMM(){
    
    [0, 0, 1, 0, 0, 1, 1] @=> int observations2[];
    hmm.train( 2, 2, observations2 );
    int velHMM[16];
    hmm.generate(16, velHMM);

}


fun void instrumentPlay(){
    [note, vel] => int messageSend[];
    int notesHMM[0];
    int velHMM[0];


    //note HMM test
    [0, 0, 1, 0, 0, 1, 1] @=> int note[];
    hmm.train( 2, 2, observations2 );
    notesHMM[16];
    hmm.generate( 16, notesHMM);


    //vel HMM test
    hmm.train( 2, 2, vel );
    int velHMM[16];
    hmm.generate(16, velHMM);

    // output
    for ( 0 => int i; i < notes.size(); i++ )
    {
        //chout <= results2[i] <= " ";
        for(0 => int i; i < numMessages.size(); i++){
            for(0 => int j; j < numMessages[j]; j++){
                for(0 => int k; k < )
                
            }
        }
        
    }
    <<<"Slices">>>;
    chout <= IO.newline();
    noteHMM.reset();
    velHMM.reset();
    chout <= IO.newline();

}
