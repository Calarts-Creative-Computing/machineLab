//Written by Colton Arnold Fall 2025


@import "/Users/mtiid/git/machineLab/signalSendClasses/OSC/globalOSCSendClass.ck";

oscSends osc;
osc.init("localhost", 50000);
for(0 => int i; i < 157; i++){
    osc.send("/modulettes", i, 127);
    <<<i>>>;
    0.1::second => now;
}
