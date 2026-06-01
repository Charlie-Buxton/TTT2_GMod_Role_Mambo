if SERVER then
  -- Only the two convars you want
  if not ConVarExists("ttt2_mambo_charge_time") then
    CreateConVar("ttt2_mambo_charge_time", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY},
      "Seconds to channel Commune")
  end

  if not ConVarExists("ttt2_mambo_seance_time") then
    CreateConVar("ttt2_mambo_seance_time", 30, {FCVAR_ARCHIVE, FCVAR_NOTIFY},
      "Seconds a spirit remains before dying")
  end
end