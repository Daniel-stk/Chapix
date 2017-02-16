$(function() {
    $('select').material_select();
    $(".button-collapse").sideNav();

    // Focus any form on the first element
    $('form.fb').find('input:text').first().focus();
    $('form.fb').find('input:text').first().keypress(function () {
        $(this).siblings('label').addClass('active');
    });

    $('.datepicker').pickadate({
        selectMonths: true, // Creates a dropdown to control month
        selectYears: 15, // Creates a dropdown of 15 years to control year
        format: 'yyyy/mm/dd',
        onStart : function() {
            $('.picker').appendTo('body');
        }
    });
    
    $('.timepicker').pickatime({
        clear: '',
        format: 'HH:i',
        closeOnSelect: true,
        onStart : function() {
            $('.picker').appendTo('body');
        }
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


    $(window).scroll(function(e){ 
        if ($('.sticky-container').length){
            var $el = $('.sticky-container'); 
            if ($(this).scrollTop() >= $el.offset().top ){ 
                $('.sticky-container').children().addClass('sticky');
            }else{
                $('.sticky-container').children().removeClass('sticky');
            }
        }
    });


});

function xaaTooggleSearch () {
    $('#xaa-search').toggle('slow',function() {
        $('#xaa-search').find('#q').focus();
    });
}

function xaaDisplayMsg (msg) {
    if (msg){
        for(var i = 0; i < msg.length; i++) {
            Materialize.toast(msg[i][1], 3000, 'msg-'+msg[i][0]);
        }
    }
}