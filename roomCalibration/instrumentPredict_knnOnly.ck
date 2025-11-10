// Explaining KNN training script:

// Parse training data
// Notes, velocity, levels
// Build features matrix  & normalize (input data / 127)
// Features[i][0]
// Features[i][1]
// Pushing 2D features array into KNN class
// Normalize testNote and testVel: query
// Initialize k
// Number of neighbors picked
// Search for k
// Show neighbors that are displayed in neighbor index
// get average of k neighbors
// print average volumne
// print recorded volume3


// Each hit = (note, velocity) → measured RMS level

@import "../signalSendClasses/OSC/globalOSCSendClass.ck";
@import "./Classes/checkVolumeClass.ck";

oscSends osc;
VolumeCheck vol;
KNN knn;
1.5::second => dur waitTime;


// STEP 1: Read JSON with per-hit data




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



// STEP 2: Build features and train KNN
float features[notes.size()][2];
for (int i; i < notes.size(); i++) {
    notes[i] / 127.0 => features[i][0];
    vels[i]  / 127.0 => features[i][1];
}

// print feature matrix dims for debugging
<<< "Feature count:", features.size(), "Dim count:", features[0].size() >>>;

// Train the KNN
knn.train(features);
<<< "✅ KNN trained with", features.size(), "samples" >>>;


// STEP 3: Predict (KNN regression-style by averaging neighbors' levels)

45 => int testNote;
100 => int testVel;

float query[2];
testNote / 127.0 => query[0];
testVel  / 127.0 => query[1];

<<< "Query:", query[0], query[1], "Query length:", query.size() >>>;

// choose k, but clamp to dataset size
3 => int k;
if (k > features.size()) {
    features.size() => k;
}



int neighborIndices[0];  // let KNN resize it
<<< "Calling knn.search (k =", k, ")..." >>>;
knn.search(query, k, neighborIndices);
<<< "Returned neighborIndices size:", neighborIndices.size() >>>;

// defensive check: make sure indices are valid
for (int i; i < neighborIndices.size(); i++) {
    neighborIndices[i] => int idx;
    if (idx < 0 || idx >= levels.size()) {
        cherr <= "Invalid neighbor index:" <= idx <= IO.newline();
        me.exit();
    }
}

// Average their RMS levels
0.0 => float avgLevel;
for (int i; i < neighborIndices.size(); i++) {
    levels[neighborIndices[i]] => float neighborLevel;
    avgLevel + neighborLevel => avgLevel;
}
avgLevel / neighborIndices.size() => float predictedLevel;

<<< "Predicted RMS for note", testNote, "vel", testVel, "=>", predictedLevel >>>;



// Optional live measurement comparison

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

<<< "Measured RMS (real):", measureAvgVolume(testNote, testVel, 1) >>>;



