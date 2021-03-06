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

    @zoom = d3.behavior.zoom().scaleExtent([.1,8]).on "zoom", @redraw

    @resize true
    $(window).resize () =>
      @resize()

    # config
    @colors = d3.scale.category10()

    # state vars
    @scale = 0
    @translate = 0
    @selected_nodes = []
    @selected_edges = []
    @mousedown_node = false

    #data for each element
    @node_data = []
    @link_data = []

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
      #if backspace
      if d3.event.keyCode in [46, 8]
        #if not typing in a form
        if $( document.activeElement ).parents('form').length == 0
          me.removeSelection()

    @restart()
    @displayData()

  _constructor: GraphEdit

  resize : (initial) =>
    @GRAPH.html ""
    @width = @GRAPH.innerWidth()
    @height = 500

    # init visual
    @canvas = d3
      .select @GRAPH.get(0)
      .append "svg"
      .on "click", () =>
        if not ( d3.event.target.classList.contains("node") or \
                d3.event.target.classList.contains("link"))
          @clearSelection()

    @svg = @canvas
      .attr "width", @width
      .attr "height", @height
      .attr "viewBox", "0 0 " + @width + " " + @height
      .attr "preserveAspectRatio", "xMidYMid meet"
      .attr "pointer-events", "all"
      .call @zoom
      .append "g"

    #D3 selector for each corresponding SVG element
    @nodes = @svg.selectAll ".node"
    @links = @svg.selectAll ".link"

    @force = d3.layout.force()
      .size [@width, @height]
      .linkDistance 150
      .charge -500
      .on 'tick', @tick
      .start()

    if not initial
      @restart()

  #animation for force layout
  tick : =>
    @nodes.attr "cx", (d) -> d.x
    @nodes.attr "cy", (d) -> d.y

    @links.attr "x1", (d) -> d.source.x
    @links.attr "y1", (d) -> d.source.y
    @links.attr "x2", (d) -> d.target.x
    @links.attr "y2", (d) -> d.target.y

  # pan/zoom when node isn't being dragged
  redraw : =>
    if not @mousedown_node
      @svg.attr "transform", "translate(" + d3.event.translate + ")" + "scale(" + d3.event.scale + ")"

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

  _propertyForm : (data, type) =>

    if type == "edge"
      locked_keys = ["src", "dest"]
    else
      locked_keys = ["node_id"]

    str = '<form class="form-horizontal graphedit-property-form" action="javascript:void(0)" role="form">'

    str += '<div class="properties">'
    for k,v of data

      str += """
        <div class="form-group graphedit-property">
          <label for="#{k}" class="col-sm-4 control-label">#{k}</label>
          <div class="col-sm-8">

      """

      if k.toLowerCase() in locked_keys
        str += """
            <input id="#{k}" name="#{k}-visible" class="form-control input-sm" value="#{v}" disabled>
            <input id="#{k}" name="#{k}" value="#{v}" type="hidden">
          """
      else
        str += """
            <div class="input-group">
              <input id="#{k}" name="#{k}" class="form-control input-sm" value="#{v}">
              <div class="input-group-btn">
                <button class="btn btn-default btn-sm graphedit-remove-property"><span class="glyphicon glyphicon-remove"></span></button>
              </div>
            </div>
          """

      str += """
          </div>
        </div>
      """
    str += "</div>"

    str += """
      <div class="form-group">
        <div class="col-sm-offset-4 col-sm-8">
          <a href="#" class="graphedit-add-property">+ Add property</a>
        </div>
      </div>
      <div class="form-group">
        <div class="col-sm-offset-4 col-sm-8">
          <button type="submit" class="btn btn-default graphedit-save-properties">Save</button>
        </div>
      </div>
    """
    str += "</form>"
    str

  _clearDataviewBindings: () =>
    $('.graphedit-add-property').off 'click'
    $('.graphedit-property-form').off 'submit'
    $('.graphedit-remove-property').off 'click'

  _setDataviewBindings: () =>
    $('.graphedit-add-property').on 'click', @clickNewProperty
    $('.graphedit-property-form').on 'submit', @submitPropertyForm
    $('.graphedit-remove-property').on 'mouseup', @clickRemoveProperty

  # display provided data (for type in {'edge', 'node'}), or whatever is currently selected
  displayData : (data, type) =>
    @_clearDataviewBindings()

    if data
      @DATAVIEW.html(@_propertyForm(data.properties, type))
    else if @selected_nodes.length + @selected_edges.length == 0
      @DATAVIEW.html('<p class="text-muted text-center">No items selected</p>')
    else if @selected_nodes.length == 1 and @selected_edges.length == 0
      @DATAVIEW.html(@_propertyForm(d3.select(@selected_nodes[0]).data()[0].properties, 'node'))
    else if @selected_nodes.length == 0 and @selected_edges.length == 1
      @DATAVIEW.html(@_propertyForm(d3.select(@selected_edges[0]).data()[0].properties, 'edge'))
    else if @selected_nodes.length == 2 and @selected_edges.length == 0
      @DATAVIEW.html('<p class="text-muted text-center">Two nodes selected, click <span class="glyphicon glyphicon-resize-horizontal"></span> to create an edge</p>')
    else
      @DATAVIEW.html('<p class="text-muted text-center">Multiple items selected</p>')

    @_setDataviewBindings()

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

  # ensures force layout knows about current data
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
  removeSelection : () =>
    for d in d3.selectAll(@selected_nodes).data()
      @node_data.splice(@node_data.indexOf(d), 1);
      @removeRelatedEdges d

    for d in d3.selectAll(@selected_edges).data()
      @link_data.splice(@link_data.indexOf(d), 1);

    @restart()
    @clearSelection()

  removeRelatedEdges : (node_dict) =>
    me = @
    to_remove = @link_data.filter (l) ->
      l.source == node_dict || l.target == node_dict
    to_remove.map (l) ->
      me.link_data.splice(me.link_data.indexOf(l), 1)

    @restart()

  renderToolbar: () =>
    @TOOLBAR.html(@toolbarTemplate())
    @TOOLBAR.find('.graphedit-toolbar-zoomin').on('click', @zoomIn)
    @TOOLBAR.find('.graphedit-toolbar-zoomout').on('click', @zoomOut)
    @TOOLBAR.find('.graphedit-toolbar-remove').on('click', @removeSelection)
    @TOOLBAR.find('.graphedit-toolbar-new-edge').on('click', @clickNewEdge)
    @TOOLBAR.find('.graphedit-toolbar-new-node').on('click', @clickNewNode)

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
  clickNewEdge: () =>
    if @selected_nodes.length == 2
      src = d3.select(@selected_nodes[0]).data()[0]
      dest = d3.select(@selected_nodes[1]).data()[0]

      @addEdge({"src":src.node_id, "dest":dest.node_id})


  #allow node inserts from front end
  _idSeq : 0
  clickNewNode: () =>
    @addNode({node_id:"new-" + @_idSeq++})

  getNodes: () =>
    (d.properties for d in @node_data)

  getEdges: () =>
    (d.properties for d in @link_data)

  clickRemoveProperty: (e) =>
    $(e.target).parents('.graphedit-property').remove()

  #add a new property to the form
  clickNewProperty: () =>
    str = """
      <div class="form-group graphedit-property graphedit-new-property">
        <div class="col-sm-4">
          <input class="form-control input-sm">
        </div>
        <div class="col-sm-8">
          <div class="input-group">
          <input class="form-control input-sm">
            <div class="input-group-btn">
              <button class="btn btn-default btn-sm graphedit-remove-property"><span class="glyphicon glyphicon-remove"></span></button>
            </div>
          </div>
        </div>

      </div>
    """
    @DATAVIEW.find('.properties').append(str)
    @DATAVIEW.find('.graphedit-remove-property').on 'mouseup', @clickRemoveProperty

  validatePropertyForm: (form_elm) =>
    #existing properties
    data = {}

    #extract existing properties (with name attrs)
    form = $(form_elm).serializeArray()

    is_valid = true

    $.each form, (i, d) => data[d.name] = d.value

    #new properties
    $(form_elm).find('.graphedit-new-property').each (i, elm) =>
      key = $(elm).find('input').first().val()
      value = $(elm).find('input').last().val()
      if key.length == 0 and value.length > 0
        $(elm).addClass('has-error')
        $(elm).append('<span class="help-block text-danger text-right">Must provide key name</span>')
        is_valid = false

      else if key.length > 0 and key of data
        $(elm).addClass('has-error')
        $(elm).append('<span class="help-block text-danger text-right">Duplicate property</span>')
        is_valid = false

    return is_valid


  submitPropertyForm: (e) =>
    e.preventDefault();

    if @validatePropertyForm(e.target)

      data = {}

      #extract existing properties (with name attrs)
      form = $(e.target).serializeArray()

      $.each form, (i, d) =>
        data[d.name] = d.value

      #add new properties
      $(e.target).find('.graphedit-new-property').each (i, elm) =>
        key = $(elm).find('input').first().val()
        value = $(elm).find('input').last().val()
        if key.length > 0
            data[key] = value

      #what's being edited?
      target = null
      if @selected_nodes.length == 1 and @selected_edges.length == 0
        target = @selected_nodes[0]
      else if @selected_nodes.length == 0 and @selected_edges.length == 1
        target = @selected_edges[0]

      if target == null
        throw "Not sure what you were editing"

      d3.select(target).data()[0].properties = data

      @restart()
      @displayData()


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
