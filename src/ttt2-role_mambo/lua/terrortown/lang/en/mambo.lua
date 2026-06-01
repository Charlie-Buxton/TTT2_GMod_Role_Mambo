L = LANG.GetLanguageTableReference("en")

L[MAMBO.name]                  = "Mambo"
L["info_popup_" .. MAMBO.name] = [[You are a Detective variant.
Use “Commune with Dead” (slot 8) to summon a victim’s silent spirit from their corpse.]]
L["body_found_" .. MAMBO.abbr]  = "They were the Mambo."
L["search_role_" .. MAMBO.abbr] = "This person was the Mambo!"
L["target_" .. MAMBO.name]      = "Mambo"
L["ttt2_desc_" .. MAMBO.name]   = [[Detective with a séance. Channel on a corpse to revive the victim as a silent, frozen spirit (skeleton) for a short time.
Spirits can only look around and answer with the Spirit Answers tool (left click = Yes, right click = No; 2s cooldown).]]
