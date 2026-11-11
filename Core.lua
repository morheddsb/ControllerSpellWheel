-- Controller Spell Wheel: a radial spell wheel for gamepads, built like the
-- game's own flyout wheel (Blizzard_GamepadActionBars/FlyoutRadial.lua).
--
-- A macro (/click ControllerSpellWheel LeftButton true) opens it. While it is
-- open the right stick's directions are bound to the same button, so a flick
-- is a real key press: a secure snippet reads the stick's angle and casts that
-- slot's spell. Pressing the macro again casts the slot the stick points at,
-- or closes the wheel with the stick centred.

local SLOTS = 8
local RADIUS = 60      -- FlyoutRadial.lua: offsetRadius
local ICON_SIZE = 36   -- FlyoutRadial.lua: iconSize
local DEADZONE = 0.3   -- stick length below which no slot is picked
local SEGMENT = 2 * math.pi / SLOTS

-- Rank 1 mage spells, clockwise from the top.
local SPELLS = {
    133,   -- Fireball
    116,   -- Frostbolt
    5143,  -- Arcane Missiles
    2136,  -- Fire Blast
    122,   -- Frost Nova
    1449,  -- Arcane Explosion
    118,   -- Polymorph
    1953,  -- Blink
}

local function Print(msg)
    print(NORMAL_FONT_COLOR_CODE .. "Controller Spell Wheel|r: " .. tostring(msg))
end

-- Forever's gamepad navigation hooks CreateFrame and refreshes the parent's
-- button groups from our (tainted) context, so frames are parented afterwards.
local function NewFrame(frameType, name, parent, template)
    local f = CreateFrame(frameType, name, nil, template)
    if parent then f:SetParent(parent) end
    return f
end

-- Slot under the stick, 1 at the top and clockwise, or nil inside the deadzone.
local function SlotForStick(x, y)
    if x * x + y * y < DEADZONE * DEADZONE then return nil end
    return math.floor(((math.atan2(x, y) + SEGMENT / 2) % (2 * math.pi)) / SEGMENT) + 1
end

--------------------------------------------------------------------------------
-- The wheel (secure: shown, hidden and bound from secure snippets in combat)

local wheel = NewFrame("Frame", "ControllerSpellWheelFrame", UIParent, "SecureHandlerShowHideTemplate")
wheel:Hide()
wheel:SetSize(200, 200)
wheel:SetPoint("CENTER")
wheel:SetFrameStrata("DIALOG")
wheel:SetAttribute("stick-index", 2)

local background = wheel:CreateTexture(nil, "BACKGROUND", nil, 0)
background:SetAtlas("gamepad-flyout-circular-base", true)
background:SetPoint("CENTER")

local indicator = wheel:CreateTexture(nil, "BACKGROUND", nil, 2)
indicator:SetAtlas("gamepad-flyout-selection-indicator", true)
indicator:SetPoint("CENTER")
indicator:Hide()

local slots = {}
for i, spellID in ipairs(SPELLS) do
    local angle = (i - 1) * SEGMENT
    local x = math.floor(RADIUS * math.sin(angle) + 0.5)
    local y = math.floor(RADIUS * math.cos(angle) + 0.5)

    local icon = wheel:CreateTexture(nil, "BORDER")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER", x, y)

    local mask = wheel:CreateMaskTexture()
    mask:SetAtlas("gamepad-flyout-circular-slot-mask", true)
    mask:SetPoint("CENTER", icon)
    icon:AddMaskTexture(mask)

    -- Below the icon, as in FlyoutRadial.lua (NormalTexture: BACKGROUND)
    local border = wheel:CreateTexture(nil, "BACKGROUND", nil, 3)
    border:SetAtlas("gamepad-flyout-circular-slot-normal", true)
    border:SetPoint("CENTER", icon)

    local highlight = wheel:CreateTexture(nil, "OVERLAY")
    highlight:SetAtlas("gamepad-flyout-circular-slot-over-border", true)
    highlight:SetPoint("CENTER", icon)
    highlight:Hide()

    slots[i] = { spellID = spellID, icon = icon, highlight = highlight }
end

local selected
local function Select(slot)
    if slot == selected then return end
    selected = slot
    for i, s in ipairs(slots) do
        s.highlight:SetShown(i == slot)
    end
    indicator:SetShown(slot ~= nil)
    if slot then
        indicator:SetRotation(math.pi - (slot - 1) * SEGMENT)
    end
    if slot and slots[slot] then
        GameTooltip_SetDefaultAnchor(GameTooltip, wheel)
        GameTooltip:SetSpellByID(slots[slot].spellID)
    else
        GameTooltip:Hide()
    end
end

-- Only called while the snippets below have the stick captured. Returning
-- false keeps the right stick from turning the camera (as SoftCursor.lua does).
wheel:SetScript("OnGamePadStick", function(_, stick, x, y)
    if stick ~= "Camera" then return true end
    Select(SlotForStick(x, y))
    return false
end)

wheel:HookScript("OnShow", function()
    for _, s in ipairs(slots) do
        s.icon:SetTexture(C_Spell.GetSpellTexture(s.spellID))
        s.icon:SetDesaturated(not C_SpellBook.IsSpellKnown(s.spellID))
    end
end)

wheel:HookScript("OnHide", function()
    Select(nil)
end)

wheel:SetAttribute("_onshow", [[
    if self:GetAttribute("capture") then
        self:EnableGamePadStick(true)
    end
    self:SetBindingClick(true, "PADRSTICKUP", "ControllerSpellWheel")
    self:SetBindingClick(true, "PADRSTICKDOWN", "ControllerSpellWheel")
    self:SetBindingClick(true, "PADRSTICKLEFT", "ControllerSpellWheel")
    self:SetBindingClick(true, "PADRSTICKRIGHT", "ControllerSpellWheel")
]])

wheel:SetAttribute("_onhide", [[
    self:ClearBindings()
    self:EnableGamePadStick(false)
]])

--------------------------------------------------------------------------------
-- The button: the macro and the stick flicks click it

local button = NewFrame("Button", "ControllerSpellWheel", UIParent, "SecureActionButtonTemplate")
button:EnableMouse(false)
button:RegisterForClicks("AnyDown")
button:SetAttribute("useOnKeyDown", true)
for i, spellID in ipairs(SPELLS) do
    button:SetAttribute("*type-s" .. i, "spell")
    button:SetAttribute("*spell-s" .. i, spellID)
end

-- Runs before each click. Returning false stops the click; returning "sN"
-- makes it cast slot N's spell (the "*spell-sN" attribute) and then hides
-- the wheel in the post snippet.
SecureHandlerWrapScript(button, "OnClick", wheel, ([[
    if not down then return false end
    if not owner:IsShown() then
        owner:Show()
        return false
    end
    local state = GetGamePadState()
    local stick = state and state.sticks[owner:GetAttribute("stick-index")]
    if not stick or stick.len < %s then
        owner:Hide()
        return false
    end
    local segment = 2 * math.pi / %d
    local slot = math.floor(((math.atan2(stick.x, stick.y) + segment / 2) %% (2 * math.pi)) / segment) + 1
    if not self:GetAttribute("*spell-s" .. slot) then return false end
    return "s" .. slot, true
]]):format(DEADZONE, SLOTS), [[
    owner:Hide()
]])

--------------------------------------------------------------------------------
-- Setup

-- The snippets can't look up which stick is the camera stick, so it is
-- stored on the wheel (out of combat only; attributes are locked in combat).
local function UpdateStickIndex()
    if InCombatLockdown() then return end
    local state = C_GamePad.GetDeviceMappedState()
    for i = 1, state and state.stickCount or 0 do
        if C_GamePad.StickIndexToConfigName(i - 1) == "Camera" then
            wheel:SetAttribute("stick-index", i)
            return
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("GAME_PAD_CONNECTED")
events:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        ControllerSpellWheelDB = ControllerSpellWheelDB or { capture = true }
        wheel:SetAttribute("capture", ControllerSpellWheelDB.capture)
    end
    UpdateStickIndex()
end)

-- /csw keys: prints the name of each gamepad button press, to see whether the
-- right stick's directions arrive as PADRSTICK* presses. Returning true passes
-- the press on, so the buttons keep working (FlyoutRadial.lua does the same).
local keyLog = NewFrame("Frame", nil, UIParent)
keyLog:SetScript("OnGamePadButtonDown", function(_, key)
    Print(key)
    return true
end)
local logging = false

SLASH_CONTROLLERSPELLWHEEL1 = "/csw"
SlashCmdList.CONTROLLERSPELLWHEEL = function(msg)
    if msg == "capture" then
        if InCombatLockdown() then
            Print("Can't change that in combat.")
            return
        end
        ControllerSpellWheelDB.capture = not ControllerSpellWheelDB.capture
        wheel:SetAttribute("capture", ControllerSpellWheelDB.capture)
        Print("Camera lock while the wheel is open: " .. (ControllerSpellWheelDB.capture and "on" or "off"))
    elseif msg == "keys" then
        if InCombatLockdown() then
            Print("Can't change that in combat.")
            return
        end
        logging = not logging
        keyLog:EnableGamePadButton(logging)
        Print("Gamepad button log: " .. (logging and "on" or "off"))
    else
        Print("Make a macro with: /click ControllerSpellWheel LeftButton true")
        Print("/csw capture - toggle the camera lock while the wheel is open")
        Print("/csw keys - toggle printing each gamepad button press")
    end
end
