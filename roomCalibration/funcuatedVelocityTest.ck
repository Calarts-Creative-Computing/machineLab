// ---------------------------------------------------------
// Measure RMS levels for multiple marimba notes
// Each hit uses a different randomized velocity
// Save every reading + actual per-hit velocity + averages to JSON
// ---------------------------------------------------------

@import "/Users/mtiid/git/machineLabCode/signalSendClasses/OSC/globalOSCSendClass.ck";
@import "/Users/mtiid/git/machineLab/roomCalibration/Classes/checkVolumeClassTest.ck";

oscSends osc;
volumeCheck vol;  // class for RMS measurements

// notes (or test labels)
[45, 52, 57, 60, 64, 69, 77, 81, 88] @=> int marimbaNotes[];

// base velocities to test (around which we randomize)
[90, 127] @=> int baseVel[];

// number of readings per note
6 => int repeats;

// time between readings
1.5::second => dur waitTime;

// store all levels [note][velocityIndex][repeats]
float allLevels[marimbaNotes.size()][baseVel.size()][repeats];

// store actual randomized velocities per hit
int allHitVelocities[marimbaNotes.size()][baseVel.size()][repeats];

// ---------------------------------------------------------
// Function: measureVolumes()
// Measures several RMS levels for a given note
// Randomizes velocity for each hit
fun void measureVolumes(int note, int baseVelocity, int repeats,
                        float levels[], int hitVelocities[]) 
                        {

    osc.init("localhost", 50000);
    <<< "----- Measuring note", note, "base velocity", baseVelocity, "-----" >>>;

    for (0 => int i; i < repeats; i++) {
        int v;

        // choose range based on base velocity
        if (baseVelocity == 90) {
            baseVelocity + Math.random2(-15, 10) => v;
        } else if (baseVelocity == 127) {
            baseVelocity + Math.random2(-25, 0) => v;
        }

        // clamp to MIDI range
        if (v < 1) 1 => v;
        if (v > 127) 127 => v;

        // store per-hit velocity
        v => hitVelocities[i];

        // send note
        osc.send("/marimba", note, v);
        <<< "Play note", note, "velocity", v, "hit", i+1, "..." >>>;

        // measure RMS
        0.2::second => now;
        vol.getLevel() => float level;
        <<< "Measured RMS level:", level >>>;

        level => levels[i];
        waitTime => now;
    }
}


// ---------------------------------------------------------
// Function: saveLevelsToJSON()
// Saves all levels + velocities + averages to JSON
// ---------------------------------------------------------
fun void saveLevelsToJSON(
    float allLevels[][][],
    int allHitVelocities[][][],
    int notes[],
    int baseVelocities[],
    int repeats
) {
    FileIO file;
    "mic_levels_per_hit.json" => string filename;
    file.open(filename, FileIO.WRITE);
    if (!file.good()) {
        <<< "Error opening", filename >>>;
        return;
    }

    file.write("[\n");

    for (0 => int i; i < notes.size(); i++) {
        for (0 => int j; j < baseVelocities.size(); j++) {
            // compute average
            0.0 => float total;
            for (0 => int k; k < repeats; k++)
                total + allLevels[i][j][k] => total;
            total / repeats => float avg;

            // build per-hit velocity + level arrays
            "[" => string hitArrayStr;
            for (0 => int k; k < repeats; k++) {
                "{ \"velocity\": " + Std.itoa(allHitVelocities[i][j][k]) +
                ", \"level\": " + Std.ftoa(allLevels[i][j][k], 5) + " }" => string entry;
                hitArrayStr + entry => hitArrayStr;
                if (k < repeats - 1) hitArrayStr + ", " => hitArrayStr;
            }
            hitArrayStr + "]" => hitArrayStr;

            // build JSON entry
            "{ \"note\": " + Std.itoa(notes[i]) +
            ", \"base_velocity\": " + Std.itoa(baseVelocities[j]) +
            ", \"hits\": " + hitArrayStr +
            ", \"average_volume\": " + Std.ftoa(avg, 5) + " }" => string entry;

            // add comma unless last entry
            if (!(i == notes.size() - 1 && j == baseVelocities.size() - 1))
                entry + "," => entry;

            entry + "\n" => entry;
            file.write(entry);
        }
    }

    file.write("]\n");
    file.close();

    <<< "Saved all mic levels (per hit) to", filename >>>;
}

// ---------------------------------------------------------
// Main Test
// ---------------------------------------------------------
fun void test() {
    for (0 => int i; i < marimbaNotes.size(); i++) {
        for (0 => int j; j < baseVel.size(); j++) {
            // temp arrays for one test group
            float tempLevels[repeats];
            int tempHitVelocities[repeats];

            // measure
            measureVolumes(marimbaNotes[i], baseVel[j], repeats, tempLevels, tempHitVelocities);

            // store in master arrays
            for (0 => int k; k < repeats; k++) {
                tempLevels[k] => allLevels[i][j][k];
                tempHitVelocities[k] => allHitVelocities[i][j][k];
            }
        }
    }

    // save to JSON
    saveLevelsToJSON(allLevels, allHitVelocities, marimbaNotes, baseVel, repeats);
    <<< "All measurements complete." >>>;
}

// ---------------------------------------------------------
// Run the test
// ---------------------------------------------------------
test();
