// const terms = parseTerms(m.data.tuples());
// const termSting = parsedTermsToString(temp, subscriptText(m));

// constants for our visualization
const baseX = 150;
const baseY = 100;
const timeslotHeight = 80;
const agentWidth = 300;
let boxHeight = 130;
const boxWidth = 200;
const LINE_HEIGHT = 20;
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
const strands = strand.atoms(true);
const messages = Message.atoms(true);
const timeslots = [];

const nextRange = Timeslot.next.tuples().map(x => x.toString());
const first = Timeslot.atoms(true).filter(timeslot => !nextRange.includes(timeslot.toString()))[0];

// putting the timeslots in order
let i;
let curr = first;
for (i = 0; i < Timeslot.atoms(true).length; i++) {
    timeslots.push(curr);
    curr = curr.next;   
}

// map from role -> name
const roles = {}
agent.tuples().forEach(x => {
    let role = x.atoms()[0].toString();
    let name = x.atoms()[1].toString();
    roles[role] = name;
});

// map from Timeslot -> Agent -> [Data]
const learnedInformation = {};
// map from Timeslot -> Agent -> [Data]
const generatedInformation = {};
// map from Timeslot -> Agent -> Boolean
const visibleInformation = {};
// map from Datum -> Message
const dataMessageMap = {};
// map from public key (Datum) -> owner (Agent)
const pubKeyMap = {};
// map from private key (Datum) -> owner (Agent)
const privKeyMap = {};

const agentNames = strands.map(x => x.toString());
const keyNames = Key.atoms(true).map(x => x.toString());

// populating the learnedInformation object
strands.forEach((strand) => {

    let s = strand.toString();

    // grab the learned_times data from the forge spec
    const learned = strand.agent.learned_times.tuples().map(tuple => tuple.atoms());

    learned.map((info) => {
        // unpack the information
        let d = info[0].toString();
        let ts = info[1].toString();

        if (!learnedInformation[ts]) {
            learnedInformation[ts] = {};
        }

        if (!learnedInformation[ts][s]) {
            learnedInformation[ts][s] = [];
        }

        if (ts !== "Timeslot0" || (!agentNames.includes(d) && !keyNames.includes(d))) {
            // store the information in our learnedInformation object
            learnedInformation[ts][s].push(d);
        }
    });

    // grab the generated_times data from the forge spec
    const generated = strand.agent.generated_times.tuples().map(tuple => tuple.atoms());

    generated.map((info) => {
        // unpack the information
        let d = info[0].toString();
        let ts = info[1].toString();

        if (!generatedInformation[ts]) {
            generatedInformation[ts] = {};
        }

        if (!generatedInformation[ts][s]) {
            generatedInformation[ts][s] = [];
        }

        // store the information in our generatedInformation object
        generatedInformation[ts][s].push(d);

    })
});

// populating the visibleInformation object (initializing everything with false)
timeslots.forEach((timeslot) => {
    const ts = timeslot.toString();
    strands.forEach((strand) => {
        const s = strand.toString();

        if (!visibleInformation[ts]) {
            visibleInformation[ts] = {};
        }

        visibleInformation[ts][s] = false;
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

const ltksMap = {};
KeyPairs0.ltks.tuples().forEach(x => {
    let s = x.toString();
    let arr = s.split(", ");
    let key = arr[2];
    let val = arr[0] + " " + arr[1];
    ltksMap[key] = val;
})

const ciphertextMap = {};
plaintext.tuples().forEach((tuple) => {
    let atoms = tuple.atoms();
    let key = atoms[0].toString();
    let val = atoms[1];

    if (!ciphertextMap[key]) {
        ciphertextMap[key] = [];
    }

    ciphertextMap[key].push(val);

    
});

const cipherKeyMap = {};
encryptionKey.tuples().forEach((tuple) => {
    let atoms = tuple.atoms();
    let key = atoms[0].toString();
    let val = atoms[1].toString();

    // TODO: just do the lookup here!!!!!!! :^)
    cipherKeyMap[key] = val;
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
 * a function to get the x coordinate of a given agent
 * @param {Object} agent - an agent prop from the forge spec
 */
function x(agent) {
    return baseX + (agentNames.indexOf(agent.toString()) * agentWidth);
}

/**
 * a function to get the y coordinate of a given timeslot
 * @param {Object} timeslot - a timeslot prop from the forge spec
 */
function y(timeslot) {

    let visibleNum = 0;
    const previousTimeslots = getTimeSlotsBefore(timeslot);

    previousTimeslots.forEach((ts) => {
        // if there is an agent with info visible in this timeslot, count it
        let i;
        let v = false;
        for (i = 0; i < strands.length; i++) {
            let a = strands[i].toString();
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
    return x(m.sender);
}

/**
 * a function to get the ending x coordinate for a message line.
 * This corresponds with the x coordinate of the message RECEIVER.
 * @param {Object} m - a message prop from the forge spec
 */
function messageX2(m) {
    return x(m.receiver);
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

function parsedTermsToString(parsedTerms, key) {

    let s = "{ "

    let i;
    for (i = 0; i < parsedTerms.length; i++) {

        let term = parsedTerms[i];

        if (term["subscript"]) {
            s += parsedTermsToString(term.content, term.subscript);
        } else {
            s += term.content; 
        }

        s += " "
    }

    s += `}[${key}]`

    return s;
}

// TODO: maybe return the objects for the simpler cases
function parseTerms(items) {

    const newItems = items.map((item) => {

        const itemString = item.toString();

        if (pubKeyMap[itemString]) {
            const s = `pubK${pubKeyMap[itemString]}`;
            return {
                content: s
            };
        } else if (itemString.includes("Ciphertext")) {
            const pt = ciphertextMap[itemString];
            const key = cipherKeyMap[itemString]; // in progress see TODO above
            return {
                content: parseTerms(pt),
                subscript: key
            }
        } else {
            return {
                content: itemString
            };
        }
    });

    return newItems;
}

function printParsedTerms(parsedTerms, key, container, x, y) {

    let i;
    for (i = 0; i < parsedTerms.length; i++) {

        let term = parsedTerms[i];

        if (term["subscript"]) {

        } else {

        }

        /*
        const temp = container.append('text')
            .attr('x', x)
            .attr('y', y + h)
            .style('font-family', '"Open Sans", sans-serif')
            .style('fill', color)
            .text(t);

        temp.append('tspan')
            .text(subscript)
            .style('font-size', 12)
            .attr('dx', 5)
            .attr('dy', 5);
*/
    }
}

/**
 * a function to construct the text of a label based on the given message
 * @param {*} m - a message prop from the forge spec 
 * @returns a string containing the text for the label
 */
function labelText(m) {

    const pt = [];
    // grabbing the plaintext for this message's data
    m.data.tuples().forEach(tuple => {

        let datum = tuple.atoms()[0].plaintext.toString();

        if (pubKeyMap[datum]) {
            pt.push(`pubK${pubKeyMap[datum]}`);
        } else if (privKeyMap[datum]) {
            // TODO: would this ever happen?
            pt.push(`privK${privKeyMap[datum]}`);
        } else {
            // funky
            pt.push(datum ? datum : tuple.toString());
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
    let k = m.data.encryptionKey.toString();
    let s;
    if (ltksMap[k]) {
        s = `ltk(${ltksMap[k]})`;
    } else if (pubKeyMap[k]) {
        s = `pubK${pubKeyMap[k]}`;
    } else {
        s = `${k}?`;
    }
    
    return s;
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

    strands.forEach((agent) => {
        const a = agent.toString();
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

//// helper function to find the last space before the given index in the given string
function spaceBefore(string, index) {

    let workingString = string;
    let spaceIndex = -1;
    let done = false;
    
    while(!done) {
        let i = workingString.indexOf(" ");
        if (i !== 0 && i !== -1 && i <= index) {
            spaceIndex = i;
            // replace the first space with an X
            workingString = workingString.slice(0, i) + "X" + workingString.slice(i + 1);
        } else {
            done = true;
        }
    }

    return spaceIndex;
}

function wrapText(container, text, width, x, y, color) {

    if (text === "") {
        return 0;
    }

    // this will be replaced if the text ends up overflowing past the given width
    const textElt = container.append('text')
        .attr('x', x)
        .attr('y', y)
        .style('font-family', '"Open Sans", sans-serif')
        .style('fill', color)
        .text(text);

    const w = textElt.node().getComputedTextLength();
    const r = width / w; // w shouldn't be zero because text is non-empty
    if (r < 1) {

        // remove the original text
        textElt.node().remove();

        // math
        const l = text.length;
        let index = Math.round(r * l);
        const spaceIndex = spaceBefore(text, index);
        index = (spaceIndex === -1) ? index : spaceIndex;
        const before = text.slice(0, index);
        const after = text.slice(index);

        // append the "before" text
        container.append('text')
            .attr('x', x) 
            .attr('y', y)
            .style('font-family', '"Open Sans", sans-serif')
            .style('fill', color)
            .text(before);

        // recur on the "after" text
        return LINE_HEIGHT + wrapText(container, after, width, x, y + LINE_HEIGHT, color);
        
    }

    return LINE_HEIGHT;
  
}

function displayInfo(container, info, x, y, color) {

    let h = 0;

    const {simple, complex} = filterComplexData(info);
    const s = simple.join(" ");

    h += wrapText(container, s, boxWidth - 25, x, y, color);

    let i;
    for (i = 0; i < complex.length; i++) {

        let t = complex[i].content;

        let subscript = complex[i].subscript;

        const temp = container.append('text')
            .attr('x', x)
            .attr('y', y + h)
            .style('font-family', '"Open Sans", sans-serif')
            .style('fill', color)
            .text(t);

        temp.append('tspan')
            .text(subscript)
            .style('font-size', 12)
            .attr('dx', 5)
            .attr('dy', 5);

        h+=LINE_HEIGHT;
    }

    return h;
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
        .attr('x2', baseX + ((strands.length - 1) * agentWidth))
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

    // draw the agents
    const a = d3.select(svg)
        .selectAll('agent')
        .data(strands)
        .join('line')
        .attr('stroke', BLUE)
        .style('stroke-width', 10)
        .attr('x1', x)
        .attr('y1', baseY) 
        .attr('x2', x)
        .attr('y2', y(timeslots[timeslots.length - 1]));

    // label the strands with their names
    const aLabel = d3.select(svg)
        .selectAll('agentLabel')
        .data(strands)
        .join('text')
        .attr('x', x)
        .attr('y', baseY - 40)
        .style('font-family', '"Open Sans", sans-serif')
        .text((a) => {
            return `${a.toString()} (${roles[a.toString()]})`;
        });

        /*
    // label the strands with their roles
    const aLabel2 = d3.select(svg)
        .selectAll('agentLabel')
        .data(strands)
        .join('text')
        .attr('x', x)
        .attr('y', baseY - 60)
        .style('font-family', '"Open Sans", sans-serif')
        .text((a) => roles[a.toString()]);
*/
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
        strands.forEach((agent) => {
            let a = agent.toString();
            if (visibleInformation[ts][a]) {

                const boxX = x(agent) - (boxWidth / 2.0);
                const boxY = y(timeslot) + 30;

                // create a group and give it an id specific to this timeslot-agent pair
                const g = d3.select(svg)
                    .append('g')
                    .attr('id', ts + a);
            
                // append the rect
                const r = g.append('rect')
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

                // collect the new information
                let newInfo = [];
                if (learnedInformation[ts] && learnedInformation[ts][a]) {
                    newInfo = learnedInformation[ts][a];
                }

                // collect the generated information
                let generatedInfo = [];
                if (generatedInformation[ts] && generatedInformation[ts][a]) {
                    generatedInfo = generatedInformation[ts][a];
                    // remove any generated info from newInfo
                    generatedInfo.forEach((x) => {
                        const index = newInfo.indexOf(x);
                        if (index > -1) {
                            newInfo.splice(index, 1);
                        }
                    });
                }

                // collect the old information
                let oldInfo = [];
                const sliceIndex = timeslots.indexOf(timeslot);
                const previousTimeslots = timeslots.slice(0, sliceIndex).map(t => t.toString());
                previousTimeslots.forEach((old_ts) => {
                    if (learnedInformation[old_ts] && learnedInformation[old_ts][a]) {
                        oldInfo = oldInfo.concat(learnedInformation[old_ts][a]);
                    }
                });

                let h = 0;

                h += displayInfo(g, generatedInfo, boxX + 10, boxY + LINE_HEIGHT, BLUE);

                h += displayInfo(g, newInfo, boxX + 10, boxY + LINE_HEIGHT + h, RED);

                h += displayInfo(g, oldInfo, boxX + 10, boxY + LINE_HEIGHT + h, BLACK);

                // TODO: calculate the resulting height and offset the next group of information
                
            } else {
                // remove the group if this timeslot is not supposed to be visible
                d3.select('#' + ts + a).remove(); 
            }
        });
    });

}

render();

