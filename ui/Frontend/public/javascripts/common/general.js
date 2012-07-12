/* This file is a collection of general and common tools for javascript/jQuery Kanopya UI */

// getMathematicOperator is function that take in input a formula and return the mathemathic operand present in.

function getMathematicOperator(formula) {
    symbols = ['+','-','\/','*','%'];
    var encounteredSymbol;
    // detect if there a math symbol in formula :
    for ( var i=0; i<symbols.length; i++) {
        var nbOfCurrentSymbol = formula.split(/symbols[i]/g).length - 1;
        if ( nbOfCurrentSymbol != 0 ) {
            encounteredSymbol = symbols[i];            
        }
    }
    return encounteredSymbol;
}