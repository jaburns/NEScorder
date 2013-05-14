NEScorder
=========

This is a device I built for recording and playing back NES gameplay on original hardware. The gameplay is saved by recording controller inputs along with a timestamp to an SD card each time the NES controller state changes. Playback is achieved by feeding the NES the recorded controller data at the appropriate time.

Playback/recording mode is selected before the NES is powered on. The device reads the state switch before the first controller state request from the NES and behaves appropriately.

The first red LED blinks when the device is active (playing back or recording). A second red LED is solid when in recording mode. A green LED is solid when in playback mode, and a yellow LED is solid when the device is inactive. The device can be inactive either by starting the NES with the rocker switch in the central off position, or when playback is complete (runs out of recorded data).

[View Schematics]()
[Download EAGLE 5.7.0 Schematic File]()
[Download Arduino Source]()

*** Demo Video

*** Development Images
