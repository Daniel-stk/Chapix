$(function(){
    $( ".sintesis-sortable" ).sortable({
        items : "li:not(:first)",
        handle : '.reorder-zone',
        // connectWith: "",
        delay: 150,
        scroll : true,
        // zIndex: 999,
        beforeStop : function(event, ui){
        },
        change: function(event, ui){
        },
        update : function(event, ui){
            $(event.target).find("li:not(:first)").each(function(idx, obj){
                $(this).attr("data-position", (idx+1));
            });
            updateOrder(event);
        },
        out : function(event, ui){            
        },
        over : function(event, ui){
        },
        receive : function (event, ui){            
        },
        remove : function(event, ui){
        },
        sort : function (event, ui){
        },
        start : function (event, ui){
        },
        stop : function(event, ui){            
        }
    }).disableSelection();
 

    $("#publicar-sintesis").on("click", function(){
        $("#sintesis-form").submit();
    });


    $(".delete-zone").on("click", function(){
        var $el = $(this);
        var id = $el.parent().attr("data-idsin");
        
        $.post('/Admin/API', {
            _mode : 'remove_sintesis_pub',
            sintesis_id : id,
            publication_id : $("#publication_id").val()
        }).done(function(data){
            var response = $.parseJSON(data);
            if (response.success){
                $el.parent().fadeOut();
            }
        });        
    });

    $(".le-tema").on("change", function(){
        var temaDelDia = $(this).prop('checked') ? 1 : 0;        
        var sinId = $(this).attr("data-sin");

        $.post('/Admin/API', {
            _mode : 'mark_tema_del_dia',
            tema_dia : temaDelDia,
            sintesis_id : sinId,
            publication_id : $("#publication_id").val()
        }).done(function(data){
            var response = $.parseJSON(data);
            if (response.success){
                Materialize.toast("Actualizado", 2000, 'msg-info');
            }
        });
    });
    
    $(".le-widget").on("change", function(){
        var widgetToday = $(this).prop('checked') ? 1 : 0;        
        var sinId = $(this).attr("data-sin");

        $.post('/Admin/API', {
            _mode : 'mark_widget_today',
            widget : widgetToday,
            sintesis_id : sinId,
            publication_id : $("#publication_id").val()
        }).done(function(data){
            var response = $.parseJSON(data);
            if (response.success){
                Materialize.toast("Actualizado", 2000, 'msg-info');
            }
        });
    });    
});


function updateOrder (event){
    var data = {
        "_mode" : "update_sin_positions",
        "seccion_id" : $(event.target).attr('data-idsec'),
        "publication_id" : $("#publication_id").val()
    };        
    
    $(event.target).find("li:not(:first)").each(function(idx, obj){
        data["sintesis_"+$(this).attr("data-idsin")] = $(this).attr("data-position");
    });
    
    $.post("/Admin/API", data).done(function(response){
        var res = $.parseJSON(response);
        Materialize.toast(res.message, 5000, 'msg-info');
    });        
}