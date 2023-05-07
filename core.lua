local AceGUI = LibStub("AceGUI-3.0")

local isPlaying = false
local previousMusicValue = GetCVar("Sound_EnableMusic")
local previousMusicVolume = GetCVar("Sound_MusicVolume")

local configFrame

---------------------------------------------------------
-- Song related functions
---------------------------------------------------------

function EnabledSongs()
    local enabledSongs = {}
    for key, value in pairs(DejaLustSettings.songs) do
        if value.enabled then
            enabledSongs[#enabledSongs+1] = value
        end
    end
    return enabledSongs
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

        local songs = EnabledSongs()
        if #songs == 0 then
            return
        end

        -- Set playing flag to true to prevent further plays
        isPlaying = true

        -- capture previous cvar values before adjusting
        previousMusicValue = GetCVar("Sound_EnableMusic")
        previousMusicVolume = GetCVar("Sound_MusicVolume")

        -- Enable music so song plays
        SetCVar("Sound_EnableMusic", 1)

        -- Check if adjust volume setting is true, and if so adjust to specified volume level
        if DejaLustSettings.adjustVolume then
            SetCVar("Sound_MusicVolume", DejaLustSettings.adjustedVolume)
        end

        -- Play random song from enabled songs
        local song
        if DejaLustSettings.enableTroll and math.random(100) == 9 then
            song = "troll.mp3"
            print("Poggies.")
        else
            song = songs[math.random(#songs)].file
        end
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

function DrawSongsSection(container)
    local scrollContainer = AceGUI:Create("ScrollFrame")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Flow")

    local songsGroup = AceGUI:Create("InlineGroup")
    songsGroup:SetTitle("Songs")
    songsGroup:SetLayout("Flow")
    songsGroup:SetFullWidth(true)
    songsGroup:SetHeight(640)

    local addDescriptionLabel = AceGUI:Create("Label")
    addDescriptionLabel:SetFullWidth(true)
    addDescriptionLabel:SetText("To add a song enter the name and file name below, make sure to include the extension (e.g. .mp3) and add the song to World of Warcraft\\_retail_\\Interface\\AddOns\\DejaLust\\songs.")

    local restartWarningLabel = AceGUI:Create("Label")
    restartWarningLabel:SetFullWidth(true)
    restartWarningLabel:SetText("Game restart required before song will play!.")
    restartWarningLabel:SetColor(1, 0, 0)

    local addSongNameEditBox, addFileNameEditBox, addSongButton

    addSongNameEditBox = AceGUI:Create("EditBox")
    addSongNameEditBox:SetLabel("Song name")
    addSongNameEditBox:SetRelativeWidth(0.4)
    addSongNameEditBox:SetCallback("OnTextChanged", function(editBox)
        addSongButton:SetDisabled(editBox:GetText() == nil or editBox:GetText() == '' or addFileNameEditBox:GetText() == nil or addFileNameEditBox:GetText() == '')
        editBox:DisableButton(true)
    end)

    addFileNameEditBox = AceGUI:Create("EditBox")
    addFileNameEditBox:SetLabel("File name (include extension)")
    addFileNameEditBox:SetRelativeWidth(0.4)
    addFileNameEditBox:SetCallback("OnTextChanged", function(editBox)
        addSongButton:SetDisabled(editBox:GetText() == nil or editBox:GetText() == '' or addSongNameEditBox:GetText() == nil or addSongNameEditBox:GetText() == '')
        editBox:DisableButton(true)
    end)

    addSongButton = AceGUI:Create("Button")
    addSongButton:SetText("Add")
    addSongButton:SetRelativeWidth(0.2)
    addSongButton:SetDisabled(true)
    addSongButton:SetCallback("OnClick", function()
        DejaLustSettings.songs[#DejaLustSettings.songs+1] = {
            ["name"] = addSongNameEditBox:GetText(),
            ["file"] = addFileNameEditBox:GetText(),
            ["enabled"] = true,
            ["default"] = false,
        }
        container:ReleaseChildren()
        DrawSongsSection(container)
    end)

    songsGroup:AddChildren(addDescriptionLabel, restartWarningLabel, addSongNameEditBox, addFileNameEditBox, addSongButton)

    -- Column headings

    local nameHeading = AceGUI:Create("Heading")
    nameHeading:SetText("Name")
    nameHeading:SetRelativeWidth(0.4)

    local fileHeading = AceGUI:Create("Heading")
    fileHeading:SetText("File")
    fileHeading:SetRelativeWidth(0.4)

    local removeHeading = AceGUI:Create("Heading")
    removeHeading:SetText("Remove")
    removeHeading:SetRelativeWidth(0.2)

    songsGroup:AddChildren(nameHeading, fileHeading, removeHeading)

    -- Song rows

    for key, song in pairs(DejaLustSettings.songs) do
        local checkBox = AceGUI:Create("CheckBox")
        checkBox:SetType("checkbox")
        checkBox:SetLabel(song.name)
        checkBox:SetValue(song.enabled)
        checkBox:SetCallback("OnValueChanged", function()
            DejaLustSettings.songs[key].enabled = checkBox:GetValue()
        end)
        checkBox:SetRelativeWidth(0.4)

        local fileLabel = AceGUI:Create("Label")
        fileLabel:SetText(song.file)
        fileLabel:SetRelativeWidth(0.4)

        local removeButton = AceGUI:Create("Button")
        removeButton:SetText("Remove")
        removeButton:SetRelativeWidth(0.2)
        removeButton:SetDisabled(song.default)
        removeButton:SetCallback("OnClick", function()
            DejaLustSettings.songs[key] = nil
            container:ReleaseChildren()
            DrawSongsSection(container)
        end)

        songsGroup:AddChildren(checkBox, fileLabel, removeButton)
    end

    scrollContainer:AddChild(songsGroup)
    container:AddChildren(scrollContainer)
end

function DrawAdditionalOptionsSection(container)

    local optionsGroup = AceGUI:Create("InlineGroup")
    optionsGroup:SetTitle("Additional settings")
    optionsGroup:SetRelativeWidth(1.0)

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

    optionsGroup:AddChildren(adjustVolumeCheckbox, volumeSlider, enableTrollSong)

    container:AddChildren(optionsGroup)
end

function DrawBuffsSection(container)

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    scrollFrame:SetLayout("Flow")

    local buffsGroup = AceGUI:Create("InlineGroup")
    buffsGroup:SetTitle("Tracking buffs")
    buffsGroup:SetLayout("Flow")
    buffsGroup:SetFullWidth(true)
    buffsGroup:SetHeight(640)

    local addBuffEditBox = AceGUI:Create("EditBox")
    addBuffEditBox:SetLabel("Add buff to track")
    addBuffEditBox:SetRelativeWidth(1.0)
    addBuffEditBox:SetCallback("OnTextChanged", function(editBox)
        text = editBox:GetText()
        editBox:DisableButton(text == nil or text == '')
    end)
    addBuffEditBox:SetCallback("OnEnterPressed", function(editBox)
        text = editBox:GetText()
        DejaLustSettings.buffs[text] = true
        container:ReleaseChildren()
        DrawBuffsSection(container)
    end)
    buffsGroup:AddChild(addBuffEditBox)

    for buff, _ in pairs(DejaLustSettings.buffs) do
        buffLabel = AceGUI:Create("Label")
        buffLabel:SetText(buff)
        buffLabel:SetRelativeWidth(0.7)
        buffsGroup:AddChild(buffLabel)

        removeButton = AceGUI:Create("Button")
        removeButton:SetText("Remove")
        removeButton:SetRelativeWidth(0.3)
        buffsGroup:AddChild(removeButton)
        removeButton:SetCallback("OnClick", function()
            DejaLustSettings.buffs[buff] = nil
            container:ReleaseChildren()
            DrawBuffsSection(container)
        end)
    end

    scrollFrame:AddChild(buffsGroup)
    container:AddChildren(scrollFrame)
end

local function SelectGroup(container, event, group)
   container:ReleaseChildren()
   if group == "songs" then
      DrawSongsSection(container)
   elseif group == "buffs" then
      DrawBuffsSection(container)
   elseif group == "additional_options" then
      DrawAdditionalOptionsSection(container)
   end
end

function ToggleConfig()
  if configFrame then
    CloseConfig()
  else
    ShowConfig()
  end
end

function ShowConfig()
    if configFrame ~= nil then
        return
    end

    -- Create a container frame
    configFrame = AceGUI:Create("Frame")
    configFrame:SetCallback("OnClose",function(widget)
     AceGUI:Release(widget)
     configFrame = nil
    end)
    configFrame:SetCallback("OnEscapePressed",function(widget)
     AceGUI:Release(widget)
     configFrame = nil
    end)
    configFrame:SetTitle("DejaLust config")
    configFrame:SetStatusText("Version: 1.0 - Author: Jovche-Barthilas")
    configFrame:SetWidth(675)
    configFrame:SetHeight(625)
    configFrame:SetLayout("Fill")

    local tabGroup =  AceGUI:Create("TabGroup")
    tabGroup:SetLayout("List")
    -- Setup which tabs to show
    tabGroup:SetTabs({{text="Songs", value="songs"}, {text="Buffs", value="buffs"}, {text="Additional options", value="additional_options"}})
    -- Register callback
    tabGroup:SetCallback("OnGroupSelected", SelectGroup)
    -- Set initial Tab (this will fire the OnGroupSelected callback)
    tabGroup:SelectTab("songs")
    -- add to the frame container
    configFrame:AddChildren(tabGroup)
end

function CloseConfig()
  configFrame = nil
end

---------------------------------------------------------
-- Slash commands
---------------------------------------------------------

SLASH_DEJALUST1 = "/dejalust";

function SlashCmdList.DEJALUST(msg)
   ShowConfig()
end
