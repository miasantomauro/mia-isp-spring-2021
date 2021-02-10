// clear the svg
d3.selectAll("svg > *").remove();
// set up tone synth
const synth = new tone.Synth().toDestination();

/*
  __  __ _   _ ___ ___ ___   ___ _   _ _  _  ___ _____ ___ ___  _  _ ___
 |  \/  | | | / __|_ _/ __| | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
 | |\/| | |_| \__ \| | (__  | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
 |_|  |_|\___/|___/___\___| |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/

*/

// index corresponds to number of sharps
const SHARP_KEYS = ["G", "D", "A", "E", "B", "F#", "C#"];
// index corresponds to number of flats
const FLAT_KEYS = ["F", "Bb", "Eb", "Ab", "Db", "Gb"];
// index is arbitrary 
const VALID_KEYS = ["C"] + SHARP_KEYS + FLAT_KEYS;
// index corresponds to position of tonic of relative major key
const MODES = ["ionian", "locrian", "aeolian", "mixolydian", "lydian", "phrygian", "dorian"];

/**
 * a function to get the next letter alphabetically after the given letter,
 * wrapping around back to A after G
 * @param {string} letter
 */
function nextLetter(letter) {
    return (letter === "G") ? "A" : String.fromCharCode(letter.charCodeAt(0) + 1);
}

/**
 * a function to get the previous letter alphabetically before the given letter,
 * wrapping around back to G after A
 * @param {string} letter
 */
function previousLetter(letter) {
    return (letter === "A") ? "G" : String.fromCharCode(letter.charCodeAt(0) - 1);
}

/**
 * a function to parse the note notation for the letter, accidental, and octave
 * @param {string} note 
 * @return {string[]} [letter, accidental, octave]
 */
function unpackNote(note) {
    if (note.length === 2) {
        return [note[0], "", note[1]];
    } else if (note.length === 3) {
        return [note[0], note[1], note[2]];
    } else {
        console.log("unsupported note format found in unpackNote: " + note);
    }
}

/**
 * a function to get the note a half-step up from the given note
 * @param {string} note
 */
function halfStep(note) {
    let [letter, accidental, octave] = unpackNote(note);
    // no accidental
    if (accidental === "") {
        if (letter === "B") {
            let newOctave = parseInt(octave) + 1;
            return "C" + newOctave;
        } else if (letter === "E") {
            return "F" + octave;
        } else {
            return letter + "#" + octave;
        }
    // sharp
    } else if (accidental === "#") {
        if (letter === "B") {
            octave = parseInt(octave) + 1;
            return "C#" + octave;
        } else if (letter === "E") {
            return "F#" + octave; 
        } else {
            return nextLetter(letter) + octave; 
        }
    // flat
    } else if (accidental === "b") {
        return letter + octave;
    } else {
        console.log("unsupported note format found in halfStep: " + note);
    }
}

/**
 * a function to get the note a whole step up from the given note
 * @param {string} note
 */
function wholeStep(note) {
    return halfStep(halfStep(note))
}

/**
 * a function to determine if the given interval represents a half step
 * @param {Interval from forge spec} interval 
 */
function isHalfStep(interval) {
    return interval.hs._id === "1";
}

/**
 * a function to, given a starting note and a sequence of intervals, construct a scale
 * @param {Interval[]} intervals 
 * @param {string} startNote 
 * @param {string[]} notes the array to populate with the resulting scale.
 */
function getNotesFromIntervals(intervals, startNote, notes) {

    notes.push(startNote);
  
    let currInterval;
    let currNote = startNote;
    let i;
    for (i = 0; i < intervals.length; i++) {
      currInterval = intervals[i];
      // if the interval is a half-step...
      if (isHalfStep(currInterval)) {
        currNote = halfStep(currNote);   
      } else { // if the interval is a whole-step...
        currNote = wholeStep(currNote);
      }
      notes.push(currNote);
    }
}

/**
 * a function to, given a sequence of intervals, determine the index of the note which represents 
 * the corresponding major key
 * @param {Interval[]} intervals 
 */
function getMajorKeyIndex(intervals) {
  // first interval is half step
  if (isHalfStep(intervals[0])) {
    // either phrygian or locrian
    if (isHalfStep(intervals[3])) {
      return 1; //locrian
    } else if (intervals[3].hs._id === "2") {
      return 5; // phrygian
    }
    // first interval is whole step
  } else {
    // either dorian, aeolian, ionian, lydian, or mixolydian
    if (isHalfStep(intervals[1])) {
      // either dorian, or aeolian
      if (isHalfStep(intervals[4])) {
        return 2; // aeolian
      } else {
        return 6; // dorian
      }
    } else {
      // either ionian, lydian, or mixolydian
      if (isHalfStep(intervals[2])) {
        // ionian or mixolydian
        if (isHalfStep(intervals[6])) {
          return 0; // ionian
        } else {
          return 3; // mixolydian
        }
      } else {
        return 4; //lydian
      }
    }
  }
}


