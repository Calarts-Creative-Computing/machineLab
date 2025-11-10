// instrumentPredict_mlpOnly.ck
// Predict RMS for a given note/velocity using pre-trained MLP
// Includes live RMS measurement from VolumeCheck
// Colton Arnold - Fall 2025

@import "../signalSendClasses/OSC/globalOSCSendClass.ck";
@import "./Classes/checkVolumeClass.ck";

oscSends osc;
VolumeCheck vol;
1.5::second => dur waitTime;

// ---------------------------------------------------------
// STEP 1: Load pre-trained MLP
// ---------------------------------------------------------
MLP mlp;
[2, 8, 8, 1] @=> int nodes[];      // must match training architecture
mlp.init(nodes);

"/Users/coltonarnold/Documents/GitHub/machineLab/roomCalibration/model_hitVelocities.txt" => string filenameModel;
mlp.load(filenameModel);

<<< "MLP loaded and initialized from:", filenameModel >>>;

// ---------------------------------------------------------
// STEP 2: Prepare input vector
// ---------------------------------------------------------
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

<<< "Predicted RMS for note", testNote, "vel", testVel, "=>", predictedRMS >>>;

// ---------------------------------------------------------
// STEP 3: Optional live RMS measurement
// ---------------------------------------------------------
fun float measureAvgVolume(int note, int velocity, int repeats) {
    0.0 => float total;
    osc.init("192.168.0.15", 8001);  // update to your OSC receiver

    <<< "----- Measuring note", note, "velocity", velocity, "-----" >>>;

    for (0 => int i; i < repeats; i++) {
        osc.send("/marimba", note, velocity);

        vol.start();
        0.3::second => now;         // listen window
        vol.stop() => float level;

        <<< "Measured RMS level:", level >>>;

        total + level => total;
        waitTime => now;
    }

    return total / repeats;
}

measureAvgVolume(testNote, testVel, 1) => float realRMS;
<<< "Measured RMS (real):", realRMS >>>;
