# Jasmine tests

describe 'GraphEdit', ->

  #grab constructor
  GraphEdit = $.fn.graphEdit.Constructor

  test_nodes = [{'node_id':123}, {'node_id':456}]
  test_edges = [{'src':123, 'dest':456, 'label':'abc', 'myproperty':true}]

  #simulate DOM element via bootstrap plugin
  element = document.createElement('div')

  it 'Exists', ->
    ge = new GraphEdit()

  it 'Gives back the right nodes when added on construction', ->
    ge = new GraphEdit(element, {nodes: test_nodes})
    nodes = ge.getNodes()
    expect(nodes).toEqual test_nodes

  it 'Gives back the right nodes when added with "addNode"', ->
    ge = new GraphEdit(element)

    for node in test_nodes
      ge.addNode(node)

    nodes = ge.getNodes()
    expect(nodes).toEqual test_nodes

  it 'Gives back the right edges when added with "addEdge"', ->
    ge = new GraphEdit(element, {nodes: test_nodes})

    for edge in test_edges
      ge.addEdge(edge)

    edges = ge.getEdges()
    expect(edges).toEqual test_edges
