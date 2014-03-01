console.log "hello world!"

# config
width = 960
height = 500
colors = d3.scale.category10()

redraw = () ->
	console.log "in redraw" 
	svg.attr "transform", "translate(" + d3.event.translate + ")" + "scale(" + d3.event.scale + ")"


# init visual
svg = d3
	.select ".graphedit_canvas"
	.append "svg"
	.attr "width", width
	.attr "height", height
	.attr "viewBox", "0 0 " + width + " " + height
	.attr "preserveAspectRatio", "xMidYMid meet"
	.attr "pointer-events", "all"
	.call d3.behavior.zoom().scaleExtent([.1,8]).on "zoom", redraw
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

#draw data
nodes = svg
		.selectAll ".node"
		.data node_data
		.enter()
		.append "circle"
		.attr "class", "node"
		.attr "r", 5
		.style "fill", (d) -> colors(d.id)
		.call force.drag

console.log nodes
