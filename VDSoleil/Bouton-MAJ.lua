---------------------------------
-- Script de collecte de quelques indicateurs solaire
-- Auteur : Sébastien Joly
-- Date : 29 août 2015
-- Eléments de calculs :
-- http://www.plevenon-meteo.info/technique/theorie/enso/ensoleillement.html
-- http://herve.silve.pagesperso-orange.fr/solaire.htm
---------------------------------
-- Fonction déterminant si année bissextile
function AnneeBissextile(annee)
  return annee%4==0 and (annee%100~=0 or annee%400==0)
end
---------------------------------
-- Fonction de chargement de label
function setDevicePropertyValue(id, label, value)
  fibaro:call(id, "setProperty", "ui."..label..".value", value)
end
---------------------------------
-- Fonction spliter
function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
---------------------------------
-- Fonction de calcul de la distance entre deux points géographique en D°.DD
function geo_distance (lat1, lon1, lat2, lon2)
  if lat1 == nil or lon1 == nil or lat2 == nil or lon2 == nil then
    return nil
  end
  local dlat = math.rad(lat2-lat1)
  local dlon = math.rad(lon2-lon1)
  local sin_dlat = math.sin(dlat/2)
  local sin_dlon = math.sin(dlon/2)
  local a = sin_dlat * sin_dlat + math.cos(math.rad(lat1)) * math.cos(math.rad(lat2)) * sin_dlon * sin_dlon
  local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
  -- 6378 km est le rayon terrestre au niveau de l'équateur
  local d = 6378 * c
  return d
end
---------------------------------
-- Fonction Arrondir
function arrondir(num, dec)
  if num == 0 then
    return 0
  else
  	local mult = 10^(dec or 0)
  	return math.floor(num * mult + 0.5) / mult
  end
end
---------------------------------
-- Procedure principale
---------------------------------
-- Initilise la variable local de l'ID du VD
local VDid = fibaro:getSelfId()
-- Récupérer les anciennes valeurs VG
local ExVDSoleilAzimut=fibaro:getGlobal("VDSoleilAzimut")
local ExVDSoleilHauteur=fibaro:getGlobal("VDSoleilHauteur")
local ExVDSoleilRadiDir=fibaro:getGlobal("VDSoleilRadiDir")
local ExVDSoleilRadiDif=fibaro:getGlobal("VDSoleilRadiDif")
local ExVDSoleilRadiDif=fibaro:getGlobal("VDSoleilRadiDif")
local ExVDSoleilLuxTot=fibaro:getGlobal("VDSoleilLuxTot")
local ExVDSoleilOcta=fibaro:getGlobal("VDSoleilOcta")
local ExVDSoleilRadiPon=fibaro:getGlobal("VDSoleilRadiPon")
local ExVDSoleilLuxPon=fibaro:getGlobal("VDSoleilLuxPon")
---------------------------------
-- Requête API loopback pour récupérer Latitude & Longitude des paramètres HC
loopback = Net.FHttp("127.0.0.1",11111)
local response = loopback:GET("/api/settings/location")
jsonTable = json.decode(response)
local Ville = (jsonTable.city)
local Latitude = (jsonTable.latitude)
local Longitude = (jsonTable.longitude)
---------------------------------
-- Elevation Google API (Free)
GoogleElevation = Net.FHttp("maps.googleapis.com")
local response = GoogleElevation:GET("/maps/api/elevation/json?locations=".. Latitude .. "," .. Longitude .. "&sensor=false")
--local jsonTable = json.decode(response["results"][1])
--local Altitude = jsonTable.elevation
jsonTable = json.decode(response)
Altitude = jsonTable.results[1].elevation
---------------------------------
-- Meteo API OpenWeatherMap
OpenWeatherMap = Net.FHttp("api.openweathermap.org")
local response = OpenWeatherMap:GET("/data/2.5/weather?lat=".. Latitude .. "&lon=" .. Longitude .. "&units=metric")
local jsonTable = json.decode(response)
local Temperature = jsonTable.main.temp
local PressionRelative = jsonTable.main.pressure
local Humidite = jsonTable.main.humidity
local Nebulosite = jsonTable.clouds.all
---------------------------------
DateHeure = os.date("%Y-%m-%d %H:%M:%S", os.time())
-- Début debug
fibaro:debug("=====================================")
fibaro:debug(os.date("%Y-%m-%d %H:%M:%S", os.time()))
fibaro:debug(Ville .. ", " .. Latitude .. ", " .. Longitude)
fibaro:debug("Altitude = " .. tostring(Altitude) .. " m")
local An = os.date("%Y")
local NiemeJourDeLAnnee = os.date("%j")
fibaro:debug("NiemeJourDeLAnnee = " .. NiemeJourDeLAnnee)
if  AnneeBissextile(An) == true then
	fibaro:debug( An .. " est bissextile.")
	JourDansLAnnee = 366
else
	fibaro:debug( An .. " n'est pas bissextile.")
	JourDansLAnnee = 365
end
---------------------------------
-- Vitesse angulaire = Combien de degrés par jour
VitesseAngulaire = 360/365.25 ----JourDansLAnnee -- ou approximativement 365.25
fibaro:debug("Vitesse angulaire = " .. VitesseAngulaire .. " par jour")
---------------------------------
-- Formule Declinaison = ArcSin(0,3978 x Sin(Va x (j - (81 - 2 x Sin(Vaï¿½ x (j - 2))))))
local Declinaison = math.deg(math.asin(0.3978 * math.sin(math.rad(VitesseAngulaire) *(NiemeJourDeLAnnee - (81 - 2 * math.sin((math.rad(VitesseAngulaire) * (NiemeJourDeLAnnee - 2))))))))
fibaro:debug("La déclinaison = " .. Declinaison .. "°")
---------------------------------
-- Temps universel décimal (UTC)
TempsDecimal = (os.date("!%H") + os.date("!%M") / 60)
fibaro:debug("Temps universel decimal (UTC)".. TempsDecimal .." H.dd")
---------------------------------
-- Temps solaire
HeureSolaire = TempsDecimal + (4 * Longitude / 60 )
fibaro:debug("Temps solaire ".. HeureSolaire .." H.dd")
---------------------------------
-- Angle horaire du soleil
AngleHoraire = 15 * ( 12 - HeureSolaire )
fibaro:debug("Angle Horaire = ".. AngleHoraire .. "°")
---------------------------------
-- La hauteur du soleil (Elévation ou altitude)
HauteurSoleil = math.deg(math.asin(math.sin(math.rad(Latitude))* math.sin(math.rad(Declinaison)) + math.cos(math.rad(Latitude)) * math.cos(math.rad(Declinaison)) * math.cos(math.rad(AngleHoraire))))
fibaro:debug("Hauteur du soleil = " .. HauteurSoleil .. "°")
local Azimut = math.acos((math.sin(math.rad(Declinaison)) - math.sin(math.rad(Latitude)) * math.sin(math.rad(HauteurSoleil))) / (math.cos(math.rad(Latitude)) * math.cos(math.rad(HauteurSoleil) ))) * 180 / math.pi
local SinAzimut = (math.cos(math.rad(Declinaison)) * math.sin(math.rad(AngleHoraire))) / math.cos(math.rad(HauteurSoleil))
if(SinAzimut<0) then
  Azimut=360-Azimut
end
fibaro:debug("Azimut du soleil = " .. Azimut .. "°")
---------------------------------
-- La durée d'insolation journalière - non stockée en VG
DureeInsolation = math.deg(2/15 * math.acos(- math.tan(math.rad(Latitude)) * math.tan(math.rad(Declinaison))))
DureeInsolation = arrondir(DureeInsolation,2)
fibaro:debug("La durée d'insolation journalière = " .. DureeInsolation .." H.dd")
---------------------------------
-- Constantes Solaire
ConstanteRatiationSolaire = 1361 -- W/m²
ConstanteRadiationLux = 200000 -- Lux
---------------------------------
-- Rayonnement solaire (en W/m²) présent à l'entrée de l'atmosphère.
RadiationAtm = ConstanteRatiationSolaire * (1 +0.034 * math.cos( math.rad( 360 * NiemeJourDeLAnnee / JourDansLAnnee )))
fibaro:debug("Radiation max en atmosphère = " .. arrondir(RadiationAtm,2) .. " W/m²")
---------------------------------
-- Coefficient d'attenuation M
PressionAbsolue = PressionRelative - arrondir((Altitude/ 8.3),1) -- hPa
fibaro:debug("Pression relative locale = " .. PressionRelative .. " hPa")
fibaro:debug("Pression absolue atmosphère = " .. PressionAbsolue .. " hPa")
SinusHauteurSoleil = math.sin(math.rad(HauteurSoleil))
M0 = math.sqrt(1229 + math.pow(614 * SinusHauteurSoleil,2)) - 614 * SinusHauteurSoleil
M = M0 * PressionRelative/PressionAbsolue
fibaro:debug("Coefficient d'attenuation = " .. M )
---------------------------------
-- Récupérer message SYNOP avec un Get HTTP sur le site Ogimet
heureUTCmoins1 = os.date("!%H")-1
if string.len(heureUTCmoins1) == 1 then
  heureUTCmoins1 = "0" .. heureUTCmoins1
end
UTC = os.date("%Y%m%d").. heureUTCmoins1.."00" -- os.date("!%M")
fibaro:debug("Horodatage UTC = " .. UTC)
-- WMOID = "07643"
local WMOID = fibaro:get(fibaro:getSelfId(), "IPAddress")
fibaro:debug("Station SYNOP = " .. WMOID)
ogimet = Net.FHttp("www.ogimet.com")
local synop = ogimet:GET("/cgi-bin/getsynop?block=".. WMOID.."&begin=" .. UTC)
--fibaro:debug(synop) ---temporaire
rslt = split(synop,",")
CodeStation = rslt[1]
Coupure = " ".. CodeStation .. " "
--fibaro:debug(rslt[1])
rslt = split(synop, " "..CodeStation.. " ")
-- fibaro:debug(rslt[2])
Trame = string.gsub(rslt[2], "=", "")
Trame = CodeStation .." ".. Trame
--fibaro:debug(Trame)
rslt = split(Trame, " ")
---------------------------------
-- Récupérer le premier caractere du 3eme mot = Nebulosité en Octa
Octa = string.sub(rslt[3], 1, 1)
fibaro:debug( Octa .. " Octa")
-- 0         Pas de couverture nuageuse
-- 1-8       Huitième
-- 9         Brouillard
-- /        Couverture indiscernable
-- cas particulier si valeur indéterminé un slash est renvoyé. Afin d'être le plus pénalisant 8 sera retenu.
if Octa == "/" then
  Octa = 8
elseif Octa == "9" then
  Octa = 8
end
---------------------------------
-- Facteur d'atténuation des couches nuageuses Kc
-- Kc=1-(0.75*((OCTA)**(3.4))
Kc=1-0.75*(math.pow(Octa/8,3.4))
fibaro:debug("Kc = " .. Kc)
---------------------------------
-- Au lever/coucher du soleil, on atteind les limites de précisions de ces calculs.
-- J'interrompts donc le calcul de radiation dès 1°.
if HauteurSoleil > 0 then
-- Radiation directe
	RadiationDirecte = RadiationAtm * math.pow(0.6,M) * SinusHauteurSoleil
	fibaro:debug("RadiationDirecte = ".. arrondir(RadiationDirecte,2) .." W/m²")
-- Radiation Diffuse
	RadiationDiffuse = RadiationAtm * (0.271 - 0.294 * math.pow(0.6,M)) * SinusHauteurSoleil
	fibaro:debug("Radiation Diffuse = ".. arrondir(RadiationDiffuse,2) .." W/m²")
-- Radiation totale
	RadiationTotale = RadiationDiffuse + RadiationDirecte
	fibaro:debug("Radiation totale = " .. arrondir(RadiationTotale,2) .." W/m²")
-- Radiation en Lux : --  1 Lux = 0,0079 W/m²
	Lux = RadiationTotale / 0.0079
	--Lux = ConstanteRadiationLux / ConstanteRatiationSolaire * RadiationTotale
	fibaro:debug("Radiation totale en lux = ".. arrondir(Lux,2).." Lux")
-- Le rayonnement solaire avec ciel nuageux
	RTOTC = RadiationTotale * Kc
	fibaro:debug("Le rayonnement solaire avec pondération = " .. arrondir(RTOTC,2))
-- Radiation en Lux pondéré
	-- LuxPondere = ConstanteRadiationLux / ConstanteRatiationSolaire * RTOTC
	LuxPondere = RTOTC / 0.0079
	fibaro:debug("Radiation totale en lux pondéré = ".. arrondir(LuxPondere,2).." Lux")	
else
  RadiationDirecte = 0
  RadiationDiffuse = 0
  RadiationTotale = 0
  Lux = 0
  RTOTC = 0
  LuxPondere = 0
end
---------------------------------
-- Stocker les variables globales
-- Créer les variables globales suivantes :
-- VDSoleilAzimut
-- VDSoleilHauteur
-- VDSoleilRadiDir
-- VDSoleilRadiDif
-- VDSoleilRadiTot
-- VDSoleilLuxTot
-- VDSoleilOcta
-- VDSoleilRadiPon
-- VDSoleilLuxPon
fibaro:setGlobal("VDSoleilAzimut", arrondir(Azimut,2))
fibaro:setGlobal("VDSoleilHauteur", arrondir(HauteurSoleil,2))
fibaro:setGlobal("VDSoleilRadiDir", arrondir(RadiationDirecte,2))
fibaro:setGlobal("VDSoleilRadiDif", arrondir(RadiationDiffuse,2))
fibaro:setGlobal("VDSoleilRadiTot", arrondir(RadiationTotale,2))
fibaro:setGlobal("VDSoleilLuxTot", arrondir(Lux,2))
fibaro:setGlobal("VDSoleilOcta", Octa)
fibaro:setGlobal("VDSoleilRadiPon", arrondir(RTOTC,2))
fibaro:setGlobal("VDSoleilLuxPon", arrondir(LuxPondere,2))

---------------------------------
-- Mise à jour des labels
-- setDevicePropertyValue(VDid, "LabelAzimut",  arrondir(Azimut,0).."°" )
if tonumber(ExVDSoleilAzimut) > arrondir(Azimut,2) then
  setDevicePropertyValue(VDid, "LabelAzimut", arrondir(Azimut,0).."° ↓")
elseif tonumber(ExVDSoleilAzimut) < arrondir(Azimut,2) then
  setDevicePropertyValue(VDid, "LabelAzimut", arrondir(Azimut,0).."° ↑")
else
  setDevicePropertyValue(VDid, "LabelAzimut", arrondir(Azimut,0).."° →")
end

--setDevicePropertyValue(VDid, "LabelHauteur", arrondir(HauteurSoleil,0) .. "°" )
if tonumber(ExVDSoleilHauteur) > arrondir(HauteurSoleil,2) then
  setDevicePropertyValue(VDid, "LabelHauteur", arrondir(HauteurSoleil,0) .. "° ↓")
elseif tonumber(ExVDSoleilHauteur) < arrondir(HauteurSoleil,2) then
  setDevicePropertyValue(VDid, "LabelHauteur", arrondir(HauteurSoleil,0) .. "° ↑")
else
  setDevicePropertyValue(VDid, "LabelHauteur", arrondir(HauteurSoleil,0) .. "° →")
end


--setDevicePropertyValue(VDid, "LabelNebulosite", Octa .. "/8")
if ExVDSoleilOcta > Octa then
  setDevicePropertyValue(VDid, "LabelNebulosite", Octa .. "/8 ↓")
elseif ExVDSoleilOcta < Octa then
  setDevicePropertyValue(VDid, "LabelNebulosite", Octa .. "/8 ↑")
else
  setDevicePropertyValue(VDid, "LabelNebulosite", Octa .. "/8 →")
end

setDevicePropertyValue(VDid, "LabelNebPourCent", Nebulosite .. "%")
setDevicePropertyValue(VDid, "LabelMaj",DateHeure)
setDevicePropertyValue(VDid, "LabelRadiationDirecte", arrondir(RadiationDirecte,0) .. " W/m²")
setDevicePropertyValue(VDid, "LabelRadiationDiffuse", arrondir(RadiationDiffuse,0) .. " W/m²")
setDevicePropertyValue(VDid, "LabelRadiationTotale", arrondir(RadiationTotale,0) .. " W/m²")
setDevicePropertyValue(VDid, "LabelLux",arrondir(Lux,0) .. " Lx")
setDevicePropertyValue(VDid, "LabelRTOTC", arrondir(RTOTC,0) .. " W/m²")
setDevicePropertyValue(VDid, "LabelLuxPondere", arrondir(LuxPondere,0) .. " Lx")
---------------------------------
-- Tag widget
fibaro:log(DateHeure)
