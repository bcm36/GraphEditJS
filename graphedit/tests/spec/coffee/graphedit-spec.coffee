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

