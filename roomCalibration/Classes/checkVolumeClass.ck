// Created by Colton Arnold Fall 2025
public class volumeCheck {
    adc => Gain g => blackhole;

    // use unity gain for calibration
    30.0 => g.gain;

    fun float getLevel() {
        1024 => int size;
        float sum;
        for (0 => int i; i < size; i++) {
            g.last() => float sample;
            sum + sample*sample => sum;
            1::samp => now;
        }
        return Math.sqrt(sum / size);
    }

    fun int threshHoldCheck(string instrument, int note, float thresh) {
        if (thresh < getLevel()) {
            <<< instrument, ": ", note, "is functioning properly" >>>;
            return 1;
        } else {
            <<< instrument, ": ", note, "is not functioning properly" >>>;
            return 0;
        }
    }
}


