@import "/Users/mtiid/git/machineLabCode/signalSendClasses/OSC/globalOSCSendClass.ck";
@import "/Users/mtiid/git/machineLabCode/roomCalibration/Classes/checkVolumeClass.ck";

oscSends osc;
volumeCheck vol;  // our class for RMS measurements

// notes (or test labels)
[45, 52, 57, 60, 64, 69, 77, 81, 88] @=> int marimbaNotes[];

// velocities to test
[ 90, 127] @=> int vel[]; // <-- added velocity array

// number of readings per note
3 => int repeats;

// time between readings (adjust to give yourself time to strike each note)
1.5::second => dur waitTime;

// store average levels
float avgLevels[marimbaNotes.size()][vel.size()]; // <-- now 2D array for note + velocity

float 

// measure rms of note
//need to change avg to each hit with slight variety in velocity
fun float measureAvgVolume(int note, int velocity, int repeats) { // <-- added velocity param
    0.0 => float total;
    osc.init("localhost", 50000);
    <<< "----- Measuring note", note, "velocity", velocity, "-----" >>>;

    for (0 => int i; i < repeats; i++) {
        osc.send("/marimba", note, velocity); // <-- use velocity
        <<< "Play note", note, "velocity", velocity, "hit", i+1, "..." >>>;

        0.2::second => now; // small delay for OSC trigger

        vol.getLevel() => float level;
        <<< "Measured RMS level:", level >>>;

        total + level => total;
        waitTime => now;
    }

    return total / repeats;
}

// ----- Save averages to JSON -----
fun void saveAveragesToJSON(float levels[][], int notes[], int velocities[]) {
    FileIO file;
    "average_mic_levels.json" => string filename;

    file.open(filename, FileIO.WRITE);
    if (!file.good()) {
        <<< "Error opening", filename >>>;
        return;
    }

    file.write("[\n");
    for (0 => int i; i < notes.size(); i++) {
        for (0 => int j; j < velocities.size(); j++) {
            Std.itoa(notes[i]) => string noteStr;
            Std.itoa(velocities[j]) => string velStr;
            Std.ftoa(levels[i][j], 5) => string avgStr;

            "{ \"note\": " + noteStr +
            ", \"velocity\": " + velStr +
            ", \"average_volume\": " + avgStr + " }" => string entry;

            // comma unless last entry
            if (!(i == notes.size() - 1 && j == velocities.size() - 1))
                entry + "," => entry; 

            entry + "\n" => entry;
            file.write(entry);
        }
    }
    file.write("]\n");
    file.close();


    <<< "Saved average mic levels to", filename >>>;
}


// ----- main test -----
fun void test() {
    for (0 => int i; i < marimbaNotes.size(); i++) {
        for (0 => int j; j < vel.size(); j++) {
            Math.random
            measureAvgVolume(marimbaNotes[i], vel[j] + velAdd, repeats) => avgLevels[i][j];
            <<< "Average mic level for note", marimbaNotes[i], 
                "velocity", vel[j], ":", avgLevels[i][j] >>>;
        }
    }

    saveAveragesToJSON(avgLevels, marimbaNotes, vel); // <-- pass velocities
    <<< "All measurements complete." >>>;
}

// Run the test
test();
