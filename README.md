# Crown & Cinder: The Black Octagon

A downloadable desktop dark-fantasy board game prototype for **3–6 players**. One player hosts directly, shares a private invite code, and everyone secretly chooses orders before the turn resolves at once.

The unique shooter-like mechanic is the **Woundline**. Ranged, melee, alchemical, and occult attacks are not simple dice rolls. Players set pull, breath, and lead before firing/striking, and the result combines player aim, attack type, unit skill, range, cover, armor, weather, wounds, and terrain.

## Built features

- Godot desktop project.
- Peer-hosted multiplayer with private invite codes.
- Procedural octagonal board made of hex spaces.
- Traditional tabletop camera with orbit, zoom, pan, and close miniature view.
- Simultaneous secret turn planning and host-authoritative resolution.
- Economy: gold, food, timber, iron, population, influence, faith.
- Territory capture, structures, recruiting, direct tribute/trade, diplomacy, betrayal.
- Brutal combat with permanent death, wounded units, and captured units.
- Dynamic weather, burning terrain, flooding, ash, and board atmosphere.
- Procedural 3D dark-fantasy stand-ins plus a scan-asset pipeline for free realistic assets.

## Run

1. Install Godot 4.x desktop editor.
2. Clone this repository.
3. Open the folder in Godot.
4. Run `res://scenes/Main.tscn`.

## Multiplayer

1. Host clicks **Host Direct Game**.
2. Host gives other players the host IP, port `37172`, and invite code.
3. Guests click **Join Game** and enter that information.
4. Host starts when 3–6 players are connected.

Direct internet hosting may require UDP port forwarding on the host network. LAN play should work with the host machine's local IP.

## Controls

- Left-click a unit or hex.
- Select your unit, then click a reachable hex to move.
- Select your unit, then click an enemy hex/unit to queue a Woundline attack.
- Use the Woundline sliders before queueing attacks.
- Right-drag: orbit.
- Middle-drag: pan.
- Mouse wheel: zoom.
- `F`: close miniature view.
- `Space`: recenter.

## Asset note

Large third-party scan assets are intentionally not committed. Drop reduced `.glb` files into `assets/scans/reduced/` and the project can be extended to instance them. See `docs/ASSET_PIPELINE.md`.
