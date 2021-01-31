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
    const octave = note[2];
    // if the note was flat...
    if (accidental === "b") {
      return letter + octave;
      // if the note was sharp...
    } else if (accidental === "#") {
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
  const intervals = Interval.atoms(true);
  const orderedIntervals = []
  constructOrderedIntervals(intervals, orderedIntervals);
  const notes = [];
  getNotesFromIntervals(orderedIntervals, startNote, notes);
  playScale(notes);
  constructVisualization(notes);

  console.log(orderedIntervals);
  console.log(notes);
}


go("C4");
