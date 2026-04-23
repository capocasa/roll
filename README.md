# roll

A little dice roller for the terminal. Supports standard notation, keep/drop, exploding dice, and Fudge dice. No network, no database, no config — just entropy.

## Install

```
nimble install roll
```

Or build from source:

```
nimble build
```

## Usage

```
roll 2d6                # two six-sided dice
roll d20                # one die, count defaults to 1
roll 1d20+5             # attack roll with modifier
roll 4d6k3              # D&D stat roll: 4d6 keep highest 3
roll 4d6k1l             # keep lowest 1
roll 3d6!               # exploding dice (reroll max)
roll 4dF                # Fudge / Fate dice
roll 2d8 1d6+2          # multiple expressions in one go
roll -v                 # show version
```

### Notation

| Syntax | Meaning |
|--------|---------|
| `NdS` | N dice with S sides |
| `+X` / `-X` | modifier added to total |
| `kN` | keep N highest (default) |
| `kNh` | keep N highest (explicit) |
| `kNl` | keep N lowest |
| `!` | exploding dice — reroll and add on max value |
| `dF` | Fudge dice: sides are -1, 0, +1 |

Dropped dice are shown in brackets. Exploded dice are marked with `!`.

## Examples

```
$ roll 4d6k3
4d6k3: 5 + [2] + 3 + 5 = 13

$ roll 1d20+5
1d20+5: 14 + 5 = 19

$ roll 3d6!
3d6!: 1 + 4 + 6! = 12

$ roll 4dF
4dF: 1 + -1 + 0 + 1 = 1
```

## Exit codes

| Code | Meaning |
|------|---------|
| 2 | invalid usage or expression |

## License

MIT
