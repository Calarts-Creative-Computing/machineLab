// Created by Colton Arnold Fall 2025
public class VolumeCheck {
    
    // ----- Audio chain -----
    adc => Gain micGain => FFT fft =^ RMS rms => blackhole;
    
    // ----- Parameters -----
    100.0 => micGain.gain;       // fixed mic gain
    2048 => fft.size;            // FFT size
    Windowing.hann(2048) => fft.window; // Hann window
    0.008 => float threshold;    // noise threshold (RMS values below ignored)

    // ----- Constructor -----
    fun void init() {
        // nothing dynamic needed; all fixed values are set above
    }

    // ----- Measure RMS for a note -----
    fun float measureAvgVolume(int note, int repeats, oscSends osc) {
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
}
