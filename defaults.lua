local buffs = {
    ["Bloodlust"] = true,
    ["Heroism"] = true,
    ["Time Warp"] = true,
    ["Ancient Hysteria"] = true,
    ["Primal Rage"] = true,
    ["Netherwinds"] = true,
    ["Drums of Rage"] = true,
    ["Drums of Fury"] = true,
}

local songs = {
    {
        ["name"] = "Dejavu",
        ["file"] = "dejavu.mp3",
        ["enabled"] = true,
    },
    {
        ["name"] = "Gas Gas Gas!",
        ["file"] = "gasgasgas.mp3",
        ["enabled"] = true,
    },
    {
        ["name"] = "Night of Fire",
        ["file"] = "nightoffire.mp3",
        ["enabled"] = true,
    },
    {
        ["name"] = "Brainpower",
        ["file"] = "brainpower.mp3",
        ["enabled"] = true,
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
      }
    end
  end
end)
frame:RegisterEvent("PLAYER_LOGIN");