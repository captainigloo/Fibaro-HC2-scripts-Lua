local myDeviceID = fibaro:getSelfId() 
if type(n) == "nil" then
n1 = tonumber(os.time())
fibaro:call(myDeviceID, "pressButton", "6")
n = 1
end

if tonumber(os.time()) > n1 + (4) then
  fibaro:call(myDeviceID, "pressButton", "6")
  n1 = tonumber(os.time())
end

