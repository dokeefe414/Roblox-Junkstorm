# JUNKSTORM! 🌩️

A colorful Roblox scavenging prototype. Collect valuable junk, return to the safe base, sell it for coins, and upgrade your bag. Watch the storm countdown: an approaching energy wall wipes out your **unbanked** loot if it catches you outside the safe zone.

**Current status:** source code ready for a first playtest; not yet playtested in Roblox Studio. The entire starter island is generated when the server script runs.

## Quick start (no extra tools needed)

1. Open Roblox Studio and create a new **Baseplate** experience.
2. In **View**, open **Explorer** and **Output**.
3. In `ReplicatedStorage`, insert a **ModuleScript** called `Config`. Replace its contents with [src/shared/Config.lua](src/shared/Config.lua).
4. In `ServerScriptService`, insert a **Script** called `Main`. Replace its contents with [src/server/Main.server.lua](src/server/Main.server.lua).
5. In `StarterPlayer > StarterPlayerScripts`, insert a **LocalScript** called `HUD`. Replace its contents with [src/client/HUD.client.lua](src/client/HUD.client.lua).
6. Click **Play**. The world should spawn automatically. Interact with glowing objects using **E** (or touch prompts on mobile).
7. Use **File > Publish to Roblox** to save the experience. Keep the experience private until testing is complete.

The server script automatically removes the default template Baseplate so the generated island is visible.

## Recommended longer-term workflow (Rojo + GitHub)

The repository includes [default.project.json](default.project.json) for [Rojo](https://rojo.space/). Install the Rojo CLI and Roblox Studio plugin, clone the repository locally, run `rojo serve` from its folder, then connect via the Studio plugin. Code changes in VS Code can then sync into Studio. Use the **manual setup above first** if this is your first Roblox project.

## First playable loop

- Explore the island and grab glowing junk with a ProximityPrompt.
- Bag capacity starts at 3. Return to **SELL** at the base to turn unbanked loot into coins.
- Buy a larger bag at the **UPGRADE** station.
- Each shared round cycles through **SCAVENGE → WARNING → STORM → RECOVERY**.
- The storm sweeps from the far end of the map toward the base. Stand in the green marked safe zone or escape to it in time.
- If caught outside the base, you lose the items in your bag (not the coins already sold).
- Up to 8 players can share a server; all interactions and rewards are checked on the server.

## Controls

- **WASD** move, **Space** jump.
- **E** interact with nearby items/stations (Roblox shows touch/gamepad prompts as applicable).
- HUD shows money, bag usage, next bag cost, and the shared storm timer.

## Repository layout

```text
default.project.json             Rojo project mapping
src/shared/Config.lua            Balance and item definitions
src/server/Main.server.lua       World, collecting, selling, upgrades, storm
src/client/HUD.client.lua        Player HUD and notices
```

## Important limitations

- **Progress currently resets when you leave.** Persistent DataStore saving is the next milestone once the gameplay is confirmed in Studio.
- Environments use only Roblox Parts, no paid assets or external dependencies.
- No paid products, Robux purchases, pet systems, or random paid rewards.
- This code has not been verified by running a Roblox Studio session from ChatGPT; use Studio **Output** to inspect any runtime errors.
- A public launch should wait for mobile testing, data persistence, anti-exploit review, art polish, and Roblox publishing eligibility checks.

## Playtest checklist

- [ ] Spawn at the safe base.
- [ ] Pick up an item; bag count increases.
- [ ] Full bags block further pickups.
- [ ] Sell items; coins go up and bag empties.
- [ ] Upgrade bag; capacity increases.
- [ ] Escape the storm before it passes; bag stays safe.
- [ ] Get hit by the storm; unbanked bag resets but sold coins remain.
- [ ] Two-player Studio test shows a shared storm and individually tracked coins.

## Next phase

Add reliable persistent player profiles, a more attractive handcrafted island, sound/VFX, first-session onboarding, and analytics **after** a playable test confirms the core loop is fun.
