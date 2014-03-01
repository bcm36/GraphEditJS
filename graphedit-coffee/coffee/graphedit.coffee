console.log "hello world!"

# config
width = 960
height = 500
colors = d3.scale.category10()
scale = 0
translate = 0

# nodes the user has currently selected
active_selection = []

redraw = () ->
	if not mousedown_node
		svg.attr "transform", "translate(" + d3.event.translate + ")" + "scale(" + d3.event.scale + ")"

zoom = d3.behavior.zoom().scaleExtent([.1,8]).on "zoom", redraw

# init visual
canvas = d3
	.select ".graphedit_canvas"
	.append "svg"
	.on "click", () ->
		if not d3.event.target.classList.contains("node")
			clearSelection()
svg = canvas
	.attr "width", width
	.attr "height", height
	.attr "viewBox", "0 0 " + width + " " + height
	.attr "preserveAspectRatio", "xMidYMid meet"
	.attr "pointer-events", "all"
	.call zoom
	.append "g"

# init nodes
node_data = ({id:a, reflexive:false} for a in [1..10])
link_data = [{"source":1, "target":3, "value":4}, {"source":1, "target":5, "value":4}]

#animation
tick = () ->
	nodes.attr "cx", (d) -> d.x
	nodes.attr "cy", (d) -> d.y

	links.attr "x1", (d) -> d.source.x
	links.attr "y1", (d) -> d.source.y
	links.attr "x2", (d) -> d.target.x
	links.attr "y2", (d) -> d.target.y

#force layout
force = d3.layout.force()
		.nodes node_data
		.links link_data
		.size [width, height]
		.linkDistance 150
		.charge -500
		.on 'tick', tick
		.start()

mousedown_node = false

links = svg.selectAll ".link"
		.data link_data 
		.enter()
		.append "line"
		.attr "class", "link"
		.style "stroke", "#000" 
		.style "stroke-width", () -> 1

		# override to turn off force layout
		"""
		.call force.drag().on "drag.force", () -> 
			d3.select(this).attr "transform", "translate(" + d3.event.x + "," + d3.event.y + ")"
		
		.call force.drag().origin () ->
			t = d3.transform(d3.select(this).attr("transform")).translate
			{x:t[0], y:t[1]}
		"""
#draw data
nodes = svg
		.selectAll ".node"
		.data node_data
		.enter()
		.append "circle"
		.attr "class", "node"
		.attr "r", 5
		.style "fill", (d) -> colors(d.id)

		.on "mousedown", (d) ->
			mousedown_node = true
			#scale = zoom.scale()
			#translate = zoom.translate()
			select this
		.on "mouseup", (d) ->
			mousedown_node = false
			#zoom.scale scale
			#zoom.translate translate

setPanMode = (turn_on) ->
	if turn_on
		console.log "drag on"
		nodes.call force.drag
	else
		console.log "drag off"
		nodes
			.on "mousedown.drag", null
			.on "touchstart.drag", null

setPanMode(true)

# mark a node as selected
select = (node) -> 
	if not d3.event.shiftKey
		clearSelection()
	
	# add to selection buffer
	active_selection.push(node)
	
	# tell node it's selected
	d.selected = true for d in d3.select(node).data()
	
	drawSelection()

clearSelection = () ->
	d3.selectAll(active_selection)
		.classed("active-node", false)
		.call (node) -> 
			node.data().selected = false
	active_selection = []

drawSelection = () ->
	d3.selectAll(active_selection)
		.classed("active-node", true)

stop = () ->
	console.log("stopped") 
	#force.stop()
setTimeout stop, 1000 

console.log nodes
