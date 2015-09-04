HC2 = Net.FHttp("192.168.1.249",80)
response = HC2:GET("/api/xdevices.json?cmd=30")
response = json.decode(response)
fibaro:debug(response.AN5)
fibaro:debug(response.AN6)
fibaro:debug(response.AN7)
fibaro:debug(response.AN8)
function round(num, dec)
  local mult = 10^(dec or 2)
  return math.floor(num * mult + 0.5) / mult
end
----------------------
-- Pince 10A * 0.00323
-- Pince 50A * 0.00646
-- Pince 50A * 0.01615
----------------------
local An5VA = round((response.AN5* 0.00323)*230)
local An6VA = round((response.AN6* 0.00323)*230)
local An7VA = round((response.AN7* 0.01615)*230)
local An8VA = round((response.AN8* 0.01615)*230)
fibaro:debug(An5VA)
fibaro:debug(An6VA)
fibaro:debug(An7VA)
fibaro:debug(An8VA)
-- MAJ VD
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label1.value",string.format("%d%s", An5VA, "VA"))
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label2.value",string.format("%d%s", An6VA, "VA"))
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label3.value",string.format("%d%s", An7VA, "VA"))
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label4.value",string.format("%d%s", An8VA, "VA"))
-- MAJ VG
fibaro:setGlobal("x400ct1", An5VA)
fibaro:setGlobal("x400ct2", An6VA)
fibaro:setGlobal("x400ct3", An7VA)
fibaro:setGlobal("x400ct4", An8VA)
DateHeure = os.date("%Y-%m-%d %H:%M:%S", os.time())
fibaro:debug(DateHeure)
fibaro:call(fibaro:getSelfId(),"setProperty","ui.Label5.value",DateHeure)
fibaro:log(DateHeure)
