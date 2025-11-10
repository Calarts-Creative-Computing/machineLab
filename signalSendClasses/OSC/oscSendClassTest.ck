//Written by Colton Arnold Fall 2025


@import "./globalOSCSendClass.ck";

oscSends osc;
osc.init("192.168.0.15", 50000);
// for(45 => int i; i < 95; i++){
//     for(0 => int j; j < 3;j++){
//         osc.send("/marimba", i, 70);
//         <<<i>>>;
//         0.75::second => now;
//     }
//     3::second => now;
// }


osc.send("/marimba", 77, 70);
0.75::second => now;
