-- Timers
-- 1 = Initial PIR, WiFi status + mqtt connect
-- 2 = Seconary PIR when connected to MQTT (with reporting)
-- 3 = Reconnection / reboot alarm

state = 0

proximityTimeout = 5000

dofile("config.lua")

mqttBroker = mqtt_broker 
mqttUser = "none"
mqttPass = "none"
mqttChannel = "/relay/1"
 
deviceID=node.chipid()
 
wifi.setmode(wifi.STATION)
wifi.sta.config (wifi_ssid, wifi_password)
wifi.sta.connect()
 
-- Pin which the relay is connected to
relayPin = 1 -- D1
gpio.mode(relayPin, gpio.OUTPUT)
gpio.write(relayPin, gpio.LOW) 
 
-- MQTT led
mqttLed = 4
gpio.mode(mqttLed, gpio.OUTPUT)
gpio.write(mqttLed, gpio.LOW)

-- Extensions

-- PIR pin
-- http://escapequotes.net/wp-content/uploads/2016/02/d1-mini-esp8266-board-sh_fixled.jpg
pirPin = 5 -- D5 (works)
gpio.mode(pirPin, gpio.INPUT)

mqtt_connected = false

-- Functions

-- Update status to MQTT
function mqtt_update()
    if m ~= NULL then
    if (gpio.read(relayPin) == 0) then
        m:publish(mqttChannel .. "/state","OFF",0,0)
    else
        m:publish(mqttChannel .. "/state","ON",0,0)
    end
    end
end

-- Subscribe to MQTT
function mqtt_sub()
    m:subscribe(mqttChannel,0, function(conn)
        print("MQTT subscribed to " .. mqttChannel)        
        pwm.setup(mqttLed, 1, 512)
        pwm.start(mqttLed)
    end)    
end

function relay_on() 
    print("Turning light ON")
    gpio.write(relayPin, gpio.HIGH)
    gpio.write(mqttLed, gpio.LOW)
    state = 1
end

relay_on()

function relay_off()
    print("Turning light OFF")                 
    gpio.write(relayPin, gpio.LOW)
    gpio.write(mqttLed, gpio.HIGH)
    state = 0
end

-- Setup
function mq(mqtt_broker) 
    m = mqtt.Client("RelayShieldX-" .. deviceID, 180, mqttUser, mqttPass)
    m:lwt("/lwt", "RelayShieldX " .. deviceID, 0, 0)
    m:on("offline", function(con)
        ip = wifi.sta.getip()
        print ("MQTT reconnecting to " .. mqttBroker .. " from " .. ip)
        tmr.alarm(3, 10000, 0, function()
            node.restart();
        end)
    end)
  
    -- On publish message receive event
    m:on("message", function(conn, topic, data)
        pwm.stop(mqttLed)
        print("Recieved:" .. topic .. ":" .. data)
        if (data=="ON") then
            relay_on() 
        elseif (data=="OFF") then
            relay_off()
        else
            print("Invalid command (" .. data .. ")")
        end    
        mqtt_update() -- do not update when not connected
    end)

    print("MQTT connecting..." .. mqtt_broker)
    m:connect(mqtt_broker, 1883, 0, function(conn)
        mqtt_connected = true
        gpio.write(mqttLed, gpio.LOW)
        print("MQTT connected to:" .. mqttBroker)
        mqtt_sub() -- run the subscription function  
        tmr.alarm(2, 2000, 1, function()
            pir_check(mqtt_connected)
        end)                  
    end)     
end

-- Main

-- Main loop (integration point)

function pir_check(report)
    report = mqtt_connected
     -- PIR Check
    local status = gpio.read(pirPin);
    if status == gpio.LOW then
        print("PIR state: CLEAR")
        relay_off()
    else
        print("PIR state: PROXIMITY")
        relay_on()
    end

    if report == true then
        print("Reporting PIR state to MQTT...")
        mqtt_update()
    end
end

tmr.alarm(1, 2000, 1, function()
    pir_check(false)
    if wifi.sta.getip() == nil then
        print("Connecting " .. wifi_ssid .. "...")
    else
        tmr.stop(1)
        print("Connected to " .. wifi_ssid  .. ", IP is "..wifi.sta.getip())
        mq(mqtt_broker) -- define in config.lua
    end
end)
