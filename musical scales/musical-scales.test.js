
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

test('nextLetter tests', () => {
    expect(nextLetter("A")).toBe("B");
    expect("A").toBe("A");
  });


