// clear the svg
d3.select(svg).selectAll("*").remove();

// grab data from forge spec
const timeslots = Timeslot.atoms(true);
const agents = Agent.atoms(true);
const messages = Message.atoms(true);

// map from Timeslot -> Agent -> [Data]
const learned_information = {};
// map from Timeslot -> Agent -> Boolean
const visible_information = {};

// populating the learned_information object
agents.forEach((agent) => {
    const learned = agent.learned_times.tuples().map(tuple => tuple.atoms());
    learned.map((info) => {
        let ts = info[1].toString();
        let d = info[0].toString();
        let a = agent.toString();
        if (learned_information[ts]) {
            if (learned_information[ts][a]) {
                learned_information[ts][a].push(d);
            } else {
                learned_information[ts][a] = [d];
            }
        } else {
            learned_information[ts] = {a : [d]};
        }
    });
});

// populating the visible_information object (with all false values)
timeslots.forEach((timeslot) => {
    agents.forEach((agent) => {

        const ts = timeslot.toString();
        const a = agent.toString();

        if (visible_information[ts]) {
            visible_information[ts][a] = false;
        } else {
            visible_information[ts] = {};
            visible_information[ts][a] = false;
        }
    });
});

// set some constants for our visualization
const baseX = 150;
const baseY = 150;
const timeslotHeight = 80;
const agentWidth = 220;
const RED = "#E54B4B";
const BLUE = "#0495c2";
const GREEN = "#19eb0e";

/*
 * Everything in this visualization is aligned along the x axis with an agent, 
 * and aligned along the y axis with a timeslot, so these next two functions will come in handy
 * in a lot of different places!
*/

/**
 * a function to get the x coordinate of a given agent
 * @param {Object} agent - an agent prop from the forge spec
 */
function x(agent) {
    return baseX + (agents.indexOf(agent) * agentWidth);
}

/**
 * a function to get the y coordinate of a given timeslot
 * @param {Object} timeslot - a timeslot prop from the forge spec
 */
function y(timeslot) {
    return baseY + (timeslots.indexOf(timeslot) * timeslotHeight);
}

// add defs to allow for custom fonts!
// ref: (https://stackoverflow.com/questions/21025876/using-google-fonts-with-d3-js-and-svg)
d3.select(svg)
    .append("defs")
    .append("style")
    .attr("type", "text/css")
    .text("@import url('https://fonts.googleapis.com/css?family=Open+Sans:400,300,600,700,800');");

// draw the timeslots
const t = d3.select(svg)
    .selectAll("timeslot") // giving these shapes a name
    .data(timeslots)
    .join("line")
    .attr("x1", baseX)
    .attr("y1", y)
    .attr("x2", baseX + ((agents.length - 1)* agentWidth))
    .attr("y2", y)
    .attr('stroke', 'black')
    .attr('fill', 'white')
    .style("stroke-dasharray", ("5, 3"));

/*
sig Agent extends Datum {
  learned_times: set Datum -> Timeslot
}
*/
function onMouseClick(mouseevent, timeslot) {

    const ts = timeslot.toString();

    agents.forEach((agent) => {

        const a = agent.toString();
        visible = visible_information[ts][a];
        visible_information[ts][a] = !visible;

        if (visible_information[ts][a]) {

            // create a group and give it an id specific to this timeslot-agent pair
            const g = d3.select(svg)
                .append("g")
                .attr("id", ts + a);
        
            // append the rect
            g.append("rect")
                .attr("x", x(agent))
                .attr("y", () => y(timeslot) - 20)
                .attr("width", 50)
                .attr("height", 50)
                .style("fill", "white")
                .style("opacity", .7);
            
            // append the new information
            g.append("text")
                .attr("x", x(agent))
                .attr("y", y(timeslot))
                .style("font-family", '"Open Sans", sans-serif')
                .style('fill', RED)
                .text(learned_information[ts][a]);  

            // collect the old information
            const sliceIndex = timeslots.indexOf(timeslot);
            const previousTimeslots = timeslots.slice(0, sliceIndex).map(t => t.toString());
            let oldInfo = [];
            previousTimeslots.forEach((old_ts) => {
                oldInfo = oldInfo.concat(learned_information[old_ts][a]);
            });

            // append the old information
            g.append("text")
                .attr("x", x(agent))
                .attr("y", () => y(timeslot) + 30)
                .style("font-family", '"Open Sans", sans-serif')
                .text(oldInfo);

        } else {
            // remove the group if this timeslot is not supposed to be visible
            d3.select("#" + ts + a).remove(); 
        }
        
    });      
}

// label the timeslots
const tLabel = d3.select(svg)
    .selectAll("timeslotLabel")
    .data(timeslots)
    .join("text")
    .on("click", onMouseClick)
    .attr("x", baseX - 90)
    .attr("y", y)
    .style("font-family", '"Open Sans", sans-serif')
    .text((t) => t._id); // any time you use a function with data, it's parameter is always the "current" datum

// draw the agents
const a = d3.select(svg)
    .selectAll("agent")
    .data(agents)
    .join("line")
    .attr("stroke", BLUE)
    .style("stroke-width", 10)
    .attr("x1", x)
    .attr("y1", baseY) 
    .attr("x2", x)
    .attr("y2", baseY + ((timeslots.length - 1) * timeslotHeight));

// label the agents
const aLabel = d3.select(svg)
    .selectAll("agentLabel")
    .data(agents)
    .join("text")
    .attr("x", x)
    .attr("y", baseY - 40)
    .style("font-family", '"Open Sans", sans-serif')
    .text((a) => a._id);

/*
 * The following four functions are helpers to determine 
 * the starting and ending coordinates for messages
*/

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
    return y(m.sendTime);
}

/**
 * a function to get the ending y coordinate for a message line.
 * This corresponds with the y coordinate of the RECEIVE time.
 * @param {Object} m - a message prop from the forge spec
 */
function messageY2(m) {
    return y(m.recvTime);
}

/*
 * The Following two functions will be called when certain mouse events are triggered
*/

/**
 * a function to display additional information about the given message
 * @param {Event} e - the js event
 * @param {Object} m - a message prop from the forge spec
 */
function onMouseEnter(e, m) {

    const boxY = baseX + (timeslots.length * timeslotHeight);
    const w = agents.length * agentWidth;

    // grabbing the plaintext for this message's data
    const pt = m.data.tuples().map(tuple => tuple.atoms()[0].plaintext.toString());

    // we can use "this" to refer to the element being hovered
    // change the color of the line to red
    d3.select(this)
        .selectAll("line")
        .attr("stroke", RED);
    

    // red rectangle
    d3.select(this)
        .append("rect")
        .attr("x", baseX)
        .attr("y", boxY)
        .attr("width", w)
        .attr("height", 100)
        .style("fill", RED)
        .style("opacity", .6);

    // message label text 
    d3.select(this)
        .append("text")
        .attr("class", "boxText")
        .attr("x", baseX + 10)
        .attr("y", boxY + 20)
        .style("font-family", '"Open Sans", sans-serif')
        .style("fill", "black")
        .text(m._id);

    // the text for the red box
    const t = `${m.sender._id} sent ${m.data} containing {${pt}} to ${m.receiver._id}`;

    // message data text
    d3.select(this)
        .append("text")
        .attr("class", "boxText")
        .attr("x", baseX + 10)
        .attr("y", boxY + 40)
        .style("font-family", '"Open Sans", sans-serif')
        .style("fill", "black")
        .text(t);
}

/**
 * a function to hide any information that way displayed about the given message
 * @param {Object} m - a message prop from the forge spec
 */
function onMouseLeave(m) {

    // change the color of the line back to green
    d3.select(this)
        .selectAll("line")
        .attr("stroke", GREEN);

    // remove the rectangle
    d3.select(this)
        .select('rect')
        .remove();

    // remove all text
    d3.select(this)
        .selectAll('.boxText')
        .remove();
}

// bind messages to m
const m = d3.select(svg)
    .selectAll("message")
    .data(messages);

// join g to m and give it event handlers
const g = m.join('g')
    .on("mouseenter", onMouseEnter) // "mouseenter" event will now trigger our onMouseEnter function
    .on("mouseleave", onMouseLeave) // "mouseleave" event will now trigger our onMouseLeave function

// draw lines to represent messages
g.append("line")            // append a line (becomes a child of g)
    .attr("x1", messageX1)  // the sender
    .attr("y1", messageY1)  // the time sent
    .attr("x2", messageX2)  // the receiver
    .attr("y2", messageY2) // the time received
    .attr("stroke", GREEN)
    .style("stroke-width", 10);

// functions for rendering arrows 
const arrowX1 = (m) => messageX1(m) > messageX2(m) ? messageX2(m) + 20 : messageX2(m) - 20;
const arrowTopY1 = (m) => messageY2(m) + 20;
const arrowBottomY1 = (m) => messageY2(m) - 20;
const arrowTopY2 = (m) => messageY2(m) - 3;
const arrowBottomY2 = (m) => messageY2(m) + 3;

// forming the top of the arrow
g.append("line")
    .attr("stroke", GREEN)
    .style("stroke-width", 10)
    .attr("x1", arrowX1)
    .attr("y1", arrowTopY1)
    .attr("x2", messageX2)
    .attr("y2", arrowTopY2);

// forming the bottom of the arrow
g.append("line")
    .attr("stroke", GREEN)
    .style("stroke-width", 10)
    .attr("x1", arrowX1)
    .attr("y1", arrowBottomY1)
    .attr("x2", messageX2)
    .attr("y2", arrowBottomY2);

/**
 * a function to compute the x value of a label based on its parent position
 * @returns the computed x value
 */
function labelX() {
    const l = d3.select(this.parentNode).select("line");
    // grabbing the values of the x1, x2, and y1 attributes
    const labelX1 = parseInt(l.attr("x1"));
    const labelX2 = parseInt(l.attr("x2"));
    // calculating and returing the x value for the message's label
    return (labelX1 + labelX2) / 2.0;
}

/**
 * a function to compute the y value of a label based on its parent position
 * @returns the computed y value
 */
function labelY() {
    const l = d3.select(this.parentNode).select("line");
    return parseInt(l.attr("y1")) - 20;
}

/**
 * a function to construct the text of a label based on the given message
 * @param {*} m - a message prop from the forge spec 
 * @returns a string containing the text for the label
 */
function labelText(m) {
    // grabbing the plaintext for this message's data
    const pt = m.data.tuples().map(tuple => tuple.atoms()[0].plaintext.toString());
    // TODO: more formatting (commas)
    const ptString = pt;
    return `{${ptString}}`;
}

/**
 * a function to construct the subscript text of a label
 * @param {*} m - a message prop from the forge spec 
 * @returns a string containing the text for the subscript
 */
function subscriptText(m) {
    return `${m.data.encryptionKey}`;
}

/**
 * a function to center text based on its length
 * @returns a new x value for the text
 */
function centerText() {
    // compute text width     
    const textWidth = this.getComputedTextLength();
    // grab current x value
    const x = d3.select(this).attr("x");
    // re-center text based on textWidth
    return x - (textWidth / 2);
}

// adding labels
const label = g.append("text")
    .attr("x", labelX) // this is temporary
    .attr("y", labelY)
    .style("font-family", '"Open Sans", sans-serif')
    .style("fill", "black")
    .text(labelText);

// subscript for hovering label
label.append('tspan')
    .text(subscriptText)
    .style('font-size', 12)
    .attr('dx', 5)
    .attr('dy', 5);

// center the text over the arrow
label.attr("x", centerText);