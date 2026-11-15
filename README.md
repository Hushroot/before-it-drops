# Before It Drops

A Godot platformer we made for the Haven Hack Club game jam. The theme was Bounce Back.

You're trying to get the last copy of GTA VI in Vice Slime. First you have to get past the other buyers, cross town, and beat the Hamster Godfather and the Vice Queen.

When you die, a brief notification appears on the right and your body stays where you fell, holding your coins. Only the three newest bodies remain. You can walk through their sides, hit them to get your coins back, or land on top to bounce higher. Some ledges need that extra height, so dying is part of figuring out the route.

## Run it

Import `project.godot` in Godot 4.3 or newer, then press F5. The latest automated checks ran on Godot 4.7.2.

Pick a fighter, watch or skip the intro, and play through The Docks, Neon Streets, and The Roof. Press B on the fighter screen if you want to go straight to the boss.

## Controls

| Action | Keyboard | PS4 controller |
|---|---|---|
| Move | A/D or left/right arrows | Left stick or d-pad |
| Jump | Space | Cross |
| Attack | J or X | Square |
| Dash | K, C, or Shift | Circle or R1 |
| Special | L | Triangle |
| Power shot | I | R2 or L1 |
| Pause | Esc | Options |

Hold jump to go higher, or release it early for a short hop. Hold down while attacking in the air to pogo off enemies and spikes. Hold up to attack above you.

Hit enemies to fill the soul meter for power shots. You can also hit the flying `$$$` tags to send them back at enemies. Benches save your respawn point and refill your health.

## Fighters

| Fighter | What they do |
|---|---|
| SPARK | Longer attack reach and a finger-gun special that fires three sparks |
| ZOOM | Double damage and a shoulder charge |
| BRAINS | Six masks of health instead of five, plus a healing special |

## Play together

Press R or Options on the fighter screen to open the co-op lobby. Up to three people can play the story on the same screen, using one keyboard player and controllers.

Press Enter or Cross to join, then left/right to choose a fighter. Press Enter again or Options to start. Backspace or Circle leaves the lobby. The camera follows everyone, and a teammate's body works as a bounce pad too.

## Editing the game

The scripts are in `scripts/`, scenes are in `scenes/`, and art and sound are in `assets/`. The levels are text maps in `scripts/levels.gd`. You can edit a map there and run the game to try it.
