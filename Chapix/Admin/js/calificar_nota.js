$(function(){

    $(".le-rate").on("click", function(){
        var $el = $(this);
        $(this).parent().find(".le-rate").each(function(){
            $(this).addClass("lighten-4");
        });
        
        $.post("/Admin/API", {
            _mode : "rate_account_note",
            account_id : $el.parent().attr('data-aid'),
            fuente_id : $el.parent().attr("data-fid"),
            url_key : $el.parent().attr("data-urlk"),
            rate : $(this).attr("data-rate")
        }).done(function(data){
            var response = $.parseJSON(data);
            if (response.success){
                $el.removeClass("lighten-4");
                Materialize.toast("Se actualizo la calificación", 5000, 'msg-info');
            }
            
        });
        
    });
    
    
});