# Mambo Role for TTT2

A custom social-deduction game role for TTT2, built in Lua for Garry's Mod.

Mambo is a public investigator who can temporarily call a dead player back as a spirit. The spirit cannot walk, speak, or use normal weapons. Instead, the Mambo has a short window to ask questions while the spirit answers with audible `Yes` and `No` sounds.

[TTT2](https://github.com/TTT-2/TTT2) expands TTT with a framework for custom roles, equipment, settings, and win conditions. This repository adds one of those roles.

## What Mambo Does

Mambo is an Innocent-team role based on the Detective. Unlike hidden roles, Mambo is publicly visible to the other players and receives access to the Detective equipment shop.

Instead of the standard DNA scanner, Mambo receives a custom **Commune with Dead** ability. To use it, the Mambo must aim at a dead player's body from close range and hold the primary attack button while the seance charges.

By default, a successful seance takes 10 seconds. During that time:

- The Mambo must continue holding the ability, looking at the same body, and staying nearby.
- The dead player is warned that they are about to return temporarily.
- Moving away, looking away, releasing the button, switching weapons, or dying cancels the seance.

After the seance completes, the dead player returns as a spirit:

- Their player model changes to a semi-transparent skeleton.
- Their screen becomes grayscale.
- They cannot move or jump.
- They cannot use voice chat or text chat.
- Their existing weapons are removed.
- They cannot pick up standard weapons.
- They are invulnerable for the duration of the seance.
- They receive a custom **Spirit Answers** ability: left click plays `Yes`, and right click plays `No`.
- Each answer has a 2-second cooldown.
- They automatically die again after 30 seconds by default.

Living spirits are intentionally excluded from victory calculations. This prevents an otherwise-finished round from continuing just because a temporary, invulnerable witness is still present.

## Example Round

Player 1 is publicly assigned the Mambo role. They are part of the Innocent team, so their goal is to help identify and eliminate the hidden Traitors.

Later in the round, Player 2 is killed. The Mambo finds Player 2's body, holds **Commune with Dead**, and stays focused on the corpse for 10 seconds. A sound plays while the ability charges, making the seance visible and risky.

Player 2 then returns as a silent skeleton for 30 seconds. They cannot explain what happened directly, so the Mambo has to ask focused questions:

> Was the person who killed you wearing a blue shirt?

Player 2 left-clicks to answer `Yes`.

> Was it Player 3?

Player 2 right-clicks to answer `No`.

The result is an investigation mechanic with a social constraint: the Mambo can gain useful information from the dead, but only if they ask the right questions and survive long enough to complete the seance.

## Project Structure

```text
src/ttt2-role_mambo/
|-- addon.json                                      # Garry's Mod addon metadata
|-- gamemodes/terrortown/entities/weapons/
|   |-- weapon_ttt2_commune/shared.lua             # Corpse-targeted seance ability
|   `-- weapon_ttt2_specter_answers/shared.lua     # Spirit Yes / No responses
|-- lua/terrortown/
|   |-- autorun/shared/sh_mambo_convars.lua         # Server configuration
|   |-- entities/roles/mambo/shared.lua             # Role setup and loadout
|   `-- lang/en/mambo.lua                           # English UI text
|-- materials/vgui/ttt/dynamic/roles/               # Role icon
`-- sound/mambo/                                    # Seance and response audio
```

## Configuration

The addon adds two server console variables:

| Console variable | Default | Purpose |
| --- | ---: | --- |
| `ttt2_mambo_charge_time` | `10` | Seconds the Mambo must channel over a corpse |
| `ttt2_mambo_seance_time` | `30` | Seconds a revived spirit remains available for questioning |

TTT2 also provides its usual role controls for enabling the role and tuning how often it appears. By default, Mambo is limited to one player and requires at least eight players in the round.

## Running the Addon

### Requirements

- Garry's Mod
- A server running [TTT2](https://github.com/TTT-2/TTT2)

### Local Installation

Copy the addon folder into the Garry's Mod addons directory:

```text
src/ttt2-role_mambo/
```

becomes:

```text
garrysmod/addons/ttt2-role_mambo/
```

Start a TTT2 server and enable the Mambo role through the standard TTT2 role settings.
