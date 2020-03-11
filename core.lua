
local AceGUI = LibStub("AceGUI-3.0")

local isPlaying = false
local previousMusicValue = GetCVar("Sound_EnableMusic")
local previousMusicVolume = GetCVar("Sound_MusicVolume")

---------------------------------------------------------
-- Song related functions
---------------------------------------------------------

function EnabledSongs()
    local enabledSongs = {}

    for key, value in pairs(DejaLustSettings.songs) do
        if value.enabled then
            enabledSongs[key] = value
        end
    end
    return enabledSongs
end

function NumberOfEnabledSongs()
    local count = 0

    for _, _ in pairs(EnabledSongs()) do
        count = count + 1
    end
    return count
end

---------------------------------------------------------
-- Frame to monitor buff events
---------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:SetScript("OnEvent", function(self, event, ...)
    unit = ...

    -- Check if unit is player and settings have been set
    if unit ~= "player" or DejaLustSettings == nil then
        return
    end

    -- Loop through player buffs to check if any of the tracked buffs are present
    local isBuffPresent = false
    for i = 1, 40 do
        name, _, _, _, _, _, _, _, _, id = UnitBuff("Player", i)
        if not name then break end
        if DejaLustSettings.buffs[name] ~= nil then 
            isBuffPresent = true
            break
        end
    end

    -- Check if buff present and isn't already playing
    if isBuffPresent and isPlaying ~= true then
        -- Set playing flag to true to prevent further plays
        isPlaying = true

        -- capture previous cvar values before adjusting
        previousMusicValue = GetCVar("Sound_EnableMusic")
        previousMusicVolume = GetCVar("Sound_MusicVolume")

        -- Enable music so song plays
        SetCVar("Sound_EnableMusic", 1)

        -- Check if adjust volume setting is true, and if so adjust to specified volume level
        if DejaLustSettings.adjust_volume then
            SetCVar("Sound_MusicVolume", DejaLustSettings.adjusted_volume)
        end

        -- Play random song from enabled songs
        song = EnabledSongs()[math.random(NumberOfEnabledSongs())].file
        PlayMusic("Interface\\AddOns\\DejaLust\\songs\\" .. song)
     elseif isPlaying and isBuffPresent == false then
        -- Reset play flag 
        isPlaying = false

        -- Reset cvar values to what they were prior to playing
        SetCVar("Sound_EnableMusic", previousMusicValue)
        SetCVar("Sound_MusicVolume", previousMusicVolume)

        -- Stop music
        StopMusic()
    end
end)

---------------------------------------------------------
-- Config UI
---------------------------------------------------------

function createBuffRow(buff, parent)
    buffRow = AceGUI:Create("SimpleGroup")
    buffRow:SetRelativeWidth(1.0)
    buffRow:SetLayout("Flow")

    buffLabel = AceGUI:Create("Label")
    buffLabel:SetText(buff)
    buffLabel:SetRelativeWidth(0.7)
    buffRow:AddChild(buffLabel)

    removeButton = AceGUI:Create("Button")
    removeButton:SetText("Remove")
    removeButton:SetRelativeWidth(0.3)
    buffRow:AddChild(removeButton)
    removeButton:SetCallback("OnClick", function() 
        DejaLustSettings.buffs[buff] = nil
        parent:ReleaseChildren()
        buildBuffsSection(parent, true)
    end)
    return buffRow
end

function buildBuffsSection(parent, isRebuild)
    for buff, _ in pairs(DejaLustSettings.buffs) do
        parent:AddChild(createBuffRow(buff, buffsGroup))
    end

    addBuffEditBox = AceGUI:Create("EditBox")
    addBuffEditBox:SetLabel("Add buff to track")
    addBuffEditBox:SetRelativeWidth(1.0)
    addBuffEditBox:SetCallback("OnTextChanged", function(editBox) 
        text = editBox:GetText()
        editBox:DisableButton(text == nil or text == '')
    end)
    addBuffEditBox:SetCallback("OnEnterPressed", function(editBox) 
        text = editBox:GetText()
        DejaLustSettings.buffs[text] = true
        parent:AddChild(createBuffRow(text, parent), addBuffEditBox)
        addBuffEditBox:SetText("")
        AceGUI:SetFocus(editBox)
    end)

    if isRebuild then
        addBuffEditBox:SetFocus()
    end

    parent:AddChild(addBuffEditBox)
end

function ShowConfig()
    -- Create a container frame
    configFrame = AceGUI:Create("Frame")
    configFrame:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
    configFrame:SetTitle("DejaLust config")
    configFrame:SetStatusText("Version: 1.0 - Author: Jovche-Barthilas")
    configFrame:SetWidth(675)
    configFrame:SetHeight(625)
    configFrame:SetLayout("Fill")

    scrollContainer = AceGUI:Create("ScrollFrame")
    scrollContainer:SetLayout("List")

    -- Songs section

    songsGroup = AceGUI:Create("InlineGroup")
    songsGroup:SetTitle("Songs")
    songsGroup:SetLayout("Flow")
    songsGroup:SetRelativeWidth(1.0)

    for key, song in pairs(DejaLustSettings.songs) do
        checkBox = AceGUI:Create("CheckBox")
        checkBox:SetType("checkbox")
        checkBox:SetLabel(song.name)
        checkBox:SetValue(song.enabled)
        checkBox:SetCallback("OnValueChanged", function() 
            DejaLustSettings.songs[key].enabled = checkBox:GetValue()
        end)
        songsGroup:AddChild(checkBox)
    end

    -- Buffs section

    buffsGroup = AceGUI:Create("InlineGroup")
    buffsGroup:SetTitle("Buffs")
    buffsGroup:SetRelativeWidth(1.0)
    buffsGroup:SetLayout("List")

    buildBuffsSection(buffsGroup,false)

    -- Additional settings section

    settingsGroup = AceGUI:Create("InlineGroup")
    settingsGroup:SetTitle("Additional settings")
    settingsGroup:SetRelativeWidth(1.0)

    volumeSlider = AceGUI:Create("Slider")
    volumeSlider:SetLabel("Music volume")
    volumeSlider:SetSliderValues(0.0, 1.0, 0.01)
    volumeSlider:SetValue(DejaLustSettings.adjustedVolume)
    volumeSlider:SetDisabled(not DejaLustSettings.adjustVolume)
    volumeSlider:SetIsPercent(true)
    volumeSlider:SetCallback("OnValueChanged", function() 
        DejaLustSettings.adjustedVolume = volumeSlider:GetValue()
    end)

    adjustVolumeCheckbox = AceGUI:Create("CheckBox")
    adjustVolumeCheckbox:SetLabel("Adjust volume on play")
    adjustVolumeCheckbox:SetValue(DejaLustSettings.adjustVolume)
    adjustVolumeCheckbox:SetRelativeWidth(1.0)
    adjustVolumeCheckbox:SetCallback("OnValueChanged", function() 
        DejaLustSettings.adjustVolume = adjustVolumeCheckbox:GetValue()
        volumeSlider:SetDisabled(not DejaLustSettings.adjustVolume)
    end)

    enableTrollSong = AceGUI:Create("CheckBox")
    enableTrollSong:SetLabel("Enable troll song")
    enableTrollSong:SetDescription("1/100 chance to play a troll song.")
    enableTrollSong:SetValue(DejaLustSettings.enableTroll)
    enableTrollSong:SetRelativeWidth(1.0)
    enableTrollSong:SetCallback("OnValueChanged", function() 
        DejaLustSettings.enableTroll = enableTrollSong:GetValue()
    end)

    settingsGroup:AddChildren(adjustVolumeCheckbox, volumeSlider, enableTrollSong)

    -- Add sections to frame

    scrollContainer:AddChildren(songsGroup, buffsGroup, settingsGroup)
    configFrame:AddChild(scrollContainer)
end 

---------------------------------------------------------
-- Slash commands
---------------------------------------------------------

SLASH_DEJALUST1 = "/dl";

function SlashCmdList.DEJALUST(msg)
   ShowConfig()
end