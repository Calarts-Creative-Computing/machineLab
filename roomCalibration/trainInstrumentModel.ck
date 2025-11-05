//---------------------------------------------------------------------
// name: trainInstrumentModel.ck
// desc: robust JSON parser for note, vel, avgVol + KNN trainer
//---------------------------------------------------------------------
@import "/Users/mtiid/git/machineLabCode/signalSendClasses/OSC/globalOSCSendClass.ck";
@import "/Users/mtiid/git/machineLabCode/roomCalibration/Classes/checkVolumeClass.ck";

oscSends osc;
volumeCheck vol;  // our class for RMS measurements

1.5::second => dur waitTime;

"/Users/mtiid/git/machineLab/average_mic_levels.json" => string filename;

// open file
FileIO fio;
fio.open(filename, FileIO.READ);

if (!fio.good()) {
    cherr <= "can't open file: " <= filename <= IO.newline();
    me.exit();
}

// data arrays
float notes[0];
float vels[0];
float avgVols[0];

// helper: extract numeric value from substring after key
fun float extractAfter(string src, string key) {
    int idx;
    src.find(key) => idx;
    if (idx < 0) return 0.0;

    // from after colon
    src.substring(idx + key.length()) => string sub;
    // cut off at comma or end brace
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

// read file line by line
string line;
while (fio.more()) {
    fio.readLine() => line;

    // skip brackets or empty lines
    if (line.find("{") < 0) continue;

    // extract all values from this line
    extractAfter(line, "note") $ float => float n;
    extractAfter(line, "velocity") $ float => float v;
    extractAfter(line, "average_volume") => float a;

    // append to arrays
    notes << n;
    vels << v;
    avgVols << a;
}

fio.close();

// confirm parsed data
<<< "Parsed entries:", notes.size(), vels.size(), avgVols.size() >>>;

//---------------------------------------------------------------------
// STEP 2: Build feature matrix + target vector
//---------------------------------------------------------------------
float features[notes.size()][2];
float targets[avgVols.size()];

for (int i; i < notes.size(); i++) {
    notes[i] => features[i][0];
    vels[i] => features[i][1];
    avgVols[i] => targets[i];
}

// optional: print sample data
for (int i; i < notes.size(); i++) {
    chout <= "Sample " <= i <= ": note=" <= features[i][0]
          <= ", vel=" <= features[i][1]
          <= ", avgVol=" <= targets[i] <= IO.newline();
          chout <= IO.newline();
}
chout <= IO.newline();
chout <= IO.newline();
chout <= IO.newline();
chout <= IO.newline();

// print arrays
<<< "Notes:", "" >>>;
for (int i; i < notes.size(); i++) {
    chout <= notes[i] <= " ";
}
chout <= IO.newline();
chout <= IO.newline();

<<< "Velocities:", "" >>>;
for (int i; i < vels.size(); i++) {
    chout <= vels[i] <= " ";
}
chout <= IO.newline();
chout <= IO.newline();

<<< "Average Volumes:", "" >>>;
for (int i; i < avgVols.size(); i++) {
    chout <= avgVols[i] <= " ";
}
chout <= IO.newline();
chout <= IO.newline();

// float temp[2];
// float X[notes.size()][2];
// float Y[avgVols.size()][1];

MLP mlp;

[2, 5, 5, 1] @=> int nodes[];
mlp.init(nodes);

//input
// [
//     [notes[0], vels[0]],
//     [notes[1], vels[1]],
//     [notes[2], vels[2]],
//     [notes[3], vels[3]],
//     [notes[4], vels[4]],
//     [notes[5], vels[5]],
//     [notes[6], vels[6]],
//     [notes[7], vels[7]],
//     [notes[8], vels[8]],
//     [notes[9], vels[9]],
//     [notes[10], vels[10]]

// ] @=> float X[][];

// for(0 => int i; i < notes.size(); i++){
//     notes[i] => float notesTemp;
//     vels[i] => float velsTemp;

//     notesTemp => temp[0];
//     velsTemp => temp[1];
//     X << temp;

//     //temp.reset();
// }
// [
//     [avgVols[0]],
//     [avgVols[1]],
//     [avgVols[2]],
//     [avgVols[3]],
//     [avgVols[4]],
//     [avgVols[5]],
//     [avgVols[6]],
//     [avgVols[7]],
//     [avgVols[8]],
//     [avgVols[9]],
//     [avgVols[10]]

// ] @=> float Y[][];

// for(0 => int i; i < avgVols.size(); i++){
//     Y << avgVols[i];
// }

float X[notes.size()][2];
float Y[notes.size()][1];

for (int i; i < notes.size(); i++) {
    notes[i] => X[i][0];
    vels[i] => X[i][1];
    avgVols[i] => Y[i][0];
}

// train
0.05 => float lr;
500 => int epochs;
mlp.train(X, Y, lr, epochs);

// file name
"model3.txt" => string filenameModel;
// save the network
mlp.save( me.dir() + filenameModel );
// print
<<< "saved model to file:", filenameModel >>>;

[0.0, 0.0] @=> float input[];
[0.0] @=> float output[];

45 => int testNote;
127 => int testVel;

mlp.predict([testNote * 1.0, testVel * 1.0], output);

fun float measureAvgVolume(int note, int velocity, int repeats) { // <-- added velocity param
    0.0 => float total;
    osc.init("localhost", 50000);
    <<< "----- Measuring note", note, "velocity", velocity, "-----" >>>;

    for (0 => int i; i < repeats; i++) {
        osc.send("/marimba", note, velocity); // <-- use velocity
        <<< "Play note", note, "velocity", velocity, "hit", i+1, "..." >>>;

        0.2::second => now; // small delay for OSC trigger

        vol.getLevel() => float level;
        <<< "Measured RMS level:", level >>>;

        total + level => total;
        waitTime => now;
    }

    return total / repeats;
}

        
<<<measureAvgVolume(testNote, testVel, 1)>>>;

<<<output[0]>>>;