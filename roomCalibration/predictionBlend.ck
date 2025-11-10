@import "/Users/mtiid/git/machineLabCode/signalSendClasses/OSC/globalOSCSendClass.ck";
@import "/Users/mtiid/git/machineLab/roomCalibration/Classes/checkVolumeClassTest.ck";

oscSends osc;
VolumeCheck vol;
MLP mlp;
KNN2 knn;

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



//load MLP training
"marimbaModelMLP_20251109.txt" => string filenameModel;
mlp.load(me.dir() + filenameModel);

<<< "Trained & saved model to:", filenameModel >>>;


//KNN training 

// Build features = [note, velocity], labels = RMS levels
float features[notes.size()][2];
float labels[notes.size()];

for (int i; i < notes.size(); i++) {
    notes[i] / 127.0 => features[i][0];
    vels[i] / 127.0 => features[i][1];
    levels[i] => labels[i];
}

// Train = store all samples
knn.train(features, labels);
<<< "Trained KNN with", notes.size(), "samples." >>>;



//Predictions

55 => int testNote;
Math.random2(60, 127) => int testVel; // random test velocity

// Build input feature (normalized like training)
float query[2];
testNote / 127.0 => query[0];
testVel / 127.0 => query[1];

// Predict with k = 5 nearest neighbors
float neighborVals[0];
knn.predict(query, 5, neighborVals);

// Compute mean of neighbors' stored levels
float sum;
for (0 => int i; i < neighborVals.size(); i++) sum += neighborVals[i];
(sum / neighborVals.size()) => float predictedLevel;

<<< "Predicted RMS for note", testNote, "vel", testVel, "=>", predictedLevel >>>;
