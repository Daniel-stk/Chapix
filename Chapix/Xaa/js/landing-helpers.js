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
			}); 
    	}
    });

    $('select').material_select();
           
    $('form').append('<input type="hidden" class="hide" name="referrer" value="'+document.referrer+'"/>');

}); // DOCUMENT READY 