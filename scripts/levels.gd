# ORIGIN: NEW, written by team.
# STORY LEVELS as text maps. Edit a map here and press F5: the level is rebuilt from this text.
# Legend (1 character = one 16 px tile):
#   #  solid ground          =  one-way platform        X  death spikes (instant death, your body stays)
#   P  player start          B  bench (checkpoint)      C  coin (geo)
#   g  lollipop guard        h  smug guard              f  flame guard (elite)
#   s  scalper (throws price tags)   t  streamer (fast)   o  preorder guy (receipt shield)   L  LINE CUTTER mini-boss (blocks the exit)
#   E  exit (next level / the store)                    1-9  sign (text in "signs")
#   .  empty (falling below the map = pit)
# Optional secrets: high coins above paired one-way ledges; hold jump on a body bounce.
extends RefCounted

const STORY := [
	"GTA VI drops TODAY.",
	"One store in Vice Slime still has a copy.",
	"Everyone in town wants it. So do you.",
]

const LEVELS := [
	{
		"title": "LEVEL 1: THE DOCKS",
		"line": "The store is across town. Rival buyers are already in line.",
		"tiles": "grass", "sky": "day", "backdrop": "docks",
		"signs": {"1": "J / SQUARE: strike\nHit a $$$ tag to BOUNCE IT BACK", "2": "In the air hold S + J on a hamster: POGO",
			"3": "Too high? Fall on the spikes...", "4": "...then jump on your body: BOUNCE BACK",
			"5": "L / TRIANGLE: special    I / R2: power shot (needs SOUL)"},
		"exit": "TO THE STREETS >",
		"map": [
			"#......................................................#",
			"#.......................................C..............#",
			"#......................................................#",
			"#.......................................==.............#",
			"#..........................................4...........#",
			"#.........................................C......E......#",
			"#..............................5..............#######..#",
			"#....................C..............3.........#######..#",
			"#.....1......................#........C.......#######..#",
			"#..................2.........#................#######..#",
			"#..P........g.........s..h==.#...B..o.t.XXX...#######..#",
			"##################...###################################",
			"##################...###################################",
			"##################...###################################",
		],
	},
	{
		"title": "LEVEL 2: NEON STREETS",
		"line": "The line goes around the block. Everyone in it wants YOUR copy.",
		"tiles": "brick", "sky": "sunset", "backdrop": "streets",
		"signs": {"1": "Pogo across their heads!", "2": "Big gap: jump, then K / CIRCLE to dash",
			"3": "This one hops. Hit it 5 times.", "4": "You know what to do."},
		"exit": "TO THE ROOF >",
		"map": [
			"#.....................................................................#",
			"#.......................................................C.............#",
			"#.....................................................................#",
			"#.......................................................==............#",
			"#.....................................................................#",
			"#...................C.........................................E.......#",
			"#...........................................................#######...#",
			"#..............................2...............3.......4....#######...#",
			"#.........1.........................................C.......#######...#",
			"#.....................................C.....................#######...#",
			"#..P........g..g..g...s..t...h..........g..B...o..f..g..XXX.#######...#",
			"##########..#..#..#..###########.......################################",
			"##########..#..#..#..###########.......################################",
			"##########..#..#..#..###########.......################################",
		],
	},
	{
		"title": "LEVEL 3: THE ROOF",
		"line": "The last copy is upstairs. Your rivals are the way up.",
		"tiles": "stone", "sky": "night", "backdrop": "roof",
		"signs": {"1": "Fall here first.", "2": "Then fall here.", "3": "THE STORE (beat the Line Cutter)"},
		"exit": "ENTER THE STORE >",
		"map": [
			"#........................................#",
			"#...C..................t.......L...3o.E..#",
			"#.................########################",
			"#...==............########################",
			"#.................########################",
			"#.......f..B...XX.########################",
			"#.......##########......##...............#",
			"#.......##########.......................#",
			"#.....1.##########.......................#",
			"#.......##########.......................#",
			"#..P.XXX##########.......................#",
			"##########################################",
			"##########################################",
			"##########################################",
		],
	},
]
