# math stuff
abs = Math.abs
pi = Math.PI
pi2 = 0.5 * pi
sin = Math.sin
asin = Math.asin
cos = Math.cos
acos = Math.acos
tan = Math.tan
atan = Math.atan
sqr = (x) -> x * x
sqrt = Math.sqrt
p2 = (a, b, c) -> (x) -> a * x * x + b * x + c
p2rt = (a, b, c) ->
	d = sqrt(b * b - 4 * a * c)
	[0.5 * (-b + d) / a, 0.5 * (-b - d) / a]
rad = (x) -> x * pi / 180
deg = (x) -> x * 180 / pi
dist = (p1, p2) -> sqrt(sqr(p2[0] - p1[0]) + sqr(p2[1] - p1[1]))
rot = (p, r, t) -> [p[0] + r * cos(t), p[1] + r * sin(t)]
involute = (p, r, t, t0 = 0) ->
	u = t0 + t
	[p[0] + r * (cos(u) + t * sin(u)), p[1] + r * (sin(u) - t * cos(u))]
tri = (a, b, c) -> {
	alpha: acos((sqr(b) + sqr(c) - sqr(a)) / (2 * b * c))
	beta: acos((sqr(a) + sqr(c) - sqr(b)) / (2 * a * c))
	gamma: acos((sqr(a) + sqr(b) - sqr(c)) / (2 * a * b))
}
gn = (p1, p2) -> [p1[1] - p2[1], p2[0] - p1[0], (p1[1] - p2[1]) * p1[0] + (p2[0] - p1[0]) * p1[1]]
intLineCircle = (a, b, c, cc, r) ->
	d = c - a * cc[0] - b * cc[1]
	N = a * a + b * b
	D = sqrt(r * r * N - d * d)
	x1 = cc[0] + (a * d + b * D) / N
	x2 = cc[0] + (a * d - b * D) / N
	y1 = cc[1] + (b * d - a * D) / N
	y2 = cc[1] + (b * d + a * D) / N
	[[x1, y1], [x2, y2]]
intCircleCircle = (c1, r1, c2, r2) ->
	a = 2 * (c2[0] - c1[0])
	b = 2 * (c2[1] - c1[1])
	c = r1 * r1 - r2 * r2 + c2[0] * c2[0] + c2[1] * c2[1] - c1[0] * c1[0] - c1[1] * c1[1]
	intLineCircle(a, b, c, c1, r1)

# SVG.js rendering wrapper
render = (svg_js_g) ->

	line = (p1, p2) ->
		svg_js_g.line(p1[0], p1[1], p2[0], p2[1])
		this

	polyline = (p...) ->
		svg_js_g.polyline(p)
		this

	path = (p) ->
		svg_js_g.path(p)
		this

	transform = (t, r) ->
		svg_js_g.transform(t, r)
		this

	circle = (c, r) ->
		svg_js_g.circle().cx(c[0]).cy(c[1]).radius(r)
		this

	text = (c, t, dc = [0, 0]) ->
		svg_js_g.text(t).move(c[0] + dc[0], c[1] + dc[1]).font({size:4}).fill('#000000').scale(1, -1)
		this

	# see https://de.wikipedia.org/wiki/Evolventenverzahnung
	gear = (c, n, p, a = rad(20), phi0 = 0, ne = 5) ->
		phi = 2 * pi / n
		m = p / pi # modul
		r = 0.5 * n * m
		rb = r * cos(a)
		rf = r - m
		ra = r + m
		dphi = 0.25 * phi + sqrt(r ** 2 - rb ** 2) / rb - acos(rb / r)
		ta = sqrt(ra ** 2 - rb ** 2) / rb
		tf = if rb < rf then sqrt(rf ** 2 - rb ** 2) / rb else 0.0
		dt = (ta - tf) / ne
		for i in [0 .. n - 1]
			polyline(involute(c, rb, tf + j * dt, phi0 + i * phi - dphi) for j in [0 .. ne])
			polyline(involute(c, rb, -tf - j * dt, phi0 + i * phi + dphi) for j in [0 .. ne])
			line(involute(c, rb, ta, phi0 + i * phi - dphi), involute(c, rb, -ta, phi0 + i * phi + dphi))
			if rb < rf
				line(involute(c, rb, tf, phi0 + i * phi - dphi), involute(c, rb, -tf, phi0 + (i - 1) * phi + dphi))
			else
				line(rot(c, rf, phi0 + i * phi - dphi), rot(c, rb, phi0 + i * phi - dphi))
				line(rot(c, rf, phi0 + (i - 1) * phi + dphi), rot(c, rb, phi0 + (i - 1) * phi + dphi))
				line(rot(c, rf, phi0 + i * phi - dphi), rot(c, rf, phi0 + (i - 1) * phi + dphi))
		this

	crosshair = (c, r = 2, n = 3) ->
		circle(c, i * r) for i in [1 .. n]
		d = (n + 1) * r
		line([c[0] - d, c[1]], [c[0] + d, c[1]])
		line([c[0], c[1] - d], [c[0], c[1] + d])
		this

	spokes = (c, r1, r2, n, d, phi0 = 0) ->
		phi = 2 * pi / n
		dt1 = asin(0.5 * d / r1)
		dt2 = asin(0.5 * d / r2)
		for i in [0 .. n - 1]
			t = phi0 + i * phi
			line(rot(c, r1, t + dt1), rot(c, r2, t + dt2))
			line(rot(c, r1, t - dt1), rot(c, r2, t - dt2))
		this

	wheel = (c, r1, r2, r3, n, d, t0 = 0, chr = 2, chn = 3) ->
		crosshair(c, chr, chn)
		spokes(c, r1, r2, n, d, t0)
		circle(c, r1)
		circle(c, r2)
		circle(c, r3)
		this

	methods = {line, polyline, path, transform, circle, text, crosshair, spokes, wheel, gear}

# create svg and groups
create_svg = (style, group_ids...) ->
	svg = SVG("drawing").size("210mm", "297mm").viewbox(0, 0, 210, 297)
	result = {svg}
	for id in group_ids
		result[id] = svg.group().attr("id", id).attr("style", style).translate(0, 297).scale(1, -1)
	result

# renders a clock escapement (deadbeat, Graham) as svg
# dependency: SVG.js http://svgjs.com/
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
escapement = () ->
	svg = create_svg("fill:none;stroke:#000000;stroke-width:0.2", "g1", "g2")
	g1 = svg["g1"]
	g2 = svg["g2"]

	c = [100, 220]
	r1 = 12.0
	r2 = 50.0
	r3 = 55.0
	r4 = 70.0
	sd = 5.0
	sn = 6
	n = 30
	ns = 6.5
	phi = 2 * pi / n
	te = rad(1.0) # todo: this is a depending var
	tt = rad(18.5) # todo: this is a depending var
	tl = rad(6.0) # todo: this is a depending var
	rt = (r4 - r3) / cos(tt)
	rl = (r4 - r3) / cos(tl)
	for i in [0 .. n - 1]
		t1 = i * phi
		t2 = t1 - te
		t3 = t1 + pi - tt
		t4 = t2 + pi - tl
		p1 = rot(c, r4, t1)
		p2 = rot(c, r4, t2)
		p3 = rot(p1, rt, t3)
		p4 = rot(p2, rl, t4)
		render(g1).polyline(p3, p1, p2, p4)
	render(g1)
	.circle(c, r1)
	.circle(c, r2)
	.circle(c, r3)
	#.circle(c, r4)
	.crosshair(c, 2.0, 3)
	.spokes(c, r1, r2, sn, sd)

	# fork
	ts = ns * pi / n
	te = rad(2.0) # todo: this is a depending var
	p0 = c
	p3 = [c[0], c[1] - r4 / cos(pi * ns / n)]
	p4 = rot(c, r4, ts + te - pi2)
	p5 = rot(c, r4, ts - te - pi2)
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
	render(g2)
	.crosshair(p3, 2.0, 3)
	.circle(p3, r1)
	.line(p8, p9)
	#.line(p11, p9)
	.line(p10, p11)
	.spokes(p3, r1, rfi, 3, sd, -pi2 - rad(1.0))
	.path("M#{p8[0]},#{p8[1]}A#{rfi},#{rfi},0,1,0,#{p10[0]},#{p10[1]}")
	.path("M#{p9[0]},#{p9[1]}A#{rfa},#{rfa},0,1,0,#{p11[0]},#{p11[1]}")
	.transform({rotation: 3.0, cx: p3[0], cy : p3[1]}, true)

	animation = () ->
		lock = true
		tic = (p) -> if lock and p > 0.5 then lock = false; wtic()
		wtic = () -> g1.animate(500, '-').transform({rotation: -6, cx: c[0], cy : c[1]}, true).after(() -> lock = true)
		ftic = (t) -> g2.animate(1000, '<>').transform({rotation: t, cx: p3[0], cy : p3[1]}, true).during(tic).after(() -> ftic(-t))
		ftic(-6)

	{svg, g1, g2, animation}

animate_escapement = (gg) ->
	gg

# animate escapement
animate_escapement2 = (e) ->
	lock = true
	tic = (p) -> if lock and p > 0.5 then lock = false; wtic()
	wtic = () -> e.g1.animate(500, '-').transform({rotation: -6, cx: e.g1.c[0], cy : e.g1.c[1]}, true).after(() -> lock = true)
	ftic = (t) -> e.g2.animate(1000, '<>').transform({rotation: t, cx: e.g2.c[0], cy : e.g2.c[1]}, true).during(tic).after(() -> ftic(-t))
	ftic(-6)

render_ratchet = (c, r1, r2, r3, r4, sd, sn, n = 6) ->
	svg = SVG("drawing").size("210mm", "297mm").viewbox(0, 0, 210, 297)
	style = "fill:none;stroke:#000000;stroke-width:0.2"
	g1 = svg.group().attr("id", "wheel").attr("style", style).translate(0, 297).scale(1, -1)
	render_ratchet_wheel(g1, c, r1, r2, r3, r4, sd, sn, n)
	g2 = svg.group().attr("id", "pawl").attr("style", style).translate(0, 297).scale(1, -1)
	render_ratchet_pawl(g2, c, r3, r4, n)
	{g1: g1, g2: g2, svg:svg.svg()}

render_ratchet_wheel = (svg, c, r1, r2, r3, r4, sd, sn, n) ->
	phi = 2 * pi / n
	tn = 40
	d = r4 - r3
	hr = d / tn
	ht = phi / tn
	for i in [0 .. n - 1]
		t0 = pi2 + i * phi
		p0 = rot(c, r3, t0)
		p1 = rot(c, r4, t0)
		points = for j in [0 .. tn]
			r = r4 - j * hr
			t = t0 + j * ht
			rot(c, r, t)
		svg.polyline([p0, p1])
		svg.polyline(points)
	svg.circle().radius(r1).cx(c[0]).cy(c[1])
	svg.circle().radius(r2).cx(c[0]).cy(c[1])
	svg.circle().radius(r3).cx(c[0]).cy(c[1])
	#svg.circle().radius(r3 + 0.5*d).cx(c[0]).cy(c[1])
	#svg.circle().radius(r4).cx(c[0]).cy(c[1])
	G(svg).crosshair(c, 2.0, 3)
	G(svg).spokes(c, r1, r2, sn, sd)
	svg.c = c
	cp = [c[0], c[1] + r4 + 2 * d]
	angles = tri(dist(p0, cp), r4, r4 + 2 * d)
	svg.t0 = deg(angles.alpha)
	svg.t1 = 360 / n
	svg.tp = (svg.t0 - svg.t1) / svg.t0
	console.log("tp", svg.tp)

render_ratchet_pawl = (svg, c, r1, r2, n) ->
	phi = 2 * pi / n
	tn = 40
	d = r2 - r1
	cy = c[1] + r2 + 2 * d
	cr = 1.5 * d
	cp = [c[0], cy]
	r0 = cy - c[1] + cr
	hr = (r0 - r2) / tn
	ht = phi / tn
	p1 = rot(c, r1, pi2 + phi)
	p2 = rot(c, r2, pi2 + phi)
	p3 = rot(c, r1 + cr, pi2)
	p4 = rot(c, r1 + 3 * cr, pi2)
	poly1 = (for i in [1 .. tn]
		r = r0 - i * hr
		t = pi2 + i * ht
		rot(c, r, t)
	).filter((p) -> dist(p, cp) >= cr)
	hr = 1.5 * d / tn
	poly2 = for i in [0 .. tn]
		r = r1 + i * hr
		t = pi2 + phi - i * ht
		rot(c, r, t)
	svg.polyline([p1, p2])
	#svg.polyline([p3, p4])
	svg.polyline(poly1)
	svg.polyline(poly2)
	svg.circle().radius(cr).cx(cp[0]).cy(cp[1])
	G(svg).crosshair(cp, 2.0, 3)
	#svg.path("M#{p4[0]},#{p4[1]}A#{cr},#{cr},0,1,0,#{p3[0]},#{p3[1]}")
	a = dist(p1, cp)
	tri1 = tri(a, r2, r2 + 2 * d)
	tri2 = tri(a, r1 + 0.5 * d, r2 + 2 * d)
	tri3 = tri(a, r1, r2 + 2 * d)
	beta0 = tri1.beta - tri3.beta
	beta1 = tri1.beta - tri2.beta
	pv = rot(cp, a, - pi2 - tri1.beta)
	svg.c = cp
	svg.t0 = deg(beta0)
	svg.t1 = deg(beta1)
	svg.phi0 = deg(1.5 * pi - tri3.beta)
	svg.phi1 = deg(1.5 * pi - tri1.beta)
	svg.phid = abs(svg.phi1 - svg.phi0)
	console.log("phid=", svg.phid)
	#svg.circle().radius(a).cx(cp[0]).cy(cp[1])

animate_ratchet = (r, time = 1000) ->
	p = r.g1.tp
	dur =  p * time
	dur1 = (1 - p) * time
	wphi = p * r.g1.t0
	wphi1 = (1 - p) * r.g1.t0
	fphi = p * r.g2.phid
	rot0 = r.g2.transform().rotation
	wtic = (d, t, a) -> r.g1.animate(d, '-').transform({rotation: t, cx: r.g1.c[0], cy : r.g1.c[1]}, true).during(wticevent).after(a)
	wticevent = (pos, morph, eased, situation) ->
		rot = r.g2.transform().rotation - (rot0 + pos * fphi)
		r.g2.transform({rotation: rot, cx: r.g2.c[0], cy : r.g2.c[1]}, true)
	after0 = () ->
		rot0 = r.g2.transform().rotation
		fphi = (1 - p) * r.g2.phid
		wtic(dur1, wphi1, after1)
	after1 = () ->
		r.g2.transform({rotation: fphi, cx: r.g2.c[0], cy : r.g2.c[1]}, true)
		wtic(dur1, wphi1, after1)
	wtic(dur, wphi, after0)

base_plan = (rg) ->
	r1 = 4 / pi
	r12 = 12 * r1
	r18 = 18 * r1
	r24 = 24 * r1
	r36 = 36 * r1
	r48 = 48 * r1
	r54 = 54 * r1
	r60 = 60 * r1
	x0 = 100
	y0 = 15
	y1 = y0 + r12 + r60
	y2 = y0 + 2 * r12 + 2 * r54
	x3 = x0 - r12 - r24
	x4 = x0 + r12 + r24
	c0 = [x0, y0]
	c1 = [x0, y1]
	c2 = [x0, y2]
	c3 = [x3, y2]
	c4 = [x4, y2]
	sn1 = intCircleCircle(c1, r48, c3, r36)
	c5 = sn1[1]
	sn2 = intCircleCircle(c1, r48, c4, r36)
	c6 = sn2[0]
	rew = 70
	yef = y2 + rew / cos(pi * 6.5 / 30)
	c7 = [x0, yef]
	y8 = y0 + r12 + r54
	c8 = [x0, y8]
	rg
	.crosshair(c0).text(c0, "c0", [4, 8]).circle(c0, r12).circle(c0, r60)
	.crosshair(c1).circle(c1, r12).circle(c1, r36)
	.crosshair(c2).circle(c2, r12)#.circle(c2, rew)
	.crosshair(c3).circle(c3, r12).circle(c3, r24)
	.crosshair(c4).circle(c4, r12).circle(c4, r24)
	.crosshair(c5).circle(c5, r12).circle(c5, r24)
	.crosshair(c6).circle(c6, r12).circle(c6, r24)
	.crosshair(c7).text(c7, "EF", [5, 10])
	.crosshair(c8, 1.5, 2)#.circle(c8, r54).circle(c8, r18)

gear = (g1, g2) ->
	svg = create_svg("fill:none;stroke:#000000;stroke-width:0.2", "g1", "g2")
	g1 = svg["g1"]
	g2 = svg["g2"]
	p = 8
	a = rad(20)
	n1 = 12
	n2 = 36
	m = p / (2 * pi)
	rd = (n1 + n2) * m
	c1 = [70, 250]
	c2 = [70, 250 - rd]
	r21 = 12
	r22 = 38
	phi0 = 1.5 * pi + pi / n2
	render(g1).gear(c1, n1, p, a).crosshair(c1)
	render(g2).gear(c2, n2, p, a, phi0).crosshair(c2).circle(c2, r21).circle(c2, r22).spokes(c2, r21, r22, 6, 6)

	animation = () ->
		n = 500000
		phi1 = n * 360 / n1
		phi2 = -n * 360 / n2
		t = 1000000000
		g1.animate(t).transform({rotation:phi1, cx:c1[0], cy:c1[1]}, true)
		g2.animate(t).transform({rotation:phi2, cx:c2[0], cy:c2[1]}, true)

	{svg, g1, g2, animation}

animation_stop = (gg) -> gg[key].stop() for key in Object.keys(gg) when key.startsWith("g")

#window.render_result = render_ratchet([100, 150], 15.0, 54.0, 62.0, 70.0, 8.0, 6, 12)
#window.render_result = render_wheel([100, 200], 15.0, 54.0, 62.0, 6, 8.0)

window.gg = gear()
window.svg = gg.svg

window.start_animation = () -> gg.animation()
window.stop_animation = () -> animation_stop(gg)
window.open_svg = () -> window.open("data:image/svg+xml," + escape(svg.svg.svg()));

start_animation()
