$(function() {

    // iniciarlizar sidemenu
    $(".button-collapse").sideNav();

    $('.scrollspy').scrollSpy();

    $('.modal-trigger').leanModal({
	dismissible: true, // Modal can be dismissed by clicking outside of the modal
	opacity: .5, // Opacity of modal background
	in_duration: 300, // Transition in duration
	out_duration: 200, // Transition out duration
	// ready: function() { alert('Ready'); }, // Callback for Modal open
	// complete: function() { alert('Closed'); } // Callback for Modal close
    }
				 );

    $(".owl-carousel").owlCarousel({
	items : 3, //10 items above 1000px browser width
	pagination: false,
	navigation: false,
	stopOnHover: true,
	autoplay : true,
	responsive: true,
	itemsDesktop : [1199,],
	itemsDesktopSmall : [901,3]
    });


    // $('select').material_select();
    // $(".button-collapse").sideNav();

    // // Focus any form on the first element
    // $('form.fb').find('input:text').first().focus();
    // $('form.fb').find('input:text').first().keypress(function () {
    //     $(this).siblings('label').addClass('active');
    // });

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