if SERVER then
  AddCSLuaFile()
  resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_mamb.vmt")
end

function ROLE:PreInitialize()
  -- darker blue
  self.color = Color(44, 88, 189, 255)

  self.abbr = "mamb"
  self.defaultTeam = TEAM_INNOCENT

  self.isPublicRole = true          -- detective-like public role
  self.isPolicingRole = true
  self.unknownTeam = true           -- Innocents/Detectives do NOT know each other

  -- allow shop access like detective
  self.defaultEquipment = SPECIAL_EQUIPMENT

  self.conVarData = {
    pct = 0.13,
    maximum = 1,
    minPlayers = 8,
    minKarma = 600,

    credits = 1, -- starting credits
    creditsAwardDeadEnable = 1,
    creditsAwardKillEnable = 0,

    togglable = true,
    shopFallback = SHOP_FALLBACK_DETECTIVE
  }
end

function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_DETECTIVE)
end

-- === Settings UI so convars show up in the TTT2 menu ===
if CLIENT then
  function ROLE:AddToSettingsMenu(parent)
    local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

    form:MakeSlider({
      serverConvar = "ttt2_mambo_charge_time",
      label = "Commune: channel time (seconds)",
      min = 1, max = 60, decimal = 0
    })

    form:MakeSlider({
      serverConvar = "ttt2_mambo_seance_time",
      label = "Spirit: lifetime (seconds)",
      min = 5, max = 180, decimal = 0
    })
  end
end

if SERVER then
  function ROLE:GiveRoleLoadout(ply, isRoleChange)
    -- Give Commune tool instead of DNA scanner
    timer.Simple(0.1, function()
      if not IsValid(ply) then return end
      ply:StripWeapon("weapon_ttt_wtester")
      ply:StripWeapon("weapon_ttt2_dna_scanner")
      ply:GiveEquipmentWeapon("weapon_ttt2_commune")
    end)
  end

  function ROLE:RemoveRoleLoadout(ply, isRoleChange)
    ply:StripWeapon("weapon_ttt2_commune")
  end
end
