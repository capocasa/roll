import std/[parseutils, random, algorithm]

type
  KeepKind* = enum
    kkNone
    kkHigh
    kkLow

  SidesKind* = enum
    skNumber
    skFudge

  Sides* = object
    case kind*: SidesKind
    of skNumber: count*: int
    of skFudge: discard

  RollSpec* = object
    diceCount*: int
    sides*: Sides
    modifier*: int
    keep*: int
    keepKind*: KeepKind
    explode*: bool

  DieResult* = object
    value*: int
    exploded*: bool

  RollResult* = object
    dice*: seq[DieResult]
    total*: int

proc parseSides(s: string; start: int): tuple[sides: Sides, next: int] =
  if start < s.len and s[start] in {'f', 'F'}:
    result.sides = Sides(kind: skFudge)
    result.next = start + 1
  else:
    var n: int
    let parsed = parseInt(s, n, start)
    if parsed == 0 or n < 1:
      raise newException(ValueError, "expected number of sides")
    result.sides = Sides(kind: skNumber, count: n)
    result.next = start + parsed

proc parse*(input: string): RollSpec =
  var pos = 0
  var diceCount = 1

  if pos < input.len and input[pos] in {'0'..'9'}:
    var n: int
    let parsed = parseInt(input, n, pos)
    if n < 1:
      raise newException(ValueError, "dice count must be positive")
    diceCount = n
    pos += parsed

  if pos >= input.len or input[pos] notin {'d', 'D'}:
    raise newException(ValueError, "expected 'd'")
  inc pos

  let (sides, next) = parseSides(input, pos)
  pos = next

  var explode = false
  if pos < input.len and input[pos] == '!':
    if sides.kind == skFudge:
      raise newException(ValueError, "fudge dice cannot explode")
    explode = true
    inc pos

  var modifier = 0
  if pos < input.len and input[pos] in {'+', '-'}:
    let sign = if input[pos] == '+': 1 else: -1
    inc pos
    var n: int
    let parsed = parseInt(input, n, pos)
    if parsed == 0:
      raise newException(ValueError, "expected number after modifier sign")
    modifier = sign * n
    pos += parsed

  var keep = 0
  var keepKind = kkNone
  if pos < input.len and input[pos] in {'k', 'K'}:
    inc pos
    var n: int
    let parsed = parseInt(input, n, pos)
    if parsed == 0:
      raise newException(ValueError, "expected number after 'k'")
    if n < 1 or n > diceCount:
      raise newException(ValueError, "keep count must be between 1 and dice count")
    keep = n
    pos += parsed
    if pos < input.len and input[pos] in {'h', 'H'}:
      keepKind = kkHigh
      inc pos
    elif pos < input.len and input[pos] in {'l', 'L'}:
      keepKind = kkLow
      inc pos
    else:
      keepKind = kkHigh

  if pos != input.len:
    raise newException(ValueError, "unexpected character at position " & $pos)

  if diceCount > 1000:
    raise newException(ValueError, "too many dice")

  RollSpec(
    diceCount: diceCount,
    sides: sides,
    modifier: modifier,
    keep: keep,
    keepKind: keepKind,
    explode: explode
  )

proc rollDie(sides: Sides): int =
  case sides.kind
  of skNumber:
    rand(1 .. sides.count)
  of skFudge:
    rand(-1 .. 1)

proc roll*(spec: RollSpec): RollResult =
  var dice: seq[DieResult]

  for _ in 1 .. spec.diceCount:
    var val = rollDie(spec.sides)
    var exploded = false
    if spec.explode and spec.sides.kind == skNumber:
      while val == spec.sides.count:
        exploded = true
        let extra = rollDie(spec.sides)
        val += extra
        if extra != spec.sides.count:
          break
    dice.add DieResult(value: val, exploded: exploded)

  var kept = dice
  if spec.keep > 0:
    let sorted = dice.sortedByIt(it.value)
    case spec.keepKind
    of kkHigh:
      kept = sorted[^spec.keep .. ^1]
    of kkLow:
      kept = sorted[0 ..< spec.keep]
    of kkNone:
      discard

  var total = 0
  for d in kept:
    total += d.value
  total += spec.modifier

  RollResult(dice: dice, total: total)
