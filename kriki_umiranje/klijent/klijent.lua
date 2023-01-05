-- klijent
local cam = nil

local isDead = false

local angleY = 0.0
local angleZ = 0.0


local enableField = false

function toggleField(enable)
    SetNuiFocus(false,false)
    enableField = enable

    if enable then
        SendNUIMessage({
            action = 'open'
        }) 
    else
        SendNUIMessage({
            action = 'close'
        }) 
    end
end

RegisterCommand('testds', function(source)
    --isDead = true
    toggleField(true)
    startTimerda = true
    StartDeathCam()
end)

RegisterCommand('stopds', function(source)
    --isDead = false
    toggleField(false)
    startTimerda = false
    EndDeathCam()
end)

AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() ~= name then
        return
    end

    toggleField(false)
end)

RegisterNUICallback('Exit', function(data, cb)
    toggleField(false)
    SetNuiFocus(false, false)

    cb('ok')
end)

--------------------------------------------------
---------------------- LOOP ----------------------
--------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        
        -- procesna kamera kontroliše da li kamera postoji i da je igrač mrtav
        if (cam and isDead) then
            ProcessCamControls()
        end
    end
end)

Citizen.CreateThread(function()
    while true do
		if startTimerda then
			SendNUIMessage({
				action = 'timer'
			}) 			
		end
		Citizen.Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        
        if (not isDead and NetworkIsPlayerActive(PlayerId()) and IsPedFatallyInjured(PlayerPedId())) then
            isDead = true
			toggleField(true)
			startTimerda = true
            StartDeathCam()
        elseif (isDead and NetworkIsPlayerActive(PlayerId()) and not IsPedFatallyInjured(PlayerPedId())) then
            isDead = false
            toggleField(false)
			startTimerda = false
            EndDeathCam()
        end
    end
end)




--------------------------------------------------
------------------- FUNKCIJE --------------------
--------------------------------------------------

-- inicijalizovati kameru
function StartDeathCam()
    ClearFocus()

    local playerPed = PlayerPedId()
    
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", GetEntityCoords(playerPed), 0, 0, 0, GetGameplayCamFov())

    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, false)
end

-- uništi kameru
function EndDeathCam()
    ClearFocus()

    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    
    cam = nil
end

-- pravljanje procesnom kamerom
function ProcessCamControls()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- onemogućite 1. lice jer kamera od 1. lica može izazvati neke greške
    DisableFirstPersonCamThisFrame()
    
    -- израчунати нову позицију
    local newPos = ProcessNewPosition()

    -- oblast fokusne kamere
    SetFocusArea(newPos.x, newPos.y, newPos.z, 0.0, 0.0, 0.0)
    
    -- postaviti koordinate cam
    SetCamCoord(cam, newPos.x, newPos.y, newPos.z)
    
    -- postaviti rotaciju
    PointCamAtCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z + 0.5)
end

function ProcessNewPosition()
    local mouseX = 0.0
    local mouseY = 0.0
    
    -- tastatura
    if (IsInputDisabled(0)) then
        -- rotation
        mouseX = GetDisabledControlNormal(1, 1) * 8.0
        mouseY = GetDisabledControlNormal(1, 2) * 8.0
        
    -- kontrolor
    else
        -- rotacija
        mouseX = GetDisabledControlNormal(1, 1) * 1.5
        mouseY = GetDisabledControlNormal(1, 2) * 1.5
    end

    angleZ = angleZ - mouseX -- oko Z ose (levo / desno)
    angleY = angleY + mouseY -- Gore dole
    -- ograničiti ugao gore/dole na 90°
    if (angleY > 89.0) then angleY = 89.0 elseif (angleY < -89.0) then angleY = -89.0 end
    
    local pCoords = GetEntityCoords(PlayerPedId())
    
    local behindCam = {
        x = pCoords.x + ((Cos(angleZ) * Cos(angleY)) + (Cos(angleY) * Cos(angleZ))) / 2 * (Cfg.radius + 0.5),
        y = pCoords.y + ((Sin(angleZ) * Cos(angleY)) + (Cos(angleY) * Sin(angleZ))) / 2 * (Cfg.radius + 0.5),
        z = pCoords.z + ((Sin(angleY))) * (Cfg.radius + 0.5)
    }
    local rayHandle = StartShapeTestRay(pCoords.x, pCoords.y, pCoords.z + 0.5, behindCam.x, behindCam.y, behindCam.z, -1, PlayerPedId(), 0)
    local a, hitBool, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    
    local maxRadius = Cfg.radius
    if (hitBool and Vdist(pCoords.x, pCoords.y, pCoords.z + 0.5, hitCoords) < Cfg.radius + 0.5) then
        maxRadius = Vdist(pCoords.x, pCoords.y, pCoords.z + 0.5, hitCoords)
    end
    
    local offset = {
        x = ((Cos(angleZ) * Cos(angleY)) + (Cos(angleY) * Cos(angleZ))) / 2 * maxRadius,
        y = ((Sin(angleZ) * Cos(angleY)) + (Cos(angleY) * Sin(angleZ))) / 2 * maxRadius,
        z = ((Sin(angleY))) * maxRadius
    }
    
    local pos = {
        x = pCoords.x + offset.x,
        y = pCoords.y + offset.y,
        z = pCoords.z + offset.z
    }
    
    
    -- Debug x,y,z axis
    --DrawMarker(1, pCoords.x, pCoords.y, pCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.03, 0.03, 5.0, 0, 0, 255, 255, false, false, 2, false, 0, false)
    --DrawMarker(1, pCoords.x, pCoords.y, pCoords.z, 0.0, 0.0, 0.0, 0.0, 90.0, 0.0, 0.03, 0.03, 5.0, 255, 0, 0, 255, false, false, 2, false, 0, false)
    --DrawMarker(1, pCoords.x, pCoords.y, pCoords.z, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0, 0.03, 0.03, 5.0, 0, 255, 0, 255, false, false, 2, false, 0, false)
    
    return pos
end

--XAchse Westen Osten
--Yachse Norden Süden
--ZAchse oben unten

--gegenkathete = x
--ankathete = y
--hypotenuse = 1
--alpha = GetCamRot(cam).z