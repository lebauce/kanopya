/**
 * HCM Blocks
 *
 */

'use strict';

Blockly.Blocks['hcm_statistic_function'] = {
  /**
   * Block for advanced math operators with single operand.
   * @this Blockly.Block
   */
  init: function() {
    var FUNCTIONS =
        [['mean', 'MEAN'],
         ['max', 'MAX'],
         ['min', 'MIN'],
         ['std', 'STD']];
    // this.setHelpUrl(Blockly.Msg.MATH_SINGLE_HELPURL);
    this.setColour(230);
    this.setOutput(true, 'Function');
    this.interpolateMsg('%1 %2',
        ['FCT', new Blockly.FieldDropdown(FUNCTIONS)],
        ['NUM', 'Metric', Blockly.ALIGN_RIGHT],
        Blockly.ALIGN_RIGHT);
    // Assign 'this' to a variable for use in the tooltip closure below.
    var thisBlock = this;
    this.setTooltip(function() {
      var mode = thisBlock.getFieldValue('FCT');
      var TOOLTIPS = {
        'MEAN': 'Return the mean.',
        'MAX': 'Return the max.',
        'MIN': 'Return the min.',
        'STD': 'Return the standard deviation.'
      };
      return TOOLTIPS[mode];
    });
  }
};

Blockly.JavaScript['hcm_statistic_function'] = function(block) {
  // Math operators with single operand.
  var stat_function = block.getFieldValue('FCT');
  var code;
  var arg;
  arg = Blockly.JavaScript.valueToCode(block, 'NUM',
        Blockly.JavaScript.ORDER_NONE) || '0';

  // First, handle cases which generate values that don't need parentheses
  // wrapping the code.
  switch (stat_function) {
    case 'MEAN':
      code = 'mean(' + arg + ')';
      break;
    case 'MAX':
      code = 'max(' + arg + ')';
      break;
    case 'MIN':
      code = 'min(' + arg + ')';
      break;
    case 'STD':
      code = 'std(' + arg + ')';
      break;
  }
  if (code) {
    return [code, Blockly.JavaScript.ORDER_FUNCTION_CALL];
  }
};

Blockly.Blocks['hcm_set'] = {
  // y variable setter.
  init: function() {
    this.setHelpUrl(Blockly.Msg.VARIABLES_SET_HELPURL);
    this.setColour(330);
    this.appendValueInput('VALUE')
        .appendField('Formula =');
    this.setTooltip(Blockly.Msg.VARIABLES_SET_TOOLTIP);
  }
};

Blockly.JavaScript['hcm_set'] = function(block) {
  var argument0 = Blockly.JavaScript.valueToCode(block, 'VALUE',
      Blockly.JavaScript.ORDER_ASSIGNMENT) || '';
  return '|' + argument0 + '|';
};

Blockly.Blocks['hcm_metric'] = {
  /**
   * Block for metrics
   * @this Blockly.Block
   */
  init: function() {
    this.setColour(230);
    this.setOutput(true, 'Metric');
    this.appendDummyInput()
        .appendField(new Blockly.FieldDropdown(blocklyHandler.metricBlockList()), 'METRIC');
    this.setTooltip('Return the selected metric.');
  }
};

Blockly.JavaScript['hcm_metric'] = function(block) {
  return blocklyHandler.metricBlockCode(block);
};
