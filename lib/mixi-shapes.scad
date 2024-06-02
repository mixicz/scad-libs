// Library: various shapes

// Thread library: https://dkprojects.net/openscad-threads/
// diameter pitch
// M2       .4
// M2.5     .45
// M3       .5
// M4       .7
// M5       .8
// M6       1
// M8       1.25
use <threads.scad>
thread_pitch = [0, .25, .4, .5, .7, .8, 1, 1, 1.25];

dir_1d = [-1, 1];
dir_2d = [
    [-1, -1, 0],
    [ 1, -1, 0],
    [-1,  1, 0],
    [ 1,  1, 0]
];


// ---=== 2D ===---

module brsquare(dim, r, center=false) {
    ds = [
        [dim[0]-2*r, dim[1]],
        [dim[0], dim[1]-2*r]
    ];
    cir = [
        [r, r],
        [r, dim[1]-r],
        [dim[0]-r, r],
        [dim[0]-r, dim[1]-r]
    ];
    
    t = center ? -dim/2 : [0,0];
    translate(t) {
        for (c = cir) {
            translate([c[0], c[1]]) bcircle(r=r);
        }
        for (c = ds) {
            translate([dim[0]/2, dim[1]/2]) square(c, center=true);
        }
    }
}

module bcircle(d = 0, r = 0) {
    r = ( r ? r : d/2 ) / cos(180/$fn);
    rotate([0, 0, 180/$fn]) circle(r=r);
}


// sector() and arc() modules are based on
//    https://openhome.cc/eGossip/OpenSCAD/SectorArc.html

module sector(r, a1 = 0, a2 = 90) {
    rr = r / cos(180 / $fn);
    step = -360 / $fn;

    points = concat([[0, 0]],
        [for(a = [a1 : step : a2 - 360]) 
            [rr * cos(a), rr * sin(a)]
        ],
        [[rr * cos(a2), rr * sin(a2)]]
    );

    difference() {
        circle(r);
        polygon(points);
    }
}

module arc(r1, r2, a1 = 0, a2 = 90) {
    difference() {
        sector(max(r1, r2), a1, a2);
        sector(min(r1, r2), a1, a2);
    }
} 


// ---=== bezier curves === ---

// source: https://gist.github.com/thehans/2da9f7c608f4a689456e714eaa2189e6
// works with both 2D and 3D

// return point along curve at position "t" in range [0,1]
// use ctl_pts[index] as the first control point
// Bezier curve has order == n
function bezier_point(ctl_pts, t, n, index=0) = (n > 1) ? 
  _bezier_point([for (i = [index:index+n-1]) ctl_pts[i] + t * (ctl_pts[i+1] - ctl_pts[i])], t, n-1) :
  ctl_pts[index] + t * (ctl_pts[index+1] - ctl_pts[index]);

// slightly optimized version takes less parameters
function _bezier_point(ctl_pts, t, n) = (n > 1) ? 
  _bezier_point([for (i = [0:n-1]) ctl_pts[i] + t * (ctl_pts[i+1] - ctl_pts[i])], t, n-1) :
  ctl_pts[0] + t * (ctl_pts[1] - ctl_pts[0]);

// n sets the order of the Bezier curves that will be stitched together
// if no parameter n is given, points will be generated for a single curve of order == len(ctl_pts) - 1
// Note: $fn is number of points *per segment*, not over the entire path.
function bezier_path(ctl_pts, n, index=0) = 
  let (
    l1 = $fn > 3 ? $fn : 200,
    l2 = len(ctl_pts),
    n = (n == undef || n > l2-1) ? l2 - 1 : n
  )
  //assert(n > 0)
  [for (segment = [index:n:l2-1-n], i = [0:l1-1])
    bezier_point(ctl_pts, i / l1, n, segment), ctl_pts[l2-1]];


// ---=== round cubes ===---

module brcube_z(dim, r, center=false) {
    ds = [
        [dim[0]-2*r, dim[1], dim[2]],
        [dim[0], dim[1]-2*r, dim[2]]
    ];
    cyl = [
        [r, r, 0, dim[2]],
        [r, dim[1]-r, 0, dim[2]],
        [dim[0]-r, r, 0, dim[2]],
        [dim[0]-r, dim[1]-r, 0, dim[2]]
    ];
    
    t = center ? -dim/2 : [0,0,0];
    translate(t) {
        for (c = cyl) {
            translate([c[0], c[1], c[2]]) bcylinder(r=r, h=c[3]);
        }
        for (c = ds) {
            translate([dim[0]/2, dim[1]/2, dim[2]/2]) cube(c, center=true);
        }
    }
}

module brcube(dim, r, center=false) {
    t = center ? -dim/2 : [0,0,0];
    a = 180 / $fn;
    hull() {
        for (x = [r, dim[0]-r])
            for (y = [r, dim[1]-r])
                for (z = [r, dim[2]-r])
                    translate(t+[x, y, z]) rotate([0, 0, a]) scale([1/cos(a), 1/cos(a), 1]) sphere(r = r/cos(a));
    }
}



// ---=== cylinders ===---

module bcylinder(d = 0, r = 0, h = 0, center = false) {
    r = ( r ? r : d/2 ) / cos(180/$fn);
    rotate([0, 0, 180/$fn]) cylinder(r=r, h=h, center=center);
}

module bcylinder_rim(d, h, rim_w = 2, rim_scale = 1) {
    cylinder(d=d, h=h);
    for (z = [rim, h-rim]) {
        translate([0, 0, z]) rotate_extrude() translate([d/2, 0, 0]) scale([rim_scale, 1, 1]) circle(r = rim);
    }
}

module brcylinder(d = 0, r = 0, h = 0, rr = 0, rfn = 0, center = false) {
    r = ( r ? r : d/2 ) / cos(180/$fn);
    rfn = rfn ? rfn : $fn;
    rrr = rr ? rr : r * .1;
    rr = rrr / cos(180/rfn);
    
    rotate([0, 0, 180/$fn]) cylinder(r=r-rr, h=h, center=center);
    translate([0, 0, center?0:rr]) rotate([0, 0, 180/$fn]) cylinder(r=r, h=h-2*rr, center=center);
    for (z = [(center?-h/2:0)+rrr, (center?h/2:h)-rrr])
        translate([0, 0, z]) rotate([0, 0, 180/$fn]) rotate_extrude() translate([r-rrr, 0, 0]) rotate([0, 0, 180/rfn]) circle(r=rr, $fn=rfn);
}

module bring(d = 0, r = 0, a = 360, rr = 0, rfn = 0, rot = true) {
    r = ( r ? r : d/2 ) / cos(180/$fn);
    rfn = rfn ? rfn : $fn;
    rrr = rr ? rr : r * .1;
    rr = rrr / cos(180/rfn);

    rotate([0, 0, rot ? 180/$fn : 0]) rotate_extrude(angle=a) translate([r, 0, 0]) rotate([0, 0, 180/rfn]) circle(r=rr, $fn=rfn);
}

module bsphere(d = 0, r = 0) {
    r = ( r ? r : d/2 ) / cos(180/$fn);
    sphere(r=r);
}

module torus(d = 0, r = 0, dr = 0, rr = 0, angle = 360) {
    r = r ? r : d / 2;
    rr = rr ? rr : dr / 2;
    
    rotate_extrude(angle=angle) translate([r, 0]) { 
        if (r <= rr) {
            difference() {
                circle(r=rr);
                translate([-r-rr+.001, 0]) square([2*rr+.002, 2*rr+.002], center=true);
            }
        } else {
            circle(r=rr);
        }
    }
}



// ---=== threads ===---

module thread(m = 0, l, pitch = -1, d = 0, internal = true, leadin = 0) {
    d = d > 0 ? d : (internal ? m * .05 + .1 : m);
    pitch = pitch > 0 ? pitch : thread_pitch[m];
    echo("Thread: M", m, " pitch=", pitch, " d=", d, " l=", l, " internal=", internal, " leadin=", leadin);
    if ($preview)
        cylinder(d=d-pitch, h=l);
    else
        metric_thread(diameter=d, pitch=pitch, length=l, internal=internal, leadin=leadin);
}


// ---=== screws ===---

// direction upwards
module screw_head_v(d = 0, m = 0, do = 0, l = 10, lh = 10) {
    di = d ? d : m + .5;
    do = do ? do : 2 * di;
    vh = (do - di) / 2;
    
    cylinder(d=di, h=l);
    cylinder(d1=do, d2=di, h=vh);
    translate([0, 0, -lh]) cylinder(d=do, h=lh+.001);
}

// direction upwards
module screw_head_flat(d = 0, m = 0, do = 0, l = 10, lh = 10, head = true) {
    di = d ? d : m + .5;
    do = do ? do : 2 * di;
    vh = (do - di) / 2;
    hh = head ? di : .001;
    
    cylinder(d=di, h=l);
    translate([0, 0, -lh]) cylinder(d=do, h=lh+hh);
}

// Supported only standard metric thread sizes M1-M10, for other you need to specify "size" (=spanner width)
module nut(size = 0, m = 0, h = 10, sides = 6, tol = .4, center = false) {
    // convert metric thread size to table index: 1.6, 2.5, 3.5, 1, 2, 3, ...
    function _idx(m) = abs(m - round(m)) <= .1 ? round(m) + 2 : round(m - 1.5);
    m2size = [
        3.2, 5, 6,
        2.5, 4, 5.5, 7, 8, 10, 11, 13, 0, 17
    ];
    
    size = size > 0 ? size : m2size[_idx(m)];
    dr = ( ( size > 0 ? size : m2size[_idx(m)] ) + tol ) / cos(180/sides);
    
    cylinder(d=dr, h=h, center=center, $fn=sides);
}


include <antiwarp.scad>