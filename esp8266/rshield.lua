-- Timers
-- 0 = WiFi status + mqtt connect
-- 1 = MQTT offline
-- 2 = Free
-- 3 = Free
-- 4 = Free
-- 5 = MQTT activity
-- 6 = Button debounce

dofile("config.lua")

mqttBroker = mqtt_broker 
mqttUser = "none"
mqttPass = "none"
mqttChannel = "/relay/1"
 
deviceID="TRAINZ"
roomID="1"
 
wifi.setmode(wifi.STATION)
wifi.sta.config (wifi_ssid, wifi_password)
 
 
-- Pin which the relay is connected to
relayPin = 1 -- D1
gpio.mode(relayPin, gpio.OUTPUT)
gpio.write(relayPin, gpio.LOW) 
 
-- MQTT led
mqttLed = 4
gpio.mode(mqttLed, gpio.OUTPUT)
gpio.write(mqttLed, gpio.LOW)
 
-- Make a short flash with the led on MQTT activity
function mqttAct()
    if (gpio.read(mqttLed) == 1) then gpio.write(mqttLed, gpio.HIGH) end
    gpio.write(mqttLed, gpio.LOW)
    tmr.alarm(5, 50, 0, function() gpio.write(mqttLed, gpio.HIGH) end)
end
 
m = mqtt.Client("RelayShield-" .. deviceID, 180, mqttUser, mqttPass)
m:lwt("/lwt", "RelayShield " .. deviceID, 0, 0)
m:on("offline", function(con)
    ip = wifi.sta.getip()
    print ("MQTT reconnecting to " .. mqttBroker .. " from " .. ip)
    tmr.alarm(1, 10000, 0, function()
        node.restart();
    end)
end)
 
 
-- Update status to MQTT
function mqtt_update()
    if (gpio.read(relayPin) == 0) then
        m:publish(mqttChannel .. "/state","OFF",0,0)
    else
        m:publish(mqttChannel .. "/state","ON",0,0)
    end
end
  
-- On publish message receive event
m:on("message", function(conn, topic, data)
    pwm.stop(mqttLed)
    --mqttAct()
    print("Recieved:" .. topic .. ":" .. data)
        if (data=="ON") then
        print("Enabling Output")
        gpio.write(relayPin, gpio.HIGH)
        gpio.write(mqttLed, gpio.LOW)
    elseif (data=="OFF") then
        print("Disabling Output")                 
        gpio.write(relayPin, gpio.LOW)
        gpio.write(mqttLed, gpio.HIGH)
    else
        print("Invalid command (" .. data .. ")")
    end
    mqtt_update()
end)
 
 
-- Subscribe to MQTT
function mqtt_sub()
    mqttAct()
    m:subscribe(mqttChannel,0, function(conn)
        print("MQTT subscribed to " .. mqttChannel)        
        pwm.setup(mqttLed, 1, 512)
        pwm.start(mqttLed)
    end)    
end

tmr.alarm(0, 1000, 1, function()
    if wifi.sta.status() == 5 and wifi.sta.getip() ~= nil then  
        tmr.stop(0)
        m:connect(mqttBroker, 1883, 0, function(conn)
            gpio.write(mqttLed, gpio.LOW)
            print("MQTT connected to:" .. mqttBroker)
            mqtt_sub() -- run the subscription function
        end)
    end
 end)
