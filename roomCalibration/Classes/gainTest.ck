// Created by Colton Arnold Fall 2025
@import "/Users/mtiid/git/machineLabCode/signalSendClasses/OSC/globalOSCSendClass.ck";
@import "../Classes/checkVolumeClass.ck";  // VolumeCheck class

oscSends osc;
VolumeCheck vol;  // our RMS measurement class

// notes (or test labels)
[45, 52, 57, 60, 64, 69, 76, 81, 88, 93, 96] @=> int marimbaNotes[];
[20, 60, 90, 127] @=> int vel[];

// number of readings per note
3 => int repeats;

// time between readings (adjust to give yourself time to strike each note)
1.5::second => dur waitTime;

127 = int vel;

// store average levels
float avgLevels[marimbaNotes.size()];

// ----- Save averages to JSON -----
fun void saveAveragesToJSON(float levels[], int notes[]) {
    FileIO file;
    "average_mic_levels.json" => string filename;

    file.open(filename, FileIO.WRITE);
    if (!file.good()) {
        <<< "Error opening", filename >>>;
        return;
    }

    file.write("[\n");
    for (0 => int i; i < notes.size(); i++) {
        Std.itoa(notes[i]) => string noteStr;
        Std.ftoa(vel) => string avgStr;
        Std.ftoa(levels[i]) => string avgStr;
        

        "{ \"note\": " + noteStr + \"vel\":" + velStr, \"average_volume\": " + avgStr + " }" => string entry;
        if (i < notes.size() - 1) entry + "," => entry;
        entry + "\n" => entry;

        file.write(entry);
    }
    file.write("]\n");
    file.close();

    <<< "Saved average mic levels to", filename >>>;
}

// ----- main test -----
fun void test() {
    for (0 => int i; i < marimbaNotes.size(); i++) {
        // measure using the class method
        for(0 => int j; j < vel.size(); j++ ){
            vol.measureAvgVolume(marimbaNotes[i], vel[j], repeats, osc) => avgLevels[i];
            <<< "Average mic level for note", marimbaNotes[i], ":", avgLevels[i] >>>;
            waitTime => now; // optional extra pause between notes
        }
    }

    saveAveragesToJSON(avgLevels, marimbaNotes);
    <<< "All measurements complete." >>>;
}

// Run the test
test();
