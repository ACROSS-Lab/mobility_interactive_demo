/**
* Name: NewModel
* Based on the internal empty template. 
* Author: THANTHUY
* Tags: 
*/


model NewModel



global {
	int nb_people <- 20;
	float step <- 10 #mn;
	list available_office <- [];
	graph road_network;
	map<road,float> new_weights;
	map<string,rgb> colors <- ["Empty building":: #blue, "House":: #yellow, "Office" :: #orange, "abc"::#green];
	image_file image_file_test <- image_file("../includes/images.jpg");


	geometry shape <- rectangle(1920, 1080);
	
	

	//tolerance for the comparison of color (white and black)
	float tolerance_BW <- 1.2 min: 1.0 max: 2.0 step: 0.1 parameter: true;
	
	//allow to increase the constrast of the image
	float coeff_constrast <- 1.0 min: 1.0 max:3.0 step: 0.1 parameter: true;
	
	//define the low threshold for the detection of block
	float low_threhold_block_detection <- 0.1 min: 0.0 max:0.5 step: 0.1 parameter: true;
	
	//define the high threshold for the detection of block
	float high_threhold_block_detection <- 0.5 min: 0.1 max:1.0 step: 0.1 parameter: true;
	
	//apply filters to improve the image quality
	bool improve_image <- false parameter: true;
	
	//possibility to save all the images produced for debugging puropose
	bool save_image <- false parameter: true;

	
	list<point> distorsion_points <- [{376.61492919921875,56.092952728271484,0.0},{1410.7509765625,26.614917755126953,0.0},{1418.1085205078125,1043.54931640625,0.0},{406.0964050292969,1068.1136474609375,0.0}];
	list<point> bounds_points <- [{668.4972170686457,466.4175824175824,0.0},{736.1781076066791,525.7582417582418,0.0}];
	list<point> blacksubblock_points <-[{537.8849721706865,469.978021978022,0.0},{569.9443413729128,497.2747252747253,0.0}];
	list<point> whitesubblock_points <-[{699.3692022263451,331.1208791208791,0.0},{731.4285714285714,360.7912087912088,0.0}];
	
	string current_mode <- "";
	list<pattern> patterns; 
	bool define_bounds_points <- false;
	bool define_distorsion_points <- false;
	bool define_whitesubblock_points <- false;
	bool define_blacksubblock_points <- false;
	point mouse_location;
	map<string,list<point>> blocks_detected;
	
	init {
		//1 = white;  0 = black
		patterns << create_pattern("Empty building", 0,1,1,1);
		patterns << create_pattern("House", 1,1,1,0);
		patterns << create_pattern("Office", 1,0,0,1);
		patterns << create_pattern("Office", 0,1,1,0);
		patterns << create_pattern("abc", 0,0,1,1);
	
		
		point pt0 <- distorsion_points[0];
		point pt1 <- distorsion_points[2];
		
		float w <- pt1.x - pt0.x;
		float h <- pt1.y - pt0.y;

		do create_agents;
		
			
	}
	reflex test_grid{
		ask environment{
			create house{
				location <- environment[0,0];
			}
		}
	} 

	action mouse_click1{
//		create house{
//			location <- environment[0,0];
//			color <- colors['House'];
//			shape <- environment[0,0].shape;
//		}
		environment selected_cell <- first(environment overlapping (#user_location));
		//write selected_cell;
		if selected_cell != nil{
			write('mouse click detected on grid model');
			if(house overlapping (#user_location) = [] and office overlapping (#user_location) = []){
				write('mouse click detected');
				create house{
					location <- selected_cell.location;
					color <- colors['House'];
					shape <- selected_cell.shape;
				}
			}
			else if(house overlapping (#user_location) != []){
				ask house overlapping (#user_location) {
					create office{
						color <- colors['Office'];
						location <- myself.location;
						shape <- myself.shape;
					}
				do die;
			}
		}
	}	
}
	
	
	
	action create_agents;
	
	//create a new pattern from a 2x2 matrix
	pattern create_pattern(string id, int v00,int v01,int v10,int v11) {
		matrix m <- {2,2} matrix_with 0;
		m[0,0] <- v00;m[0,1] <- v01;m[1,0] <- v10;m[1,1] <- v11; 
		pattern p  <- pattern_with(id, {2,2}, 0);
		p <- p with_matrix m;
		return p;
	}
	
	action define_distorsions_points {
		define_distorsion_points <- not define_distorsion_points;
		define_whitesubblock_points <- false;
		define_blacksubblock_points <- false;
		define_bounds_points <- false;
		distorsion_points <- [];
		
		current_mode <- "Definition of distorsion points";
	}
	
	action define_white_subblock {
		define_distorsion_points <- false;
		define_whitesubblock_points <- not define_whitesubblock_points;
		define_blacksubblock_points <- false;
		define_bounds_points <- false;
		whitesubblock_points <- [];
		current_mode <- "Definition of the white block";
	}
	
	action define_black_subblock {
		define_distorsion_points <- false;
		define_whitesubblock_points <- false;
		define_blacksubblock_points <- not define_blacksubblock_points;
		define_bounds_points <- false;
		blacksubblock_points <- [];
		current_mode <- "Definition of the black block";
	}
	
	action define_mouse_loc {
		mouse_location <- #user_location;
	}
	
	action define_bounds {
		define_distorsion_points <- false;
		define_whitesubblock_points <- false;
		define_blacksubblock_points <- false;
		define_bounds_points <- not define_bounds_points;
		bounds_points <- [];
		current_mode <- "Definition of the block bound";
	}
	
	action mouse_click {
			
		if define_distorsion_points {
			if (length(distorsion_points) < 4) {
				distorsion_points << #user_location;
				if length(distorsion_points) = 4{
					write sample(distorsion_points);
				}
				
			}
		} else if define_whitesubblock_points {
			if (length(whitesubblock_points) < 2) {
				whitesubblock_points << #user_location;
				if (length(whitesubblock_points) = 2) {
					write sample(whitesubblock_points);
				} 
			}
			
		} else if define_blacksubblock_points {
			if (length(blacksubblock_points) < 2) {
				blacksubblock_points << #user_location;
				if (length(blacksubblock_points) = 2) {
					write sample(blacksubblock_points);
				} 
			} 
			
		} else if define_bounds_points {
			if (length(bounds_points) < 2) {
				bounds_points << #user_location;
				if (length(bounds_points) = 2) {
					write sample(bounds_points);
				} 
			} 
			
		}
	}
	
	action define_code {
		
		current_mode <- "Detection of the codes of the blocks";
		write "Detection of the codes of the blocks";
		blocks_detected <- [];
		
		//building the geometries (black block, white block, block bounds) from the points defined
		geometry black_subblock <- length(blacksubblock_points) = 2 ? polygon([blacksubblock_points[0],{blacksubblock_points[1].x, blacksubblock_points[0].y},blacksubblock_points[1],{blacksubblock_points[0].x, blacksubblock_points[1].y} ]): nil;
		geometry white_subblock <- length(whitesubblock_points) = 2 ? polygon([whitesubblock_points[0],{whitesubblock_points[1].x, whitesubblock_points[0].y},whitesubblock_points[1],{whitesubblock_points[0].x, whitesubblock_points[1].y} ]): nil;
		geometry bounds_g <- length(bounds_points) = 2 ? polygon([bounds_points[0],{bounds_points[1].x, bounds_points[0].y},bounds_points[1],{bounds_points[0].x, bounds_points[1].y} ]): nil;
		
		//detecting the code
		list<block> blocks <- detect_blocks(
			image_file_test.path, //image from which detecting the block code
			patterns, //list of patterns to detect
			distorsion_points, //list of 4 detection points (top-left, top-right, bottom-right, bottom-left)
			  8,8, //size of the grid (columns, rows)
			  black_subblock, //black subblock for the computation of the black intensity 
			  white_subblock,//white subblock for the computation of the white intensity
			  bounds_g, //example of block for computation of the expected size of blocks
			 tolerance_BW, //optional: tolerance for black and white color: default: 1.0
			low_threhold_block_detection,//optional: low threshold for block detection, default: 0.1
			 high_threhold_block_detection, //optional: high threshold for block detection, default: 0.5
			 coeff_constrast, //optional: coefficient to increase the contrast of the imahe, default: 2.0 
			 save_image, //optional: save the image produced (just for debugging purpose)
			improve_image //optional: apply filter on the image, default: false
		);
		
		int count_house <- 0;
		loop a over: blocks{
			if (a = nil or a.type = nil){
				continue;				
			}
			
			if(a.type.id = "House"){
				ask environment{
					create house{
						location <- environment[0,0];
						shape <- square(5);
						color <- #yellow; 
					}
				}
	
			}
		}
		
		//group the blocks per id for visualization purpose
		loop b over: blocks {
			if  b.type != nil {
				if not(b.type.id in blocks_detected.keys) {
					blocks_detected[b.type.id] <- [b.shape.location];
				} else {
					blocks_detected[b.type.id] << b.shape.location;
				}				
			} 
		}
		
		//validation of the code - if there is an error (pattern not detected, or wrong pattern detected), display a square around the falty blocks
		ask cell {
			error <- true;
			loop bb over: blocks {
				if bb.shape overlaps self {
					error <- bb.type = nil or (int(float(type)) != int(bb.type.id)) ;
					break;
				}
			} 
		}
		write "Number of errors: " + (cell count each.error);
	}
}


species road{
	rgb color <- #black;
	aspect default{
		draw shape color: color;
	}
}

species empty_building{
	rgb color;
	
	aspect default{
		draw shape color:color;
	}
}

species house parent:empty_building{
}

species office parent:empty_building{
}

grid environment height:8 width:8 neighbors:4{
	list<environment> neighbors2 <- self neighbors_at 2;

}



species cell 
{
	string type;
	rgb color;
	bool error <- false;
	
	aspect default {
		if error {
			draw shape.contour width: 5 color: color;
		}
	}
}


experiment analyseImage type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display image_display {
			overlay position: { 5, 5 } size: { 800 #px, 180 #px } background: # black transparency: 0.4 border: #black rounded: true
            {
            	draw "current action: " + current_mode at: { 50#px,  30#px } color: # white font: font("Helvetica", 30, #bold);
            	draw "'d': detecting codes of blocks" at: { 50#px,  60#px } color: # white font: font("Helvetica", 20, #bold);
            	
            	draw "'p': define the distorsion points" at: { 50#px,  80#px } color: # white font: font("Helvetica", 20, #bold);
            	draw "'b': define the black block" at: { 50#px,  100#px } color: # white font: font("Helvetica", 20, #bold);
            	draw "'w': define the white block" at: { 50#px,  120#px } color: # white font: font("Helvetica", 20, #bold);
            	draw "'g': define the bound of block" at: { 50#px,  140#px } color: # white font: font("Helvetica", 20, #bold);
            	
            }
			image image_file_test;
			species cell position: {0,0,0.01};
			event "p" action: define_distorsions_points;
			event "d" action: define_code;
			event "b" action: define_black_subblock;
			event "w" action: define_white_subblock;
			event "g" action: define_bounds;
			event #mouse_move action: define_mouse_loc;
			event #mouse_down action: mouse_click;
			graphics "mouse_loc" {
				draw circle(5) at: mouse_location;
			}
			graphics "distorsion" {
				loop pt over: distorsion_points {
					draw circle(10) color: #red at: pt;
				}
			}
			graphics "blackSubBlock" {
				loop pt over: blacksubblock_points {
					draw circle(2) color: #magenta at: pt;
				}
			}
			graphics "whiteSubBlock" {
				loop pt over: whitesubblock_points {
					draw circle(2) color: #cyan at: pt;
				}
			}
			graphics "bounds points" {
				loop pt over: bounds_points {
					draw square(2) color: #gold at: pt;
				}
			}
			graphics "blocks detected" {
				loop id over: blocks_detected.keys {
					rgb col <- colors[id];
					loop pt over: blocks_detected[id] {
						draw circle(20) color: col at: pt;
					}
				}
			}
		}
	
	
		display main_display type:opengl{
			grid environment border: #black;
			species empty_building aspect: default;
			species road aspect: default;
			species house aspect: default;
			species office aspect: default;
			event mouse_down action:mouse_click1;
		}	
	
	}
}