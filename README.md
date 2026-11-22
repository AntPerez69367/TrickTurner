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

- **Watch chat for lockpicking requests** — the master switch. **Stop** and **Start**
  in the window header do the same thing, as does right-clicking the minimap button
  or `/tt stop` and `/tt start`. While stopped nothing is read from chat at all.
- **Channels** — one switch per server channel you are joined to, read from
  `GetChannelList` when you open the options. Custom, community and greyed-out
  channels are left out: they report no zone channel ID, and nothing on them is read.
  General, Trade, Services and TradeLocal start on, anything else off. Switches are
  keyed by channel name, not by the `/1 /2 /3` slot, which shifts as channels are
  joined and left.
- **Say**, **Yell** and **Whispers** — separate switches, since they are not channels.
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
shorthand. Two things veto a message outright: a provider phrase like `let me open`,
`open your` or `tips appreciated`, and price-per-unit phrasing like `5g each`, which
is how competing locksmiths advertise. Terms match whole words, so `av` cannot match inside
`available`.

Every card shows its own reasoning in the tooltip, and `/tt dev` scores any message
you paste at it. When something is wrong you can see which signal caused it.

One known gap: a genuine request that names a dungeon can fall below the threshold,
because dungeon names are strong reject signals. `/tt misses` shows those.

## Tuning

The **Tuning** tab holds two things. **Weight needed to raise a job** is the raw score
a message must reach, as a number rather than the three presets, and it shares the
same setting as Sensitivity on the Options tab.

**Log anything scoring at least** is a separate, lower bar for what gets recorded.
Matches are always kept; this decides how far below the job weight to keep looking, so
you can see the requests that nearly made it. Set it to 0 to keep everything with any
signal at all.

Below the two sliders is the log itself, newest first: the sender, the channel, the
score, whether it matched, was vetoed as a competitor advertisement, or fell below the
weight, and the player's own words. Each row has **+** and **-** to mark whether the
verdict was right; clicking the same one again clears the mark. The last 300 entries
and your marks are kept across sessions in `TrickTurnerDB`, so the text, the score and
your opinion sit together and the weights can be changed against real traffic rather
than guesses. **Clear** empties it.

## Worth knowing

It never whispers, invites, or advertises on its own. The click is the product. The
client can also block outgoing messages entirely, and when it does, an action tells
you rather than failing quietly.
