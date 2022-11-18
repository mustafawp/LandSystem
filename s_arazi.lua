db = dbConnect("sqlite","arazi.db")

if db then
	print("sa")
end
local tablo = { }
local alans = { }
local girenler = { }
local arazisahipleri = { }
local sahipkadi
local id
local giren
local area
local alana
local tarih

addEventHandler("onResourceStart", resourceRoot, function() 
        dbQuery(araziolustur, db, "SELECT * FROM veriler")
end)	

function araziolustur(veriler)
    local veri = dbPoll(veriler,0)
	tablo = {}
	arazisahipleri = {}
    arazileriyenidenolustur(veri)
end

function arazileriyenidenolustur(veriler)
    for i,v in ipairs (veriler) do 
		local x,y,bx,by,renk,aracengel,id,sahip,ucret = v.arazix,v.araziy,v.arazib,v.araziu,v.arazirenk,v.araziaracizin,v.araziid,v.arazisahip,v.araziucret
		local r,g,b = hexToRGB(renk)  
		local alan = createColCuboid (x,y,-50,bx,by, 3000) 
		local area = createRadarArea (x,y,bx,by,r,g,b,170) 
		table.insert(arazisahipleri,sahip)
		if not tablo[alan] then tablo[alan] = {} end 
		tablo[alan].area = area 
		tablo[alan].alans = alan
		tablo[alan].aracengel = aracengel
		tablo[alan].id = id
		tablo[alan].arazisahip = sahip
		tablo[alan].arazitarih = ucret
		addEventHandler("onColShapeHit", alan, girdi) 
		addEventHandler("onColShapeLeave", alan, cikti) 
	end
end

local oyuncuhesap
local arazid
local adam

function AraziSatinAl(veris)
	local result = dbPoll(veris,0)
	local mani
	local arazisahibi
	for i,v in pairs(result) do
		mani = v.arazifiyat
		arazisahibi = v.arazisahip
	end
	local adaminpara = getPlayerMoney(adam)
	if tonumber(adaminpara) >= tonumber(mani) then
		dbExec(db,"UPDATE veriler SET arazisahip = ?, arazidurum = ?, arazioncekif = ? WHERE araziid = ?",oyuncuhesap,"Satışta Değil",mani,arazid)
		takePlayerMoney(adam,mani)
		sahibeparayigonder(mani,arazisahibi)
		table.insert(arazisahipleri,oyuncuhesap)
		for i,v in pairs(arazisahipleri) do
			if tostring(v) == tostring(arazisahibi) then 
				table.remove(arazisahipleri,i)
			end
		end
		exports.hud:dm("#ffffffBu araziyi, #ff7f00Başarıyla Satın Aldınız!",adam,255,255,255,true)
		triggerClientEvent(adam,"AraziSystem:MainPanelKapa",adam)
	else
		exports.hud:dm("#ffffffBu araziyi almak için, #ff7f00Yeterli Paran Yok.",adam,255,255,255,true)
	end
end

function sahibeparayigonder(mani,sahip)
	exports["bankasistem"]:AraziParasiniVer(mani,sahip)
end

addEvent("AraziSystem:SatisVeDevir",true)
addEventHandler("AraziSystem:SatisVeDevir",root,function(id,olay,oyuncu)
	if olay == "Devir" then	
		if getAccountName(getPlayerAccount(source)) == oyuncu then exports.hud:dm("#ffffffKendi arazini, #ff7f00kendine devredemezsin!?",source,255,255,255,true) return end
		for i,v in pairs(arazisahipleri) do
			if tostring(v) == tostring(oyuncu) then exports.hud:dm("#ffffffSeçili oyuncunun, #ff7f00zaten arazisi var.",source,255,255,255,true) return end
		end
		dbExec(db,"UPDATE veriler SET arazisahip = ?, arazidurum = ?, arazioncekif = ? WHERE araziid = ?",oyuncu,"Satılık Değil","Devredildi",id)
		table.insert(arazisahipleri,oyuncu)
		for i,v in pairs(arazisahipleri) do
			if tostring(v) == tostring(getAccountName(getPlayerAccount(source))) then 
				table.remove(arazisahipleri,i)
			end
		end
		exports.hud:dm("#ff7f00Arazi No: "..tostring(id).." isimli arazini, başarıyla devrettin.",source,255,255,255,true)
		triggerClientEvent(source,"AraziSystem:YonetimPanelKapa",source)
	elseif olay == "Satış" then
		oyuncuhesap = getAccountName(getPlayerAccount(source))
		for i,v in pairs(arazisahipleri) do
			if tostring(v) == tostring(oyuncuhesap) then exports.hud:dm("#ffffffSenin, #ff7f00zaten arazin var.",source,255,255,255,true) return end
 		end
		adam = source
		arazid = id
		dbQuery(AraziSatinAl,db,"SELECT * FROM veriler WHERE araziid = ?",id)
	elseif olay == "SunucuyaSatış" then
		local data = dbPoll(dbQuery(db, "SELECT * FROM veriler"), -1)
		local degeri
		local para
		if type(data) == "table" and #data ~= 0 then
		for i,v in pairs(data) do 
			if tonumber(id) == tonumber(v.araziid) then
				para = tonumber(v.araziilkfiyat)
				degeri = math.ceil(para*.9*100/100/2)
			end
		end
		givePlayerMoney(source,degeri)
		exports.hud:dm("#ffffffBaşarıyla arazini, #ff7f00Sunucu Yönetimine #ffffffSattın! Kazancın: "..degeri,source,255,255,255,true)
		dbExec(db,"UPDATE veriler SET arazisahip = ?, arazidurum = ?, arazioncekif = ?, arazifiyat = ? WHERE araziid = ?","MaddeGaming","Satışta",degeri,para,id)
		triggerClientEvent(source,"AraziSystem:YonetimPanelKapa",source)
	end
	end
end)


addEvent("AraziSystem:SatisaCikar",true)
addEventHandler("AraziSystem:SatisaCikar",root,function(id,miktar,olay)
	if tonumber(miktar) < 0 then exports.hud:dm("#ff7f00Arazi fiyatı 0 'dan #ffffffküçük olamaz!",source,255,255,255,true) return end
	if olay == "Satış" then
	if tonumber(miktar) <= 0 then exports.hud:dm("#ff7f00Arazi No: "..tostring(id).." isimli arazini, satışa çıkaramadın. Sebep: Miktar - içermemeli.",source,255,255,255,true) return end
	dbExec(db,"UPDATE veriler SET arazidurum = ?, arazifiyat = ? WHERE araziid = ?","Satışta",miktar,id)
	exports.hud:dm("#ff7f00Arazi No: "..tostring(id).." isimli arazini, başarıyla satışa çıkardın. Miktar: "..miktar,source,255,255,255,true)
	triggerClientEvent(source,"AraziSystem:YonetimPanelKapa",source)
	elseif olay == "Kaldir" then
		dbExec(db,"UPDATE veriler SET arazidurum = ? WHERE araziid = ?","Satılık Değil",id)
		exports.hud:dm("#ff7f00Arazi No: "..tostring(id).." isimli arazini, başarıyla satıştan çıkardın.",source,255,255,255,true)
		triggerClientEvent(source,"AraziSystem:YonetimPanelKapa",source)
	end
end)

function girdi(oyuncu)
	cisim = getElementType(oyuncu)
	if cisim == "player" then
		if getPedOccupiedVehicle(oyuncu) then return end
		if isGuestAccount(getPlayerAccount(oyuncu)) then return end
		--if getElementData(oyuncu,"AraziSystem:Tarim") == true then return end
		giren = oyuncu
		id = tablo[source].id
		area = tablo[source].area
		alana = tablo[source].alans
		tarih = tablo[source].arazitarih
		local ismi = getAccountName(getPlayerAccount(oyuncu))
		table.insert(girenler,tostring(ismi))
		triggerClientEvent(oyuncu,"AraziSystem:Guncelle",oyuncu,girenler)
		dbQuery(arazibilgiac,db,"SELECT * FROM veriler")
	 elseif cisim == "vehicle" then
		if tostring(tablo[source].aracengel) == "true" then
			oyuncua = getVehicleOccupant(oyuncu,0)
			if getElementData(oyuncua,"AraziSystem:Tarim") == true then return end
			destroyElement(oyuncu) 
			id = tablo[source].id
			area = tablo[source].area
			alana = tablo[source].alans
			tarih = tablo[source].arazitarih
			local ismi = getAccountName(getPlayerAccount(oyuncua))
			table.insert(girenler,tostring(ismi))
			local adi = getAccount(ismi)
			local tepki = getAccountPlayer(adi)
			giren = tepki
			exports.hud:dm("#ffffffBu araziye #ff7f00Araçla Girmek Yasak #ffffffolduğu için, aracın kaldırıldı.",tepki,255,255,255,true)
			triggerClientEvent(tepki,"AraziSystem:Guncelle",tepki,girenler)
			dbQuery(arazibilgiac,db,"SELECT * FROM veriler")
		 elseif tostring(tablo[source].aracengel) == "false" then
			oyuncua = getVehicleOccupant(oyuncu,0)
			if getElementData(oyuncua,"AraziSystem:Tarim") == true then return end
			id = tablo[source].id
			area = tablo[source].area
			alana = tablo[source].alans
			tarih = tablo[source].arazitarih
			local ismi = getAccountName(getPlayerAccount(oyuncua))
			table.insert(girenler,tostring(ismi))
			local adi = getAccount(ismi)
			local tepki = getAccountPlayer(adi)
			giren = tepki
			triggerClientEvent(tepki,"AraziSystem:Guncelle",tepki,girenler)
			dbQuery(arazibilgiac,db,"SELECT * FROM veriler")
		end
	end
end


function arazibilgiac(veriler)
	local secilen = dbPoll(veriler,0)
	for i,v in pairs(secilen) do
		if id == v.araziid then
			sahipkadi = v.arazisahip
		end
	end
	triggerClientEvent(giren,"AraziSystem:AraziGiris",giren,secilen,id)
end

function cikti(oyuncu)
	if getElementType(oyuncu) == "vehicle" then
		oyuncua = getVehicleOccupant(oyuncu,0)
		local ismi = getAccountName(getPlayerAccount(oyuncua))
		local adi = getAccount(ismi)
		local tepki = getAccountPlayer(adi)
		for i,v in pairs(girenler) do 
			if ismi == v then
				table.remove(girenler,i)
			end
		end
		triggerClientEvent(tepki,"AraziSystem:Guncelle",tepki,girenler)
	else
	local ismi = getAccountName(getPlayerAccount(oyuncu))
	for i,v in pairs(girenler) do 
		if ismi == v then
			table.remove(girenler,i)
		end
	end
	triggerClientEvent(oyuncu,"AraziSystem:Guncelle",oyuncu,girenler)
	end
end


addEvent("AraziSystem:YonetimKontrol",true)
addEventHandler("AraziSystem:YonetimKontrol",root,function()
	local hesap = getAccountName(getPlayerAccount(source))
	if hesap == sahipkadi then
		triggerClientEvent(source,"AraziSystem:YonetimPanelAc",source)
	else
		exports.hud:dm("#FFFFFFBu Arazi #ff7f00sana ait değil, #ffffffo yüzden yönetim panelini açamazsın.",source,255,255,255,true) return	end
end)

addEvent("AraziSystem:Aracİzni",true)
addEventHandler("AraziSystem:Aracİzni",root,function(durum)
	hesap = getAccountName(getPlayerAccount(source))
	if durum == "ac" then
	dbExec(db,"UPDATE veriler SET araziaracizin = ? WHERE arazisahip = ?","false",hesap)
	tablo[alana].aracengel = "false"
	elseif durum == "kapa" then
		dbExec(db,"UPDATE veriler SET araziaracizin = ? WHERE arazisahip = ?","true",hesap)
		tablo[alana].aracengel = "true"
	end
end)

addEvent("AraziSystem:AraziRenkDegis",true)
addEventHandler("AraziSystem:AraziRenkDegis",root,function(renk,id)
	if #renk ~= 6 then exports.hud:dm("#FFFFFFArazi Rengi #ff7f006 harf veya rakamdan, #ffffffoluşmalıdır.",source,255,255,255,true) return end
	dbExec(db,"UPDATE veriler SET arazirenk = ? WHERE araziid = ?",renk,id)
	local r,g,b = hexToRGB(renk)
	setRadarAreaColor(area,r,g,b,170)
	exports.hud:dm("#FFFFFFArazi Rengi #ff7f00Başarıyla Değiştirildi! #ffffff(bu işlemi sık kullanmak ban sebebi.)",source,255,255,255,true)
end)

local veh

addEvent("AraziSystem:AraziEk",true)
addEventHandler("AraziSystem:AraziEk",root,function(id)
	local tarih = tablo[alana].arazitarih
    local time = getRealTime()
    local monthday = time.monthday
	local gun = string.format("%02d",monthday-1)
	if tonumber(gun) == 31 or tonumber(gun) == 30 then exports.hud:dm("#FFFFFFAraziye #ff7f00Ayın 30 u ve 31 inde #ffffffEkim yapamazsın. Sebep: (ekin yok)",source,255,255,255,true) return end
    local month = time.month
    local year = time.year
    local bugun = string.format("%02d-%02d-%04d", monthday, month + 1, year + 1900)
	local bigunsonra = string.format("%02d-%02d-%04d", monthday, month + 1, year + 1900)
	if tarih == "Bilinmiyor" then
		if tostring(tablo[alana].aracengel) == "true" then exports.hud:dm("#FFFFFFArazine #ff7f00Araç Girişi Yasak #ffffffolduğu için, işlem iptal edildi.",source,255,255,255,true) return end
		if getPedOccupiedVehicle(source) then destroyElement(oyuncu) end
		setElementData(source,"AraziSystem:Tarim",true)
		local x, y, z = getElementPosition(source)
		veh = createVehicle(532, x, y, z, 0, 0, 330)
        warpPedIntoVehicle(source, veh, 0)
		triggerClientEvent(source,"AraziSystem:EkinEk",source,id)
		exports.hud:dm("#FFFFFFArazine #ff7f00Ekim işlemine #ffffffbaşarıyla başladın! CheckPoint leri takip et!",source,255,255,255,true)
		triggerClientEvent(source,"AraziSystem:YonetimPanelKapa",source)
	elseif tarih == bugun then
		exports.hud:dm("#FFFFFFAraziye #ff7f00iki gün sonra #ffffffTekrardan işlem yapabileceksin.",source,255,255,255,true)
	elseif tarih == bigunsonra then
		exports.hud:dm("#FFFFFFAraziye #ff7f00Yarın#ffffffTekrardan işlem yapabileceksin.",source,255,255,255,true)
	else
		if tostring(tablo[alana].aracengel) == "true" then exports.hud:dm("#FFFFFFArazine #ff7f00Araç Girişi Yasak #ffffffolduğu için, işlem iptal edildi.",source,255,255,255,true) return end
		if getPedOccupiedVehicle(source) then destroyElement(oyuncu) end
		setElementData(source,"AraziSystem:Tarim",true)
		local x, y, z = getElementPosition(source)
		veh = createVehicle(532, x, y, z+2, 0, 0, 330)
        warpPedIntoVehicle(source, veh, 0)
		triggerClientEvent(source,"AraziSystem:EkinEk",source,id)
		exports.hud:dm("#FFFFFFArazine #ff7f00Ekim işlemine #ffffffbaşarıyla başladın! CheckPoint leri takip et!",source,255,255,255,true)
		triggerClientEvent(source,"AraziSystem:YonetimPanelKapa",source)
	end
end)

addEventHandler("onVehicleExit",root,function(player)
	if getElementData(player,"AraziSystem:Tarim") == true then
		local time = getRealTime()
		local monthday = time.monthday
		local month = time.month
		local year = time.year
		local bugun = string.format("%02d-%02d-%04d", monthday, month + 1, year + 1900)
		dbExec(db,"UPDATE veriler SET araziucret = ? WHERE araziid = ?",bugun,id)
		destroyElement(veh)
		setElementData(player,"AraziSystem:Tarim",false)
		tablo[alana].arazitarih = bugun
		triggerClientEvent(player,"AraziSystem:MarkerSifirla",player)
		exports.hud:dm("#FFFFFFAraçtan indiğin için #ff7f00Biçme işlemi#ffffff İptal edildi. Ceza olarak 2 gün sonra tekrar yapabileceksin.",player,255,255,255,true)
	end
end)

addEventHandler("onPlayerQuit", root, function()
	if getElementData(player,"AraziSystem:Tarim") == true then
		local vehs = getPedOccupiedVehicle(source)
		destroyElement(vehs)
		setElementData(source,"AraziSystem:Tarim",false)
		triggerClientEvent(sonra,"AraziSystem:MarkerSifirla",source)
	end
end)

addEventHandler("onPlayerWasted",root,function()
	if getElementData(source,"AraziSystem:Tarim") == true then
		destroyElement(veh)
		setElementData(source,"AraziSystem:Tarim",false)
		triggerClientEvent(source,"AraziSystem:MarkerSifirla",source)
		exports.hud:dm("#FFFFFFÖldüğün için #ff7f00Biçme işlemi#ffffff İptal edildi.",source,255,255,255,true)
	end
end)

addEvent("AraziSystem:AraziEkimBitir",true)
addEventHandler("AraziSystem:AraziEkimBitir",root,function(id)
	local time = getRealTime()
    local monthday = time.monthday
    local month = time.month
    local year = time.year
	local bugun = string.format("%02d-%02d-%04d", monthday, month + 1, year + 1900)
	dbExec(db,"UPDATE veriler SET araziucret = ? WHERE araziid = ?",bugun,id)
	destroyElement(veh)
	tablo[alana].arazitarih = bugun
	local para = math.random(200000,250000)
	givePlayerMoney(source,para)
end)
function hexToRGB( num ) 
  num = string.gsub( num, "#", "" )
  local r = tonumber( "0x" .. string.sub( num, 1, 2 ) ) or 255
  local g = tonumber( "0x" .. string.sub( num, 3, 4 ) ) or 255	
  local b = tonumber( "0x" .. string.sub( num, 5, 6 ) ) or 255
  return r, g, b 
end