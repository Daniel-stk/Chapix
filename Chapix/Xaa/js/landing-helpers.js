$(function(){
	
    $.post("/Xaa/API",{  
        mode : "get_all_countries"
    }).done(function(response){
           var obj = jQuery.parseJSON(response);
           var innerHtml = '';
           $.each(obj.countries, function(idx, val){
           		innerHtml += '<option value="'+val.country_id+'">'+val.country+'</option>'
           });
           $('#mkt_country').html(innerHtml);
           $('#mkt_country').removeClass('browser-default');
           $('#mkt_country').material_select();
    }); 
            
    $(document).on('change', '#mkt_country', function(){
    	if ($('#mkt_state').length){
			$.post("/Xaa/API", {  
				mode : "get_all_states",
				country_id : $(this).val()
			}).done(function(response){
				var obj = jQuery.parseJSON(response);
	           	var innerHtml = '';
	           	$.each(obj.countries, function(idx, val){
	           		innerHtml += '<option value="'+val.state_id+'">'+val.state+'</option>'
	           	});
	           	$('#mkt_state').html(innerHtml);
	           	$('#mkt_state').removeClass('browser-default');
	           	$('#mkt_state').material_select();
			}); 
    	}
    });

    $('#mkt_gender').removeClass('browser-default');
    $('#mkt_gender').material_select();
           
	// $("#mkt_country").jeoCountrySelect({
 //        callback: function () {
 //        	$('#mkt_country').removeClass('browser-default');
 //        	$("#mkt_country").material_select();
 //        }
 //    });

 //    $(document).on('change', '#mkt_country', function() {
 //    	var countryID = $(this).val();
        
 //    	if ( $('#mkt_state').length ){
 //            var innerHtml = '';
 //    		jeoquery.getGeoNames('countryInfo', {country : countryID}, function(data){  		
 // 				jeoquery.getGeoNames('children', {geonameId : data.geonames[0].geonameId}, function(states){ 
 // 					$.each(states.geonames, function(key, value){
 // 						innerHtml += '<option value="'+value.name+'">'+value.name+'</option>';
 // 					});
 //                    $('#mkt_state').html(innerHtml);
 //                    $('#mkt_state').removeClass('browser-default');
 //                    $('#mkt_state').material_select(); 
 // 				});
 // 			});
 //    	}
 //    });



}); // DOCUMENT READY 