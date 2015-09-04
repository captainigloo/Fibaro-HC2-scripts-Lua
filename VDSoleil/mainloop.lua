maintenant = os.date("%H:%M", os.time())
---------------------------------
-- Fonction d'initialisation de label
---------------------------------
function setDevicePropertyValue(id, label, value)
  fibaro:call(id, "setProperty", "ui."..label..".value", value)
end
---------------------------------
local myDeviceID = fibaro:getSelfId() 
if maintenant > fibaro:getValue(1, "sunriseHour") and maintenant < fibaro:getValue(1, "sunsetHour") then
-- ID icône jour
  fibaro:call(myDeviceID, "setProperty", "currentIcon", 227)
	if type(n) == "nil" then
		n1 = tonumber(os.time())
		fibaro:call(myDeviceID, "pressButton", "12")
		n = 1
	end
	if tonumber(os.time()) > n1 + (60) then -- maj toutes les minutes
  		fibaro:call(myDeviceID, "pressButton", "12")
  		n1 = tonumber(os.time())
	end
else
-- ID icône nuit
	fibaro:call(myDeviceID, "setProperty", "currentIcon", 229)
end
