@import "../signalSendClasses/OSC/globalOSCSendClass.ck";
@import "./Classes/checkVolumeClass.ck";

oscSends osc;
VolumeCheck vol;
MLP mlp;
KNN knn;

1.5::second => dur waitTime;


[45, 52, 57, 60, 66, 71, 77, 83, 88, 90] @=> int marimbaDatasetNotes[];


[45, 47, 48, 50, 52, 53, 54, 55, 57, 59, 60, 62, 64, 66, 67, 69, 71] @=> int marimbaTestNotes[];

//create test note and vel
48 => int testNote;
100 => int testVel;


// Read JSON with per-hit data"/Users/coltonarnold/Documents/GitHub/machineLab/mic_levels_per_hit.json" => string filename;

"/Users/mtiid/git/machineLab/roomCalibration/mic_levels_per_hit.json" => string filename;


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

//  helper to extract between key markers 
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

// parse per-hit JSON
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

//Load pre-trained MLP

[2, 8, 8, 1] @=> int nodes[];      // must match training architecture
mlp.init(nodes);

"/Users/mtiid/git/machineLab/roomCalibration/model_hitVelocities.txt" => string filenameModel;
mlp.load(filenameModel);

<<< "MLP loaded and initialized from:", filenameModel >>>;

fun float mlpPredict(int testNote){


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

fun float knnPredict(int testNote){

    float features[notes.size()][2];
    for (int i; i < notes.size(); i++) {
        notes[i] / 127.0 => features[i][0];
        vels[i]  / 127.0 => features[i][1];
    }

    // print feature matrix dims for debugging
    <<< "Feature count:", features.size(), "Dim count:", features[0].size() >>>;

    // Train the KNN
    knn.train(features);
    <<< " KNN trained with", features.size(), "samples" >>>;


    // Predict (KNN regression-style by averaging neighbors' levels)

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

fun float measureAvgVolume(int note, int velocity, int repeats) {

    0.0 => float total;
    osc.init("localhost", 8001);

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


// get prediction from both models

// Compute sine-shaped alpha between dataset notes
// Returns 0.0 if testNote matches a dataset note
// Returns 1.0 halfway between two dataset notes
fun float getAlpha(int testNote, int datasetNotes[])
{
    // if exactly in dataset → max closeness
    for (0 => int i; i < datasetNotes.size(); i++)
    {
        if (testNote == datasetNotes[i])
            return 1.0;
    }

    // handle below and above range
    if (testNote <= datasetNotes[0]) return 0.0;
    if (testNote >= datasetNotes[datasetNotes.size() - 1]) return 0.0;

    // find lower and upper notes surrounding testNote
    int lower;
    int upper;
    for (0 => int i; i < datasetNotes.size() - 1; i++)
    {
        if (testNote > datasetNotes[i] && testNote < datasetNotes[i + 1])
        {
            datasetNotes[i]     => lower;
            datasetNotes[i + 1] => upper;
            break;
        }
    }

    // normalize position between lower and upper → [0.0 .. 1.0]
    (testNote - lower) $ float / (upper - lower) $ float => float t;

    // inverted sine curve (1 - sin(pi * t))
    1.0 - Math.sin(Math.PI * t) => float a;

    return a;
}

// open JSON file before loop
FileIO fout;
fout.open("/Users/mtiid/git/machineLab/roomCalibration/marimba_results.json", FileIO.WRITE);

if (!fout.good()) {
    cherr <= "Error: could not open marimba_results.json" <= IO.newline();
    me.exit();
}
fout <= "[\n";

// main loop
for (0 => int i; i < marimbaTestNotes.size(); i++) {
    0.004 => float marginOfError; // acceptable RMS error margin
    marimbaTestNotes[i] => int testNote;

    knnPredict(testNote) => float knnPrediction;
    mlpPredict(testNote) => float mlpPrediction;
    measureAvgVolume(testNote, testVel, 3) => float realVol;

    getAlpha(testNote, marimbaDatasetNotes) => float a;
    (a * mlpPrediction) + ((1 - a) * knnPrediction) => float finalPrediction;
    realVol - finalPrediction => float recordedOff;

    realVol + marginOfError => float maximum;
    realVol - marginOfError => float minimum;

    string adjustment;
    if (Math.fabs(recordedOff) <= marginOfError){
        "No adjustments needed" => adjustment;
        <<<testNote, " No adjustments needed">>>;
    }

    else if (recordedOff > marginOfError){
        "Move mallet closer to surface: Too Loud" => adjustment;
        <<<testNote, "Move mallet closer to surface: Too Loud">>>;
    }

    else{
        "Move mallet further from surface: Too soft" => adjustment;
        <<<testNote, " Move mallet further from surface: Too soft">>>;
    }

    <<< "Note:", testNote, "Alpha:", a, "MLP:", mlpPrediction,
        "KNN:", knnPrediction, "Final:", finalPrediction,
        "Real:", realVol, "Offset:", recordedOff, adjustment >>>;

    // Write to JSON
    fout <= "  {\n";
    fout <= "    \"note\": " <= testNote <= ",\n";
    fout <= "    \"alpha\": " <= a <= ",\n";
    fout <= "    \"mlp_prediction\": " <= mlpPrediction <= ",\n";
    fout <= "    \"knn_prediction\": " <= knnPrediction <= ",\n";
    fout <= "    \"final_prediction\": " <= finalPrediction <= ",\n";
    fout <= "    \"real_volume\": " <= realVol <= ",\n";
    fout <= "    \"offset\": " <= recordedOff <= ",\n";
    fout <= "    \"margin_min\": " <= minimum <= ",\n";
    fout <= "    \"margin_max\": " <= maximum <= ",\n";
    fout <= "    \"adjustment\": \"" <= adjustment <= "\"\n";
    fout <= "  }";
    if (i < marimbaTestNotes.size() - 1)
        fout <= ",\n";
    else
        fout <= "\n";
}

// close JSON array
fout <= "]\n";
fout.close();

<<< "Results saved to marimba_results.json" >>>;
<<< "test complete." >>>;
