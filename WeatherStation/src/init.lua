--init.lua
print("Setting up WIFI...")
wifi.setmode(wifi.STATION)
--modify according your wireless router settings
wifi.sta.config("YOUR_WIFI_NETWORK","YOUR_WIFI_PASWORD")
wifi.sta.connect()
error_count = 0

function sendData(T,H,P)
    -- conection to thingspeak.com
    print("Sending data to thingspeak.com")
    sk=net.createConnection(net.TCP, 0)
    sk:on("receive", function(sk, c) print(c) end )
    sk:connect(80,"api.thingspeak.com")
    sk:on("connection", function(sk,c)
        -- Wait for connection before sending.
        sk:send("GET /update?key=YOUR_KEY&field1="..T.."&field2="..H.."&field3="..P.."&field4="..error_count.." HTTP/1.1\r\nHost: api.thingspeak.com\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")
    end)    
    sk = nil
end

function getData(t,h)
    dht22 = require("dht22")
    dht22.read(2)
    t = dht22.getTemperature()
    h = dht22.getHumidity()
    
    if h == nil then
      print("Error reading from DHT22")
      error_cont= error_count + 1
      gpio.write(1, gpio.HIGH)
    else
      gpio.write(1, gpio.LOW)
      bmp180 = require("bmp180")
      
      -- ###############################################
      --                              DHT22
      -- ###############################################
      TC = ((t-(t % 10)) / 10).."."..(t % 10)
      TF = (9 * t / 50 + 32).."."..(9 * t / 5 % 10)
      -- temperature in degrees Celsius  and Farenheit
      -- floating point and integer version:
      print("Temperature: "..TC.." deg C")
      -- only integer version:
      print("Temperature: "..TF.." deg F")
      -- only float point version:
      print("Temperature: "..(9 * t / 50 + 32).." deg F")    
      -- humidity
      -- floating point and integer version
      H = ((h - (h % 10)) / 10).."."..(h % 10)
      print("Humidity: "..H.."%")
      
      -- ###############################################
      --                              BMP180
      -- ###############################################
      OSS = 1 -- oversampling setting (0-3)      
      bmp180.init(4,3)
      bmp180.read(OSS)
      p = bmp180.getPressure()
      P = p
      Hpa = (p / 100).."."..(p % 100)
      Mbar = (p / 100).."."..(p % 100)
      Mmhg = (p * 75 / 10000).."."..((p * 75 % 10000) / 1000)

      -- pressure in differents units
      print("Pressure: "..(p).." Pa")
      print("Pressure: "..Hpa.." hPa")
      print("Pressure: "..Mbar.." mbar")
      print("Pressure: "..Mmhg.." mmHg")
        
      -- release module      
      bmp180 = nil
      package.loaded["bmp180"]=nil     
      sendData(TC,H,P)
    end
    
end

tmr.alarm(1, 60000, 1, function() 
    if wifi.sta.getip()== nil then 
        print("IP unavaiable, Waiting...") 
    else
        --tmr.stop(1)
        print("Config done, IP is "..wifi.sta.getip())
        getData()
    end    
end)
