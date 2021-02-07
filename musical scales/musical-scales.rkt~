#lang forge

/*
  Synthesis of (western) musical scales

  Nim Telson Spring 2021 Logic for Systems

  ASSUMPTIONS
  -----------
  * standard western music-theory setting (unsure if we need to assume 12-TET?)
  * The intervals are all that matter, not the tones
  * intervals are always ascending, and are always of H, W, or WH lengths
*/

option sb 250 -- give more power to eliminate isomorphic solutions

-- An interval corresponds to a number of half-steps
abstract sig Interval {
  hs: one Int,
  next: one Interval
}
sig W extends Interval {}
sig H extends Interval {}

-- In Alloy, we'd say "one sig Start in Interval {}"
one sig Start {
  start: one Interval
}

pred intervalSizes {
  all s: W | s.hs = sing[2]
  all s: H | s.hs = sing[1]
}

pred intervalsPartitionOctave {
   -- forgetting to convert h.hs to an intexpr produces a confusing error
  (sum s: Interval | sum[s.hs]) = 12
  all s: Interval | Interval in s.^next
-- could I instead add an inst bound saying that next is linear?
  all s: next.Interval | one next[s]
}

pred limitAdjacencies {
  -- But aren't these limits a bit arbitrary?
  all s: H | next[s] not in H    
}

pred synthesize {
  intervalSizes
  intervalsPartitionOctave  
  limitAdjacencies
}

pred diatonic {
  #W = 5
  #H = 2
  Interval = W + H -- robust to adding 3-semitone WH, etc.
}

-- not used in main spec, testing function in this setting
fun mytest[i: Interval]: set Interval {
    {i2: Interval | i.hs = i2.hs}
}

--------------------------------------------------------------------------------

-- Make sure that Forge can count to 12! (not factorial)
-- bitwidth=3: 8 ints [-4, 3]
-- bitwidth=4: 16 ints [-8, 7]
-- bitwidth=5: 32 ints [-16, 15]

-- Also, assumption that there are 8 tones in the scale

run {
  synthesize
  diatonic
} for 7 Interval, 5 Int
, 7 H, 7 W -- Note that RIGHT NOW we need explicit subsig bounds or very confusing unsat


--------------------------------------------------------------------------------
-- Testing
--------------------------------------------------------------------------------

inst ionian {
  H = H2 + H6
  W = W0 + W1  +  W3 + W4 + W5
  Interval = W0 + W1 + H2 + W3 + W4 + W5 + H6
  start = Start0->W0
  next = W0 -> W1 +
         W1 -> H2 +
         H2 -> W3 +
         W3 -> W4 +
         W4 -> W5 +
         W5 -> H6 +
         H6 -> W0
}

test expect {
   -- Note well: currently it is *REQUIRED* to give the W, H, Interval numeric bounds
   --  (as of Dec 19 2020). Without Interval, you get an error. Without W and H, you get unsat.
   --  NT thinks this is a bug in bounds-generation.

ionianGenerated: {synthesize diatonic} for 7 W, 7 H, 7 Interval, 5 Int for ionian is sat
}