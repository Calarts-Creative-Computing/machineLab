@import "../signalSendClasses/OSC/globalOSCSendClass.ck";
@import "./Classes/checkVolumeClass.ck";

oscSends osc;
VolumeCheck vol;
MLP mlp;
KNN knn;

1.5::second => dur waitTime;


[45, 52, 57, 60, 66, 71, 77, 83, 88, 90] @=> int marimbaDatasetNotes[];


[55] @=> int marimbaTestNotes[];




// STEP 1: Read JSON with per-hit data"/Users/coltonarnold/Documents/GitHub/machineLab/mic_levels_per_hit.json" => string filename;

"/Users/coltonarnold/Documents/GitHub/machineLab/mic_levels_per_hit.json" => string filename;


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

//create test note and vel
55 => int testNote;
100 => int testVel;

fun float mlpPredict(){
    //Load pre-trained MLP

    [2, 8, 8, 1] @=> int nodes[];      // must match training architecture
    mlp.init(nodes);

    "/Users/coltonarnold/Documents/GitHub/machineLab/roomCalibration/model_hitVelocities.txt" => string filenameModel;
    mlp.load(filenameModel);

    <<< "MLP loaded and initialized from:", filenameModel >>>;

    // STEP 2: Prepare input vector
    45 => int testNote;
    100 => int testVel;

    float inVec[2];
    testNote / 127.0 => inVec[0];     // normalize note
    testVel / 127.0 => inVec[1];      // normalize velocity

    // output array must have 1 element
    float output[1];
    mlp.predict(inVec, output);

    // rescale output back to original RMS units
    output[0] / 1000.0 => float predictedRMS;

    <<<"here is MLP prediction: ", predictedRMS>>>;

    return predictedRMS;
}

fun float knnPredict(){

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

   
    return predictedLevel;
}

// get prediction from both models
knnPredict() => float knnPrediction;

mlpPredict() => float mlpPrediction;

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

        <<< "Measured RMS level for: "  + level >>>;

        total + level => total;
        waitTime => now;
    }

    return total / repeats;
}

measureAvgVolume(testNote, testVel, 1) => float realVol;

0.0 => float a;


// Output closeness for each dataset note
// for (0 => int i; i < marimbaDatasetNotes.size(); i++) {
//     999 => float minDist; // track nearest test note distance

//     // Find nearest test note
//     for (0 => int j; j < marimbaTestNotes.size(); j++) {
//         Math.abs(marimbaDatasetNotes[i] - marimbaTestNotes[j]) => float dist;
//         if (dist < minDist){
//             dist => minDist;
//         } 
//     }

//     // Map distance to closeness [1.0 → 0.0]
//     // adjust the divisor to control curve steepness
//     Math.exp(-0.3 * minDist) => a;

//     <<< "Note:", marimbaDatasetNotes[i], "Closeness:", a >>>;
// }


(a * mlpPrediction) + ((1 - a) * knnPrediction) => float finalPrediction;


realVol - finalPrediction => float recordedOff;

<<<"final prediction:  ",  finalPrediction>>>;

<<< "Measured RMS (real): ", realVol >>>;

<<<"Offset: ", recordedOff>>>;


//adjust to solinoid... I think. might be the opposite we will test

0.001 => float marginOfError;


if(recordedOff > marginOfError){

    <<<testNote, " Move mallet closer to surface">>>;

}

else if(recordedOff < marginOfError){

    <<<testNote, " Move mallet further from surface">>>;

}

else{

    <<<"No adjustments needed">>>;
}

