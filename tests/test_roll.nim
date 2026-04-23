import std/[unittest, algorithm]
import roll/parse

test "parse basic dice":
  let spec = parse("2d6")
  check spec.diceCount == 2
  check spec.sides.kind == skNumber
  check spec.sides.count == 6
  check spec.modifier == 0
  check spec.keep == 0
  check spec.explode == false

test "parse single die default count":
  let spec = parse("d20")
  check spec.diceCount == 1
  check spec.sides.count == 20

test "parse with modifier":
  let spec = parse("3d8+2")
  check spec.diceCount == 3
  check spec.modifier == 2

test "parse with negative modifier":
  let spec = parse("1d6-1")
  check spec.modifier == -1

test "parse keep highest":
  let spec = parse("4d6k3")
  check spec.diceCount == 4
  check spec.keep == 3
  check spec.keepKind == kkHigh

test "parse keep lowest explicit":
  let spec = parse("4d6k1l")
  check spec.keep == 1
  check spec.keepKind == kkLow

test "parse exploding":
  let spec = parse("3d6!")
  check spec.explode == true
  check spec.sides.count == 6

test "parse fudge":
  let spec = parse("4dF")
  check spec.diceCount == 4
  check spec.sides.kind == skFudge

test "parse fudge lowercase":
  let spec = parse("df")
  check spec.diceCount == 1
  check spec.sides.kind == skFudge

test "parse invalid missing d":
  expect ValueError:
    discard parse("26")

test "parse invalid fudge explode":
  expect ValueError:
    discard parse("2dF!")

test "parse invalid keep count":
  expect ValueError:
    discard parse("2d6k3")

test "roll basic dice":
  let spec = parse("2d6")
  let r = roll(spec)
  check r.dice.len == 2
  for d in r.dice:
    check d.value in 1..6
  check r.total >= 2
  check r.total <= 12

test "roll fudge dice":
  let spec = parse("4dF")
  let r = roll(spec)
  check r.dice.len == 4
  for d in r.dice:
    check d.value in -1..1
  check r.total >= -4
  check r.total <= 4

test "roll keep high reduces total dice":
  let spec = parse("4d6k3")
  let r = roll(spec)
  check r.dice.len == 4
  # total should be sum of top 3
  let sorted = r.dice.sortedByIt(it.value)
  let expected = sorted[1].value + sorted[2].value + sorted[3].value
  check r.total == expected

test "roll with modifier":
  let spec = parse("1d6+5")
  let r = roll(spec)
  check r.total >= 6
  check r.total <= 11
  check r.total == r.dice[0].value + 5
