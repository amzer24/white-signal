# Traps and enemies for Worlds 2 to 4

Research date: 25 Sep 2026. Reads with `docs/levels/world-1.md`.

## Summary

1. The best next traps reuse moves the Spark already has. Bumping, dashing and stomping each get a new use.
2. The cheapest additions run on a clock or a simple trigger. They fit the existing route proof with little new work.
3. Enemies that react to where the Spark is looking or standing cost more, because the simulator has to search harder.
4. In four greys, danger must come from shape and motion. Spikes on top, teeth and shaking read at 16 px. Colour cannot help.
5. Each world should own 2 to 3 new things, one per level, with the fourth level mixing them. World 1 already does this.

Cost: **Low** is a new tile on a clock or trigger, which the proof already handles. **Medium** needs new code in both simulators (`tools/levels/` and `scripts/world1/w1_sim.gd`). **High** reacts to the Spark every frame, so the proof search gets slower.

## Traps, ranked

| Code | Trap | Based on | Skill tested | Works with our moves | Reads in 4 greys at 16 px | Tell | Cost |
|---|---|---|---|---|---|---|---|
| T1 | **Channel blocks.** Bumping a switch block swaps two sets of blocks between solid and outline. | Mario Maker On/Off blocks, Celeste touch switches | Routing, reading | Uses the bump from below. A switch mid-air lets you change the floor while jumping. | Very well. Solid grey block against a dotted outline. | None needed. The outline shows where the block will be. | Low |
| T2 | **Beat blocks.** Blocks appear and vanish in a set order on a beat. | Mega Man "appearing blocks" | Timing, memory | Dash reaches a block before it goes. Wall kick off a block that is about to vanish. | Well if the next block shows a faint outline first. | Outline flickers 0.3 s before it appears. The block shakes before it vanishes. A tick on each beat. | Low |
| T3 | **Sweep arm.** A line of static dots turns around a pivot. | Mario Fire Bar | Timing | Dash through the gap as it passes. | Well. White dots on a dark line, turning. | The motion is the tell. It is always visible. | Low to medium |
| T4 | **Line emitter.** A wall box fires one bolt along its row when something crosses the row. | Spelunky arrow trap, Bill Blaster | Reading, nerve | Jump over the bolt, or lure it with rubble or a walker. The bolt kills walkers too. | Well, if the bolt is not a white blob (see asset lessons). | Lamp lights for 0.3 s with a rising sound, then it fires. | Medium (needs projectiles) |
| T5 | **Cracked wall.** A wall panel that breaks when you dash into it. | Celeste smashable walls | Reading, exploring | Gives dash a second job. Good for hiding big shards. | Well. A crack pattern on the panel. | The crack, plus a glint like the hidden block. | Low |
| T6 | **Carrier wind.** A zone that pushes the Spark sideways or up. | Celeste Chapter 4 (unverified which chapter) | Routing, nerve | Dash against the wind. Wall slide in a crosswind. | Fair. Needs moving streak lines, which must not look like the walker's static. | Streaks speed up 0.5 s before a gust. A rising hiss. | Medium (changes movement) |
| T7 | **Ram block.** A block with one lit face. Dash into that face and it charges to the far wall. | Celeste Kevin blocks | Nerve, routing | Pure dash. You ride it or get crushed by it. | Well. One white face on a dark block. | The lit face shows the direction. A wind-up shake before it charges. | Medium |
| T8 | **Rising static.** A line of static rises up a shaft and kills on touch. | DKC Returns tidal wave (unverified) | Nerve | Wall kicks between two walls, lift rings and dash under pressure. | Well. A band of the walker's crawling stripes. | A low rumble and screen shake before it starts. It starts only when you enter. | Medium |

Left out: the Prince of Persia slicer (a press on its side), ice and conveyors (new physics for the proof), and hidden falling blocks (they break our "show it first" rule).

## Enemies, ranked

Our only attacks are the stomp and CHARGE, so a shield on the front of an enemy means nothing. "Armoured" for us means spikes on top.

| Code | Enemy | Based on | Pattern | How it counters or rewards our moves | Reads at 16 px | Tell | Cost |
|---|---|---|---|---|---|---|---|
| E1 | **Spiked walker.** A walker with spikes on top. | Spiny (SMB), Zinger (DKC) | Patroller, stomp-immune | Stops the stomp habit. Can only be killed by traps: a press, loose floor or rubble. CHARGE lets you survive touching it. | Very well. The spikes are the silhouette. | None needed. The shape is the warning. | Low (walker plus one flag) |
| E2 | **Hopper.** Already built and drawn. | Mario hopping enemies | Jumper | You run under it mid-hop or stomp it on the way down. | Already drawn with a 0.24 s crouch. | The crouch. | Already built |
| E3 | **Wave flyer.** Flies straight across in a wave. | Castlevania Medusa Head, SMB3 Paragoomba | Sine wave | Stompable. A line of them over a pit is a stomp chain bridge. | Well. Add two wing pixels to a walker-like body. | Its path is steady. You can see it coming from off screen. | Low (a path set by time) |
| E4 | **Relay turret.** Sits still and fires a slow pulse on a clock. | Bill Blaster, Mega Man turrets | Shooter | Stomp it to shut it off. It does not fire when you stand next to it or on it, as in SMB. | Well. A box with one eye facing the way it fires. | Eye brightens for 0.3 s with a charge-up sound. | Medium (shares projectiles with T4) |
| E5 | **Listener.** Drifts toward you only while you face away. Stops and covers its face when you look at it. | Boo (SMB3, Super Mario World) | Chaser | Tests reading. It slows a player who always runs one way. Stomp does nothing. | Well. A pale shape, face shown or hidden. | Its face turns as it starts to move. A faint rising whine. | High (reacts to the Spark every frame) |
| E6 | **Jammer.** Floats above the screen and drops spiked walkers. | Lakitu (SMB) | Spawner | Rewards a high route and stomping it from above. Rubble can hit it. | Fair. Needs a cloud-like shape that is not the Spark. | Arm raised for 0.4 s before each throw. | High (tracks the Spark, makes enemies) |

Left out: a ceiling hanger (overlaps the dropper) and a burrower (hard to show in four greys).

## How classic games pace new things

- **Hayashida:** one idea per level, in four steps (learn, harder, twist, mastery). He set no number per world.
- **Mario 3 and Super Mario World:** each world is a place (desert, water, sky, a cave dome, a forest), and the place decides the hazards.
- **Celeste:** each chapter owns a set of objects. Chapter 1 adds several (zip movers, crumble blocks, springs). Chapter 5 adds five.
- **Super Meat Boy:** saws appear as scenery in 1-2 and only become a hazard in 1-6.
- **Enemy variety:** enemies should differ in what the player must do, not in speed. Pair a threat above with one below (Frogatto, Build a Bad Guy Workshop).

For our four-level worlds this means 3 new things per world: one each in levels 1 to 3, and level 4 mixes them with a mini-boss. World 1 already works this way.

## Proposed plan for Worlds 2 to 4

| World | Name and theme | Owned new things | Level beats | Reuses from earlier |
|---|---|---|---|---|
| 2 | **The Switchyard.** A dead relay yard. The line splits into channels. | E2 hopper, E1 spiked walker, T1 channel blocks | 2-1 hoppers. 2-2 spiked walkers, killed with presses and rubble. 2-3 channel blocks. 2-4 a relay mini-boss who swaps the channels, with hoppers. | Presses, loose floors, gates |
| 3 | **The Aerials.** Broadcast masts high above the city. Wind carries the signal. | T6 carrier wind, E3 wave flyer, T3 sweep arm | 3-1 wave flyers over pits. 3-2 wind. 3-3 sweep arms on the masts. 3-4 a lift ring climb through wind and flyers. | Lift rings, moving girders, springs |
| 4 | **Dead Air.** The deep exchange under the network. The caller is close. | E4 relay turret with T4 line emitter, E5 listener, T8 rising static | 4-1 turrets and emitters. 4-2 listeners in the dark. 4-3 the rising static shaft. 4-4 the last Gate and the other spark. | Droppers, timed gates, everything |

Held in reserve: T2, T5 (good for secrets anywhere), T7 and E6. World 2 is almost all low cost. World 3 needs one movement change. World 4 needs projectiles and the only high-cost enemy.

## Asset and feel lessons

1. **Silhouette first.** Block the shape in one grey. If it does not read, detail will not fix it. Super Mario Land kept sprites very simple so they read on a four-shade, low-contrast screen. ([androidarts on Super Mario Land](https://androidarts.com/sml/sml.htm))
2. **Less detail reads better.** Shovel Knight's first King Knight sprite was too detailed and was simplified over several passes. ([Yacht Club Games](https://www.yachtclubgames.com/blog/breaking-the-nes/))
3. **White means the Spark.** A white bolt would look like the player. Draw bolts as a hollow ring or a dark core with a white edge.
4. **Tells need sound as well as frames.** One study measured simple reaction at about 330 ms to a light and 285 ms to a sound. ([Shelton and Kumar 2010](https://www.scirp.org/html/4-2400003_2689.htm)) Other lab figures are lower (unverified). Our 0.3 s visual tells are near that limit on a first meeting. Start the sound when the tell starts, not when the trap fires.
5. **Keep 2 to 3 tell frames.** The current sheets already do this. A tell is the "wind-up" players expect. ([Game Developer on telegraphing](https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing))
6. **Give each trap family its own sound.** Clock traps tick. Triggered traps rise in pitch. Chasers whine. This is a recommendation, not a sourced finding.

Not researched in depth: Rayman Legends, Hollow Knight and Castlevania traps.

## Sources

- Hayashida on Super Mario 3D Land: https://www.gamedeveloper.com/design/the-structure-of-fun-learning-from-i-super-mario-3d-land-i-s-director
- Super Mario Bros 3 worlds: https://www.mariowiki.com/Super_Mario_Bros._3
- Super Mario World: https://strategywiki.org/wiki/Super_Mario_World
- Bill Blaster: https://www.mariowiki.com/Bill_Blaster
- Boo: https://www.mariowiki.com/Boo
- Spiny: https://www.mariowiki.com/Spiny
- Fire Bar: https://www.mariowiki.com/Fire_Bar
- Zinger: https://www.mariowiki.com/Zinger
- Mega Man appearing blocks: https://megaman.fandom.com/wiki/Appearing_Block
- Prince of Persia traps: https://en.wikipedia.org/wiki/Prince_of_Persia_(1989_video_game)
- Spelunky arrow trap: https://spelunky.fandom.com/wiki/Arrow_Trap_(HD)
- Medusa Head: https://castlevania.fandom.com/wiki/Medusa_Head
- Celeste Forsaken City: https://celeste.ink/wiki/Forsaken_City
- Celeste Mirror Temple: https://celeste.ink/wiki/Mirror_Temple
- Celeste objects (Kevin blocks): https://celestegame.fandom.com/wiki/Objects
- Celeste overview: https://en.wikipedia.org/wiki/Celeste_(video_game)
- Super Meat Boy saw blade: https://supermeatboy.fandom.com/wiki/Saw_Blade
- DKC Returns review (tidal wave, unverified): https://www.destructoid.com/reviews/review-donkey-kong-country-returns/
- Platformer enemy design: https://frogatto.com/2013/01/03/platformer-enemy-design/
- Build a Bad Guy Workshop: https://www.gamedeveloper.com/design/build-a-bad-guy-workshop---designing-enemies-for-retro-games
- Enemy attacks and telegraphing: https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing
- Super Mario Land graphics: https://androidarts.com/sml/sml.htm
- Breaking the NES: https://www.yachtclubgames.com/blog/breaking-the-nes/
- Auditory and visual reaction times: https://www.scirp.org/html/4-2400003_2689.htm
