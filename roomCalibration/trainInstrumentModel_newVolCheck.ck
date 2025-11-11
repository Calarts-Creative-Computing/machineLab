// Train MLP using per-hit velocities from JSON
// Each hit = (note, velocity) → measured RMS level
// Updated version with correct scaling and RMS measurement integration
// Colton Arnold - Fall 2025

@import "../signalSendClasses/OSC/globalOSCSendClass.ck";
@import "./Classes/checkVolumeClass.ck";

oscSends osc;
VolumeCheck vol;

1.5::second => dur waitTime;


//Read JSON with per-hit data

"/Users/coltonarnold/Documents/GitHub/machineLab/mic_levels_per_hit.json" => string filename;

FileIO fio;
fio.open(filename, FileIO.READ);
if (!fio.good()) {
    cherr <= "can't open file: " <= filename <= IO.newline();
    me.exit();
}

float notes[0];
float vels[0];
float levels[0];

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

string line;
while (fio.more()) {
    fio.readLine() => line;
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

//Prepare training data
float X[notes.size()][2];
float Y[notes.size()][1];

for (int i; i < notes.size(); i++) {
    // normalize to [0,1]
    notes[i] / 127.0 => X[i][0];
    vels[i] / 127.0 => X[i][1];
    // scale RMS up for more stable training
    levels[i] * 1000.0 => Y[i][0];
}

//Train MLP
MLP mlp;
[2, 8, 8, 1] @=> int nodes[];
mlp.init(nodes);

0.001 => float lr;  // smaller learning rate for stability
4000 => int epochs;

<<< "Training", notes.size(), "data points..." >>>;
mlp.train(X, Y, lr, epochs);
<<< "Training complete." >>>;

"model_hitVelocities.txt" => string filenameModel;
mlp.save(me.dir() + filenameModel);

<<< "Trained & saved model to:", filenameModel >>>;

//Test model + optional real measurement
64 => int testNote;
Math.random2(60, 127) => int testVel;  // random test velocity

float output[0];
float inVec[2];

// normalize test inputs
testNote / 127.0 => inVec[0];
testVel / 127.0 => inVec[1];

mlp.predict(inVec, output);

// rescale output back down
output[0] / 1000.0 => float predictedRMS;
<<< "Predicted RMS for note", testNote, "vel", testVel, "=>", predictedRMS >>>;

//Live measurement using new VolumeCheck class
fun float measureAvgVolume(int note, int velocity, int repeats) {
    0.0 => float total;
    osc.init("192.168.0.15", 8001);

    <<< "----- Measuring note", note, "velocity", velocity, "-----" >>>;

    for (0 => int i; i < repeats; i++) {
        osc.send("/marimba", note, velocity);

        // start new RMS window
        vol.start();
        0.3::second => now; // listen window
        vol.stop() => float level; // max RMS over that window

        <<< "Measured RMS level:", level >>>;

        total + level => total;
        waitTime => now;
    }

    return total / repeats;
}

// measure one note and print live RMS
measureAvgVolume(testNote, testVel, 1) => float realRMS;
<<< "Measured RMS (real):", realRMS >>>;
