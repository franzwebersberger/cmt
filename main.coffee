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
render_escapement = (c, r1, r2, r3, r4, sd, sn, n = 30, ns = 6.5) ->
	svg = SVG("drawing").size("210mm", "297mm").viewbox(0, 0, 210, 297)
	style = "fill:none;stroke:#000000;stroke-width:0.2"
	g1 = svg.group().attr("id", "wheel").attr("style", style).translate(0, 297).scale(1, -1)
	render_escapement_wheel(g1, c, r1, r2, r3, r4, sd, sn, n)
	g2 = svg.group().attr("id", "fork").attr("style", style).translate(0, 297).scale(1, -1)
	render_escapement_fork(g2, c, r1, r4, sd, n, ns)
	{g1: g1, g2: g2, svg:svg.svg()}

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
sqrt = Math.sqrt
sqr = (x) -> x * x
rad = (x) -> x * pi / 180
deg = (x) -> x * 180 / pi
dist = (p1, p2) -> sqrt(sqr(p2[0] - p1[0]) + sqr(p2[1] - p1[1]))
rot = (p, r, t) -> [p[0] + r * cos(t), p[1] + r * sin(t)]
tri = (a, b, c) ->
	angle =
		alpha: acos((sqr(b) + sqr(c) - sqr(a)) / (2 * b * c))
		beta: acos((sqr(a) + sqr(c) - sqr(b)) / (2 * a * c))
		gamma: acos((sqr(a) + sqr(b) - sqr(c)) / (2 * a * b))

# center circles (crosshair)
render_center = (svg, c, r1, n) ->
	for i in [1 .. n]
		svg.circle().radius(i * r1).cx(c[0]).cy(c[1])
	d = (n + 1) * r1
	svg.line(c[0] - d, c[1], c[0] + d, c[1])
	svg.line(c[0], c[1] - d, c[0], c[1] + d)

# spokes
render_spokes = (svg, c, r1, r2, d, n, t0 = 0) ->
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
		t2 = t1 - te
		t3 = t1 + pi - tt
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
	svg.c = c

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
	svg.transform({rotation: 3.0, cx: p3[0], cy : p3[1]}, true)
	svg.c = p3

# animate escapement
animate_escapement = (e) ->
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
	render_center(svg, c, 2.0, 3)
	render_spokes(svg, c, r1, r2, sd, sn)
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
	#render_center(svg, p1, 1, 1)
	svg.circle().radius(cr).cx(cp[0]).cy(cp[1])
	render_center(svg, cp, 2.0, 3)
	#svg.path("M#{p4[0]},#{p4[1]}A#{cr},#{cr},0,1,0,#{p3[0]},#{p3[1]}")
	a = dist(p1, cp)
	tri1 = tri(a, r2, r2 + 2 * d)
	tri2 = tri(a, r1 + 0.5 * d, r2 + 2 * d)
	tri3 = tri(a, r1, r2 + 2 * d)
	beta0 = tri1.beta - tri3.beta
	beta1 = tri1.beta - tri2.beta
	pv = rot(cp, a, - pi2 - tri1.beta)
	#render_center(svg, pv, 1, 1)
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


window.start_animation = () -> window.animation = animate_ratchet(render_result, 500)
window.stop_animation = () -> window.animation?.stop()
#window.render_result = render_escapement([100, 220], 12, 47, 55, 70, 8.0, 6, 30, 6.5)
#animate_escapement(render_result)
window.render_result = render_ratchet([100, 150], 15.0, 54.0, 62.0, 70.0, 8.0, 6, 12)
document.getElementById("download").href = "data:image/svg+xml," + render_result.svg

window.g = render_result.g2
window.c = render_result.g2.c
