// clear the svg
d3.selectAll("svg > *").remove();

// grab data from forge spec
const timeslots = Timeslot.atoms(true);
const agents = Agent.atoms(true);
const messages = Message.atoms(true);

// set some constants for our visualization
const baseX = 120;
const baseY = 100;
const timeslotHeight = 60;
const agentWidth = 100;
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

// label the timeslots
const tLabel = d3.select(svg)
    .selectAll("timeslotLabel")
    .data(timeslots)
    .join("text")
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
    .attr("y", baseY - 10)
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

    // we can use "this" to refer to the element being hovered!

    // change the color of the line to red
    d3.select(this)
        .select("line")
        .attr("stroke", RED)

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
        .attr("x", baseX + 10)
        .attr("y", boxY + 20)
        .style("font-family", '"Open Sans", sans-serif')
        .style("fill", "black")
        .text(m._id);

    const t = `${m.sender._id} sent ${m.data} to ${m.receiver._id}`;

    // message data text
    d3.select(this)
        .append("text")
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
        .select("line")
        .attr("stroke", GREEN);

    // remove the rectangle
    d3.select(this)
        .select('rect')
        .remove();

    // remove all text
    d3.select(this)
        .selectAll('text')
        .remove();
    
    // the reason we don't just select remove all the children is because
    // the line representing the message is also a child of this
}

// draw the messages
const m = d3.select(svg)
    .selectAll("message")
    .data(messages)
    .join("g") // this is just a container
    .on("mouseenter", onMouseEnter) // "mouseenter" event will now trigger our onMouseEnter function
    .on("mouseleave", onMouseLeave) // "mouseleave" event will now trigger our onMouseLeave function
    .append("line") // append a line (becomes a child of g)
    .attr("stroke", GREEN)
    .style("stroke-width", 10)
    .attr("x1", messageX1) // the sender
    .attr("y1", messageY1) // the time sent
    .attr("x2", messageX2) // the receiver
    .attr("y2", messageY2); // the time received