$(function() {

	// iniciarlizar sidemenu
	$(".button-collapse").sideNav();

	$('.scrollspy').scrollSpy();

	$('.form-overlay').hover(function(){ 
		$('.sign-txt').addClass('fade-out');
		$('.register-item').addClass('appear');
		$(".sign-btn").addClass("step-aside");
	}, function(){
		$('.sign-txt').removeClass('fade-out');
		$('.register-item').removeClass('appear');
		$(".sign-btn").removeClass("step-aside");
	});

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


});