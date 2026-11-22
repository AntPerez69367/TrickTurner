# Trick Turner

A lockpicking shop for the WoW Forever client. It watches chat for people asking to
have a box opened and puts each one on a board you can work. It never sends anything
to another player on its own.

## Install

Drop the `TrickTurner` folder into `Interface/AddOns` and restart the client, or
extract a release zip there directly.

## Use

Open the board with `/trick` or `/tt`.

Each request becomes one card showing who asked, which channel they used, which box
they named, and what the box needs against your lockpicking. Hover a card to see the
full message and why it matched. Invite and whisper sit on the card itself; done and
ignore are at the bottom.

**Whisper** types a greeting into your chat box addressed to that customer and stops
there. You press Enter. Nothing is sent for you, ever.

A repeat post from the same customer updates their card rather than adding a second
one. Cards disappear after thirty minutes, and the board holds fifty at most — when it
is full, an untouched card is dropped before one you have already worked.

## Settings

- **Watch chat for lockpicking requests** — the master switch. Right-clicking the
  minimap button does the same thing.
- **Channels** — Trade, General, LookingForGroup, Say, Yell and whispers
  individually. **Other channels** covers custom and server channels, which is where
  the traffic may actually be on this client.
- **Sensitivity** — how much evidence a message needs. Loose catches terse requests
  like `lockbox?` and `rogue pls` at the cost of more noise; Strict wants a full
  sentence. Normal is the default.
- **Hide boxes above my skill** — only hides a card when both the box and your skill
  are known. A card whose box nobody named is never hidden.
- **Alerts** — a sound and a chat line for each new request, throttled per customer so
  a repeat post does not chime twice.
- **Whisper draft** — the greeting typed for you. `%NAME%`, `%BOX%` and `%SKILL%` are
  replaced.

## Commands

- `/tt` — open the board
- `/tt start`, `/tt stop` — watch chat, or do not
- `/tt dev <message>` — score a message and print every signal that fired
- `/tt misses` — messages that named a box but scored too low
- `/tt clear` — empty the board

## How matching works

A message earns points for naming a box, for asking language, for mentioning a rogue
or lockpicking, and for offering a tip. It loses points for dungeon and raid
shorthand. Two things veto a message outright: a seller phrase like `let me open` or
`open your`, and price-per-unit phrasing like `5g each`, which is how competing
locksmiths advertise. Terms match whole words, so `av` cannot match inside
`available`.

Every card shows its own reasoning in the tooltip, and `/tt dev` scores any message
you paste at it. When something is wrong you can see which signal caused it.

Two known gaps, both measured: an advertisement whose only seller markers are phrases
customers also write (`Tips welcome`) reaches the board, and a genuine request that
mentions a dungeon by name can fall below the threshold. `/tt misses` shows the
second kind.

## Worth knowing

It never whispers, invites, or advertises on its own. The click is the product. The
client can also block outgoing messages entirely, and when it does, an action tells
you rather than failing quietly.

## Tests

The matching stage touches no client API, so it runs headless:

```sh
sh tests/run.sh
```

It uses `lua5.1` when one is installed and falls back to the embedded Lua 5.1 in the
Python `lupa` package. Every corpus line is asserted at all three sensitivities.
