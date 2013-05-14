NEScorder
=========

This is a device I built for recording and playing back NES gameplay on original hardware. The gameplay is saved by recording controller inputs along with a timestamp to an SD card each time the NES controller state changes. Playback is achieved by feeding the NES the recorded controller data at the appropriate time.

Playback/recording mode is selected before the NES is powered on. The device reads the state switch before the first controller state request from the NES and behaves appropriately.

The first red LED blinks when the device is active (playing back or recording). A second red LED is solid when in recording mode. A green LED is solid when in playback mode, and a yellow LED is solid when the device is inactive. The device can be inactive either by starting the NES with the rocker switch in the central off position, or when playback is complete (runs out of recorded data).

[View Schematics](https://raw.github.com/jeremyaburns/NEScorder/master/NEScorder_JAB_rev2.png)  
[Download EAGLE 5.7.0 Schematic File](https://github.com/jeremyaburns/NEScorder/raw/master/NEScorder_JAB_rev2.sch)  
[Download Arduino Source](https://raw.github.com/jeremyaburns/NEScorder/master/NEScorder.pde)

### Demo Video

[![Demonstration](http://img.youtube.com/vi/HrCzMA-UMKc/0.jpg)](http://www.youtube.com/watch?v=HrCzMA-UMKc)  

### Development Images

<<<<<<< HEAD
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/1.jpg)  
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/2.jpg)  
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/3.jpg)  
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/4.jpg)  
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/5.jpg)  
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/6.jpg)  
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/7.jpg)  
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/8.jpg)  
![](https://raw.github.com/jeremyaburns/NEScorder/master/dev-images/9.jpg)  
=======
![](https://raw.github.com/jeremyaburns/NEScorder/master/NEScorder_JAB_rev2.png)
>>>>>>> d0bb08c8228b8dd2fb163d8638d57173cde271e5
