// Created by Colton Arnold Fall 2025
// Created by Colton Arnold Fall 2025
@import "/Users/mtiid/git/machineLabCode/signalSendClasses/OSC/globalOSCSendClass.ck";

oscSends osc;

// notes (or test labels)
[45, 52, 57, 60, 64, 69, 76, 81, 88, 93, 96] @=> int marimbaNotes[];

// number of readings per note
3 => int repeats;

// time between readings (adjust to give yourself time to strike each note)
1::second => dur waitTime;

// store average levels
float avgLevels[marimbaNotes.size()];

// ----- FFT/RMS setup -----
adc => Gain micGain => FFT fft =^ RMS rms => blackhole;

// FFT parameters
2048 => fft.size;
Windowing.hann(2048) => fft.window;

// ----- mic gain -----
100.0 => micGain.gain;  // increase if readings too small, decrease if clipping

// ----- noise threshold -----
0.008 => float threshold;  // RMS values below this are ignored

// ----- measure RMS for a note -----
fun float measureAvgVolume(int note, int repeats) {
    0.0 => float total;
    osc.init("localhost", 50000);
    <<< "----- Measuring note", note, "-----" >>>;

    for (0 => int i; i < repeats; i++) {
        osc.send("/marimba", note, 127);
        <<< "Play note", note, "hit", i+1, "..." >>>;

        // tiny wait so OSC message triggers
        0.2::second => now;

        // measure for a short duration after hit
        0.5::second => dur measureDur;
        0.0 => float maxRMS;
        now + measureDur => time endTime;

        while (now < endTime) {
            rms.upchuck() @=> UAnaBlob blob;
            blob.fval(0) => float level;

            if (level > threshold && level > maxRMS) level => maxRMS;

            fft.size()::samp => now;
        }

        <<< "Measured RMS level (peak above threshold):", maxRMS >>>;
        total + maxRMS => total;

        1::second => now; // pause before next hit
    }

    return total / repeats;
}

// ----- Save averages to JSON -----
fun void saveAveragesToJSON(float levels[], int notes[]) {
    FileIO file;
    "average_mic_levels.json" => string filename;

    file.open(filename, FileIO.WRITE);
    if (!file.good()) {
        <<< "Error opening", filename >>>;
        return;
    }

    file.write("[\n");
    for (0 => int i; i < notes.size(); i++) {
        Std.itoa(notes[i]) => string noteStr;
        Std.ftoa(levels[i], 5) => string avgStr;

        "{ \"note\": " + noteStr + ", \"average_volume\": " + avgStr + " }" => string entry;
        if (i < notes.size() - 1) entry + "," => entry;
        entry + "\n" => entry;

        file.write(entry);
    }
    file.write("]\n");
    file.close();

    <<< "Saved average mic levels to", filename >>>;
}

// ----- main test -----
fun void test() {
    2::seconds => now;
    for (0 => int i; i < marimbaNotes.size(); i++) {
        measureAvgVolume(marimbaNotes[i], repeats) => avgLevels[i];
        <<< "Average mic level for note", marimbaNotes[i], ":", avgLevels[i] >>>;
    }

    saveAveragesToJSON(avgLevels, marimbaNotes);
    <<< "All measurements complete." >>>;
}

test();
