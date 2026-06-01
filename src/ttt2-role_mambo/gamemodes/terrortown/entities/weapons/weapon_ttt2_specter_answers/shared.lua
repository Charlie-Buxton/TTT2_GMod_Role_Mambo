if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tttbase"
SWEP.PrintName = "Spirit Answers"
SWEP.Slot = 7
SWEP.Kind = WEAPON_NONE
SWEP.HoldType = "normal"
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.AllowDrop = false
SWEP.AutoSpawnable = false
SWEP.Spawnable = false
SWEP.NoSights = true

SWEP.Primary.Automatic   = false
SWEP.Primary.Delay       = 2
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo        = "none"

SWEP.Secondary.Automatic   = false
SWEP.Secondary.Delay       = 2

local SND_YES = "mambo/yes.wav"
local SND_NO  = "mambo/no.wav"

if SERVER then
  if file.Exists("sound/"..SND_YES, "GAME") then resource.AddFile("sound/"..SND_YES) end
  if file.Exists("sound/"..SND_NO,  "GAME") then resource.AddFile("sound/"..SND_NO)  end
end

function SWEP:Initialize()
  self:SetHoldType(self.HoldType)
end

local function playLoud(owner, snd)
  if not IsValid(owner) then return end
  if file.Exists("sound/"..snd, "GAME") then
    -- louder & farther reach (sound level 95, full volume)
    owner:EmitSound(snd, 95, 100, 1, CHAN_VOICE)
  else
    owner:EmitSound("buttons/button14.wav", 70, 100, 0.9, CHAN_AUTO)
  end
end

function SWEP:PrimaryAttack() -- LEFT CLICK = YES
  self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
  self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
  if not SERVER then return end
  playLoud(self:GetOwner(), SND_YES)
end

function SWEP:SecondaryAttack() -- RIGHT CLICK = NO
  self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
  self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
  if not SERVER then return end
  playLoud(self:GetOwner(), SND_NO)
end
