bluesky-client-libperl
========================
The library provides a simple way to connect the bluesky API. 

Requirements
------------

- perl v5.14.2 or upper.

- Another perl modules: "libwww-perl" and "libjson-perl".

How to
------

```shell
perl testlib.pl
```

The "testlib.pl" is using "bluesky_cli.pm" in order to get all of sensor data that connecting bluesky. The program will show the sensor data from all of sensor nodes that connected the mcp3208 or the same another ADC modules of all channel. In addidition, the pin number can be specified with the API provided by the light-weight connecting protocol of [Blue-sky cloud server](https://github.com/Bluesky-CPS/BlueSkyLoggerCloudBINResearchVer1.0).
  
***Author***: *Praween AMONTAMAVUT*
