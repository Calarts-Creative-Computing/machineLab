// ---------------------------------------------------------
// Measure RMS levels for multiple marimba notes & velocities
// Save every reading + averages to JSON
// ---------------------------------------------------------

@import "/Users/mtiid/git/machineLabCode/signalSendClasses/OSC/globalOSCSendClass.ck";
@import "/Users/mtiid/git/machineLabCode/roomCalibration/Classes/checkVolumeClass.ck";

oscSends osc;
volumeCheck vol;  // our class for RMS measurements

// notes (or test labels)
[45, 52, 57, 60, 64, 69, 77, 81, 88] @=> int marimbaNotes[];

// velocities to test
[90, 127] @=> int vel[];

// number of readings per note
3 => int repeats;

// time between readings
1.5::second => dur waitTime;

// ---------------------------------------------------------
// Function: measureVolumes()
// Measures several RMS levels for a given note/velocity
// Returns array of levels
// ---------------------------------------------------------
fun float[] measureVolumes(int note, int velocity, int repeats) {
    float levels[repeats];
    osc.init("localhost", 50000);
    <<< "----- Measuring note", note, "velocity", velocity, "-----" >>>;

    for (0 => int i; i < repeats; i++) {
        osc.send("/marimba", note, velocity);
        <<< "Play note", note, "velocity", velocity, "hit", i+1, "..." >>>;

        0.2::second => now; // small delay before measuring

        vol.getLevel() => float level;
        <<< "Measured RMS level:", level >>>;

        level => levels[i];
        waitTime => now;
    }

    return levels;
}

// ---------------------------------------------------------
// Function: saveLevelsToJSON()
// Saves all levels + averages to a JSON file
// ---------------------------------------------------------
fun void saveLevelsToJSON(float allLevels[][][], int notes[], int velocities[], int repeats) {
    FileIO file;
    "mic_levels_full.json" => string filename;
    file.open(filename, FileIO.WRITE);
    if (!file.good()) {
        <<< "Error opening", filename >>>;
        return;
    }

    file.write("[\n");
    for (0 => int i; i < notes.size(); i++) {
        for (0 => int j; j < velocities.size(); j++) {
            // compute average
            0.0 => float total;
            for (0 => int k; k < repeats; k++)
                total + allLevels[i][j][k] => total;
            total / repeats => float avg;

            // build levels array string
            "[" => string levelsStr;
            for (0 => int k; k < repeats; k++) {
                Std.ftoa(allLevels[i][j][k], 5) => string val;
                levelsStr + val => levelsStr;
                if (k < repeats - 1) levelsStr + ", " => levelsStr;
            }
            levelsStr + "]" => levelsStr;

            // build JSON entry
            "{ \"note\": " + Std.itoa(notes[i]) +
            ", \"velocity\": " + Std.itoa(velocities[j]) +
            ", \"levels\": " + levelsStr +
            ", \"average_volume\": " + Std.ftoa(avg, 5) + " }" => string entry;

            // add comma unless last entry
            if (!(i == notes.size() - 1 && j == velocities.size() - 1))
                entry + "," => entry;

            entry + "\n" => entry;
            file.write(entry);
        }
    }
    file.write("]\n");
    file.close();

    <<< "✅ Saved all mic levels to", filename >>>;
}

float levels[];

// ---------------------------------------------------------
// Main Test
// ---------------------------------------------------------
fun void test() {
    // 3D array: [note][velocity][repeat]
    float allLevels[marimbaNotes.size()][vel.size()][repeats];

    for (0 => int i; i < marimbaNotes.size(); i++) {
        for (0 => int j; j < vel.size(); j++) {
            levels << measureVolumes(marimbaNotes[i], vel[j], repeats);
            for (0 => int k; k < repeats; k++)
                levels[k] => allLevels[i][j][k];
        }
    }

    saveLevelsToJSON(allLevels, marimbaNotes, vel, repeats);
    <<< "All measurements complete." >>>;
}

// ---------------------------------------------------------
// Run the test
// ---------------------------------------------------------
test();