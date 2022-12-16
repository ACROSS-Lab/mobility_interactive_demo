/**
* Name: GridModel
* Based on the internal empty template. 
* Author: THANTHUY
* Tags: 
*/


model GridModel

/* Insert your model definition here */
global{
	int nb_people <- 20;
	float step <- 10 #mn;
	list available_office <- [];
	graph road_network;
	map<road,float> new_weights;
	init{	
		create road from: split_lines(union(environment collect each.shape.contour));	
		road_network <- as_edge_graph(road);
	}

	//when a road is busy, it turns into yellow & inhabitant's speed decreases
	reflex update_road{
//		map<road,float> weights_map <- road as_map (each::(count(inhabitant overlapping each)) / each.shape.perimeter));
//		road_network <- as_edge_graph(road) with_weight weights_map;
		loop i over: road{
			int nb_people_on_road <- length(inhabitant overlapping i);
			if(nb_people_on_road/i.shape.perimeter >= 0.65){
				ask i{
					color <- #yellow;
					ask inhabitant overlapping i{
						speed <- speed * 0.05;
					}
				}
			}else{
				ask i{
					color <- #black;
				}
			}
			//write 'traffic'+ nb_people_on_road/i.shape.perimeter;
		}
	}
	
	

	reflex info{
//		write current_date.hour;
	}

	reflex update_office_location{
			ask inhabitant{
				if ( office none_matches (each overlaps location)) {
					if (available_office none_matches (each overlaps office_location) ) {
						office_location <- not empty(available_office) ? any_location_in(one_of(available_office))  : house_location;					
					}										
				}
		}
	}

	reflex update_available_office{
		loop i over: office{
			if(length(inhabitant overlapping i) < 20 and !(i in available_office)){
				available_office <- available_office + i;
			}
			if((i in available_office) and (length(inhabitant overlapping i) >= 20)){
				available_office <- available_office - i;
			}
			
		}
	}
	
	action create_house{
		
	}
	
	action mouse_click{
		environment selected_cell <- first(environment overlapping (#user_location));
		//write selected_cell;
		if selected_cell != nil{
			if(house overlapping (#user_location) = [] and office overlapping (#user_location) = []){
				create house{
				location <- selected_cell.location;
				color <- #blue;
				shape <- selected_cell.shape;
				create inhabitant number: rnd(nb_people){
						location <- any_location_in((selected_cell).shape);
						house_location <- location;
						office_location <- not empty(available_office) ? any_location_in(one_of(available_office)) : nil;
					}				
				}
			}
			
			else if(house overlapping (#user_location) != []){
				ask house overlapping (#user_location) {
					//kill inhabitant belongs to that house
					loop i over: inhabitant{
						if (selected_cell overlaps i.house_location){
							ask i{
								do die;
							}
						}				
					}
					create office{
						color <- #orange;
						location <- myself.location;
						shape <- myself.shape;
						loop i over: inhabitant{
//							if i.office_location = nil{
//								ask world {do update_office_location;}
//							}
						}	
					}
					
				do die;
				}
			}
			
			else {
				ask office overlapping (#user_location){
					ask inhabitant inside(self){
						location <- not empty(available_office) ? any_location_in(one_of(available_office)) : house_location;
					}
					available_office >> self;
					do die;
				}			
//				write ('number of available office after kill one: ' + length(available_office));
			}	
		}
	}
	
}



species inhabitant skills:[moving]{
	point office_location <- nil;
	point house_location <- nil;
	point target <- nil;
	float speed <- 0.1;
	aspect default{
		draw circle(4) color: #red;
	}

	reflex choose_target{		
		if(current_date.hour >= 7 and current_date.hour <= 17){
			target <- office_location;// any_location_in(one_of(available_office));
		}
		else{
			target <- house_location;			
		}
	}
	
	reflex moving when: target != nil{
		do goto target:target on:road_network speed:0.01;
		if (location = target){
			target <-  nil;
		}
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

experiment grid_model type:gui{
	output{
		display main_display type:opengl{
			//grid environment border: #black;
			species empty_building aspect: default;
			species road aspect: default;
			species house aspect: default;
			species office aspect: default;
			species inhabitant aspect: default;
			event mouse_down action:mouse_click;
		}	
	}
}
