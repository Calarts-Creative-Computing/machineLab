public class VolumeCheck {
    // --- signal chain ---
    adc => FFT fft =^ RMS rms => blackhole;

    // --- parameters ---
    1024 => fft.size;
    Windowing.hann(1024) => fft.window;

    // --- internal state ---
    0.0 => float maxRMS;
    false => int measuring;

    // --- start measuring ---
    fun void start() {
        true => measuring;
        0.0 => maxRMS;
        spork ~ measureLoop();
    }

    // --- stop measuring and return max RMS ---
    fun float stop() {
        false => measuring;
        return maxRMS;
    }

    // --- main measurement loop ---
    fun void measureLoop() {
        while (measuring) {
            rms.upchuck() @=> UAnaBlob blob;
            blob.fval(0) => float currentRMS;

            if (currentRMS > maxRMS) {
                currentRMS => maxRMS;
            }

            fft.size()::samp => now;
        }
    }
}



