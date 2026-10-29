# Sky Coin Rush 🪙

A fast, round-based coin-collection race on floating islands. Built for Roblox Studio.

## The Loop (why it's addicting)
1. 60-second rounds — race across floating islands collecting as many coins as you can
2. Coins are permanent currency — spend them on Speed, Jump, and Trail upgrades
3. Upgrades make the next round easier → earn faster → upgrade faster
4. Round winner gets a +25 coin bonus; leaderboard tracks Wins & Coins

## Setup (5 minutes, no building required)
1. Open Roblox Studio → new Baseplate → **delete the Baseplate**
2. Create each script below in **ServerScriptService** (right-click → Insert Object → Script),
   then paste the matching file's contents:
   - `MapBuilder.server.lua` — Script, named `MapBuilder`
   - `GameServer.server.lua` — Script, named `GameServer`
   - `AntiCheat.server.lua` — Script, named `AntiCheat`
   - `LightingSetup.server.lua` — Script, named `LightingSetup`
3. In **StarterPlayer → StarterPlayerScripts**, add a **LocalScript** named `ClientFX`
   and paste `ClientFX.client.lua`
4. Press **Play** — the map builds itself, rounds start automatically.

## Map
The MapBuilder script procedurally constructs everything at runtime:
- Central lobby with a neon rim and spawn
- 14 floating islands in a ring (deterministic seed — same fair map every time)
- Wooden plank bridges connecting every island
- Jump pads every 3rd island
- Crystal undersides, trees, clouds, and a fall-zone ocean below

## Anti-cheat design (why there are no cheaters)
- **Server owns everything**: coin counts, upgrade levels, round state.
  No remote exists that can grant currency — the only inputs a client can send
  are "buy upgrade X" and "I touched coin Y", both fully re-validated server-side.
- **Position validation**: a coin only counts if the server sees the player within
  12 studs of it, at the coin's real position.
- **Teleport detection**: any single-frame position jump > 60 studs rubber-bands
  the player back and increments their violation count.
- **Speed-hack detection**: sustained ground movement above the max legit build
  (Speed Lv5 + headroom) zeroes the player's velocity.
- **Stat tamper reversion**: clients that edit WalkSpeed/JumpPower get instantly
  reverted to the server-known value via `AllowedSpeed`/`AllowedJump` attributes.
- 25 violations = kick.

## Graphics
- Future lighting technology, golden-hour sun (15:30), warm color grading
- SunRays, Bloom, subtle DepthOfField, Atmosphere haze
- Neon coins with sparkle particle emitters
- Animated coin-pop "+1 coin" HUD feedback, tween-based
- Vibrant stylized palette: grass islands, purple crystals, neon rim

## Config values (edit top of GameServer.server.lua)
| Setting | Default | What it does |
|---|---|---|
| `ROUND_TIME` | 60 | Seconds per round |
| `INTERMISSION` | 8 | Seconds between rounds |
| `COINS_PER_ROUND` | 40 | Coins spawned each round |
| `COIN_VALUE` | 1 | Currency per coin |
| `WIN_BONUS` | 25 | Bonus coins for winning a round |

Upgrades (server-authoritative):
| Upgrade | Base cost | Max level | Effect |
|---|---|---|---|
| Speed | 50 (+8/level) | 5 | +4 WalkSpeed per level |
| Jump | 60 (+10/level) | 5 | +10 JumpPower per level |
| Trail | 100 (+75/level) | 3 | Golden trail cosmetic |

## Notes
- Data currently resets on server restart — swap the `loadData` function in
  `GameServer.server.lua` for DataStoreService persistence before publishing.
- Player data table is in-memory and cleaned up on leave — no memory leak.
- To publish: File → Publish to Roblox, then enable the game in Creator Dashboard.
