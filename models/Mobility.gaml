/**
* Name: Mobility
* Based on the internal empty template. 
* Author: THANTHUY
* Tags: 
*/


model Mobility

/* Insert your model definition here */

global{
	shape_file shapefile_buildings  <- shape_file("../includes/tlu_building.shp");
	shape_file shapefile_roads 		<- shape_file("../includes/tlu_roads.shp");
	geometry shape  <- envelope(shapefile_roads);
	graph road_network;
	
	float step <- 15 #minute;
//	point init_location;
	int count_die <- 0;
	init{
		create building from: shapefile_buildings;
		create road from: shapefile_roads;
		create road from: clean_network(shapefile_roads.contents, 20.0,true,true);
		road_network <- as_edge_graph(road);
	}
	action define_inhabitants_office {
		ask inhabitant {
			office_location <- not empty(office) ? any_location_in(one_of(office))  : nil;		
		}
	}
	
	//map<road,float> new_weights;
	
	reflex write_info{
		write current_date.hour;	
		
		write count_die;
	}
	
	
	action building_change{
		
		if(building overlapping (#user_location) != []){
			ask building overlapping (#user_location){
				create house{
					shape <- myself.shape;
					location <- myself.location;	
					int nb <- int(myself.shape.area/500);
					create inhabitant number: rnd(1,nb){
						location <- any_location_in(myself.shape);
						house_location <- location;
						office_location <- not empty(office) ? any_location_in(one_of(office)) : nil;
					}					
				}
				do die;		
			}
		}		
		
		 else if (house overlapping (#user_location) != []){	 	
			ask (house overlapping (#user_location)){			
				ask inhabitant{				
					loop i over: inhabitant {
						if (myself overlaps i.house_location){
//							write ('init location of inhabitant  = myself.location');
							count_die <- count_die + 1;
							ask i{
								do die;
							}
						}
					}
				}
				create office{
					shape <- myself.shape;
					location <- myself.location;
					ask world {do define_inhabitants_office;}
				}
				do die;
			}
		}
		
		//office		
		 else if (office overlapping (#user_location) != []){
			ask (office overlapping (#user_location)){
				ask inhabitant inside (self){
					//office_location <- not empty(office) ? any_location_in(one_of(office))  : nil;
					do die;
				}
				create building{
					shape <- myself.shape;
					location <- myself.location;
				}
				write(length(inhabitant));
				do die;
			}
		}
	}
}

species inhabitant skills: [moving]{
	point target;
	point house_location;
	point office_location;
//	point init_location;
	rgb color <- rnd_color(255);
	reflex choose_target when: target = nil{
	
		if(current_date.hour >= 7 and current_date.hour <= 17){
			target <- office_location;
		}
		else{
			target <- house_location;			
		}
	}

	reflex moving {
		do goto target: target on: road_network  ;
		if (target = location){
			target <- nil;
		}	
	}
	aspect default{
		draw circle(4) color:color;
	}
}

species road{
	aspect default{ 
		draw shape color:color;
	}
}


species building{
	rgb color <- #yellow;	
	aspect default{
		draw shape color:color;
	}
}

species house{
	rgb color <- #red;
	aspect default{
		draw shape color:color;
	}
}

species office{
	rgb color <- #blue;

	aspect default{
		draw shape color:color;
	}
}

//grid environment width:8 height:8 neighbors:4{
//	rgb color <- #yellow;
//}

experiment mobility type:gui{
	output{
		display test{
			//grid environment lines:#black;	
			species building aspect: default;
			species road aspect: default;
			species house aspect: default;
			species office aspect: default;
			species inhabitant aspect: default;
			event mouse_down action: building_change;
		}
	}
}	


