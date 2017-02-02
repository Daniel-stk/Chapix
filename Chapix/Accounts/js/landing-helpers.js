$(function(){
	var countryCode = '';

  $(document).on('change', '#mkt_country', function(){
      if ($('#mkt_state').length){
        $.post("/Xaa/API", {  
          mode : "get_all_states",
          country_id : $(this).val()
        }).done(function(response){
          var obj = jQuery.parseJSON(response);
                var innerHtml = '';
                $.each(obj.states, function(idx, val){
                  innerHtml += '<option value="'+val.state_id+'">'+val.state+'</option>'
                });
                $('#mkt_state').html(innerHtml);
        }); 
      }
    });

  if ( $('#mkt_country').length || $('#mkt_state').length ){
        $.ajax({
          url: "http://ip-api.com/json",
          type: 'GET',
          success: function(json){
            countryCode = json.countryCode;
             
            if ( !$('#mkt_country').length ){
              $.post("/Xaa/API", {  
                mode : "get_all_states",
                country_id : countryCode
              }).done(function(response){
                var obj = jQuery.parseJSON(response);
                      var innerHtml = '';
                      $.each(obj.states, function(idx, val){
                        innerHtml += '<option value="'+val.state_id+'">'+val.state+'</option>'
                      });
                      $('#mkt_state').html(innerHtml);
              });              
            }else{
              $.post("/Xaa/API",{  
                  mode : "get_all_countries"
              }).done(function(response){
                     var obj = jQuery.parseJSON(response);
                     var innerHtml = '';
                     $.each(obj.countries, function(idx, val){
                        innerHtml += '<option value="'+val.country_id+'">'+val.country+'</option>'
                     });
                     $('#mkt_country').html(innerHtml);
                     $('#mkt_country').val(countryCode);
              }); 
            }
          },
          error: function(err){
            if ( !$('#mkt_country').length ){
              $.post("/Xaa/API", {  
                mode : "get_all_states",
              }).done(function(response){
                var obj = jQuery.parseJSON(response);
                      var innerHtml = '';
                      $.each(obj.states, function(idx, val){
                        innerHtml += '<option value="'+val.state_id+'">'+val.state+'</option>'
                      });
                      $('#mkt_state').html(innerHtml);
              });              
            }else{
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
            }
          }
        });        
  }


    $('select').material_select();
           
    $('form').append('<input type="hidden" class="hide" name="referrer" value="'+document.referrer+'"/>');

}); // DOCUMENT READY 