// ---------------------------------------------------------
// Train MLP using per-hit velocities from JSON
// Each hit = (note, velocity) → measured RMS level
// ---------------------------------------------------------

@import "/Users/mtiid/git/machineLabCode/signalSendClasses/OSC/globalOSCSendClass.ck";
@import "/Users/mtiid/git/machineLab/roomCalibration/Classes/checkVolumeClassTest.ck";

oscSends osc;
volumeCheck vol;

1.5::second => dur waitTime;

// ---------------------------------------------------------
// STEP 1: Read JSON with per-hit data
// ---------------------------------------------------------
"/Users/mtiid/git/machineLab/mic_levels_per_hit.json" => string filename;

FileIO fio;
fio.open(filename, FileIO.READ);
if (!fio.good()) {
    cherr <= "can't open file: " <= filename <= IO.newline();
    me.exit();
}

// arrays to hold flattened data
float notes[0];
float vels[0];
float levels[0];

// --- helper to extract between key markers ---
fun float extractAfter(string src, string key) {
    int idx;
    src.find(key) => idx;
    if (idx < 0) return 0.0;
    src.substring(idx + key.length()) => string sub;

    sub.find(",") => int comma;
    sub.find("}") => int brace;
    if (comma >= 0) sub.substring(0, comma) => sub;
    else if (brace >= 0) sub.substring(0, brace) => sub;

    sub.replace(":", "");
    sub.replace("\"", "");
    sub.trim() => sub;

    if (sub.find(".") >= 0)
        return Std.atof(sub);
    else
        return Std.atoi(sub);
}

// --- parse per-hit JSON ---
string line;

while (fio.more()) {
    fio.readLine() => line;

    // Each entry is a single-line JSON object
    if (line.find("\"note\"") >= 0 && line.find("\"velocity\"") >= 0) {
        extractAfter(line, "note") => float n;
        extractAfter(line, "velocity") => float v;
        extractAfter(line, "level") => float l;

        notes << n;
        vels << v;
        levels << l;
    }
}

fio.close();


// ---------------------------------------------------------
// STEP 2: Prepare training data
// ---------------------------------------------------------
float X[notes.size()][2];
float Y[notes.size()][1];

for (int i; i < notes.size(); i++) {
    notes[i] => X[i][0];
    vels[i] => X[i][1];
    levels[i] => Y[i][0];
}

// ---------------------------------------------------------
// STEP 3: Train MLP
// ---------------------------------------------------------
MLP mlp;
[2, 8, 8, 1] @=> int nodes[];
mlp.init(nodes);

0.05 => float lr;
800 => int epochs;

mlp.train(X, Y, lr, epochs);

"model_hitVelocities.txt" => string filenameModel;
mlp.save(me.dir() + filenameModel);

<<< "Trained & saved model to:", filenameModel >>>;

// ---------------------------------------------------------
// STEP 4: Test model + optional real measurement
// ---------------------------------------------------------
55 => int testNote;
Math.random2(60, 127) => int testVel;  // random test velocity

float output[0];
mlp.predict([testNote * 1.0, testVel * 1.0], output);

<<< "Predicted RMS for note", testNote, "vel", testVel, "=>", output[0] >>>;

// Optional: Measure live RMS from marimba
fun float measureAvgVolume(int note, int velocity, int repeats) {
    0.0 => float total;
    osc.init("localhost", 50000);
    <<< "----- Measuring note", note, "velocity", velocity, "-----" >>>;
    for (0 => int i; i < repeats; i++) {
        osc.send("/marimba", note, velocity);
        0.2::second => now;
        vol.getLevel() => float level;
        total + level => total;
        waitTime => now;
    }
    return total / repeats;
}

<<< "Measured RMS (real):", measureAvgVolume(testNote, testVel, 1) >>>;
