// TODO: determine a better way to test lol

// half step
console.log(halfStep("A3") === "A#3");
console.log(halfStep("A#3") === "B3");
console.log(halfStep("Bb3") === "B3");
console.log(halfStep("B3") === "C4");
console.log(halfStep("B#3") === "C#4");
console.log(halfStep("Cb4") === "C4");
console.log(halfStep("C4") === "C#4");
console.log(halfStep("C#4") === "D4");
console.log(halfStep("Db4") === "D4");
console.log(halfStep("D4") === "D#4");
console.log(halfStep("D#4") === "E4");
console.log(halfStep("Eb4") === "E4");
console.log(halfStep("E4") === "F4");
console.log(halfStep("Fb4") === "F4");
console.log(halfStep("F4") === "F#4");
console.log(halfStep("F#4") === "G4");

// whole step
console.log(wholeStep("C4") === "D4");
console.log(wholeStep("B4") === "C#5");
console.log(wholeStep("D#3") === "F3");

// getValidKey

console.log(getNoteEquiv("C4") === "C4");
console.log(getNoteEquiv("C#4") === "Db4");
console.log(getNoteEquiv("B#3") === "C4");
console.log(getNoteEquiv("Eb5") === "D#5");
console.log(getNoteEquiv("E#3") === "F3");

console.log(getValidKey("C4") === "C4");
console.log(getValidKey("Cb4") === "B3");
