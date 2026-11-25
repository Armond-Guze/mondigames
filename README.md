# MondiGames prototype

An original desktop tactical FPS prototype. The first build is an offline practice range with six targets, a 45-second clock, and an eight-shot magazine.

The second build adds a visible weapon, shot audio, and an amber hit marker.

## Run it

Extract the project, import `project.godot` in Godot 4, and press F6 with `arena.tscn` open or F5 to run the project.

Click the game to capture the mouse. Move with WASD, walk with Shift, jump with Space, aim with the mouse, shoot with left click, and reload with R. Escape pauses and releases the mouse. Enter starts a fresh round.

## Source

- `arena.gd` builds the map and handles targets, timing, shooting, and the HUD.
- `player.gd` controls movement and camera input.

The next milestone is a small original map with a round objective and a private 1v1 playtest. Use that playtest to refine movement, map routes, and round pacing before expanding to larger teams.
