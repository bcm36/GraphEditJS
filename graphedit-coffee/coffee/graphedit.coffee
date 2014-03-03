$ = window.jQuery

"use strict"

# GRAPHEDIT CLASS DEFINITION
# =========================
class GraphEdit
  constructor: ( element, options ) ->
    $el = $(element)

    $el.append """
    <div class="graphedit-toolbar"></div>
    <div class="row">
      <div class="graphedit-graph col-sm-8"></div>
      <div class="graphedit-dataview col-sm-4"></div>
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
    @active_selection = []
    @mousedown_node = false

    @zoom = d3.behavior.zoom().scaleExtent([.1,8]).on "zoom", @redraw

    # init visual
    @canvas = d3
      .select @GRAPH.get(0)
      .append "svg"
      .on "click", () ->
        if not d3.event.target.classList.contains("node")
          me.clearSelection()

    @svg = @canvas
      .attr "width", @width
      .attr "height", @height
      .attr "viewBox", "0 0 " + @width + " " + @height
      .attr "preserveAspectRatio", "xMidYMid meet"
      .attr "pointer-events", "all"
      .call @zoom
      .append "g"

    # init nodes
    @node_data = ({id:a, reflexive:false} for a in [1..4])
    @link_data = [{"source":1, "target":3, "value":4}, {"source":1, "target":3, "value":4}]
    @force = d3.layout.force()
      #.nodes @node_data
      #.links @link_data
      .size [@width, @height]
      .linkDistance 150
      .charge -500
      .on 'tick', @tick
      .start()

    @nodes = @svg.selectAll ".node"
    @links = @svg.selectAll ".link"

    #@setNodes(@node_data)
    #@setLinks([{"source":1, "target":3, "value":4}, {"source":1, "target":3, "value":4}])
    @restart()



  _constructor: GraphEdit

  method : =>
    alert "I am a method"
    0

  #animation
  tick : =>
    @nodes.attr "cx", (d) -> d.x
    @nodes.attr "cy", (d) -> d.y

    @links.attr "x1", (d) -> d.source.x
    @links.attr "y1", (d) -> d.source.y
    @links.attr "x2", (d) -> d.target.x
    @links.attr "y2", (d) -> d.target.y

  # clear the selection
  clearSelection : () ->
    d3.selectAll(@active_selection)
      .classed("active-node", false)
      .call (node) ->
        node.data().selected = false
    @active_selection = []
    @TOOLBAR.find('.graphedit-toolbar-remove').attr('disabled', 'disabled')
    @TOOLBAR.find('.graphedit-toolbar-new-edge').attr('disabled', 'disabled')
    @displaySelection()

  displaySelection : (data) =>
    if data
      @DATAVIEW.html("<pre>" + JSON.stringify(data, null, 2) + "</pre>")
    else if @active_selection.length == 0
      @DATAVIEW.html("")
    else if @active_selection.length == 1
      @DATAVIEW.html("<pre>" + JSON.stringify(d3.select(@active_selection[0]).data()[0], null, 2) + "</pre>")

  # draw the selection
  drawSelection : () =>
    d3.selectAll(@active_selection)
      .classed("active-node", true)

    @displaySelection()

  # mark a node as selected
  select : (node) =>
    if not d3.event.shiftKey
      @clearSelection()

    # add to selection buffer
    @active_selection.push(node)
    @TOOLBAR.find('.graphedit-toolbar-remove').removeAttr('disabled')

    if @active_selection.length == 2
      @TOOLBAR.find('.graphedit-toolbar-new-edge').removeAttr('disabled')
    else
      @TOOLBAR.find('.graphedit-toolbar-new-edge').attr('disabled', 'disabled')

    # tell node it's selected
    d.selected = true for d in d3.select(node).data()

    @drawSelection()

  redraw : =>
    if not @mousedown_node
      @svg.attr "transform", "translate(" + d3.event.translate + ")" + "scale(" + d3.event.scale + ")"

  resetForce : =>
    @force
      .links @link_data
      .nodes @node_data
      .start()

  restart : =>
    me = @
    @links = @links.data(@link_data)

    # update existing links
    @links
      .style "stroke", "#000"
      .attr "class", "link"

    # new links
    @links.enter()
      .insert "line", ".node"
      .attr "class", "link"
      .style "stroke", "#000"
      .style "stroke-width", () -> 1

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
        me.displaySelection(d3.select(this).data()[0])
      .on "mouseout", () ->
        me.displaySelection()
      .on "mousedown", () ->
        me.mousedown_node = true
        me.scale = me.zoom.scale()
        me.translate = me.zoom.translate()
        me.select this
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
    for i in [0..@node_data.length]
      if @node_data[i].node_id == node_id
        return i
    return -1

  addNode : (node) =>
    @node_data.push(node)
    @restart()

  addLink : (link) =>

    #translate to internal references
    link['source'] = @getNodeIndex link['src']
    link['target'] = @getNodeIndex link['dest']

    @link_data.push(link)
    @restart()

  remove : () =>
    if @active_selection.length > 0
      for d in d3.selectAll(@active_selection).data()
        @node_data.splice(@node_data.indexOf(d), 1);
        @removeRelatedEdges d
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
    me = @
    @TOOLBAR.html(@toolbarTemplate())
    @TOOLBAR.find('.graphedit-toolbar-zoomin').on('click', @zoomIn)
    @TOOLBAR.find('.graphedit-toolbar-zoomout').on('click', @zoomOut)
    @TOOLBAR.find('.graphedit-toolbar-remove').on('click', @remove)
    @TOOLBAR.find('.graphedit-toolbar-new-edge').on('click', @newEdge)
    @TOOLBAR.find('.graphedit-toolbar-new-node').on('click', @newNode)

    d3.select(window).on 'keydown', () ->
      if d3.event.keyCode in [46, 8]
        me.remove()

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
    if @active_selection.length == 2
      src = d3.select(@active_selection[0]).data()[0]
      dest = d3.select(@active_selection[1]).data()[0]

      @addLink({"src":src.node_id, "dest":dest.node_id})

  _idSeq : 0

  newNode: () =>
    @addNode({node_id:"new-" + @_idSeq++})


# GRAPHEDIT PLUGIN DEFINITION
# ==========================

$.fn.graphEdit = ( option, params ) ->
  this.each ->
    $this = $(@)
    data = $this.data 'graphEdit'
    if !data then $this.data 'graphEdit', (data = new GraphEdit @, option)
    if typeof option is 'string' then data[option].call $this, params

$.fn.graphEdit.Constructor = GraphEdit


# DATA API
# ===================================

$ ->
  $('body').on 'click.graphEdit.data-api', '[data-pluginNameAction^=Action]', ( e ) ->
    $(e.target).graphEdit()
