panel_width = 297;
panel_height = 210;
panel_angle = 25;
thickness = 4;
front_height = 50;
pillar_width = 20;


box_depth = cos(panel_angle) * (panel_height-2*thickness);
box_height = sin(panel_angle) * panel_height + front_height;


module output_cube(name, width, height) {
    echo(name, width, height);
    cube([width, height, thickness]);
}

module panel()
    rotate(panel_angle, [1,0,0]) cube([panel_width, panel_height, thickness]);

module front()
    output_cube("front", panel_width, front_height);
    
module bottom() {
    output_cube("bottom", panel_width-2*thickness, box_depth);
}

module back() {
    cube([panel_width-2*thickness, box_height, thickness]);
}

module pillar(height, rotation_vector) {
    color([1, 0, 0]) {
        translate([0, pillar_width, 0]) rotate(90, [0,0,-11])
        difference() {
            cube([pillar_width, pillar_width, height]);
            
            // cutout for triangle form
            translate([0,0,-height/2]) rotate(45, [0,0,1]) cube([2*pillar_width, 2*pillar_width, 2*height]);
            // cutout for top angle
            angle_height = rotation_vector == [1,0,0] || rotation_vector == [-1,0,0] ? tan(panel_angle) * pillar_width : 0;
            angle_height2 = rotation_vector == [0,-1,0] ? tan(panel_angle) * pillar_width * 2 : angle_height;

            translate([0,0,height-angle_height2]) rotate(panel_angle, rotation_vector) translate([-pillar_width/2,-pillar_width/2,0]) cube([2*pillar_width, 2*pillar_width, height]);
        }
    }
}

module pillar_with_front_height(height, rotation_vector) {
    added_angle_height = tan(panel_angle) * pillar_width;
    pillar(height+added_angle_height, rotation_vector);
}

module side() {
    color([0.5,0.5,0]) {
        difference() {
            output_cube("side", box_depth+thickness, box_height);
            
            translate([0,front_height,-thickness/2]) rotate(panel_angle, [0,0,1]) cube([2*box_depth, box_height, 2*thickness]);
        }
    }
}

translate([-panel_width - 50, 0, 0]) {
    translate([0, 0, front_height]) panel();
    translate([0, 0, front_height]) rotate(90, [-1,0,0]) front();
    translate([thickness, thickness, 0]) bottom();
    translate([thickness, box_depth+thickness, box_height]) rotate(90, [-1,0,0]) back();
    
    // front left
    translate([thickness,thickness,thickness]) pillar_with_front_height(front_height-thickness, [0,1,0]);
    
    // front right
    translate([panel_width-thickness,thickness,thickness]) rotate(90, [0,0,1]) pillar_with_front_height(front_height-thickness, [1,0,0]);
    
    // back left
    translate([thickness,box_depth+thickness,thickness]) rotate(90, [0,0,-1]) pillar_with_front_height(box_height-thickness, [-1,0,0]);
    
    // back right
    translate([panel_width-thickness,box_depth+thickness,thickness]) rotate(180, [0,0,1]) pillar_with_front_height(box_height-thickness, [0,-1,0]);
    
    // right side
    translate([panel_width-thickness, thickness, 0]) rotate(90, [0,0,1]) rotate(90, [1,0,0]) side();
    
    // left side
    translate([0,thickness,0]) rotate(90, [0,0,1]) rotate(90, [1,0,0]) side();
}