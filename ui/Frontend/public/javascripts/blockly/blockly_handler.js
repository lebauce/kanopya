var blocklyHandler = {

    currentMetricCategory: {},
    metricCategoryList: [],
    metricList: [],
    statisticFunctionList: [],
    options: {},
    formula: '',

    getMetricCategoryById: function(id) {
        var resultList = this.metricCategoryList.filter(function(obj) {
          return obj.id === id;
        });
        return resultList[0];
    },

    getMetricList: function(metricCategoryId) {
        metricCategoryId = metricCategoryId || null;
        var categoryId = metricCategoryId || this.currentMetricCategory.id;
        var resultList;
        if (categoryId < 0) {
            resultList = this.metricList;
        } else {
            resultList = this.metricList.filter(function(obj) {
                return obj.categoryId === categoryId;
            });
        }
        return resultList;
    },

    toolbox: function() {
        var toolbox = '<xml>';
        toolbox += '  <block type="hcm_metric"><field name="METRIC">[default]</field></block>';
        toolbox += '  <block type="hcm_statistic_function"><field name="FCT">MEAN</field></block>';
        toolbox += '  <block type="math_arithmetic"><field name="OP">ADD</field></block>';
        toolbox += '  <block type="math_number"><field name="NUM"></field></block>';
        toolbox += '</xml>';
        return toolbox;
    },

    defaultWorkspaceXml: function() {
        var defaultXml = '<xml>';
        defaultXml += '  <block type="hcm_set" deletable="false" x="20" y="100">';
        defaultXml += '  </block>';
        defaultXml += '</xml>';
        return defaultXml;
    },

    init: function(metricCategoryData, metricData, statisticFunctionData, options) {

        var this_ = this;

        this.metricCategoryList = metricCategoryData['metric-category'];
        this.currentMetricCategory = this.metricCategoryList[0];
        this.metricList = metricData;
        this.statisticFunctionList = statisticFunctionData;
        this.options = options;

        var metricList = this.getMetricList();
        var defaultMetricId = (metricList.length > 0) ? metricList[0].id : ''; 
        var toolbox = this.toolbox().replace('[default]', defaultMetricId);
        Blockly.inject($('#blockly-container')[0],
            {path: '/javascripts/vendor/blockly/', toolbox: toolbox});
        this.setDefaultWorkspace();
        Blockly.addChangeListener(this.updateOutputFormula);

        var metricCategory = $('#metric-category');
        metricCategory.change(function() {
            var categoryId = parseInt(metricCategory.val(), 10);
            this_.setMetricCategory(categoryId);
        });
        metricCategory.trigger('change');
    },

    setDefaultWorkspace: function() {
        var xml = Blockly.Xml.textToDom(this.defaultWorkspaceXml());
        Blockly.Xml.domToWorkspace(Blockly.mainWorkspace, xml);
    },

    getFormula: function() {
        var code = Blockly.JavaScript.workspaceToCode();

        var startIndex = code.indexOf('|') + 1;
        var endIndex = code.indexOf('|',startIndex);

        return code.substring(startIndex, endIndex);
    },

    updateOutputFormula: function() {
        var formula = blocklyHandler.getFormula();

        if (this.formula === formula) {
            return;
        };
        this.formula = formula;

        var metricList = blocklyHandler.metricList;

        var startIndex, endIndex, metricId, resultList;
        while ((startIndex = formula.indexOf('[')) > -1) {
            startIndex += 1;
            endIndex = formula.indexOf(']', startIndex);
            metricId = formula.substring(startIndex, endIndex)
            resultList = metricList.filter(function(obj) {
                return obj.id === metricId;
            });
            formula = formula.replace('[' + metricId + ']', resultList[0].label);
        }
        $('#metric-formula').text('Formula = ' + formula);

        if (blocklyHandler.options.changeFormula && typeof blocklyHandler.options.changeFormula == 'function') {
            blocklyHandler.options.changeFormula.call(null);
        }
    },

    setMetricCategory: function(categoryId) {
        this.currentMetricCategory = this.getMetricCategoryById(categoryId);
        this.refreshMetricList();
    },

    refreshMetricList: function() {
        var metricList = this.getMetricList();
        var defaultMetricId = (metricList.length > 0) ? metricList[0].id : '';
        var toolbox = this.toolbox().replace('[default]', defaultMetricId);
        Blockly.updateToolbox(toolbox);
    },

    metricBlockList: function() {
        var metricList = this.getMetricList();
        var blockList = [];
        if (metricList.length === 0) {
            blockList.push([]);
        } else {
            for (var i = 0; i < metricList.length; i++) {
                blockList.push([metricList[i].label, metricList[i].id]);
            }
        }
        return blockList;
    },

    statisticFunctionBlockList: function() {
        var blockList = [];
        for (var i = 0; i < this.statisticFunctionList.length; i++) {
            blockList.push([this.statisticFunctionList[i].label, this.statisticFunctionList[i].id]);
        };
        return blockList;
    },

    metricBlockCode: function(block) {
        // var metricList = this.getMetricList(-1);
        // var fieldValue = block.getFieldValue('METRIC');
        // var resultList = metricList.filter(function(obj) {
        //     return obj.id === fieldValue;
        // });
        // return [resultList[0].label, Blockly.JavaScript.ORDER_ATOMIC];

        return ['[' + block.getFieldValue('METRIC') + ']', Blockly.JavaScript.ORDER_ATOMIC];
    },

    saveWorkspace: function() {
        // var xml = Blockly.Xml.workspaceToDom(Blockly.mainWorkspace);
        // var xml_text = Blockly.Xml.domToText(xml);

        var formula = blocklyHandler.getFormula();
        formula = formula.replace(/[\[\]]+/g, '');
    }

};
