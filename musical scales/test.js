// TODO: determine a better way to test lol

// half step
console.log(halfStep("B3") === "C4");
console.log(halfStep("E3") === "F3");
console.log(halfStep("F3") === "F#3");
console.log(halfStep("C4") === "C#4");

// whole step
console.log(wholeStep("C4") === "D4");
console.log(wholeStep("B4") === "C#5");
console.log(wholeStep("D#3") === "F3");