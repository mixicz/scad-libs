// ---=== antiwarp ===---

// "V" shape cut (internal function)
/* 
   TOP view (XY)        SIDE view (YZ)
   <--- w -->               <--- l -->
   __________               __________
   \        /  ^           /         /  ^
    \      /   |          /         /   |
     \    /    | l       /         /    | h
      \  /     |        /. angle  /     |
       \/      v       /__)______/      v
*/
module aw_cut(w, l, h, angle = 90) {
    ao = h * tan(angle - 90);
    points = [
        [-w/2, -.001, 0],
        [   0,     l, 0],
        [ w/2, -.001, 0],
        [-w/2, -.001+ao, h],
        [   0,     l+ao, h],
        [ w/2, -.001+ao, h],
    ];
    faces = [
        [0, 2, 1],
        [3, 4, 5], 
        [0, 1, 4, 3],
        [1, 2, 5, 4], 
        [0, 3, 5, 2]
    ];
    
    polyhedron(points=points, faces=faces);
}

/*
Renders a grid of "V" shaped notches which is used to prevent warping of large flat surfaces.
Base orientation is along X and Z axes with notches direction in positive values on Y axis.

Parameters:
    w, h - width and height of the grid
    center_x, center_z - whether the grid is centered along X and Z axes
    cut_w - width of the notches
    cut_l - length (depth) of the notches
    cut_h - height of the notches
    spacing - distance between notches, if 0 then calculated from density
    density - number of notches per unit of cut_w
    ofs - offset of the consecutive rows of notches as fraction of notch distance
    angle - angle of the surface (90 = vertical surface) - this is prefered over rotating along X axis as this will keep the notches fully horizontal in order to slice properly
    render - render the notches or display just transparent mockup surface to highlight the affected area (in preview mode)
*/
module aw(w, h, center_x = false, center_z = false, cut_w = .2, cut_l = 1, cut_h = 3, spacing = 0, density = 0.1, ofs = .5, angle = 90, render = !$preview) {
    dist = spacing > 0 ? spacing : cut_w / density;
    x0 = center_x ? -w/2 : 0;
    z0 = center_z ? -h/2 : 0;
    xs = ( w % dist ) / 2;
    xo = dist * ofs;
    count_x = floor(w / dist);
    count_z = floor(h / cut_h);
    top_h = h % cut_h;
    
    if (render) {
        for (xi = [0 : count_x]) {
            for (zi = [0 : count_z-1]) {
                if (zi%2 == 0 || xi < count_x) {
                    translate([x0+xs+xi*dist+xo*(zi%2), zi*cut_h*tan(angle-90), z0+zi*cut_h]) aw_cut(w=cut_w, l=cut_l, h=cut_h, angle=angle);
                }
            }
            if (top_h > 0.001) {
                if (count_z%2 == 0 || xi < count_x) {
                    translate([x0+xs+xi*dist+xo*(count_z%2), count_z*cut_h*tan(angle-90), z0+count_z*cut_h]) aw_cut(w=cut_w, l=cut_l, h=top_h, angle=angle);
                }
            }
        }
    } else {
        #hull() {
            translate([x0+xs, -.001, z0]) cube([count_x*dist, cut_l, .001]);
            translate([x0+xs, h*tan(angle-90)-.001, z0+h-.001]) cube([count_x*dist, cut_l, .001]);
        }
    }
}
