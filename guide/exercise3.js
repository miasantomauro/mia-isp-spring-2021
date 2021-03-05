/*
  ____  _   ___                _      _             ___             _   _               _           _  _   _       _    
 |__ / (_) / __|_  _ _ __ _ __| |_  _(_)_ _  __ _  | __|  _ _ _  __| |_(_)___ _ _  ___ | |_ ___    /_\| |_| |_ _ _( )___
  |_ \  _  \__ \ || | '_ \ '_ \ | || | | ' \/ _` | | _| || | ' \/ _|  _| / _ \ ' \(_-< |  _/ _ \  / _ \  _|  _| '_|/(_-<
 |___/ (_) |___/\_,_| .__/ .__/_|\_, |_|_||_\__, | |_| \_,_|_||_\__|\__|_\___/_||_/__/  \__\___/ /_/ \_\__|\__|_|   /__/
                    |_|  |_|     |__/       |___/                                                                                     
*/

// this clears the svg that Sterling provides to us
d3.selectAll("svg > *").remove();

// grabbing Shape from instance variables
const listOfShapes = Shape.atoms(true);

const start = 0;    // the position of the first rect
const width = 50;   // the width of each rect
const margin = 10;  // the space between each rect

/**
 * a function to calculate the x coordinate of a given list item
 * @param {Object} listItem a member of listOfShapes, a Shape from the forge model
 */
function x(listItem) {
    // gets the index of the given listItem in listOfShapes
    const i = listOfShapes.indexOf(listItem);
    // calculates and returns the x position based on the index and other constants
    return i * (rectWidth + margin) + start;
}

d3.select(svg)
    .selectAll("myShape")   
    .data(listOfShapes)     
    .join("rect")           
    .attr("x", x)           // supplying a function here         
    .attr("y", 0)           
    .attr("width", width)   // using our width constant from above
    .attr("height", 0)
