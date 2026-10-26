# Reel Legends

A relaxing Roblox fishing collection game: cast, catch, sell, upgrade your rod, unlock new
islands and fill your Fish Book.

**New here? Start with [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md).** The ready-to-open game file is
[build/ReelLegends.rbxlx](build/ReelLegends.rbxlx).

## What's in the game

- **43 fish** across 3 zones (Sunny Shallows, Misty Mangroves, Frostbite Bay), 6 rarities from
  Common to Mythic, random weights, and rare **Shiny** variants worth 3x.
- **Fish Book** that tracks every species, how many you caught and your heaviest.
- **8 rods** bought with coins. Better rods raise luck, bite speed and the reel zone size.
- **Reel minigame:** tap when the needle is in the green. Rarer fish need more hits and move faster.
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
src/server/              ServerScriptService.Server
  DataService            loading, saving, leaderstats
  FishingService         casting, bites, catches (server decides the fish)
  EconomyService         selling, rods, zones, rebirths, daily reward, menu actions
  ShopService            game passes and receipt processing
  CosmeticService        titles, trails, rod skins, VIP extras, earned titles
  WorldService           prompts, gates, leaderboard and event boards
  MapBuilder             builds a starter world when Workspace has no "Map"
src/client/              StarterPlayerScripts.Client (all UI is built in code)
tools/build_place.py     builds build/ReelLegends.rbxlx from src/
```

Rebuild the place file after changing scripts:

```
python3 tools/build_place.py      # or: rojo build -o build/ReelLegends.rbxlx
```
