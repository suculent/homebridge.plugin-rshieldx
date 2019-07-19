# homebridge-plugin-rshieldX

[![Greenkeeper badge](https://badges.greenkeeper.io/suculent/homebridge.plugin-rshieldx.svg)](https://greenkeeper.io/)

This is simple [homebridge](https://github.com/nfarina/homebridge) plugin for Wemos D1 with single Relay Shield and additional accessories.

Purpose of this implementation is to drive a simple on/off LED light in kids’ wardrobe closet. As soon as someone enters in, PIR sensor turns off the light. Light gets turned off after a timer when PIR sensor does not detect anything.

Whole system reports to Homebridge through MQTT and can be controlled from iOS device through respective Homebridge plugin.

## Prerequisites

* ESPTool (to load LUA code to Wemos D1)
* Wemos D1 with NodeMCU firmware
* Wemos Relay shield or any other relay conencted to pin D1 (configurable)
* Homebridge on local WiFi
* Any relay-controlled light, in this case a 12V LED Strip (separate power)
* PIR Sensor (tested with HC-SR501 preferably, would require adjustments for HC-505)

## Installation

```
    git clone https://github.com/suculent/homebridge-plugin-rshieldx.git
    cd homebridge-plugin-rshieldx
    npm install -g .
```

Edit config.lua in the esp8266 folder with your wifi credentials and load all the lua files to your Wemos D1 ESP8266 (using ESPTool).

Restart your Wemos. It should start listening to your MQTT channel. You can test it by sending `ON` or `OFF` to MQTT channel `/relay/1` with default configuration.

Edit your Homebridge configuration based on sample-config.json file.

Restart your homebridge and add the new device.

---

TODO: Add documentation for PIR and LEDs when done
