-- weapon_ttt2_commune.lua

if SERVER then
  AddCSLuaFile()

  -- networking for on-screen messages
  util.AddNetworkString("MamboSeancePrep")     -- bool: show/hide "get ready" while channeling
  util.AddNetworkString("MamboSpecterNotice")  -- float, float: overlay seconds, seance seconds
end

SWEP.Base     = "weapon_tttbase"
SWEP.HoldType = "normal" -- holstered/relaxed look to others

-- keep class name stable for loadouts/shops
SWEP.ClassName = "weapon_ttt2_commune"

if CLIENT then
  SWEP.PrintName     = "Commune with Dead"
  SWEP.Slot          = 8
  SWEP.ViewModelFOV  = 70
  SWEP.DrawCrosshair = true
end

SWEP.UseHands      = true
SWEP.ViewModel     = "models/weapons/c_arms.mdl"
SWEP.WorldModel    = "models/weapons/w_toolgun.mdl"
SWEP.Kind          = WEAPON_EQUIP2
SWEP.AllowDrop     = false
SWEP.AutoSpawnable = false
SWEP.Spawnable     = false
SWEP.DrawAmmo      = false

-- Hide world model entirely so others don't see a gun in-hand
function SWEP:DrawWorldModel()
  return -- do not draw the world model
end

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Delay       = 0.25
SWEP.Primary.Ammo        = "none"

-- sounds (place files under: sound/mambo/*.wav)
local SND_BEGIN      = "mambo/commune_begin.wav"
local SND_SUCCESS    = "mambo/commune_success.wav"

-- specter tool class (single tool with LMB/RMB)
local SPECTER_TOOL_WEP = "weapon_ttt2_specter_answers"

local CHANNEL_MAX_DIST = 100
local TRACE_MAX        = 80

-- specter visuals
local SKELETON_MODEL   = "models/player/skeleton.mdl"
local SPECTER_ALPHA    = 130 -- semi-transparent

-- === ConVar helpers (server) ===
local function GetChargeTime()
  local c = GetConVar("ttt2_mambo_charge_time")
  return (c and c:GetFloat()) or 10
end

local function GetSeanceTime()
  local c = GetConVar("ttt2_mambo_seance_time")
  return (c and c:GetFloat()) or 30
end

if SERVER then
  if file.Exists("sound/"..SND_BEGIN, "GAME")   then resource.AddFile("sound/"..SND_BEGIN) end
  if file.Exists("sound/"..SND_SUCCESS, "GAME") then resource.AddFile("sound/"..SND_SUCCESS) end

  -- Mute specters: block text chat + voice while NWBool set
  hook.Add("PlayerSay", "MamboSpecterBlockText", function(ply)
    if not IsValid(ply) then return end
    if ply:GetNWBool("MamboSpecter") then
      ply:ChatPrint("[Spirit] You cannot speak while you are a spirit.")
      return "" -- swallow message
    end
  end)

  hook.Add("PlayerCanHearPlayersVoice", "MamboSpecterBlockVoice", function(_, talker)
    if not IsValid(talker) then return end
    if talker:GetNWBool("MamboSpecter") then
      return false, false -- nobody hears them, no 3D voice
    end
  end)
end

-------------------------------------------------------
-- Channel state helper (NWVars drive the HUD)
-------------------------------------------------------
function SWEP:SetChannel(active, endTime, total)
  if SERVER then
    self:SetNWBool("mambo_channeling", active and true or false)
    if active then
      self:SetNWFloat("mambo_channel_end", endTime or 0)
      self:SetNWFloat("mambo_channel_total", total or 0)
    else
      self:SetNWFloat("mambo_channel_end", 0)
      self:SetNWFloat("mambo_channel_total", 0)
    end
  end

  -- keep legacy fields synced (harmless)
  if CLIENT then
    self.Channeling = active and true or false
    self.ChannelEnd = endTime or 0
    self._Total     = total or self._Total
  end
end

-- ========= CLIENT HUD/UI =========
if CLIENT then
  -- big, readable fonts for specter state
  surface.CreateFont("MamboSpecterTitle", {font = "Trebuchet MS", size = 42, weight = 900, outline = false})
  surface.CreateFont("MamboSpecterBody",  {font = "Trebuchet MS", size = 30, weight = 800, outline = false})

  -- Channel progress HUD (reads NWVars now)
  hook.Add("HUDPaint", "ttt2_mambo_commune_progress", function()
    local lp  = LocalPlayer()
    local wep = IsValid(lp) and lp:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_ttt2_commune" then return end

    if not wep:GetNWBool("mambo_channeling", false) then return end

    local remain = math.max(0, wep:GetNWFloat("mambo_channel_end", 0) - CurTime())
    local total  = wep:GetNWFloat("mambo_channel_total", 10)
    local frac   = total > 0 and (1 - (remain / total)) or 0

    local w,h = 400,20
    local x,y = (ScrW()-w)/2, ScrH()*0.8
    surface.SetDrawColor(0,0,0,160) surface.DrawRect(x,y,w,h)
    surface.SetDrawColor(123,63,160,255) surface.DrawRect(x+2,y+2,(w-4)*math.Clamp(frac,0,1),h-4)
    draw.SimpleText("Bridging life and death… "..math.ceil(remain).."s",
      "Trebuchet24", ScrW()/2, y-18, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
  end)

  -- message overlays for the TARGET being revived
  local mambo_prep_active = false
  local mambo_specter_notice_until = 0
  local mambo_specter_fade_end = 0

  net.Receive("MamboSeancePrep", function()
    mambo_prep_active = net.ReadBool()
  end)

  net.Receive("MamboSpecterNotice", function()
    local overlay_dur = net.ReadFloat() or 6
    local seance_secs = net.ReadFloat() or 0
    mambo_specter_notice_until = CurTime() + overlay_dur
    mambo_specter_fade_end = seance_secs > 0 and (CurTime() + seance_secs) or 0
  end)

  hook.Add("HUDPaint", "MamboSeanceOverlays", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    -- "Get ready..." during channeling (only visible to the target)
    if mambo_prep_active then
      draw.SimpleTextOutlined("Get ready… you are being temporarily revived.",
        "Trebuchet24", ScrW()/2, ScrH()*0.36, Color(255,255,255,230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,180))
      draw.SimpleTextOutlined("Remain silent. Do NOT speak now or when revived!",
        "Trebuchet24", ScrW()/2, ScrH()*0.40, Color(255,180,180,230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,180))
      -- NOTE: controls are intentionally NOT shown here
    end

    -- "You are a spirit…" after revival (bigger + spaced)
    if mambo_specter_notice_until > CurTime() then
      draw.SimpleTextOutlined("You are a spirit. Do NOT speak.",
        "MamboSpecterTitle", ScrW()/2, ScrH()*0.40, Color(255,255,255,235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,200))

      draw.SimpleTextOutlined("Use the Spirit Tool — LEFT CLICK = YES, RIGHT CLICK = NO.",
        "MamboSpecterBody", ScrW()/2, ScrH()*0.46, Color(200,230,255,235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,200))

      if mambo_specter_fade_end > CurTime() then
        local remain = math.ceil(mambo_specter_fade_end - CurTime())
        draw.SimpleTextOutlined("You will fade in "..remain.."s.",
          "MamboSpecterBody", ScrW()/2, ScrH()*0.52, Color(200,230,255,230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,200))
      end
    end
  end)

  -- ✅ EXTRA SAFETY: if we die / round ends while the prep overlay is on, clear it locally
  hook.Add("PlayerDeath", "MamboClearPrepOnDeath", function(victim)
    if victim ~= LocalPlayer() then return end
    mambo_prep_active = false
  end)

  hook.Add("TTTEndRound", "MamboClearPrepOnRoundEnd", function()
    mambo_prep_active = false
  end)

  -- grayscale while specter (always on while in specter state)
  hook.Add("RenderScreenspaceEffects", "MamboSpecterGrayscale", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:GetNWBool("MamboSpecter", false) then return end

    local tab = {
      ["$pp_colour_addr"] = 0,
      ["$pp_colour_addg"] = 0,
      ["$pp_colour_addb"] = 0,
      ["$pp_colour_brightness"] = 0,
      ["$pp_colour_contrast"]   = 1,
      ["$pp_colour_colour"]     = 0,
      ["$pp_colour_mulr"]       = 0,
      ["$pp_colour_mulg"]       = 0,
      ["$pp_colour_mulb"]       = 0
    }
    DrawColorModify(tab)
  end)
end

-- ========= helpers =========
local function ValidCorpse(ent)
  return IsValid(ent)
     and ent:GetClass() == "prop_ragdoll"
     and (not CORPSE or not CORPSE.IsValidBody or CORPSE.IsValidBody(ent))
end

local function GetCorpseAimed(owner)
  local tr = util.TraceLine({
    start  = owner:EyePos(),
    endpos = owner:EyePos() + owner:GetAimVector() * TRACE_MAX,
    filter = owner,
    mask   = MASK_SHOT
  })
  if ValidCorpse(tr.Entity) then return tr.Entity end
end

function SWEP:PlayLoop(owner)
  if not SERVER or not IsValid(owner) then return end
  if not file.Exists("sound/"..SND_BEGIN, "GAME") then return end
  if self._loop then self._loop:Stop() end
  self._loop = CreateSound(owner, SND_BEGIN)
  if self._loop then self._loop:Play() end
end

function SWEP:StopLoop()
  if not SERVER then return end
  if self._loop then self._loop:Stop() self._loop = nil end
end

-- ✅ FIX: always clear the victim “Get ready…” overlay when channel ends unexpectedly
local function ClearSeancePrep(victim)
  if not SERVER then return end
  if not IsValid(victim) then return end

  net.Start("MamboSeancePrep")
    net.WriteBool(false)
  net.Send(victim)
end

local function ResolveVictimFromCorpse(corpse)
  if CORPSE and CORPSE.GetPlayer then
    local ply = CORPSE.GetPlayer(corpse)
    if IsValid(ply) then return ply end
  end

  local victim
  local sid64 = corpse.sid64 or (CORPSE and CORPSE.GetPlayerSteamID64 and CORPSE.GetPlayerSteamID64(corpse))
  if sid64 then
    sid64 = tostring(sid64)
    for _, p in ipairs(player.GetAll()) do
      if IsValid(p) and p:SteamID64() == sid64 then victim = p break end
    end
  end

  if not IsValid(victim) and corpse.uqid and player.GetByUniqueID then
    local p = player.GetByUniqueID(corpse.uqid); if IsValid(p) then victim = p end
  end

  if not IsValid(victim) and corpse.nick then
    for _, p in ipairs(player.GetAll()) do if IsValid(p) and p:Nick() == corpse.nick then victim = p break end end
  end

  return IsValid(victim) and victim or nil
end

function SWEP:Initialize()
  self:SetHoldType("normal")
end

function SWEP:PrimaryAttack()
  local owner = self:GetOwner()
  if not IsValid(owner) then return end

  local corpse = GetCorpseAimed(owner)
  if not ValidCorpse(corpse) then return end
  if owner:GetPos():DistToSqr(corpse:GetPos()) > (CHANNEL_MAX_DIST * CHANNEL_MAX_DIST) then return end

  local victim = ResolveVictimFromCorpse(corpse)
  if not IsValid(victim) then
    if SERVER then owner:ChatPrint("[Mambo] Couldn't resolve the corpse's owner.") end
    return
  end

  if victim.IsReviving and victim:IsReviving() then
    if SERVER then owner:ChatPrint("[Mambo] That spirit is already being called back...") end
    return
  end
  if victim:Alive() and not (SpecDM and not victim:IsGhost()) then
    if SERVER then owner:ChatPrint("[Mambo] That player is already alive.") end
    return
  end

  if SERVER and plyspawn and plyspawn.MakeSpawnPointSafe then
    local spawnOk = plyspawn.MakeSpawnPointSafe(victim, corpse:GetPos())
    if not spawnOk then
      owner:ChatPrint("[Mambo] Not enough space to return the spirit here.")
      return
    end
  end

  local charge = math.max(0.1, GetChargeTime())
  self:SetNextPrimaryFire(CurTime() + 0.2)

  self:PlayLoop(owner)

  self._ChannelTarget = corpse
  self._ChannelVictim = victim
  self._ChannelEnd    = CurTime() + charge
  self._ChannelStart  = CurTime()

  -- drive UI via NWVars
  self:SetChannel(true, self._ChannelEnd, charge)

  -- tell the victim "get ready..." while we channel
  if SERVER then
    net.Start("MamboSeancePrep")
      net.WriteBool(true)
    net.Send(victim)
  end

  -- ✅ FIX: if the Mambo dies mid-channel, clear the victim UI + stop the channel
  if SERVER then
    local wep   = self
    local hk    = ("mambo_commune_ownerdeath_%d"):format(wep:EntIndex())
    wep._OwnerDeathHook = hk

    hook.Add("PlayerDeath", hk, function(p)
      if p ~= owner then return end
      if not IsValid(wep) then hook.Remove("PlayerDeath", hk) return end

      ClearSeancePrep(wep._ChannelVictim)

      wep:StopLoop()
      wep:SetChannel(false)
      wep.ThinkActive = false

      hook.Remove("PlayerDeath", hk)
      wep._OwnerDeathHook = nil
    end)
  end

  -- keep a holstered look even while channeling
  -- self:SetHoldType("slam") -- intentionally removed
  self:StartThink()
end

function SWEP:StartThink()
  if self.ThinkActive then return end
  self.ThinkActive = true
  self:Think()
end

function SWEP:Think()
  if not self.ThinkActive then return end
  local owner = self:GetOwner()
  if not IsValid(owner) then self:CancelChannel() return end

  if not owner:KeyDown(IN_ATTACK) then self:CancelChannel() return end
  local aimed = GetCorpseAimed(owner)
  if not IsValid(aimed) or aimed ~= self._ChannelTarget then self:CancelChannel() return end
  if owner:GetPos():DistToSqr(self._ChannelTarget:GetPos()) > (CHANNEL_MAX_DIST * CHANNEL_MAX_DIST) then
    self:CancelChannel() return
  end

  if CurTime() >= (self._ChannelEnd or 0) then self:FinishChannel() return end
  self:NextThink(CurTime() + 0.05)
  return true
end

function SWEP:CancelChannel()
  self.ThinkActive = false
  self:SetHoldType("normal")
  self:StopLoop()
  self:SetChannel(false)

  -- ✅ FIX: hide the "get ready" prompt for the victim even on unexpected cancel paths
  if SERVER then
    ClearSeancePrep(self._ChannelVictim)

    if self._OwnerDeathHook then
      hook.Remove("PlayerDeath", self._OwnerDeathHook)
      self._OwnerDeathHook = nil
    end
  end
end

-- also clear UI/sound on holster/remove/drop (covers edge cases)
function SWEP:Holster()
  -- ✅ FIX: if holstered/stripped while channeling, clear victim prompt
  if SERVER then
    ClearSeancePrep(self._ChannelVictim)

    if self._OwnerDeathHook then
      hook.Remove("PlayerDeath", self._OwnerDeathHook)
      self._OwnerDeathHook = nil
    end
  end

  self:SetChannel(false)
  self:StopLoop()
  self:SetHoldType("normal")
  self.ThinkActive = false
  return true
end

function SWEP:OnRemove()
  -- ✅ FIX: if weapon removed while channeling, clear victim prompt
  if SERVER then
    ClearSeancePrep(self._ChannelVictim)

    if self._OwnerDeathHook then
      hook.Remove("PlayerDeath", self._OwnerDeathHook)
      self._OwnerDeathHook = nil
    end
  end

  self:SetChannel(false)
  self:StopLoop()
  self.ThinkActive = false
end

-------------------------------------------------------
-- SPECTER HELPERS (module scope)
-------------------------------------------------------
local function unique(ply, tag) return ("mambo_specter_%s_%s"):format(ply:EntIndex(), tag) end

local function installFreeze(ply)
  local tMove = unique(ply, "move")
  local tCmd  = unique(ply, "cmd")

  hook.Add("SetupMove", tMove, function(p, mv)
    if p ~= ply then return end
    mv:SetForwardSpeed(0)
    mv:SetSideSpeed(0)
    mv:SetUpSpeed(0)
    local btn = mv:GetButtons()
    btn = bit.band(btn, bit.bnot(IN_JUMP + IN_DUCK + IN_SPEED + IN_WALK + IN_FORWARD + IN_BACK + IN_MOVELEFT + IN_MOVERIGHT))
    mv:SetButtons(btn)
  end)

  hook.Add("StartCommand", tCmd, function(p, cmd)
    if p ~= ply then return end
    cmd:RemoveKey(IN_JUMP)
  end)

  return {tMove, tCmd}
end

local function removeFreeze(tags)
  if not tags then return end
  for _, t in ipairs(tags) do
    hook.Remove("SetupMove", t)
    hook.Remove("StartCommand", t)
  end
end

local function installPickupBlock(ply)
  local t = unique(ply, "pickup")
  hook.Add("PlayerCanPickupWeapon", t, function(p, wep)
    if p ~= ply then return end
    local cls = IsValid(wep) and wep:GetClass() or ""
    return (cls == SPECTER_TOOL_WEP) and true or false
  end)
  return t
end

local function removePickupBlock(tag)
  if tag then hook.Remove("PlayerCanPickupWeapon", tag) end
end

-- confirm a player's body as found/identified before removing their corpse
local function confirmCorpseFor(ply)
  if not IsValid(ply) then return end

  -- TTT2: confirm player globally (scoreboard + roles update)
  if ply.ConfirmPlayer then
    ply:ConfirmPlayer(true)
  end

  -- Base TTT: try to mark the rag as found if it still exists
  local rag_to_confirm

  if IsValid(ply.server_ragdoll) then
    rag_to_confirm = ply.server_ragdoll
  else
    for _, rag in ipairs(ents.FindByClass("prop_ragdoll")) do
      local rp = (CORPSE and CORPSE.GetPlayer and CORPSE.GetPlayer(rag)) or nil
      if rp == ply then rag_to_confirm = rag break end
    end
  end

  if IsValid(rag_to_confirm) and CORPSE and CORPSE.SetFound then
    CORPSE.SetFound(rag_to_confirm, true)
  end

  if SendFullStateUpdate then SendFullStateUpdate() end
end

local function removeCorpseFor(ply)
  -- Confirm the body first so scoreboard/logs reflect an identified body
  confirmCorpseFor(ply)

  if IsValid(ply.server_ragdoll) then
    if file.Exists("sound/"..SND_SUCCESS, "GAME") then
      sound.Play(SND_SUCCESS, ply.server_ragdoll:GetPos(), 90, 100, 1)
    end
    SafeRemoveEntity(ply.server_ragdoll)
    return
  end
  for _, rag in ipairs(ents.FindByClass("prop_ragdoll")) do
    local rp = (CORPSE and CORPSE.GetPlayer and CORPSE.GetPlayer(rag)) or nil
    if rp == ply then
      if file.Exists("sound/"..SND_SUCCESS, "GAME") then
        sound.Play(SND_SUCCESS, rag:GetPos(), 90, 100, 1)
      end
      SafeRemoveEntity(rag)
      return
    end
  end
  if file.Exists("sound/"..SND_SUCCESS, "GAME") then
    sound.Play(SND_SUCCESS, ply:GetPos(), 90, 100, 1)
  end
end

local function startSpecter(ply)
  if not SERVER then return end
  if not IsValid(ply) then return end

  local seance_secs = math.max(0.1, GetSeanceTime())

  -- network flag for client FX & mutes
  ply:SetNWBool("MamboSpecter", true)

  -- visuals
  local oldModel = ply:GetModel()
  local oldCol   = ply:GetColor()
  local oldRM    = ply:GetRenderMode()

  ply:SetModel(SKELETON_MODEL)
  ply:SetRenderMode(RENDERMODE_TRANSALPHA)
  ply:SetColor(Color(oldCol.r, oldCol.g, oldCol.b, SPECTER_ALPHA))

  -- invulnerable + single tool only
  ply:GodEnable()
  ply:StripWeapons()
  timer.Simple(0, function()
    if not IsValid(ply) then return end
    ply:Give(SPECTER_TOOL_WEP)
    ply:SelectWeapon(SPECTER_TOOL_WEP)
  end)

  -- no movement/jump
  local freezeTags = installFreeze(ply)
  local pickupTag  = installPickupBlock(ply)

  -- "You are a spirit..." center-screen notice, and tell the client the fade seconds
  net.Start("MamboSpecterNotice")
    net.WriteFloat(6)           -- overlay duration
    net.WriteFloat(seance_secs) -- spirit lifetime
  net.Send(ply)

  -- auto die after N seconds
  local tname = unique(ply, "life")
  timer.Create(tname, seance_secs, 1, function()
    if not IsValid(ply) then return end
    ply:GodDisable()
    if ply:Alive() then ply:Kill() end
  end)

  -- cleanup on death/round end (and destroy corpse)
  local tDeath = unique(ply, "death")
  hook.Add("PlayerDeath", tDeath, function(p) if p == ply then
    if timer.Exists(tname) then timer.Remove(tname) end
    removeFreeze(freezeTags)
    removePickupBlock(pickupTag)
    ply:SetNWBool("MamboSpecter", false)
    hook.Remove("PlayerDeath", tDeath)

    -- remove corpse + play success sting again
    timer.Simple(0, function()
      if IsValid(ply) then removeCorpseFor(ply) end
    end)

    -- restore visuals (mostly moot since they're dead)
    if IsValid(ply) then
      ply:GodDisable()
      ply:SetRenderMode(oldRM or RENDERMODE_NORMAL)
      ply:SetColor(oldCol or color_white)
      if oldModel then ply:SetModel(oldModel) end
    end
  end end)

  local tRound = unique(ply, "roundend")
  hook.Add("TTTEndRound", tRound, function()
    if timer.Exists(tname) then timer.Remove(tname) end
    removeFreeze(freezeTags)
    removePickupBlock(pickupTag)
    ply:SetNWBool("MamboSpecter", false)
    hook.Remove("TTTEndRound", tRound)
    if IsValid(ply) then
      ply:GodDisable()
      ply:SetRenderMode(oldRM or RENDERMODE_NORMAL)
      ply:SetColor(oldCol or color_white)
      if oldModel then ply:SetModel(oldModel) end
    end
  end)
end
-------------------------------------------------------

function SWEP:FinishChannel()
  self.ThinkActive = false
  self:SetHoldType("normal")
  self:StopLoop()
  self:SetChannel(false)

  if SERVER then
    -- ✅ remove the owner-death hook now that we finished
    if self._OwnerDeathHook then
      hook.Remove("PlayerDeath", self._OwnerDeathHook)
      self._OwnerDeathHook = nil
    end

    local owner  = self:GetOwner()
    local corpse = self._ChannelTarget
    local victim = self._ChannelVictim
    if not (IsValid(owner) and IsValid(corpse) and IsValid(victim)) then return end

    -- stop the "get ready" prompt
    ClearSeancePrep(victim)

    if file.Exists("sound/"..SND_SUCCESS, "GAME") then
      owner:EmitSound(SND_SUCCESS, 70, 100, 1, CHAN_AUTO)
    end

    local reviveTime = 0 -- revive immediately after channel finishes

    victim:Revive(
      reviveTime,
      function(ply) -- on_success
        -- GLOBAL CHAT ANNOUNCEMENT
        PrintMessage(HUD_PRINTTALK,
          ("A Mambo summoned the spirit of %s for questioning!"):format(ply:Nick()))

        -- Start specter state (model, freeze, single tool, invuln, auto-die & corpse delete)
        startSpecter(ply)

        if ply.ResetConfirmPlayer then ply:ResetConfirmPlayer() end
        if ply.SendRevivalReason then ply:SendRevivalReason(nil) end
        if SendFullStateUpdate then SendFullStateUpdate() end
      end,
      nil,               -- no validate callback
      true,              -- keep corpse semantics
      REVIVAL_BLOCK_NONE -- use enum (no round-end blocking)
    )

    -- Optional watcher: cancel if mambo stops holding/aiming during tiny reviveTime
    local key = ("mambo_revive_watch_%s"):format(victim:EntIndex())
    local deadline = CurTime() + math.max(0.1, reviveTime) + 0.25
    hook.Add("Think", key, function()
      if not IsValid(victim) or CurTime() > deadline then hook.Remove("Think", key) return end
      if not IsValid(owner) or not owner:Alive() or owner:IsSpec() then
        victim:CancelRevival()
        hook.Remove("Think", key)
        return
      end
      if owner:GetActiveWeapon() ~= self or not owner:KeyDown(IN_ATTACK) then
        victim:CancelRevival()
        hook.Remove("Think", key)
        return
      end
    end)
  end
end

function SWEP:OnDrop()
  -- ✅ FIX: clear victim prompt if dropped/removed mid-channel
  if SERVER then
    ClearSeancePrep(self._ChannelVictim)

    if self._OwnerDeathHook then
      hook.Remove("PlayerDeath", self._OwnerDeathHook)
      self._OwnerDeathHook = nil
    end
  end

  self:SetChannel(false)
  self:StopLoop()
  self:Remove()
end

-- =====================================================
-- WIN CHECK: Ignore specters (skeletons) for victory
-- Intervene ONLY while at least one specter is alive.
-- =====================================================
if SERVER then
  local function anySpecterAlive()
    for _, p in ipairs(player.GetAll()) do
      if IsValid(p) and p:Alive() and not p:IsSpec() and p:GetNWBool("MamboSpecter", false) then
        return true
      end
    end
    return false
  end

  local function livingNonSpecterTeams()
    local teams_alive = { INNOCENT = false, TRAITOR = false, OTHER = false }
    local non_spec_count = 0

    for _, p in ipairs(player.GetAll()) do
      if IsValid(p) and p:Alive() and not p:IsSpec() and not p:GetNWBool("MamboSpecter", false) then
        non_spec_count = non_spec_count + 1

        -- Resolve team (TTT2)
        local t = (p.GetTeam and p:GetTeam()) or nil
        if t == TEAM_TRAITOR then
          teams_alive.TRAITOR = true
        elseif t == TEAM_INNOCENT then
          teams_alive.INNOCENT = true
        else
          teams_alive.OTHER = true
        end
      end
    end

    return teams_alive, non_spec_count
  end

  hook.Add("TTTCheckForWin", "MamboIgnoreSpectersWin", function()
    -- Only touch win logic while a specter exists; otherwise let base TTT/TTT2 handle it.
    if not anySpecterAlive() then return end

    local teams_alive, non_spec_count = livingNonSpecterTeams()

    -- If there are NO living non-specters but a specter exists, end the round now (innocents).
    if non_spec_count == 0 then
      return WIN_INNOCENT
    end

    -- If ONLY one real team remains among non-specters, end in their favor.
    local only_inno  = teams_alive.INNOCENT and not teams_alive.TRAITOR and not teams_alive.OTHER
    local only_trait = teams_alive.TRAITOR  and not teams_alive.INNOCENT and not teams_alive.OTHER

    if only_inno then
      return WIN_INNOCENT
    elseif only_trait then
      return WIN_TRAITOR
    end

    -- Mixed non-specter teams still alive -> do nothing (let core logic continue).
    return
  end)
end