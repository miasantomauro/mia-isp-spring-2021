const synth = new tone.Synth().toDestination();

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


function playScale(orderedIntervals, startNote) {

  const now = tone.now()
  let note = startNote;

  // play first note
  synth.triggerAttackRelease(note, "8n", now);

  let currInterval;
  let i;
  for (i = 0; i < orderedIntervals.length; i++) {
    currInterval = orderedIntervals[i];
    // if the interval is a half-step...
    if (currInterval.hs._id === "1") {
      note = halfStep(note);
      // if the interval is a whole-step...
    } else if (currInterval.hs._id === "2") {
      note = wholeStep(note);
    }
    // play note!
    synth.triggerAttackRelease(note, "8n", now + (i * .5) + .5);
  }
}

/*
 __   _____ ____  ___ _   _ _  _  ___ _____ ___ ___  _  _ ___ 
 \ \ / /_ _|_  / | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
  \ V / | | / /  | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
   \_/ |___/___| |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/
                                                              
*/

const bottom = 400;
const left = 50;
const w = 30;

function constructOrderedIntervals(intervals, orderedIntervals) {

  const firstInterval = Start0.start;
  let currInterval = firstInterval;
  orderedIntervals.push(firstInterval);

  let i;
  for (i = 0; i < intervals.length; i++) {
    currInterval = currInterval.next;
    orderedIntervals.push(currInterval);
  }
}

function drawStaff() {
  let i;
  for (i = 0; i < 5; i++) {
    let y = bottom - (i * w);
    d3.select(svg)
       .append("line")
       .attr("x1", left)
       .attr("y1", y)
       .attr("x2", left + 500)
       .attr("y2", y)
       .attr("stroke", "black")
  }
}

function drawNotes(orderedIntervals) {
  const x = (interval, index) => {
    return index * w + left + 20;
  }

  const y = (interval, index, array) => {
    let cumulative = 0;
    let i;
    for (i = 0; i <= index; i++) {
      let x = parseInt(orderedIntervals[i].hs._id);
      cumulative += x;
    }
    return bottom - (cumulative * 15) + (w / 2);
  }

  d3.select(svg)
  .selectAll('circle')
  .data(orderedIntervals)
  .join('circle')
  .attr('r', w / 2)
  .attr('cx', x)
  .attr('cy', y)
  .style('stroke', 'black')
  .style('fill', 'white');
}

function constructVisualization(orderedIntervals) {
  drawStaff();
  drawNotes(orderedIntervals)
}

/**
 * TODO: add parameters based on user input(?)
 */
function go(startingNote) {
  const intervals = Interval.atoms(true);
  const orderedIntervals = []
  constructOrderedIntervals(intervals, orderedIntervals);
  constructVisualization(orderedIntervals);
  playScale(orderedIntervals, startingNote)
}

go("E4");
