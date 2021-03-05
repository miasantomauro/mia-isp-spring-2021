/*
  _   _   _____   _____ _    
 / | (_) / __\ \ / / __( )___
 | |  _  \__ \\ V / (_ |/(_-<
 |_| (_) |___/ \_/ \___| /__/
                             
*/

// this clears the svg that Sterling provides to us
d3.selectAll("svg > *").remove();

// declaring some constants so we can easily use color later. This is just vanilla javascript.
const RED = "#E54B4B";
const BLUE = "#0495c2";
const GREEN = "#19eb0e";

// the following code selects the svg, appends a rectangle to it, 
// then specifies attributes and styles for that rectangle
d3.select(svg)              // select the svg 
    .append("rect")         // append a rectangle element to the selected element (the svg)
    .attr("x", 10)          // give the rect an x coordinate
    .attr("y", 10)          // give the rect a y coordinate
    .attr("width", 150)     // give the rect a width
    .attr("height", 100)    // give the rect a height
    .style("fill", RED);    // give the rect a fill color (RED is declared in line 5)