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
node_data = ({id:a, reflexive:false} for a in [1..100])

#animation
tick = () ->
	nodes.attr "cx", (d) -> d.x
	nodes.attr "cy", (d) -> d.y

#force layout
force = d3.layout.force()
		.nodes node_data
		.size [width, height]
		.linkDistance 150
		.charge -500
		.on 'tick', tick
		.start()

mousedown_node = false

#draw data
nodes = svg
		.selectAll ".node"
		.data node_data
		.enter()
		.append "circle"
		.attr "class", "node"
		.attr "r", 5
		.style "fill", (d) -> colors(d.id)

		# override to turn off force layout
		.call force.drag().on "drag.force", () -> 
			d3.select(this).attr "transform", "translate(" + d3.event.x + "," + d3.event.y + ")"
		
		.call force.drag().origin () ->
			t = d3.transform(d3.select(this).attr("transform")).translate
			{x:t[0], y:t[1]}
		
		.on "mousedown", (d) ->
			mousedown_node = true
			scale = zoom.scale()
			translate = zoom.translate()
			select this
		.on "mouseup", (d) ->
			mousedown_node = false
			zoom.scale scale
			zoom.translate translate

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
	force.stop()
setTimeout stop, 1000 

console.log nodes
