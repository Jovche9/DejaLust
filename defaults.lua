local buffs = {
    ["Bloodlust"] = true,
    ["Heroism"] = true,
    ["Time Warp"] = true,
    ["Ancient Hysteria"] = true,
    ["Primal Rage"] = true,
    ["Netherwinds"] = true,
    ["Fury of the Aspects"] = true,
    ["Drums of Rage"] = true,
    ["Drums of Fury"] = true,
}

local songs = {
    {
        ["name"] = "Dejavu",
        ["file"] = "dejavu.mp3",
        ["enabled"] = true,
        ["default"] = true,
    },
    {
        ["name"] = "Gas Gas Gas!",
        ["file"] = "gasgasgas.mp3",
        ["enabled"] = true,
        ["default"] = true,
    },
    {
        ["name"] = "Night of Fire",
        ["file"] = "nightoffire.mp3",
        ["enabled"] = true,
        ["default"] = true,
    },
    {
        ["name"] = "Brainpower",
        ["file"] = "brainpower.mp3",
        ["enabled"] = true,
        ["default"] = true,
    },
    {
        ["name"] = "Running in the 90s",
        ["file"] = "running_in_the_90s.mp3",
        ["enabled"] = true,
        ["default"] = true,
    }
}


local frame = CreateFrame("Frame");
frame:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    if not DejaLustSettings then
      DejaLustSettings = {
        ["buffs"] = buffs,
        ["songs"] = songs,
        ["adjustVolume"] = false,
        ["adjustedVolume"] = 1.0,
        ["enableTroll"] = true,
        ["evokerMigration"] = true,
      }
    elseif DejaLustSettings.evokerMigration ~= true and DejaLustSettings.buffs["Fury of the Aspects"] == nil then
      DejaLustSettings.buffs["Fury of the Aspects"] = true
      DejaLustSettings.evokerMigration = true
    else
      DejaLustSettings.evokerMigration = true
    end
  end
end)
frame:RegisterEvent("PLAYER_LOGIN");
