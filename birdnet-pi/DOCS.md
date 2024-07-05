I've tested lots of settings by running 2 versions of my HA birdnet-pi addon in parallel using the same rtsp feed, and comparing impact of parameters. 
My conclusions aren't universal, as it seems to be highly dependent on the region and type of mic used. For example, the old model seems to be better in Australia, while the new one better in Europe.

# Microphone considerations
The critical element is the microphone quality : a Boya By-lm 40 or clippy EM272 (with a very good aux-usb converter) is key to improve the quality of detections. 
Here is some example tests I did (whole threads are really interesting also): https://github.com/mcguirepr89/BirdNET-Pi/discussions/39#discussioncomment-9706951 
https://github.com/mcguirepr89/BirdNET-Pi/discussions/1092#discussioncomment-9706191

My recommendation (https://github.com/mcguirepr89/BirdNET-Pi/discussions/39#discussioncomment-9706951) :
- Best entry system (< 50€) : Boya By-lm40 (30€) + deadcat (10 €)
- Best middle system (< 100 €) : HyperX Quadcast (80€) + deadcat (10€) ; but I'm concerned about the longevity of this mic outside
- Best high end system (< 150 €) : Clippy EM272 (55€) + Rode AI micro trrs to usb (70€) + Rycote deadcat (27€)

My current system : 
- EM272 clippy TTRS
- AI RODE micro TTRS to USB converter
- Rpi3b+ that converts the USB signal to rtsp (48khz, 16bits, mono, as this is what the model uses)

# App settings recommendation
- Model
    - Version : 6k_v2,4 _(performs better in Europe at least, the 6k performs better in Australia)_
    - Species range model : v1 _(uncheck v2.4 ; seems more robust in Europe)_
    - Species occurence threshold : 0,001 _(was 0,00015 using v2.4 ; use the Species List Tester to check the correct value for you)_
- Audio settings
    - Default
    - Channel : 1 _(doesn't really matter as analysis is made on mono signal ; 1 allows decreased saved audio size but seems to give slightly messed up spectrograms in my experience)_
    - Recording Length : 18 _(that's because I use an overlap of 0,5 ; so it analysis 0-3s ; 2,5-5,5s ; 5-8s ; 7,5-10,5 ; 10-13 ; 12,5-15,5 ; 15-18)_
    - Extraction Length : 9s _(could be 6, but I like to hear my birds :-))_
    - Audio format : mp3 _(why bother with something else)_
- Birdnet-lite settings
    - Overlap : 0,5s
    - Minimum confidence : 0,7
    - Sigmoid sensitivity : 1,25 _(I've tried 1,00 but it gave much more false positives ; as decreasing this value increases sensitivity)_
