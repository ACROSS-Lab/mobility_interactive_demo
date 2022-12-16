/**
* Name: interactivegrid
* Based on the internal empty template. 
* Author: THANTHUY
* Tags: 
*/


model webcam

import "Grid Model.gaml"

global {
	webcam webcam1 <- webcam(1);
	int image_width <- 480;
	int image_height <- 270; 
	list<environment> houses <- [];
	list<environment> offices <- [];
	list<empty_building> empty_buildings <- [];
	map<string,rgb> colors <- ["Empty building":: #blue, "House":: #yellow, "Office" :: #orange];
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

	
	list<point> distorsion_points <- [{487.9398496240601,92.40641711229948,0.0},{1426.2857142857142,63.529411764705884,0.0},{1504.2406015037593,1056.8983957219252,0.0},{453.29323308270676,1068.4491978609626,0.0}];
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
		patterns << create_pattern("Empty building", 0,0,0,0);
		patterns << create_pattern("House", 1,1,1,1);
		patterns << create_pattern("Office", 1,0,0,1);
		patterns << create_pattern("Office", 0,1,1,0);
	
		
		point pt0 <- distorsion_points[0];
		point pt1 <- distorsion_points[2];
		
		float w <- pt1.x - pt0.x;
		float h <- pt1.y - pt0.y;

		do create_agents;
	
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
		write length(house);
		current_mode <- "Detection of the codes of the blocks";
		write "Detection of the codes of the blocks";
		blocks_detected <- [];
		
		//building the geometries (black block, white block, block bounds) from the points defined
		geometry black_subblock <- length(blacksubblock_points) = 2 ? polygon([blacksubblock_points[0],{blacksubblock_points[1].x, blacksubblock_points[0].y},blacksubblock_points[1],{blacksubblock_points[0].x, blacksubblock_points[1].y} ]): nil;
		geometry white_subblock <- length(whitesubblock_points) = 2 ? polygon([whitesubblock_points[0],{whitesubblock_points[1].x, whitesubblock_points[0].y},whitesubblock_points[1],{whitesubblock_points[0].x, whitesubblock_points[1].y} ]): nil;
		geometry bounds_g <- length(bounds_points) = 2 ? polygon([bounds_points[0],{bounds_points[1].x, bounds_points[0].y},bounds_points[1],{bounds_points[0].x, bounds_points[1].y} ]): nil;
		
		//detecting the code
		list<block> blocks <- detect_blocks(
			webcam1, //image from which detecting the block code
			image_width, image_height,
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

				
		
		loop j from: 0 to: 63{
			if (blocks[j].type = nil  or blocks[j].type.id = nil){continue;}

			int x <- j/8;
			int y <- j mod 8;
			
			if blocks[j].type.id = 'House'{
				if(house overlapping environment[x,y] != []){
					continue;
				}
				if (house overlapping environment[x,y] = [] and office overlapping environment[x,y] = [] and empty_building overlapping environment[x,y] = []){
					create house{
						shape <- environment[x,y].shape;
						location <- (environment[x,y].shape).location;
						color <- colors['House']; 	
					}
				}
				else{	
					if(office overlapping environment[x,y] != []){
						ask office overlapping environment[x,y]{do die;}
						create house{
							shape <- environment[x,y].shape;
							location <- (environment[x,y].shape).location;
							color <- colors['House']; 	
						}
					}
					if(empty_building overlapping environment[x,y] != []){
						ask empty_building overlapping environment[x,y]{do die;}
						create house{
							shape <- environment[x,y].shape;
							location <- (environment[x,y].shape).location;
							color <- colors['House']; 	
						}
					}	
				}
			}
			
//			if blocks[j].type.id = 'Office'{
//				write 'Office detected at environment[' + x + ',' + y + ']';
//				if(office overlapping environment[x,y] != []){
//					continue;
//				}
//				if (house overlapping environment[x,y] = [] and office overlapping environment[x,y] = [] and empty_building overlapping environment[x,y] = []){
//					create office{
//						shape <- environment[x,y].shape;
//						location <- (environment[x,y].shape).location;
//						color <- colors['Office']; 	
//					}
//				}
//				else{	
//					if(house overlapping environment[x,y] != []){
//						ask house overlapping environment[x,y]{do die;}
//						create office{
//							shape <- environment[x,y].shape;
//							location <- (environment[x,y].shape).location;
//							color <- colors['Office']; 	
//						}
//					}
//					if(empty_building overlapping environment[x,y] != []){
//						ask empty_building overlapping environment[x,y]{do die;}
//						create office{
//							shape <- environment[x,y].shape;
//							location <- (environment[x,y].shape).location;
//							color <- colors['Office']; 	
//						}
//					}	
//				}
//			}

//			if blocks[j].type.id = 'Empty environment'{
//				if(empty_building overlapping environment[x,y] != []){
//					break;
//				}
//				else if (house overlapping environment[x,y] = [] and office overlapping environment[x,y] = [] and empty_building overlapping environment[x,y] = []){
//					create empty_building{
//						shape <- environment[x,y].shape;
//						location <- (environment[x,y].shape).location;
//						color <- colors['Empty building']; 	
//					}
//				}
//				else{	
//					if(office overlapping environment[x,y] != []){
//						ask office overlapping environment[x,y]{do die;}
//						create empty_building{
//							shape <- environment[x,y].shape;
//							location <- (environment[x,y].shape).location;
//							color <- colors['Empty building']; 	
//						}
//					}
//					if(house overlapping environment[x,y] != []){
//						ask house overlapping environment[x,y]{do die;}
//						create empty_building{
//							shape <- environment[x,y].shape;
//							location <- (environment[x,y].shape).location;
//							color <- colors['Empty building']; 	
//						}
//					}	
//				}
//			}
			x <- nil;
			y <- nil;	
		}
		
		write 'numbers of office: ' + length(office);
		write 'numbers of house: ' + length(house);
		write 'numbers of empty building: ' + length(empty_building);
		
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
	
	reflex refresh_households when:cycle mod 100 = 0{
//		webcam1 save_webcam "here.jpg";
		let c <- cam_shot("tmp.jpg", image_width, image_height, webcam1);
		do define_code;
	}

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
		display image_display type:java2D {
			overlay position: { 5, 5 } size: { 800 #px, 180 #px } background: # black transparency: 0.4 border: #black rounded: true
            {
            	draw "current action: " + current_mode at: { 50#px,  30#px } color: # white font: font("Helvetica", 30, #bold);
            	draw "'d': detecting codes of blocks" at: { 50#px,  60#px } color: # white font: font("Helvetica", 20, #bold);
            	
            	draw "'p': define the distorsion points" at: { 50#px,  80#px } color: # white font: font("Helvetica", 20, #bold);
            	draw "'b': define the black block" at: { 50#px,  100#px } color: # white font: font("Helvetica", 20, #bold);
            	draw "'w': define the white block" at: { 50#px,  120#px } color: # white font: font("Helvetica", 20, #bold);
            	draw "'g': define the bound of block" at: { 50#px,  140#px } color: # white font: font("Helvetica", 20, #bold);
            	
            }
			image "tmp.jpg" refresh:true;
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
			//grid environment border: #black;
			species empty_building aspect: default;
			species road aspect: default;
			species house aspect: default;
			species office aspect: default;
			species inhabitant aspect: default;
		//	event mouse_down action:mouse_click;
		}	
	
	}
}