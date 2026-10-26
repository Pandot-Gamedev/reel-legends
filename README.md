# Reel Legends

A relaxing Roblox fishing collection game: cast, catch, sell, upgrade your rod, unlock new
islands and fill your Fish Book.

**New here? Start with [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md).** The ready-to-open game file is
[build/ReelLegends.rbxlx](build/ReelLegends.rbxlx).

## What's in the game

- **43 fish** across 3 zones (Sunny Shallows, Misty Mangroves, Frostbite Bay), 6 rarities from
  Common to Mythic, random weights, and rare **Shiny** variants worth 3x.
- **Fish Book** that tracks every species, how many you caught and your heaviest.
- **8 rods** bought with coins. Better rods raise luck and bite speed, and make the reeling fight easier.
- **Old Pete's guide** for new players: step-by-step goals with a golden line to follow.
- **Lively hub:** shopkeepers (Marina, Tackle Tom, Rodney, Old Pete), fishing docks with lanterns,
  bubbling hotspots, boats, a lighthouse, jumping fish and seagulls.
- **Angler level** shown above your head, with coin rewards per level. Catches are held up over
  your head for everyone to see; new species and records get confetti.
- **Over-the-shoulder camera** that follows the mouse (Alt frees the cursor); phones keep touch controls.
- **Fishing that needs attention:** fake nibbles tempt you to strike early, the real bite gives you
  under a second to strike or the fish steals your bait, then a **tension fight**: hold to reel,
  ease off before the line snaps, and let go when the fish thrashes. Rarer fish fight harder.
- **Bag with favorites:** keep the fish you like; favorites are never sold or used up.
- **Fish Market** with per-fish selling and rotating **in-demand fish** that sell for double.
- **Bait & Tackle:** buy bait with coins or make better bait out of fish you caught. Bait boosts
  bite speed, luck, shiny or legendary chances, and a fish that bites eats it.
- **Old Pete's daily bounties:** three fish requests a day, paying 3x market price plus bait.
- **Hub island** with a Fish Market, Rod Shop, global "most fish caught" leaderboard, event board
  and a VIP dock.
- **Rebirths:** reset coins, rods and zones for a permanent +25% coins per rebirth.
- **Weekly legendary fish** that rotate every Monday (00:00 UTC), plus **weather** that changes
  every 15 minutes (rain, fog, storms, golden hour) with small free boosts for everyone.
- **Daily login reward** with a 7-day streak, and free **earned titles** for completing zones.
- **Saving** with DataStores (session locking, autosave, safe shutdown).
- Works on PC, phone and console (tap, click, Space or gamepad A).

## Monetization (never pay-to-win)

| Item | Type | Effect |
|---|---|---|
| VIP | Game pass | Golden name tag, crown, VIP dock, golden bobber |
| Auto Sell | Game pass | Bag sells itself when full |
| Big Bag | Game pass | 60 fish instead of 20 |
| Zone Teleporter | Game pass | Teleport to unlocked zones |
| Rod skins, trails, titles | Developer products | Looks only |
| Private servers | Monthly | Play with friends only |

Nothing sold for Robux affects which fish you catch, your luck, or your coins per fish.

## Project layout (Rojo)

```
default.project.json     Rojo project: maps src/ into the game
src/shared/              ReplicatedStorage.Shared (used by server and players)
  Config.luau            bag size, rebirth cost, daily reward, timings
  Fish.luau              every fish and rarity
  Rods.luau, Zones.luau  rods and zones
  Shop.luau              game pass and product ids (fill these in)
  Events.luau            weekly legendary + weather, computed from the clock
  Fight.luau             reeling fight rules (shared so the server can check catches)
  Bait.luau              bait list, prices and recipes
  Market.luau            sell prices and in-demand fish
  Bounties.luau          daily bounty generation and rewards
  Level.luau             angler XP and levels
  Tutorial.luau          Old Pete's guide steps
  FishModel.luau         builds 3D fish from parts
src/server/              ServerScriptService.Server
  DataService            loading, saving, leaderstats
  FishingService         casting, bites, catches (server decides the fish)
  EconomyService         market, bait, bounties, rods, zones, rebirths, daily reward
  ShopService            game passes and receipt processing
  CosmeticService        titles, trails, rod skins, VIP extras, earned titles
  WorldService           prompts, gates, leaderboard and event boards
  TutorialService        moves players through Old Pete's guide
  NpcService             spawns the shopkeepers
  MapBuilder             builds a starter world when Workspace has no "Map"
src/client/              StarterPlayerScripts.Client (all UI is built in code, plus the camera)
tools/build_place.py     builds build/ReelLegends.rbxlx from src/
tools/make_store_art.py  draws the game icon, thumbnails and shop icons into store/
```

Rebuild the place file after changing scripts:

```
python3 tools/build_place.py      # or: rojo build -o build/ReelLegends.rbxlx
```
