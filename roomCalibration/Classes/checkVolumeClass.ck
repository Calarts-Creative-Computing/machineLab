// Created by Colton Arnold Fall 2025
public class VolumeCheck {
    // --- signal chain ---
    adc => FFT fft =^ RMS rms => blackhole;

    // --- parameters ---
    1024 => int fftSize;
    0.9 => float smoothing;

    // --- setup ---
    fftSize => fft.size;
    Windowing.hann(fftSize) => fft.window;

    // --- internal state ---
    float smoothed;
    float maxRMS;
    float rmsVal;

    // --- constructor ---
    fun void init(int size) {
        size => fftSize;
        fftSize => fft.size;
        Windowing.hann(fftSize) => fft.window;
    }

    // --- core RMS measurement function ---
    fun float getLevel() {
        // measure for a short duration
        1024 => int frames;
        0.0 => smoothed => maxRMS;

        // collect several FFT+RMS frames
        for (0 => int i; i < frames; i++) {
            rms.upchuck() @=> UAnaBlob blob;
            blob.fval(0) => rmsVal;

            // exponential smoothing
            (smoothing * smoothed) + ((1 - smoothing) * rmsVal) => smoothed;

            // track peak for normalization
            if (smoothed > maxRMS) smoothed => maxRMS;

            fft.size()::samp => now;
        }

        // normalize to 0–1 (based on observed RMS range)
        if (maxRMS > 0.0) smoothed / maxRMS => float normalized;
        else smoothed => normalized;

        // return normalized RMS
        return normalized;
    }

    fun int threshHoldCheck(string instrument, int note, float thresh, float recordedOutput) {
        if (thresh < recordedOutput) {
            <<< instrument, ": ", note, "is functioning properly" >>>;
            return 1;
        } else {
            <<< instrument, ": ", note, "is not functioning properly" >>>;
            return 0;
        }
    }
}


