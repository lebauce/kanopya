var blocklyHandler = {
    
    currentMetricCategory: {},
    metricCategoryList: [],
    metricList: [],

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
        defaultXml += '  <block type="hcm_set" deletable="false" x="85" y="100">';
        defaultXml += '  </block>';
        defaultXml += '</xml>';
        return defaultXml;
    },

    init: function() {

        var this_ = this;

        function loadMetricCategoryList() {
            $.getJSON( "ajax/metric-category.json", function(data) {
                afterLoadMetricCategoryList(data);
            });
        }

        function afterLoadMetricCategoryList(data) {
            this_.metricCategoryList = data;
            this_.currentMetricCategory = this_.metricCategoryList[0];
            loadMetricList();
        }

        function loadMetricList() {
            $.getJSON( "ajax/metric.json", function(data) {
                afterLoadMetricList(data);
            });
        }

        function afterLoadMetricList(data) {
            this_.metricList = data;
            var toolbox = this_.toolbox().replace('[default]', this_.getMetricList()[0].id);
            Blockly.inject($('#blockly-container')[0],
                {path: '/javascripts/vendor/blockly/', toolbox: toolbox});
            this_.setDefaultWorkspace();
            Blockly.addChangeListener(this_.updateOutputFormula);

            var blocklyDiv = $('#blockly-container');
            var onresize = function(e) {
                blocklyDiv.css('width', ($('#metric-editor').css('width') - 40) + 'px');
                blocklyDiv.css('height', ($('#metric-editor').css('height') - 40) + 'px');
            }
            onresize();
            window.addEventListener('resize', onresize);
        }

        loadMetricCategoryList();
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
        var metricList = blocklyHandler.metricList;
        var formula = blocklyHandler.getFormula();

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
        $('#formula').text('Formula = ' + formula);
    },

    setMetricCategory: function(categoryId) {
        this.currentMetricCategory = this.getMetricCategoryById(categoryId);
        this.refreshMetricList();
    },

    refreshMetricList: function() {
        var toolbox = this.toolbox().replace('[default]', this.getMetricList()[0].id);
        Blockly.updateToolbox(toolbox);
    },

    metricBlockList: function() {
        var metricList = this.getMetricList();
        var blockList = [];
        for (var i = 0; i < metricList.length; i++) {
            blockList.push([metricList[i].label, metricList[i].id]);
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

        console.log(formula);
    }

};
