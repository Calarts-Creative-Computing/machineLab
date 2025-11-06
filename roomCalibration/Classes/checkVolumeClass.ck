// Created by Colton Arnold Fall 2025
public class volumeCheck{

    // connect microphone (ADC) to blackhole so we can measure it without hearing
    adc => Gain g => blackhole;

    // set mic gain if needed (default is 1.0)
    30.0 => g.gain;

    // RMS (root-mean-square) level calculation
    fun float getLevel() {
        // measure across a short window
        512 => int size;
        float sum;
        for (0 => int i; i < size; i++) {
            g.last() => float sample;
            sum + sample*sample => sum;
            1::samp => now;
        }
        return Math.sqrt(sum / size);
    }

    fun int threshHoldCheck(string instrument, int note, float thresh){

        if(thresh < getLevel()){

            <<<instrument,": ", note,  " is functioning properly">>>;
            return 1;
        }

        else{

            <<<instrument, ": ", note, " is not functioning preoperly">>>;
            return 0;
        }
    }

}

