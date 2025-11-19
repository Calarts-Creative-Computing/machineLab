// Measure RMS levels for multiple marimba notes

// Each hit uses a different randomized velocity

// Save every reading + actual per-hit velocity to JSON

@import "../signalSendClasses/OSC/globalOSCSendClass.ck";
@import "./Classes/checkVolumeClass.ck";

oscSends osc;
VolumeCheck vol;  // class for RMS measurements

// Notes to test
[45, 52, 57, 60, 66, 71, 77, 83, 88, 90] @=> int marimbaNotes[];    
//[ 53] @=> int marimbaNotes[];

// Base velocities (around which we randomize)
[70, 90, 127] @=> int baseVel[];

// Number of readings per note
6 => int repeats;

// Time between readings
1.5::second => dur waitTime;

// Store all levels [note][velocityIndex][repeats]
float allLevels[marimbaNotes.size()][baseVel.size()][repeats];

// Store actual randomized velocities per hit
int allHitVelocities[marimbaNotes.size()][baseVel.size()][repeats];


// Measures several RMS levels for a given note
// Randomizes velocity for each hit
fun void measureVolumes(int note, int baseVelocity, int repeats, float levels[], int hitVelocities[]) {
    osc.init("localhost", 50000);

    // initialize OSC
    <<< "Measuring note", note, "base velocity", baseVelocity >>>;

    // create volume measurement object

    // loop for each hit
    for (0 => int i; i < repeats; i++) {
        int v;

        // Choose range based on base velocity
        if (baseVelocity == 70) {
            baseVelocity + Math.random2(-5, 15) => v;
        } else if (baseVelocity == 90) {
            baseVelocity + Math.random2(-25, 15) => v;
        } else if (baseVelocity == 127) {
            baseVelocity + Math.random2(-25, 0) => v;
        }

        // Clamp to MIDI range
        if (v < 1) 1 => v;
        if (v > 127) 127 => v;

        // Store per-hit velocity
        v => hitVelocities[i];

        // Send note to external OSC receiver
        osc.send("/marimba", note, v); // <-- use velocity
        <<< "Play note", note, "velocity", v, "hit", i+1, "..." >>>;

        // --- Measure RMS for this note ---
        vol.start();               // begin RMS capture
        0.3::second => now;        // allow sound to play and measure
        vol.stop() => float level; // stop and get max RMS
        <<< "Measured RMS level:", level >>>;

        level => levels[i];

        // wait before next note (define waitTime earlier if you use it)
        1.5::second => now;
    }

    //Optional exact base velocity tests
    for (0 => int i; i < 3; i++) {
        int v;
        baseVelocity => v;

        if (v < 1) 1 => v;
        if (v > 127) 127 => v;

        v => hitVelocities[i];
        osc.send("/marimba", note, v);
        <<< "Play note", note, "velocity", v, "hit", i+1, "..." >>>;

        // measure again
        vol.start();
        0.3::second => now;
        vol.stop() => float level;
        <<< "Measured RMS level:", level >>>;

        level => levels[i];
        1.5::second => now;
    }
}


// Function: saveLevelsToJSON()
// Saves all hits (note, velocity, level) individually to JSON
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

    // Iterate through all hits
    for (0 => int i; i < notes.size(); i++) {
        for (0 => int j; j < baseVelocities.size(); j++) {
            for (0 => int k; k < repeats; k++) {
                "{ \"note\": " + Std.itoa(notes[i]) +
                ", \"velocity\": " + Std.itoa(allHitVelocities[i][j][k]) +
                ", \"level\": " + Std.ftoa(allLevels[i][j][k], 5) + " }" => string entry;

                // Add comma unless last entry
                if (!(i == notes.size() - 1 && j == baseVelocities.size() - 1 && k == repeats - 1))
                    entry + "," => entry;

                entry + "\n" => entry;
                file.write(entry);
            }
        }
    }

    file.write("]\n");
    file.close();

    <<< "Saved all individual mic levels to", filename >>>;
}


// Main Test

fun void test() {
    for (0 => int i; i < marimbaNotes.size(); i++) {
        //1::minute => now; // Allow time between note groups

        for (0 => int j; j < baseVel.size(); j++) {
            float tempLevels[repeats];
            int tempHitVelocities[repeats];

            measureVolumes(marimbaNotes[i], baseVel[j], repeats, tempLevels, tempHitVelocities);

            for (0 => int k; k < repeats; k++) {
                tempLevels[k] => allLevels[i][j][k];
                tempHitVelocities[k] => allHitVelocities[i][j][k];
            }
        }
    }

    saveLevelsToJSON(allLevels, allHitVelocities, marimbaNotes, baseVel, repeats);
    <<< "All measurements complete." >>>;
}


// Run the test

0.1::minute => now;
test();
