$ = window.jQuery

"use strict"

# GRAPHEDIT CLASS DEFINITION
# =========================
class GraphEdit
  constructor: ( element, options ) ->
    $el = $(element)

    me = @

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
      .style "stroke", "#F00"
      .attr "class", "link"

    # new links
    @links.enter()
      .append "line"
      .attr "class", "link"
      .style "stroke", "#000"
      .style "stroke-width", () -> 1

    @links.exit().remove()

    @nodes = @nodes.data(@node_data, (d)-> d.id)

    # update existing nodes
    @nodes
      .style "fill", (d) -> me.colors(d.id)

    # new nodes
    @nodes.enter()

      .append "circle"
      .attr "class", "node"
      .attr "r", 5
      .style "fill", (d) -> me.colors(d.id)
      .call me.force.drag

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
