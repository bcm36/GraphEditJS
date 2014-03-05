$ = window.jQuery

"use strict"

# GRAPHEDIT CLASS DEFINITION
# =========================
class GraphEdit
  constructor: ( element, options ) ->
    $el = $(element)

    $el.append """
    <div class="row">
      <div class="col-sm-8">
        <div class="row">
          <div class="graphedit-graph"></div>
        </div>
        <div class="row">
          <div class="col-sm-12"><div class="graphedit-toolbar"></div></div>
        </div>
      </div>
      <div class="col-sm-4"><div class="graphedit-dataview"></div></div>
    </div>
    """

    @TOOLBAR = $el.find('.graphedit-toolbar')
    @GRAPH = $el.find('.graphedit-graph')
    @DATAVIEW = $el.find('.graphedit-dataview')

    me = @

    @renderToolbar()

    # config
    @width = @GRAPH.innerWidth()
    @height = 500
    @colors = d3.scale.category10()

    # state vars
    @scale = 0
    @translate = 0
    @selected_nodes = []
    @selected_edges = []
    @mousedown_node = false

    @zoom = d3.behavior.zoom().scaleExtent([.1,8]).on "zoom", @redraw

    # init visual
    @canvas = d3
      .select @GRAPH.get(0)
      .append "svg"
      .on "click", () ->
        if not ( d3.event.target.classList.contains("node") or \
                d3.event.target.classList.contains("link"))
          me.clearSelection()

    @svg = @canvas
      .attr "width", @width
      .attr "height", @height
      .attr "viewBox", "0 0 " + @width + " " + @height
      .attr "preserveAspectRatio", "xMidYMid meet"
      .attr "pointer-events", "all"
      .call @zoom
      .append "g"

    @force = d3.layout.force()
      .size [@width, @height]
      .linkDistance 150
      .charge -500
      .on 'tick', @tick
      .start()

    #data for each element
    @node_data = []
    @link_data = []

    #D3 selector for each corresponding SVG element
    @nodes = @svg.selectAll ".node"
    @links = @svg.selectAll ".link"

    # add any provided nodes/edges on init
    if options
      if options.nodes
        for node in options.nodes
          @addNode node

      if options.edges
        for edge in options.edges
          @addEdge edge

    #enable deletion via delete/backspace key
    d3.select(window).on 'keydown', () ->
      if d3.event.keyCode in [46, 8]
        me.remove()

    @restart()
    @displayData()

  _constructor: GraphEdit

  #animation for force layout
  tick : =>
    @nodes.attr "cx", (d) -> d.x
    @nodes.attr "cy", (d) -> d.y

    @links.attr "x1", (d) -> d.source.x
    @links.attr "y1", (d) -> d.source.y
    @links.attr "x2", (d) -> d.target.x
    @links.attr "y2", (d) -> d.target.y

  # clear the selection
  clearSelection : () ->
    d3.selectAll(@selected_nodes)
      .classed("active-node", false)
      .call (node) ->
        node.data().selected = false
    @selected_nodes = []

    d3.selectAll(@selected_edges)
      .classed("active-edge", false)
      .call (edge) ->
        edge.data().selected = false
    @selected_edges = []

    @TOOLBAR.find('.graphedit-toolbar-remove').attr('disabled', 'disabled')
    @TOOLBAR.find('.graphedit-toolbar-new-edge').attr('disabled', 'disabled')
    @drawSelection()

  displayData : (data) =>
    if data
      @DATAVIEW.html("<pre>" + JSON.stringify(data.properties, null, 2) + "</pre>")
    else if @selected_nodes.length + @selected_edges.length == 0
      @DATAVIEW.html("<pre>No items selected</pre>")
    else if @selected_nodes.length == 1 and @selected_edges.length == 0
      @DATAVIEW.html("<pre>" + JSON.stringify(d3.select(@selected_nodes[0]).data()[0].properties, null, 2) + "</pre>")
    else if @selected_nodes.length == 0 and @selected_edges.length == 1
      @DATAVIEW.html("<pre>" + JSON.stringify(d3.select(@selected_edges[0]).data()[0].properties, null, 2) + "</pre>")
    else
      @DATAVIEW.html("<pre>Multiple items selected</pre>")

  # display highlight on selected items
  drawSelection : () =>
    d3.selectAll(@selected_nodes)
      .classed("active-node", true)

    d3.selectAll(@selected_edges)
      .classed("active-edge", true)

    @displayData()

  # mark a node as selected
  selectNode : (node) =>
    if not d3.event.shiftKey
      @clearSelection()

    # add to selection buffer
    @selected_nodes.push(node)

    @TOOLBAR.find('.graphedit-toolbar-remove').removeAttr('disabled')

    # iff 2 nodes selected, allow new edge
    if @selected_nodes.length == 2 and @selected_edges.length == 0
      @TOOLBAR.find('.graphedit-toolbar-new-edge').removeAttr('disabled')
    else
      @TOOLBAR.find('.graphedit-toolbar-new-edge').attr('disabled', 'disabled')

    # tell node it's selected
    d.selected = true for d in d3.select(node).data()

    @drawSelection()

  # mark edge as selected
  selectEdge : (edge) =>
    if not d3.event.shiftKey
      @clearSelection()

    # add to selection buffer
    @selected_edges.push(edge)

    @TOOLBAR.find('.graphedit-toolbar-remove').removeAttr('disabled')

    # tell node it's selected
    d.selected = true for d in d3.select(edge).data()

    @drawSelection()

  redraw : =>
    if not @mousedown_node
      @svg.attr "transform", "translate(" + d3.event.translate + ")" + "scale(" + d3.event.scale + ")"

  resetForce : =>
    @force
      .links @link_data
      .nodes @node_data
      .start()

  # renders and changes to data
  restart : =>
    me = @
    @links = @links.data @link_data

    # update existing links
    @links
      .attr "class", "link"

    # new links
    @links.enter()
      .insert "line", ".node"
      .attr "class", "link"
      .on "mouseover", () ->
        link = d3.select(@)
        me.displayData(link.data()[0])
      .on "mouseout", () ->
        link = d3.select(@)
        me.drawSelection()
      .on "mousedown", () ->
        me.selectEdge @

    @links.exit().remove()

    @nodes = @nodes.data @node_data

    # update existing nodes
    @nodes
      .style "fill", (d) -> me.colors(d.node_id)

    # new nodes
    @nodes.enter()

      .append "circle"
      .attr "class", "node"
      .attr "r", 5
      .style "fill", (d) -> me.colors(d.node_id)
      .call me.force.drag

      .on "mouseover", () ->
        me.displayData(d3.select(@).data()[0])
      .on "mouseout", () ->
        me.drawSelection()
      .on "mousedown", () ->
        me.mousedown_node = true
        me.scale = me.zoom.scale()
        me.translate = me.zoom.translate()
        me.selectNode @
      .on "mouseup", () ->
        me.mousedown_node = false
        me.zoom.scale me.scale
        me.zoom.translate me.translate

    # clear old ones
    @nodes.exit().remove()

    # update force
    @resetForce()

  # looks up index of provided node
  getNodeIndex: (node_id) =>
    for i in [0..@node_data.length - 1]
      if @node_data[i].node_id == node_id
        return i
    return -1

  addNode : (node) =>

    # move to properties sub-dict
    node = {'properties':node}
    node.node_id = node.properties.node_id

    @node_data.push(node)
    @restart()

  addEdge : (link) =>

    #translate to internal references
    link = {'properties':link}
    link['source'] = @getNodeIndex link.properties.src
    link['target'] = @getNodeIndex link.properties.dest
    if link['source'] == -1
      throw "Couldn't find a node with ID " + link.properties.src
      return
    else if link['target'] == -1
      throw "Couldn't find a node with ID " + link.properties.dest
      return

    @link_data.push(link)
    @restart()

  #removes any selected nodes/edges
  remove : () =>
    for d in d3.selectAll(@selected_nodes).data()
      @node_data.splice(@node_data.indexOf(d), 1);
      @removeRelatedEdges d

    for d in d3.selectAll(@selected_edges).data()
      @link_data.splice(@link_data.indexOf(d), 1);

    @restart()
    @clearSelection()

  removeRelatedEdges : (d) =>
    me = @
    to_remove = @link_data.filter (l) ->
      l.source == d || l.target == d
    to_remove.map (l) ->
      me.link_data.splice(me.link_data.indexOf(l), 1)

    @restart()


  renderToolbar: () =>
    @TOOLBAR.html(@toolbarTemplate())
    @TOOLBAR.find('.graphedit-toolbar-zoomin').on('click', @zoomIn)
    @TOOLBAR.find('.graphedit-toolbar-zoomout').on('click', @zoomOut)
    @TOOLBAR.find('.graphedit-toolbar-remove').on('click', @remove)
    @TOOLBAR.find('.graphedit-toolbar-new-edge').on('click', @newEdge)
    @TOOLBAR.find('.graphedit-toolbar-new-node').on('click', @newNode)

  toolbarTemplate: () =>
    """
      <div class="btn-group">
        <button type="button" class="btn btn-default graphedit-toolbar-zoomin"><span class="glyphicon glyphicon-zoom-in"></span></button>
        <button type="button" class="btn btn-default graphedit-toolbar-zoomout"><span class="glyphicon glyphicon-zoom-out"></span></button>
      </div>
      <div class="btn-group">
        <button type="button" class="btn btn-default graphedit-toolbar-new-node"><span class="glyphicon glyphicon-plus-sign"></span></button>
        <button type="button" class="btn btn-default graphedit-toolbar-new-edge" disabled="disabled"><span class="glyphicon glyphicon-resize-horizontal"></span></button>
        <button type="button" class="btn btn-default graphedit-toolbar-remove" disabled="disabled"><span class="glyphicon glyphicon-trash"></span></button>
      </div>
    """

  zoomIn : () =>
    s = @zoom.scale()
    @zoom.center([@width/2,@height/2])
    @zoom.scale(s * 1.5)
    @zoom.event(@svg)

  zoomOut : () =>
    s = @zoom.scale()
    @zoom.center([@width/2,@height/2])
    @zoom.scale(s * 0.5)
    @zoom.event(@svg)

  #connect two selected notes with an edge
  newEdge: () =>
    if @selected_nodes.length == 2
      src = d3.select(@selected_nodes[0]).data()[0]
      dest = d3.select(@selected_nodes[1]).data()[0]

      @addEdge({"src":src.node_id, "dest":dest.node_id})

  _idSeq : 0

  newNode: () =>
    @addNode({node_id:"new-" + @_idSeq++})

  getNodes: () =>
    (d.properties for d in @node_data)

  getEdges: () =>
    (d.properties for d in @link_data)


# GRAPHEDIT PLUGIN DEFINITION
# ==========================

$.fn.graphEdit = ( option, params ) ->

  #default return this, except for getters
  ret = this
  this.each ->
    $this = $(@)
    data = $this.data 'graphEdit'
    if !data then $this.data 'graphEdit', (data = new GraphEdit @, option)
    if typeof option is 'string'
      if option == 'getNodes'
        # return nodes
        ret = data.getNodes()
      else if option == 'getEdges'
        # return edges
        ret = data.getEdges()
      else
        # call method 'option' and return self
        data[option].call $this, params
  ret

$.fn.graphEdit.Constructor = GraphEdit

# DATA API
# ===================================

$ ->
  $('body').on 'click.graphEdit.data-api', '[data-pluginNameAction^=Action]', ( e ) ->
    $(e.target).graphEdit()
