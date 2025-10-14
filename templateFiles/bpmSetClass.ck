//Written by Colton Arnold Fall 2025

public class bpmSet{

    fun float bpm(int bpm){

        //500ms == 120 bpm
        //120 / 60 == 2 
        //1000 / 2 == 500;

        bpm / 60.0 => float remainder;

        1000 / remainder => float durationTime;
        return durationTime;

    }
}