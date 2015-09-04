HC2 = Net.FHttp("192.168.1.249",80)
response = HC2:GET("/api/xdevices.json?cmd=30")
response = json.decode(response)
fibaro:debug(response.AN1)
fibaro:debug(response.AN2)
fibaro:debug(response.AN3)
fibaro:debug(response.AN4)
--Arrondi
function round(num, dec)
  local mult = 10^(dec or 2)
  return math.floor(num * mult + 0.5) / mult
end
--SHT-X3:Temp-TC5050 
local An3TC5050  = round((((response.AN3 * 0.00323)- 1.63)/0.0326))
fibaro:debug(An3TC5050)
--SHT-X3:RH-SH100
--if (An3TC5050 == 0) then
-- 	local An1SH100 = round(((((response.AN1 * 0.00323)/3.3)-0.1515) / 0.00636) /(1.0546 - (0.00216 * An3TC5050)))
--else
	local An1SH100 = round((((response.AN1 * 0.00323/3.3)-0.1515) / 0.00636))
--end
fibaro:debug(An1SH100)
--SHT-X3:Light-LS100  
local An2LS100 = round((response.AN2 * 0.09775))
fibaro:debug(An2LS100)
--RIEN
local An4RIEN = round(response.AN4)
fibaro:debug(An4RIEN)
--Affichage
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label1.value",string.format("%d%s", An1SH100, " %"))
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label2.value",string.format("%d%s", An2LS100, " %"))
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label3.value",string.format("%d%s", An3TC5050, " °C"))
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label4.value",string.format("%d%s", An4RIEN, " "))

DateHeure = os.date("%Y-%m-%d %H:%M:%S", os.time())
fibaro:debug(DateHeure)
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label5.value",DateHeure)
fibaro:log(DateHeure)
