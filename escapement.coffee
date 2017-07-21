# http://jsfiddle.net/dz7y84o0/14/
# renders a clock (deadbeat, Graham) escapement as svg
# unit: mm
#
# params:
# c: center of escapement wheel
# r1: inner radius
# r2: inner ring radius
# r3: outer ring radius
# r4: outer radius
# sd: spokes width
# sn: number of spokes
# n: number of teeth
# ns: übergriffene teilungen todo: translate
render_escapement = (c, r1, r2, r3, r4, sd, sn, n = 30, ns = 6.5) ->
	svg = SVG("drawing").size("210mm", "297mm").viewbox(0, 0, 210, 297)
	style = "fill:none;stroke:#000000;stroke-width:0.2"

	# wheel
	g1 = svg.group().attr("id", "wheel").attr("style", style).translate(0, 297).scale(1, -1)
	render_escapement_wheel(g1, c, r1, r2, r3, r4, sd, sn, n)
	
	# fork
	g2 = svg.group().attr("id", "fork").attr("style", style).translate(0, 297).scale(1, -1)
	render_escapement_fork(g2, c, r1, r4, sd, n, ns)

	# console output
	document.getElementById("svg-out").textContent = svg.svg()
	{wheel: g1, fork: g2, svg: svg:svg.svg()}

# math stuff
pi = Math.PI
pi2 = 0.5 * pi
sin = Math.sin
asin = Math.asin
cos = Math.cos
sqrt = Math.sqrt
sqr = (x) -> x * x
rad = (x) -> x * pi / 180
dist = (p1, p2) -> sqrt(sqr(p2[0] - p1[0]) + sqr(p2[1] - p1[1]))
rot = (p, r, t) -> [p[0] + r * cos(t), p[1] + r * sin(t)]

# renders center circles (crosshair) 
render_center = (svg, c, r1, n) ->
	for i in [1 .. n]
		svg.circle().radius(i * r1).cx(c[0]).cy(c[1])
	d = (n + 1) * r1
	svg.line(c[0] - d, c[1], c[0] + d, c[1])
	svg.line(c[0], c[1] - d, c[0], c[1] + d)
	
# spokes
render_spokes = (svg, c, r1, r2, d, n, t0 = 0) ->
	if n > 0
		phi = 2 * pi / n
		dt1 = asin(0.5 * d / r1)
		dt2 = asin(0.5 * d / r2)
		for i in [0 .. n-1]
			t = t0 + i * phi
			p1 = rot(c, r1, t + dt1)
			p2 = rot(c, r2, t + dt2)
			p3 = rot(c, r1, t - dt1)
			p4 = rot(c, r2, t - dt2)
			svg.line(p1[0], p1[1], p2[0], p2[1])
			svg.line(p3[0], p3[1], p4[0], p4[1])

# escapement wheel
render_escapement_wheel = (svg, c, r1, r2, r3, r4, sd, sn, n) ->
	phi = 2 * pi / n
	te = rad(1.0) # todo: this is a depending var
	tt = rad(18.5) # todo: this is a depending var
	tl = rad(6.0) # todo: this is a depending var
	rt = (r4 - r3) / cos(tt)
	rl = (r4 - r3) / cos(tl)
	for i in [0 .. n - 1]
		t1 = i * phi
		t2 = i * phi - te
		t3 = i * phi + pi - tt 
		t4 = t2 + pi - tl
		p1 = rot(c, r4, t1)
		p2 = rot(c, r4, t2)
		p3 = rot(p1, rt, t3)
		p4 = rot(p2, rl, t4)
		svg.line(p1[0], p1[1], p3[0], p3[1])
		svg.line(p1[0], p1[1], p2[0], p2[1])
		svg.line(p2[0], p2[1], p4[0], p4[1])
	svg.circle().radius(r1).cx(c[0]).cy(c[1])
	svg.circle().radius(r2).cx(c[0]).cy(c[1])
	svg.circle().radius(r3).cx(c[0]).cy(c[1])
	svg.circle().radius(r4).cx(c[0]).cy(c[1])
	render_center(svg, c, 2.0, 3)
	render_spokes(svg, c, r1, r2, sd, sn)

# escapement fork
render_escapement_fork = (svg, c, r1, r2, d, n, ns) ->
	ts = ns * pi / n
	te = rad(2.0) # todo: this is a depending var
	p0 = c
	p3 = [c[0], c[1] - r2 / cos(pi * ns / n)]
	p4 = rot(c, r2, ts + te - pi2)
	p5 = rot(c, r2, ts - te - pi2)

	rfa = dist(p3, p4)
	rfi = dist(p3, p5)

	tlift = rad(2.0)
	tlock = rad(2.0)
	
	tp0 = pi2 + 0.5 * (tlock + tlift)
	tp8 = pi2 + ts + tlock + tlift - tp0
	p8 = rot(p3, rfi, tp8)
	tp9 = pi2 + ts + tlock - tp0
	p9 = rot(p3, rfa, tp9)
	
	tp10 = 1.5 * pi - ts + tlift - tp0
	p10 = rot(p3, rfi, tp10)
	tp11 = 1.5 * pi - ts - tp0
	p11 = rot(p3, rfa, tp11)
	
	render_center(svg, p3, 2.0, 2)
	svg.circle().radius(r1).cx(p3[0]).cy(p3[1])
	svg.line(p8[0], p8[1], p9[0], p9[1])
	svg.line(p10[0], p10[1], p11[0], p11[1])
	render_spokes(svg, p3, r1, rfi, d, 3, -pi2)
	svg.path("M#{p8[0]},#{p8[1]}A#{rfi},#{rfi},0,1,0,#{p10[0]},#{p10[1]}")
	svg.path("M#{p9[0]},#{p9[1]}A#{rfa},#{rfa},0,1,0,#{p11[0]},#{p11[1]}")


escapement = render_escapement([100, 220], 12, 47, 55, 70, 8.0, 6, 30, 6.5)
