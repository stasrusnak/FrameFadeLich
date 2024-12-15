local frames = {}
local isElvUI
local isCasting

-- Проверка на наличие ElvUI
local function Check_ElvUI()
    isElvUI = IsAddOnLoaded("ElvUI")
end

-- Показать фреймы
local function ShowFrames()
    for _, frame in pairs(frames) do
        if frame and frame.SetAlpha then
            frame:SetAlpha(1)
        end
    end
end

-- Скрыть фреймы
local function HideFrames()
    for _, frame in pairs(frames) do
        if frame and frame.SetAlpha then
            frame:SetAlpha(0)
        end
    end
end

-- Проверка на полное здоровье
local function FullHealth(unit)
    return UnitHealth(unit) == UnitHealthMax(unit)
end

-- Проверка на полный ресурс (мана или энергия)
local function FullMana(unit)
    local powerType = UnitPowerType(unit)
    return (powerType ~= 0 and powerType ~= 3) or UnitPower(unit) == UnitPowerMax(unit)
end

-- Проверка настроения питомца
local function HappyPet()
    if UnitCreatureType("pet") ~= "Beast" then
        return true
    else
        return GetPetHappiness() and GetPetHappiness() > 1
    end
end

-- Условия для питомца
local function PetConditions()
    if not UnitExists("pet") then return true end
    return HappyPet() and FullHealth("pet")
end

-- Условия для игрока
local function PlayerConditions()
    local fullHealth = FullHealth("player")
    local fullMana = FullMana("player")
    local outOfCombat = not InCombatLockdown()

    return fullHealth and fullMana and not isCasting and outOfCombat
end

-- Проверка на отдых
local function CheckResting()
    if IsResting() then
        PlayerRestGlow:SetAlpha(PlayerFrame:GetAlpha())
    end
end

-- Основная проверка условий
local function CheckConditions()
    local noTarget = not UnitExists("target")
    local playerReady = PlayerConditions()
    local petReady = PetConditions()

    if noTarget and playerReady and petReady then
        HideFrames()
        CheckResting()
    else
        ShowFrames()
        CheckResting()
    end
end

-- Настройка фреймов
local function SetupFrames()
    if isElvUI then
        -- Попытка получить ElvUI фреймы
        local playerFrame = _G["ElvUF_Player"]
        local petFrame = _G["ElvUF_Pet"]
        frames = { playerFrame, petFrame }
    else
        -- Использование стандартных фреймов
        frames = { PlayerFrame, PetFrame }
    end

    for _, frame in pairs(frames) do
        if frame then
            frame:HookScript("OnEnter", function()
                ShowFrames()
                CheckResting()
            end)

            frame:HookScript("OnLeave", function()
                CheckConditions()
            end)
        end
    end
end

-- События
local events = CreateFrame("Frame", nil, UIParent)
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_HEALTH")
events:RegisterEvent("UNIT_POWER_UPDATE")
events:RegisterEvent("UNIT_SPELLCAST_START")
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
events:RegisterEvent("UNIT_SPELLCAST_STOP")
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UNIT_PET")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        if not events.loaded then
            events.loaded = true
            Check_ElvUI()
            SetupFrames()
        end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if arg1 == "player" then
            isCasting = true
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if arg1 == "player" then
            isCasting = nil
        end
    end
    CheckConditions()
end)
