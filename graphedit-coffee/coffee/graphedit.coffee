$ = window.jQuery

"use strict"

# GRAPHEDIT CLASS DEFINITION
# =========================
class GraphEdit
	constructor: ( element, options ) ->
    $el = $(element)
    
	# config
    @width = 960
    @height = 500
    @colors = d3.scale.category10()

    # state vars
    @scale = 0
    @translate = 0
    @active_selection = []
    @mousedown_node = false

    @zoom = d3.behavior.zoom().scaleExtent([.1,8]).on "zoom", @redraw

    # init visual
    me = @
    @canvas = d3
      .select element
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
    @node_data = ({id:a, reflexive:false} for a in [1..10])
    @link_data = [{"source":1, "target":3, "value":4}, {"source":1, "target":5, "value":4}]

    #force layout
    @force = d3.layout.force()
        .nodes @node_data
        .links @link_data
        .size [@width, @height]
        .linkDistance 150
        .charge -500
        .on 'tick', @tick
        .start()

    # add links
    @links = @svg.selectAll ".link"
        .data @link_data
        .enter()
        .append "line"
        .attr "class", "link"
        .style "stroke", "#000"
        .style "stroke-width", () -> 1

    # add nodes
    @nodes = @svg
        .selectAll ".node"
        .data @node_data
        .enter()
        .append "circle"
        .attr "class", "node"
        .attr "r", 5
        .style "fill", (d) -> me.colors(d.id)
        .call me.force.drag

        .on "mousedown", (d) ->
          me.mousedown_node = true
          me.scale = me.zoom.scale()
          me.translate = me.zoom.translate()
          me.select this
        .on "mouseup", (d) ->
          me.mousedown_node = false
          me.zoom.scale me.scale
          me.zoom.translate me.translate



	_constructor: GraphEdit

	method : =>
		alert "I am a method"

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

  # draw the selection
  drawSelection : () =>
    d3.selectAll(@active_selection)
      .classed("active-node", true)

  # mark a node as selected
  select : (node) =>
    if not d3.event.shiftKey
      @clearSelection()

      # add to selection buffer
      @active_selection.push(node)

      # tell node it's selected
      d.selected = true for d in d3.select(node).data()

      @drawSelection()

  redraw : =>
  	if not @mousedown_node
		  @svg.attr "transform", "translate(" + d3.event.translate + ")" + "scale(" + d3.event.scale + ")"



# GRAPHEDIT PLUGIN DEFINITION
# ==========================

$.fn.graphEdit = ( option ) ->
	this.each ->
		$this = $(@)
		data = $this.data 'graphEdit'
		if !data then $this.data 'graphEdit', (data = new GraphEdit @, option)
		if typeof option is 'string' then data[option].call $this

$.fn.graphEdit.Constructor = GraphEdit


# DATA API
# ===================================

$ ->
	$('body').on 'click.graphEdit.data-api', '[data-pluginNameAction^=Action]', ( e ) ->
		$(e.target).graphEdit()
