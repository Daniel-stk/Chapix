$(function(){  
    var keywords = $("#keywords").val().split(",");    
    var datos = [];
    
    $.each(keywords, function(idx, obj){
        if (obj) datos.push( { tag : obj} );
    });
    
    $('#le-keywords').material_chip({
        placeholder: '+ keyword',
        secondaryPlaceholder: 'Agrega keywords',
        data: datos
    });
    
    
    $('#le-keywords').on('chip.add', function(e, chip){
        var tags = $('#le-keywords').material_chip('data');
        var newKeys = '';
        $.each(tags, function(idx, obj){
            if (newKeys) newKeys += ',';
            if (obj.tag) newKeys += obj.tag;            
        });        
        $("#keywords").val(newKeys);        
    });
    
    $('#le-keywords').on('chip.delete', function(e, chip){
        var tags = $('#le-keywords').material_chip('data');
        var newKeys = '';                         
        $.each(tags, function(idx, obj){
            if (newKeys) newKeys += ",";
            if (obj.tag) newKeys += obj.tag;
        });        
        $("#keywords").val(newKeys);        
    });    
});


function deleteDevice (el, deviceId, accountId) {
    $.post("/Admin/API", {
        _mode : 'delete_account_device',
        device_id : deviceId,
        account_id : accountId
    }).done(function(response){
        var data = $.parseJSON(response);
        if (data.success){            
            Materialize.toast(data.message, 5000, 'msg-info');
            console.log(el);
            $(el).parent().parent().fadeOut();
        }
    });
}