// Created by Colton Arnold Fall 2025
@import "../roomCalibration/Classes/checkVolumeClass.ck";
@import "../signalSendClasses/midi/midiInstrumentClass.ck";
@import "../signalSendClasses/OSC/globalOSCSendClass.ck";

volumeCheck volCheck;
oscSends osc;
midiInstrumentSends midiSend;

OscIn in;
OscOut inMonitor;
OscMsg msg;

"127.0.0.1" => string ipAddress;

[45,52,57,60,64,69,76,81,88,93,96] @=> int marimbaNotes[];
[0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1] @=> float marimbaThresh[];

//notes for ganapati
[1, 2, 3, 7, 8, 10, 12, 13, 14] @=> int ganapatiArray[];

// Dynamic 2D array to store failing note+velocity pairs
int loggedNotes[0][0];

[20, 40, 60, 80, 100, 127] @=> int vel[];

500::ms => dur beat;
3 => int repeats;

// JSON save function
fun void saveResultsToJSON(int badPairs[][]) {
    FileIO file;
    "nonfunctional_marimba.json" => string filename;

    file.open(filename, FileIO.WRITE);
    if (!file.good()) {
        <<< "Error: could not open", filename >>>;
        return;
    }

    file.write("[\n");

    0 => int i;
    while (i < badPairs.size()) {
        // Convert integers to strings using Std.itoa()
        Std.itoa(badPairs[i][0]) => string noteStr;
        Std.itoa(badPairs[i][1]) => string velStr;

        // Build JSON entry
        "{ \"note\": " + noteStr + ", \"velocity\": " + velStr + " }" => string entry;

        if (i < badPairs.size() - 1) entry + "," => entry;
        entry + "\n" => entry;

        file.write(entry);
        i++;
    }

    file.write("]\n");
    file.close();

    <<< "Saved non-functional notes+velocities to", filename >>>;
}

//MarimBot
fun void marimBot() {
    osc.init(ipAddress, 50000);
    int testVal;

    for (0 => int i; i < marimbaNotes.size(); i++) {
        for (0 => int j; j < vel.size(); j++) {
            for (0 => int k; k < repeats; k++) {
                osc.send("/marimba", marimbaNotes[i], vel[j]);
                beat => now;

                volCheck.threshHoldCheck("/marimba", marimbaNotes[i], marimbaThresh[i]) => testVal;

                if (testVal == 1) {
                    <<< "/marimba :", marimbaNotes[i], "velocity:", vel[j], "is functioning properly" >>>;
                } 
                else if (testVal == 0) {
                    <<< "/marimba :", marimbaNotes[i], "velocity:", vel[j], "does NOT work" >>>;

                    // Check if note+velocity pair is already logged
                    0 => int found;
                    0 => int m;
                    while (m < loggedNotes.size()) {
                        if (loggedNotes[m][0] == marimbaNotes[i] && loggedNotes[m][1] == vel[j]) {
                            1 => found;
                            break;
                        }
                        m++;
                    }

                    if (found == 0) {
                        // Append failing note+velocity pair
                        [marimbaNotes[i], vel[j]] @=> int pair[];
                        loggedNotes << pair;
                    }
                }

                500::ms => now;
            }
        }
    }

    <<< "Non-functional notes+velocities:", loggedNotes >>>;
}

//Run 
marimBot();
saveResultsToJSON(loggedNotes);
