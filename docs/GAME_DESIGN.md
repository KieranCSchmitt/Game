# Crown & Cinder — Design Canon

## Pitch

A 3D medieval dark-fantasy economy war board game where 3–6 players secretly plan turns, grow cursed economies, and resolve combat through the **Woundline**, a shooter-inspired aiming system translated onto a tabletop.

## Match loop

1. Players join a private direct-hosted table.
2. The host starts once 3–6 players are seated.
3. A procedural octagonal hex board appears.
4. Every realm begins evenly with a keep, nearby territory, a lord, levy, longbow, and equal resources.
5. Players secretly queue moves, attacks, builds, recruits, tribute, and diplomacy.
6. Orders resolve simultaneously.
7. Income, territory control, permanent deaths, wounds, captures, betrayal, weather, fire, flooding, and ash reshape the board.
8. Highest economy/territory score wins at the target score or turn limit.

## Shooter twist: the Woundline

The Woundline turns board-game attacks into a tactical aiming ritual. Before resolving an attack, the player sets:

- **Pull** — how hard the strike/shot is driven.
- **Breath** — timing and steadiness.
- **Lead** — prediction of distance, movement, wind, and fear.

The host combines those with attack type, skill, armor, cover, range, weather, terrain, wounds, and deterministic turn seed. The result feels like planning a shot rather than rolling a generic die.

## Factions

- Ashen Crown — fallen human kingdom.
- Briar Oath — forest-bound wardens.
- Graveforge — dwarven necro-smiths.
- Moon Reliquary — silver cult knights.
- Hollow Choir — faith-haunted mages.
- Saltwolf March — raiders and privateers.

## Visual target

The board should feel like a physical luxury war table: dark wax, wet wood, mud, iron, bone, stone, fog, and torchlight. The current implementation uses procedural geometry so it runs immediately. The asset pipeline allows realistic scan props to be added later.
