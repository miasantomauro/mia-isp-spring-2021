// TODOs
// - better text formatting (https://github.com/d3plus/d3plus/wiki/Text-Wrapping)
// - dropped / tampered messages (?)

// constants for our visualization
const baseX = 150;
const baseY = 100;
const timeslotHeight = 80;
const nameWidth = 300;
let boxHeight = 130;
const boxWidth = 200;
const RED = '#E54B4B';
const BLUE = '#0495C2';
const GREEN = '#19EB0E';
const BLACK = '#000000';

// add defs to allow for custom fonts!
// ref: (https://stackoverflow.com/questions/21025876/using-google-fonts-with-d3-js-and-svg)
d3.select(svg)
    .append('defs')
    .append('style')
    .attr('type', 'text/css')
    .text("@import url('https://fonts.googleapis.com/css?family=Open+Sans:400,300,600,700,800');");

// data from forge spec
const timeslots = Timeslot.atoms(true);
const names = name.atoms(true);
const messages = Message.atoms(true);

// map from Timeslot -> name -> [Data]
const learnedInformation = {};
// map from Timeslot -> name -> [Data]
const generatedInformation = {};
// map from Timeslot -> name -> Boolean
const visibleInformation = {};
// map from Datum -> Message
const dataMessageMap = {};
// map from public key (Datum) -> owner (name)
const pubKeyMap = {};
// map from private key (Datum) -> owner (name)
const privKeyMap = {};

const nameNames = names.map(x => x.toString());
const keyNames = Key.atoms(true).map(x => x.toString());

// populating the learnedInformation object
names.forEach((name) => {

    let a = name.toString();

    // grab the learned_times data from the forge spec
    const learned = name.learned_times.tuples().map(tuple => tuple.atoms());

    learned.map((info) => {
        // unpack the information
        let d = info[0].toString();
        let ts = info[1].toString();

        if (!learnedInformation[ts]) {
            learnedInformation[ts] = {};
        }

        if (!learnedInformation[ts][a]) {
            learnedInformation[ts][a] = [];
        }

        if (ts !== "Timeslot0" || (!nameNames.includes(d) && !keyNames.includes(d))) {
            // store the information in our learnedInformation object
            learnedInformation[ts][a].push(d);
        }
    });

    // grab the generated_times data from the forge spec
    const generated = name.generated_times.tuples().map(tuple => tuple.atoms());

    generated.map((info) => {
        // unpack the information
        let d = info[0].toString();
        let ts = info[1].toString();

        if (!generatedInformation[ts]) {
            generatedInformation[ts] = {};
        }

        if (!generatedInformation[ts][a]) {
            generatedInformation[ts][a] = [];
        }

        // store the information in our generatedInformation object
        generatedInformation[ts][a].push(d);

    })
});

// populating the visibleInformation object (initializing everything with false)
timeslots.forEach((timeslot) => {
    const ts = timeslot.toString();
    names.forEach((name) => {
        const a = name.toString();

        if (!visibleInformation[ts]) {
            visibleInformation[ts] = {};
        }

        visibleInformation[ts][a] = false;
    });
});

// populating the dataMessageMap object
data.tuples().forEach((tuple) => {
    let m = tuple.atoms()[0];
    let d = tuple.atoms()[1].toString();
    dataMessageMap[d] = m;
});

// populating privKeyMap
KeyPairs0.owners.tuples().forEach(x => {
    let atoms = x.atoms();
    let key = atoms[0].toString();
    let owner = atoms[1].toString();
    privKeyMap[key] = owner;
});

// populating pubKeyMap
KeyPairs0.pairs.tuples().forEach(x => {
    let atoms = x.atoms();
    let private = atoms[0].toString();
    let public = atoms[1].toString();
    let owner = privKeyMap[private]; 
    pubKeyMap[public] = owner;
});

/**
 * gets the names of the timeslots before the given one
 * @param {*} timeslot - a Timeslot prop from the forge spec
 * @returns an array of strings
 */
function getTimeSlotsBefore(timeslot) {
    const sliceIndex = timeslots.indexOf(timeslot);
    return timeslots.slice(0, sliceIndex).map(t => t.toString());
}

/**
 * a function to get the x coordinate of a given name
 * @param {Object} name - an name prop from the forge spec
 */
function x(name) {
    return baseX + (names.indexOf(name) * nameWidth);
}

/**
 * a function to get the y coordinate of a given timeslot
 * @param {Object} timeslot - a timeslot prop from the forge spec
 */
function y(timeslot) {

    let visibleNum = 0;
    const previousTimeslots = getTimeSlotsBefore(timeslot);

    previousTimeslots.forEach((ts) => {
        // if there is an name with info visible in this timeslot, count it
        let i;
        let v = false;
        for (i = 0; i < names.length; i++) {
            let a = names[i].toString();
            if (visibleInformation[ts][a]) {
                v = true;
            }
        }
        if (v) {
            visibleNum++;
        }
    });
 
    return baseY + (timeslots.indexOf(timeslot) * timeslotHeight) + (visibleNum * boxHeight);
}

/**
 * a function to get the starting x coordinate for a message line. 
 * This corresponds with the x coordinate of the message SENDER.
 * @param {Object} m - a message prop from the forge spec
 */
 function messageX1(m) {
    return x(m.sender.agent);
}

/**
 * a function to get the ending x coordinate for a message line.
 * This corresponds with the x coordinate of the message RECEIVER.
 * @param {Object} m - a message prop from the forge spec
 */
function messageX2(m) {
    return x(m.receiver.agent);
}

/**
 * a function to get the starting y coordinate for a message line.
 * This corresponds with the y coordinate of the SEND time.
 * @param {Object} m - a message prop from the forge spec
 */
function messageY1(m) {
    return y(m.sendTime); // TODO
}

/**
 * a function to get the ending y coordinate for a message line.
 * This corresponds with the y coordinate of the RECEIVE time.
 * @param {Object} m - a message prop from the forge spec
 */
function messageY2(m) {
    return y(m.sendTime); // Y1 and Y2 are sendTime because of model change 
}

/**
 * a function to compute the x value of a label based on its parent's position
 * @returns the computed x value
 */
function labelX() {
    const l = d3.select(this.parentNode).select('line');
    // grabbing the values of the x1, x2, and y1 attributes
    const labelX1 = parseInt(l.attr('x1'));
    const labelX2 = parseInt(l.attr('x2'));
    // calculating and returing the x value for the message's label
    return (labelX1 + labelX2) / 2.0;
}

/**
 * a function to compute the y value of a label based on its parent's position
 * @returns the computed y value
 */
function labelY() {
    const l = d3.select(this.parentNode).select('line');
    return parseInt(l.attr('y1')) - 20;
}

/**
 * a function to construct the text of a label based on the given message
 * @param {*} m - a message prop from the forge spec 
 * @returns a string containing the text for the label
 */
function labelText(m) {
    // grabbing the plaintext for this message's data
    const pt = m.data.tuples().map(tuple => {
        let datum = tuple.atoms()[0].plaintext.toString();
        if (pubKeyMap[datum]) {
            return `pubK${pubKeyMap[datum]}`;
        } else if (privKeyMap[datum]) {
            // TODO: would this ever happen?
            return `privK${privKeyMap[datum]}`;
        } else {
            return datum;
        }
    });
    // TODO: more formatting (commas) ?
    const ptString = pt;
    return `{${ptString}}`;
}

/**
 * a function to construct the subscript text of a label
 * @param {*} m - a message prop from the forge spec 
 * @returns a string containing the text for the subscript
 */
function subscriptText(m) {
    let pubKey = m.data.encryptionKey.toString();
    let owner = pubKeyMap[pubKey];
    return `pubK${owner}`;
}

/**
 * a function to center text based on its length
 * @returns a new x value for the text
 */
function centerText() {
    // compute text width     
    const textWidth = this.getComputedTextLength();
    // grab current x value
    const x = d3.select(this).attr('x');
    // re-center text based on textWidth
    return x - (textWidth / 2);
}

function onMouseClick(mouseevent, timeslot) {
    const ts = timeslot.toString();

    names.forEach((name) => {
        const a = name.toString();
        visible = visibleInformation[ts][a];
        visibleInformation[ts][a] = !visible;
    });
    
    render();
}

// check if its an encripted message, public key, or private key
function replaceDatum(d) {
    if (dataMessageMap[d]) {
        let m = dataMessageMap[d];
        return {
            content: labelText(m),
            subscript: subscriptText(m)
        };
    } else if (pubKeyMap[d]) {
        return {
            content: `pubK${pubKeyMap[d]}`
        };
    } else if (privKeyMap[d]) {
        // TODO: would this ever happen?
        return {
            content: `privK${privKeyMap[d]}`
        };
    } else {
        return {
            content: d
        };
    }
}

function filterComplexData(textArray) {

    const simple = [];
    const complex = [];

    textArray.forEach((d) => {

        let replaced = replaceDatum(d);

        if ('subscript' in replaced) {
            complex.push(replaced);
        } else {
            simple.push(replaced.content);
        }

    });

    return {simple, complex};
}

function formatText(container, startX, startY, textArray, color) {

    const filtered = filterComplexData(textArray);

    // split the text so that there is no more than 3 items per line
    const infoPerLine = 3;
    const lineHeight = 20;
    const numberOfLines = Math.ceil(filtered.simple.length / infoPerLine) + filtered.complex.length;

    let line;
    for (line = 0; line < numberOfLines; line++) {

        let rangeStart = line * infoPerLine;
        let rangeEnd = line * infoPerLine + infoPerLine;

        const lineContents = filtered.simple.slice(rangeStart, rangeEnd);

        // append the old information
        const text = container.append('text')
            .attr('x', startX)
            .attr('y', () => startY + (lineHeight * line))
            .style('font-family', '"Open Sans", sans-serif')
            .style('fill', color)
            .text(lineContents);
    }

    let simpleLines = 0
    if (filtered.simple.length > 0) {
        simpleLines = line - 1;
    }

    // FOR each thing in complex, give it it's own line
    for (line = 0; line < filtered.complex.length; line++) {
        let currInfo = filtered.complex[line];
        const text = container.append('text')
            .attr('x', startX)
            .attr('y', () => startY + (lineHeight * (simpleLines + line)))
            .style('font-family', '"Open Sans", sans-serif')
            .style('fill', color)
            .text(currInfo.content);

        text.append('tspan')
            .text(currInfo.subscript)
            .style('font-size', 12)
            .attr('dx', 5)
            .attr('dy', 5);
    }

    return numberOfLines * lineHeight;
}

function render() {
    // clear the svg
    d3.select(svg).selectAll('*').remove();

    // draw the timeslots
    const t = d3.select(svg)
        .selectAll('timeslot') // giving these shapes a name
        .data(timeslots)
        .join('line')
        .attr('x1', baseX)
        .attr('y1', y)
        .attr('x2', baseX + ((names.length - 1) * nameWidth))
        .attr('y2', y)
        .attr('stroke', BLACK)
        .attr('fill', 'white')
        .style('stroke-dasharray', ('5, 3'));

    // label the timeslots
    const tLabel = d3.select(svg)
        .selectAll('timeslotLabel')
        .data(timeslots)
        .join('text')
        .on('click', onMouseClick)
        .attr('x', baseX - 90)
        .attr('y', y)
        .style('font-family', '"Open Sans", sans-serif')
        .style('cursor', 'pointer')
        .text((t) => t._id);

    // draw the names
    const a = d3.select(svg)
        .selectAll('name')
        .data(names)
        .join('line')
        .attr('stroke', BLUE)
        .style('stroke-width', 10)
        .attr('x1', x)
        .attr('y1', baseY) 
        .attr('x2', x)
        .attr('y2', y(timeslots[timeslots.length - 1]));

    // label the names
    const aLabel = d3.select(svg)
        .selectAll('nameLabel')
        .data(names)
        .join('text')
        .attr('x', x)
        .attr('y', baseY - 40)
        .style('font-family', '"Open Sans", sans-serif')
        .text((a) => a._id);

    // bind messages to m
    const m = d3.select(svg)
        .selectAll('message')
        .data(messages);

    // join g to m and give it event handlers
    const g = m.join('g');

    // draw lines to represent messages
    g.append('line')            // append a line (becomes a child of g)
        .attr('x1', messageX1)  // the sender
        .attr('y1', messageY1)  // the time sent
        .attr('x2', messageX2)  // the receiver
        .attr('y2', messageY2) // the time received
        .attr('stroke', GREEN)
        .style('stroke-width', 10);

    // functions for rendering arrows 
    const arrowX1 = (m) => messageX1(m) > messageX2(m) ? messageX2(m) + 20 : messageX2(m) - 20;
    const arrowTopY1 = (m) => messageY2(m) + 20;
    const arrowBottomY1 = (m) => messageY2(m) - 20;
    const arrowTopY2 = (m) => messageY2(m) - 3;
    const arrowBottomY2 = (m) => messageY2(m) + 3;

    // forming the top of the arrow
    g.append('line')
        .attr('stroke', GREEN)
        .style('stroke-width', 10)
        .attr('x1', arrowX1)
        .attr('y1', arrowTopY1)
        .attr('x2', messageX2)
        .attr('y2', arrowTopY2);

    // forming the bottom of the arrow
    g.append('line')
        .attr('stroke', GREEN)
        .style('stroke-width', 10)
        .attr('x1', arrowX1)
        .attr('y1', arrowBottomY1)
        .attr('x2', messageX2)
        .attr('y2', arrowBottomY2);

    // adding labels
    const label = g.append('text')
        .attr('x', labelX) // this is temporary
        .attr('y', labelY)
        .style('font-family', '"Open Sans", sans-serif')
        .style('fill', BLACK)
        .text(labelText);

    // subscript for hovering label
    label.append('tspan')
        .text(subscriptText)
        .style('font-size', 12)
        .attr('dx', 5)
        .attr('dy', 5);

    // center the text over the arrow
    label.attr('x', centerText);

    timeslots.forEach((timeslot) => {
        let ts = timeslot.toString();
        names.forEach((name) => {
            let a = name.toString();
            if (visibleInformation[ts][a]) {

                const boxX = x(name) - (boxWidth / 2.0);
                const boxY = y(timeslot) + 30;

                // create a group and give it an id specific to this timeslot-name pair
                const g = d3.select(svg)
                    .append('g')
                    .attr('id', ts + a);
            
                // append the rect
                g.append('rect')
                    .attr('x', boxX)
                    .attr('y', boxY)
                    .attr('width', boxWidth)
                    .attr('height', boxHeight)
                    .attr('rx', 6)
                    .attr('ry', 6)
                    .style('fill', 'white')
                    .style('opacity', .8)
                    .attr('stroke', BLUE)
                    .attr('stroke-width', '3');

                let textHeight = 20;

                let newInfo = [];
                if (learnedInformation[ts] && learnedInformation[ts][a]) {
                    newInfo = learnedInformation[ts][a];
                }

                // fetch any generated information and remove it from newInfo
                if (generatedInformation[ts] && generatedInformation[ts][a]) {
                    const generatedInfo = generatedInformation[ts][a];
                    generatedInfo.forEach((x) => {

                        const index = newInfo.indexOf(x);
                        if (index > -1) {
                            newInfo.splice(index, 1);
                        }
                    });

                    // display the generated info in green
                    textHeight += formatText(g, boxX + 5, boxY + textHeight, generatedInfo, GREEN);
                    textHeight += 20;
                }
                
                if (newInfo) {
                    // display the new info in red
                    textHeight += formatText(g, boxX + 5,  boxY + textHeight, newInfo, RED);
                    textHeight += 20;
                }
    
                // collect the old information
                const sliceIndex = timeslots.indexOf(timeslot);
                const previousTimeslots = timeslots.slice(0, sliceIndex).map(t => t.toString());
                let oldInfo = [];
                previousTimeslots.forEach((old_ts) => {
                    oldInfo = oldInfo.concat(learnedInformation[old_ts][a]);
                });

                // display the old info over multiple lines
                textHeight += formatText(g, boxX + 5, boxY + textHeight, oldInfo, BLACK);
                textHeight += 20;

                // TODO: set boxHeight to be the max of itself and textHeight + 20 or something ?
    
            } else {
                // remove the group if this timeslot is not supposed to be visible
                d3.select('#' + ts + a).remove(); 
            }
        });
    });

}

render();