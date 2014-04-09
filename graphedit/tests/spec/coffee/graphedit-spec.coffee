# Jasmine tests

describe 'GraphEdit', ->

  #grab constructor
  GraphEdit = $.fn.graphEdit.Constructor

  test_nodes = [{'node_id':123}, {'node_id':456}]
  test_edges = [{'src':123, 'dest':456, 'label':'abc', 'myproperty':true}]

  beforeEach ->
    #simulate DOM element via bootstrap plugin
    @element = document.createElement('div')

  afterEach ->
    $(@element).remove()

  it 'Exists', ->
    ge = new GraphEdit()
    expect(ge).toBeDefined()

  it 'Gives back the right nodes when added on construction', ->
    ge = new GraphEdit(@element, {nodes: test_nodes})
    nodes = ge.getNodes()
    expect(nodes).toEqual test_nodes

  it 'Gives back the right nodes when added with "addNode"', ->
    ge = new GraphEdit(@element)

    for node in test_nodes
      ge.addNode(node)

    nodes = ge.getNodes()
    expect(nodes).toEqual test_nodes

  it 'Gives back the right edges when added with "addEdge"', ->
    ge = new GraphEdit(@element, {nodes: test_nodes})

    for edge in test_edges
      ge.addEdge(edge)

    edges = ge.getEdges()
    expect(edges).toEqual test_edges

  it 'Renders the right number of nodes and edges', ->
    ge = new GraphEdit(@element)
    for node in test_nodes
      ge.addNode(node)
    for edge in test_edges
      ge.addEdge(edge)

    expect($(@element).find('.node').length).toBe test_nodes.length
    expect($(@element).find('.link').length).toBe test_edges.length

  it 'Save new node properties', ->
    ge = new GraphEdit(@element, {nodes: test_nodes, edges: test_edges})
    test_nodes[0]

    #click first node
    svg_elt = $(@element).find('.node').first()

    event = document.createEvent("MouseEvents");
    event.initMouseEvent("mousedown",true,true)
    svg_elt.get(0).dispatchEvent(event)

    #add property in form

    $(@element).find('.graphedit-add-property').trigger('click')

    $(@element).find('.graphedit-new-property').find('input').first().val("test_prop")
    $(@element).find('.graphedit-new-property').find('input').last().val("test_val")

    console.log $(@element).find('.graphedit-save-properties')
    
    $(@element).find('.graphedit-save-properties').trigger('click')
    #form = $(@element).find('form.graphedit-property-form')
    #submitCallback = jasmine.createSpy()
    #form.submit(submitCallback);
    #expect(submitCallback).toHaveBeenCalled()

    #check results
    console.log ge.getNodes()
