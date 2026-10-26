# Reel Legends: setup guide for beginners

This guide takes you from "never opened Roblox Studio" to "my game is live and selling".
You don't need to write any code. Each step says roughly how long it takes.

**Total: about 2-3 hours, spread over 2 weeks.** Steps 1-4 fit in your first week.

---

## Step 0. Things you need (15 minutes, once)

1. **A Roblox account.** If you plan to cash out Robux later (DevEx), you must be 13 or older,
   have a verified email, and turn on 2-step verification: roblox.com > Settings > Security.
2. **Roblox Studio** (free). Go to [create.roblox.com](https://create.roblox.com), click
   **Start Creating**, and install Studio. Log in with your Roblox account.

## Step 1. Download the game (2 minutes)

1. Open the GitHub repository for this project.
2. Click the `build` folder, then `ReelLegends.rbxlx`.
3. Click the **Download raw file** button (the arrow pointing down, top right of the file).

That one file contains the whole game: all scripts are already inside it.

## Step 2. Open it and play (10 minutes)

1. Start Roblox Studio and choose **File > Open from File...**, then pick `ReelLegends.rbxlx`.
2. Press the blue **Play** button at the top (or press F5).
3. Wait a moment. The game builds its own world: a hub island with a Fish Market and Rod Shop,
   and three islands to the east connected by bridges.

**Try this to check everything works:**

- [ ] Old Pete's guide appears at the top of the screen, with a golden line pointing where to go.
      Follow it: it covers everything below in about 3 minutes.
- [ ] Move the mouse: the camera turns with it, over your character's shoulder. Scroll to zoom.
      Press **Alt** to get the mouse pointer back (press again to lock it).
- [ ] Press **1** to hold your rod. The text under the dot in the middle of the screen says whether
      you can fish where you're aiming ("Click to cast", "Hotspot!", "Locked", "Aim at the water").
- [ ] Walk to the end of a **Fishing Dock** and cast near the bubbles (a hotspot: faster bites).
- [ ] While the line is out you can't walk. Pressing a movement key reels the line back in.
- [ ] Watch for small **"nibble..."** dips. Don't click on those, or you scare the fish away.
- [ ] When a big **"!"** appears and the bobber plunges, click fast. Too slow and the fish steals your bait.
- [ ] The fight: **hold** the mouse (or Space) to reel. Let go when the tension bar turns red, and
      when it says the fish is about to thrash. Fill the Catch bar to land it.
- [ ] Your character holds the fish over their head. New species and records get confetti.
      Your **level** (top left and above your head) goes up as you catch fish.
- [ ] Press **Q** for your Bag. Mark a fish as a favorite ("Keep?") so it's never sold.
- [ ] Sell at **Marina's Fish Market** (press **E** at the stall). In-demand fish sell for double.
- [ ] **Tackle Tom** sells bait and makes better bait from your spare fish.
- [ ] **Old Pete** has three bounties a day at his board (or press **N**).
- [ ] Fish jump out of the water, seagulls circle overhead, and the lighthouse and boats sit by the hub.

A message saying **"Saving is off"** is normal for now. Step 3 fixes it.

Press the red **Stop** button (Shift+F5) to stop playing.

> If the rod points down into the ground instead of out in front of you, tell me and I'll
> flip it. (It's one number: `ROD_TILT` in `ServerScriptService > Server > FishingService`.)

## Step 3. Publish it to Roblox (10 minutes)

1. In Studio: **File > Publish to Roblox**.
2. Choose **Create new experience**. Name: `Reel Legends` (or your own name). Genre: *Simulation*.
   Leave it **private** for now. Click **Create**.
3. Open **Home > Game Settings > Security** and turn on **Enable Studio Access to API Services**.
   Click **Save**.
4. Press **Play** again, catch a few fish, sell them, then **Stop**. Press **Play** once more:
   your coins are still there. Saving works.

From now on, after any change in Studio, use **File > Publish to Roblox** to update the live game.

## Step 4. Make it look nicer (optional, 30-60 minutes, any time)

The starter world is plain blocks on purpose: it works, and you can dress it up whenever you like.

**Easy way: add decorations.** Open **Toolbox** (View > Toolbox), search for things like
"palm tree", "dock", "lighthouse", "boat", "snow pine", and drag them onto the islands.

- Put decorations in a new folder in Workspace called `Decorations`.
  **Don't** name a folder `Map` (see below).
- **Free models can contain bad scripts.** After adding one, expand it in the Explorer and delete
  anything called `Script` or `LocalScript` inside it, unless you know what it does.

> If you already pasted a `Map` into Workspace before an update, delete it (or rename it) so the
> game can build the newest starter world, then paste it in again if you want to edit it.

**Bigger change: edit the world itself.** The world is built by code each time the game starts,
so you can't click on it until you press Play. To make it permanent and editable:

1. Press **Play**. In the Explorer, find **Workspace > Map**. Right-click it > **Copy**.
2. Press **Stop**. Right-click **Workspace** > **Paste Into**.
3. Now `Map` is saved in your place. The game sees it and stops building its own. You can move,
   recolor, resize or replace anything.

The game finds its important parts by **attributes** (shown at the bottom of the Properties
window). If you rebuild something, copy these onto your new parts:

| Attribute | Value | What it does |
|---|---|---|
| `FishingZone` | `shallows`, `mangroves` or `frostbite` | Invisible flat part on the water. Casting into it catches that zone's fish. |
| `ZoneGate` | zone id | Wall blocking a locked zone. Needs a ProximityPrompt inside. |
| `ZoneSpawn` | zone id, or `hub` | Where the Travel menu drops players. |
| `Station` | `Sell`, `Rods`, `Bait`, `Bounties`, `Leaderboard`, `EventBoard` | Market, rod shop and bait shop counters, the bounty board, and the two info boards. Each needs a ProximityPrompt inside (except the info boards). |
| `VipDoor` | ticked | Door only VIP players can walk through. |
| `Hotspot` | ticked | Bubbling spot on the water. Casting within 12 studs gives faster bites. |
| `Npc` | `OldPete`, `Marina`, `TackleTom` or `Rodney` | Where that character stands, facing the part's front. |
| `GuideTarget` | `Dock` | Where Old Pete's guide line points for the "cast from the dock" step. |

## Step 5. Set up the shop (30 minutes)

The shop only sells looks and time-savers. Nobody can buy fish, luck or coins, so the game stays fair.
Until you do this step, shop items show **"Coming soon"**.

### 5a. Create the 4 game passes

1. Go to [create.roblox.com/dashboard/creations](https://create.roblox.com/dashboard/creations)
   and click your game.
2. In the left menu: **Monetization > Passes > Create a Pass**.
3. Upload an image (any square picture is fine for now; I can describe icons later),
   type the name, click **Create Pass**.
4. Click the new pass > **Sales** > turn on **Item for Sale**, set the price, **Save**.
5. Copy the pass **ID** (the number in the page address, or via the "..." menu > Copy Asset ID).

Make these four (suggested prices in Robux):

| Pass | Price | Description to paste |
|---|---|---|
| VIP | 250 | Golden VIP name tag, a crown, and access to the VIP dock. |
| Auto Sell | 150 | Your bag sells itself when it fills up, wherever you are. |
| Big Bag | 100 | Carry 60 fish instead of 20. |
| Zone Teleporter | 200 | Teleport to any zone you have unlocked. |

### 5b. Create the cosmetic products

In the same left menu: **Monetization > Developer Products > Create a Developer Product**.
Make one for each item below, then copy each product's **ID**.

| Product | Price |
|---|---|
| Golden Rod Skin | 99 |
| Neon Pink Rod Skin | 75 |
| Galaxy Rod Skin | 149 |
| Candy Rod Skin | 49 |
| Ocean Trail | 49 |
| Fire Trail | 75 |
| Rainbow Trail | 129 |
| Title: Big Catch | 25 |
| Title: Fish Whisperer | 49 |
| Title: Sea Legend | 99 |

### 5c. Paste the IDs into the game

1. In Studio's Explorer: **ReplicatedStorage > Shared > Shop**. Double-click it.
2. Each item has `gamePassId = 0` or `productId = 0`. Replace the `0` with the matching ID.
   Example: `gamePassId = 0` becomes `gamePassId = 912345678`.
3. **File > Publish to Roblox**.

Test it: press Play, open **Shop**. Prices appear and buying works. Purchases made inside Studio
are fake and free, so test away.

> Tip: to try every pass in Studio before making them, open **Shared > Config** and set
> `Config.TestPassesInStudio = true`. It never affects the real game.

### 5d. Private servers (2 minutes)

Creator Dashboard > your game > **Monetization > Private Servers** (or Game Settings in Studio) >
turn on, price **50-100 Robux a month**. Players love fishing with just their friends.

**Premium Payouts** need nothing from you: Roblox pays you when Premium members play.

## Step 6. Go live (30 minutes)

1. Creator Dashboard > your game > **Configure**: write a short description, for example:

   > Catch 40+ fish across 3 islands! Fill your Fish Book, upgrade your rod, and hunt this week's
   > legendary fish. New weather every 15 minutes. Rebirth for permanent coin bonuses.

2. Add a game **icon** (512x512) and at least one **thumbnail** (1920x1080). A screenshot of your
   character fishing at sunset works well.
3. Fill in the **Maturity & Compliance questionnaire** (required before going public).
4. In Studio: **Game Settings > Permissions > Playability: Public**. Save.
5. Share the link with friends and ask them to play for 10 minutes. Watch what confuses them.

## Changing the game later

Everything you might want to tweak is in plain lists, no coding needed:

| To change | Open |
|---|---|
| Fish names, rarities, values | `ReplicatedStorage > Shared > Fish` |
| Rod prices and stats | `ReplicatedStorage > Shared > Rods` |
| Bait prices, recipes and bonuses | `ReplicatedStorage > Shared > Bait` |
| How hard fish fight, strike timing | `ReplicatedStorage > Shared > Fight` and the rarity list in `Fish` |
| Bounty rewards | `ReplicatedStorage > Shared > Bounties` |
| Zone unlock prices | `ReplicatedStorage > Shared > Zones` |
| Bag size, rebirth cost, daily reward, weather length | `ReplicatedStorage > Shared > Config` |
| Shop items and IDs | `ReplicatedStorage > Shared > Shop` |

After a change: **File > Publish to Roblox**. Live servers pick it up as they restart; to force it,
Creator Dashboard > your game > "..." > **Shut Down All Servers**.

## Getting updates from me

When I improve the code, I'll tell you exactly which scripts changed. Two ways to get them:

- **Simple:** open that script in Studio, select all (Ctrl+A), and paste the new version from
  GitHub. Then publish.
- **Rojo (optional, saves time once updates get bigger):** install the **Rojo** plugin from the
  Studio Toolbox (Plugins tab), install [Rokit](https://github.com/rojo-rbx/rokit), then run
  `rokit install` and `rojo serve` in this project's folder and click **Connect** in the Rojo
  plugin. Studio's scripts then match the files exactly. Rojo only touches scripts, never your
  world, so your scenery is safe.

## How the game makes money (fairly)

- **Passes and cosmetics** (step 5): one-time purchases that never change which fish you catch.
- **Private servers** (step 5d): small monthly subscriptions.
- **Premium Payouts:** automatic, based on time Premium players spend in your game. Long, relaxed
  fishing sessions are exactly what earns these.

Robux you earn can be cashed out through DevEx once you have 30,000 earned Robux
(about $114), are 13+, and have filled in the tax form in the Creator Dashboard.
