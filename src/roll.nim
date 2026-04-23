import std/[strutils, random, sequtils, algorithm]
import cligen
from roll/parse import parse, RollSpec, RollResult, DieResult, Sides, KeepKind, skNumber, skFudge, kkNone, kkHigh, kkLow

const Version = staticRead("../roll.nimble").splitLines().filterIt(it.startsWith("version")).
    mapIt(it.split("=")[1].strip().strip(chars = {'"'}))[0]

clCfg.version = Version

const
  ExitUsage = 2

proc die(msg: string, code: int) {.noreturn.} =
  stderr.writeLine msg
  quit code

proc formatDie(d: DieResult; spec: RollSpec; kept: seq[DieResult]): string =
  let isKept = d in kept
  var s = $d.value
  if d.exploded:
    s.add "!"
  if not isKept and spec.keep > 0:
    s = "[" & s & "]"
  s

proc rollOne(input: string) =
  let spec = parse.parse(input)
  let result = parse.roll(spec)

  var kept = result.dice
  if spec.keep > 0:
    let sorted = result.dice.sortedByIt(it.value)
    case spec.keepKind
    of kkHigh:
      kept = sorted[^spec.keep .. ^1]
    of kkLow:
      kept = sorted[0 ..< spec.keep]
    of kkNone:
      discard

  var parts: seq[string]
  for d in result.dice:
    parts.add formatDie(d, spec, kept)
  var line = input & ": " & parts.join(" + ")
  if spec.modifier > 0:
    line.add " + " & $spec.modifier
  elif spec.modifier < 0:
    line.add " - " & $(-spec.modifier)
  line.add " = " & $result.total
  echo line

proc roll*(expressions: seq[string]): int =
  ## Roll dice. Expressions use notation like 2d6, 1d20+5, 4d6k3, 3d6!, 4dF.
  if expressions.len == 0:
    die "roll: expected at least one expression", ExitUsage

  randomize()
  for e in expressions:
    try:
      rollOne(e)
    except ValueError:
      die "roll: invalid expression: " & e, ExitUsage

  0

dispatch roll,
  help = {"expressions" : "dice expressions, e.g. 2d6 1d20+5 4d6k3"},
  short = {"version" : 'v'}
