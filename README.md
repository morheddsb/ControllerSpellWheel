# Controller Spell Wheel

A World of Warcraft addon for WoW Forever: a gamepad spell wheel like the game's own flyout
wheel (e.g. mage portals), but with spells you choose. Prototype: one wheel with eight rank 1
mage spells, set in `Core.lua` (`SPELLS`).

## Install

Download `ControllerSpellWheel-<version>.zip` from
[Releases](https://github.com/morheddsb/ControllerSpellWheel/releases) and unzip it into
`Interface/AddOns`, or install it through the [WowUp Hub](https://wowup.io/guide/wowup/hub).

## Use

1. Make a macro with:
   ```
   /click ControllerSpellWheel LeftButton true
   ```
2. Put it on a gamepad action bar slot, e.g. a trigger.
3. Press it to open the wheel. Flick the right stick towards a spell to cast it.
   Pressing the macro again casts the spell the stick points at, or closes the wheel if the
   stick is centred.

`/csw capture` toggles whether the right stick is kept from turning the camera while the wheel
is open (on by default).

`/csw keys` toggles printing the name of each gamepad button press in chat, for troubleshooting.

`/csw stickbuttons` toggles the game setting `GamePadStickAxisButtons`, which sends the sticks'
directions as button presses (needed for flick casting), or says it doesn't exist.

## How it works

- The wheel and the button are secure frames, so opening, closing and casting work in combat.
- While the wheel is open, the right stick's directions (`PADRSTICKUP` etc.) are bound to the
  button. A flick is a key press; a secure snippet reads the stick's angle (`GetGamePadState`)
  and casts that slot's spell.
- The camera lock uses `EnableGamePadStick` and an `OnGamePadStick` handler that returns
  `false`, as the game's `SoftCursor.lua` does.

## Known gaps

- Other gamepad buttons don't close the wheel (the game's wheel closes on any button).
- No cooldowns on the wheel.
- The spells are fixed in `Core.lua`.

## Releasing

Bump `## Version:` in `ControllerSpellWheel.toc`, commit, then push a matching tag (`v<version>`).
The `Release` workflow builds the zip with `tools/package.sh` and publishes a GitHub release, which
the [WowUp Hub](https://wowup.io/guide/wowup/hub) picks up.
