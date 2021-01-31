// clear the svg
d3.selectAll("svg > *").remove();
// set up tone synth
const synth = new tone.Synth().toDestination();
// this is kind of arbitrary ? but needed for now
const lowestNote = "C4";

/*
  __  __ _   _ ___ ___ ___   ___ _   _ _  _  ___ _____ ___ ___  _  _ ___
 |  \/  | | | / __|_ _/ __| | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
 | |\/| | |_| \__ \| | (__  | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
 |_|  |_|\___/|___/___\___| |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/

*/
const SHARP_KEYS = ["G", "D", "A", "E", "B", "F#", "C#"];
const FLAT_KEYS = ["Gb", "Db", "Ab", "Eb", "Bb", "F"];
const VALID_KEYS = ["C"] + SHARP_KEYS + FLAT_KEYS;

/**
 * a function to get the next letter alphabetically after the given letter,
 * wrapping around back to A after G
 * @param {*} letter
 */
function nextLetter(letter) {
  if (letter === "G") {
    return "A";
  } else {
    return String.fromCharCode(letter.charCodeAt(0) + 1);
  }
}

/**
 * a function to get the next letter alphabetically after the given letter,
 * wrapping around back to G after A
 * @param {*} letter
 */
function previousLetter(letter) {
  if (letter === "A") {
    return "G";
  } else {
    return String.fromCharCode(letter.charCodeAt(0) - 1);
  }
}

/**
 * a function to get the note a half-step up from the given note
 * @param {*} note
 */
function halfStep(note) {
  // if the note does not contain any accidentals...
  if (note.length === 2) {
    // extract out the letter and the octave
    const letter = note[0];
    const octave = note[1];
    // special case for B and E
    if (letter === "B") {
      let newOctave = parseInt(octave) + 1;
      return "C" + newOctave;
    } else if (letter === "E") {
      return "F" + octave;
      // regular case
    } else {
      return letter + "#" + octave;
    }
    // if the note contains accidentals...
  } else if (note.length === 3) {
    // extract out the letter, accidental, and octave
    const letter = note[0];
    const accidental = note[1];
    let octave = note[2];
    // if the note was flat...
    if (accidental === "b") {
      return letter + octave;
      // if the note was sharp...
    } else if (accidental === "#") {
      if (letter === "B") {
        octave = parseInt(octave) + 1;
        return "C#" + octave;
      }
      return nextLetter(letter) + octave;
    }
  }
}

/**
 * a function to get the note a whole step up from the given note
 * @param {*} note
 */
function wholeStep(note) {
  return halfStep(halfStep(note))
}

// use the indexes from functions below tell you which mode you're in
// for example, if the corresponding major key's tonic is the first note, you're in ionian
// if the corresponding major key's tonic is the second note, you're in locrian
const modes = ["ionian", "locrian", "aeolian", "mixolydian", "lydian", "phrygian", "dorian"];

function isHalfStep(interval) {
  return interval.hs._id === "1";
}

/**
 * given a sequence of intervals, determines the index of the note which represents the corresponding major key
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

/**
 * given a sequence of intervals, determines the index of the note which represents the corresponding minor key
 * @param {*} intervals 
 */
function getMinorKeyIndex(intervals) {
  const maj = getMajorKeyIndex(intervals);
  return (maj + 5) % 7;
}


function getNoteEquiv(note) {
  if (note.length === 3) {
    const letter = note[0];
    const accidental = note[1];
    const octave = note[2];
    if (accidental === "#") { 
      if (letter === "E") {
        return "F" + octave;
      } else if (letter === "B") {
        const newOctave = parseInt(octave) + 1;
        return "C" + newOctave;
      } else {
        return nextLetter(letter) + "b" + octave;
      }
    } else if (accidental === "b") {
      if (letter === "F") {
        return "E" + octave;
      } else if (letter === "C") {
        const newOctave = parseInt(octave) - 1;
        return "B" + newOctave;
      } else {
        return previousLetter(letter) + "#" + octave;
      }
    }
  } else {
    return note;
  }
}

/**
 * a function to remove the octave from the given note
 * @param {} note 
 */
function truncNote(note) {
  let truncatedNote;
  if (note.length === 2) {
    truncatedNote = note[0];
  } else {
    truncatedNote = note[0] + note[1];
  }
  return truncatedNote;
}

/**
 * given an arbitrary key, return an equivalent one that is one the circe of fifths
 * @param {*} key 
 */
function getValidKey(key) {
  const truncatedKey = truncNote(key);
  
  if (VALID_KEYS.includes(truncatedKey)) {
    return key;
  } else {
    return getNoteEquiv(key);
  }
}

function keyUsesSharps(key) {
  const truncatedKey = truncNote(key);
  return SHARP_KEYS.includes(truncatedKey);
}

function keyUsesFlats(key) {
  let truncatedKey;
  if (key.length === 2) {
    truncatedKey = key[0];
  } else {
    truncatedKey = key[0] + key[1];
  }
  return FLAT_KEYS.includes(truncatedKey);
}

function fitNotesToKey(key, notesApprox, notes) {
  let toReplace = [];
  if (keyUsesSharps(key)) {
    toReplace.push("b");
  } else if (keyUsesFlats(key)) {
    toReplace.push("#")
  } else {
    toReplace.push("b");
    toReplace.push("#");
  }

  let i;
  for (i = 0; i < notesApprox.length; i++) {
    let currNote = notesApprox[i];
    if (currNote.length === 3) {
      if (toReplace.includes(currNote[1])) {
        currNote = getNoteEquiv(currNote);
      }
    }
    notes.push(currNote);
  }
}

/*
  ___  ___  _   _ _  _ ___    ___ _   _ _  _  ___ _____ ___ ___  _  _ ___
 / __|/ _ \| | | | \| |   \  | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
 \__ \ (_) | |_| | .` | |) | | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
 |___/\___/ \___/|_|\_|___/  |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/

*/

function getNotesFromIntervals(intervals, startNote, notes) {

  notes.push(startNote);

  let currInterval;
  let currNote = startNote;
  let i;
  for (i = 0; i < intervals.length; i++) {
    currInterval = intervals[i];
    // if the interval is a half-step...
    if (currInterval.hs._id === "1") {
      currNote = halfStep(currNote);
      notes.push(currNote);
      // if the interval is a whole-step...
    } else if (currInterval.hs._id === "2") {
      currNote = wholeStep(currNote);
      notes.push(currNote);
    }
  }
}


function playScale(notes) {

  const now = tone.now()

  let i;
  for (i = 0; i < notes.length; i++) {
    synth.triggerAttackRelease(notes[i], "8n", now + (i * .5));
  }
}

/*
 __   _____ ____  ___ _   _ _  _  ___ _____ ___ ___  _  _ ___
 \ \ / /_ _|_  / | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
  \ V / | | / /  | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
   \_/ |___/___| |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/

*/

const bottom = 400;
const left = 100;
const w = 25;
const margin = 30;

function constructOrderedIntervals(intervals, orderedIntervals) {

  const firstInterval = Start0.start;
  let currInterval = firstInterval;
  orderedIntervals.push(firstInterval);

  let i;
  for (i = 0; i < intervals.length - 1; i++) {
    currInterval = currInterval.next;
    orderedIntervals.push(currInterval);
  }
}

function drawStaff() {
  let i;
  for (i = 0; i < 5; i++) {
    let y = bottom - (i * w) - w;
    d3.select(svg)
       .append("line")
       .attr("x1", left)
       .attr("y1", y)
       .attr("x2", left + 500)
       .attr("y2", y)
       .attr("stroke", "black")
  }
}

function noteToY(note) {

  let offset = 0;
  let letter;
  let octave;

  if (note.length === 2) {
    letter = note[0];
    octave = note[1];
  } else if (note.length === 3) {
    letter = note[0];
    const accidental = note[1];
    octave = note[2];

  }

  const lowestOctave = parseInt(lowestNote[1]);
  offset += (7 * (octave - lowestOctave));

  const letterCharCode = letter.charCodeAt(0);
  const lowestCharCode = lowestNote.charCodeAt(0);

  if (letterCharCode > lowestCharCode) {
    offset += letterCharCode - lowestCharCode;
  } else if (letterCharCode < lowestCharCode) {
    offset += 7 - (lowestCharCode - letterCharCode)
  }

  return bottom - (w * (offset / 2))

}

function drawNotes(notes) {
  const x = (note, index) => {
    return index * (w + margin) + left + 20; // todo replace 20 with width of treble clef
  }

  const y = (note, index) => {
    return noteToY(note);
  }

  const accX = (note, index) => {
	  return x(note, index) - 36;
  }

  const accY = (note, index) => {
	  return y(note, index) + 5;
  }

  const acc = (note) => {
    if (note.length === 3) {
      const accidental = note[1];
      if (accidental === "#") {
        return "#"
      } else if (accidental === "b") {
        return "♭"
      }
    }
    return ""
  }

  const circles = d3.select(svg)
  .selectAll('ellipse')
  .data(notes)
  .join('ellipse')
  .attr('rx', w / 2 + 5)
  .attr('ry', w / 2)
  .attr('cx', x)
  .attr('cy', noteToY)
  .style('stroke', 'black')
  .style('fill', 'white');

  const accidentals = d3.select(svg)
  .selectAll('text')
  .data(notes)
  .join('text')
  .attr('x', accX)
  .attr('y', accY)
  .style("font", "24px times")
  .text(acc);
}

function constructVisualization(notes) {
  drawStaff();
  drawNotes(notes)
}

/**
 * TODO: add parameters based on user input(?)
 */
function go(startNote) {

  // constructing ordered array of intervals
  const intervals = Interval.atoms(true);
  const orderedIntervals = []
  constructOrderedIntervals(intervals, orderedIntervals);

  // constructing the notes array
  const notesApprox = [];
  getNotesFromIntervals(orderedIntervals, startNote, notesApprox);

  // adjusting the notes based on the key signature
  const majIndex = getMajorKeyIndex(orderedIntervals);
  const majKeyApprox = notesApprox[majIndex];
  const majKey = getValidKey(majKeyApprox);

  // reconstruct the notes array
  const notes = [];
  fitNotesToKey(majKey, notesApprox, notes);

  // playing the scale out loud
  playScale(notes);

  // rendering the scale on the staff
  constructVisualization(notes);

  console.log("This is " + notes[0] + " " + modes[majIndex]);
  console.log("which is in the key of " + truncNote(majKey) + " major");

}

go("C4");
