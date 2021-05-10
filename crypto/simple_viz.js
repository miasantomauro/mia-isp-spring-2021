// constants for our visualization
const baseX = 150;
const baseY = 100;
const timeslotHeight = 80;
const nameWidth = 300;
const boxHeight = 130;
const boxWidth = 200;

// colors
const RED = '#E54B4B';
const BLUE = '#0495C2';
const GREEN = '#19EB0E';
const BLACK = '#000000';

// data from forge spec
const timeslots = Timeslot.atoms(true);
const names = Agent.atoms(true);
const messages = Message.atoms(true);

// map from Datum -> Message
const dataMessageMap = {};
// map from public key (Datum) -> owner (name)
const pubKeyMap = {};
// map from private key (Datum) -> owner (name)
const privKeyMap = {};

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
    return baseY + (timeslots.indexOf(timeslot) * timeslotHeight);
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
        .attr('x', baseX - 90)
        .attr('y', y)
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

}

render();