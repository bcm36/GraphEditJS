# Jasmine tests

describe 'GraphEdit', ->

    #grab constructor
    GraphEdit = $.fn.graphEdit.Constructor

    it 'Exists', ->
        ge = new GraphEdit()
        ge.getNodes()
