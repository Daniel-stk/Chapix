$(function() {
    $('select').material_select();
    $(".button-collapse").sideNav();

    // Focus any form on the first element
    $('form.fb').find('input:text').first().focus();
    $('form.fb').find('input:text').first().keypress(function () {
        $(this).siblings('label').addClass('active');
    });


    $('.msg').each(function() {
        $(this).hide();
        if($(this).hasClass('msg-success')){
            Materialize.toast($(this).html(), 3000, 'msg-success');
        } else if ($(this).hasClass('msg-danger')){
            Materialize.toast($(this).html(), 180000, 'msg-danger');
            var snd = new Audio("/media/beep.wav");
            snd.play();
        } else if ($(this).hasClass('msg-warning')){
            Materialize.toast($(this).html(), 180000, 'msg-warning');
            var snd = new Audio("/media/beep.wav");
            snd.play();
        } else if ( $(this).hasClass('msg-info') ) {
	    Materialize.toast($(this).html(), 180000, 'msg-info');
            var snd = new Audio("/media/beep.wav");
            snd.play();
	      }else {
            Materialize.toast($(this).html(), 3000);
        }
    });


});

function xaaTooggleSearch () {
    $('#xaa-search').toggle('slow',function() {
        $('#xaa-search').find('#q').focus();
    });
}
