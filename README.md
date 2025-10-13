This is new code for the Machine Lab. Created Fall 2025. The placement on the Mac Mini will be updated since the git there is still my personal. This should be updated within the next few days.


here is the documentation. still working on this and is growing
https://docs.google.com/document/d/1uutdjhiEyeLgWIF5r2Y9500Ud31y423JzLYUDOhCyBg/edit?usp=sharing

Here is examples of the Machine Lab working:

https://drive.google.com/file/d/1NqgNh5402NuWN-dgFYZ01IAsCorxDvGL/view?usp=sharing
https://drive.google.com/file/d/13Xh5cRvY6e5F_13FU7rEfg_Vk8flD7fi/view?usp=sharing



Below is how to write for the Machine Lab:

Going forward, I will be referencing the composer as the client and the computer in the machine lab as server.

Any software that can send OSC can be used
Tested software is below (what I use lol)
  Max
  Supercollider
  Ableton
    To run in Ableton, you will need Max4Live, NOT the OSC send that is already within Ableton. This does not format the message correctly. 
    
Client must connect to the server’s router
Currently listed as MrRoboto
If this does not show up in network settings (or your using some bizarre linux distro, i know y’all are out there), you can manually join with the following address
  192.168.1.1
    Host IP address is below:
      192.168.1.145
      This should not change (in theory), but will be updated if this occurs
      
  As of now there is no password
  
Client will be sending OSC to server on port 8001 using the following addresses for each instrument

  /breakBot
  
  /ganaPati
  
  /tammy
  
  /marimba
  
  /rattleTron
  
  /trimpbeat
  
  Future instruments will follow the same naming convention
  
The format for the clients messages will be in this format. Address, note, velocity
    I.E: /breakBot 1 127

    
This should be all you need, I will be doing more comprehensive testing to ensure this, but as of now this should work.

On Github, I will put templates for how to send the signals for ease of use for client to use
