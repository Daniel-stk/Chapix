$(function(){
	
});

var regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
$(window).load(function(){
	if(typeof(Storage) !== "undefined") {
		// localStorage.clear();
	    if ( !localStorage.FormsHome && document.location.pathname.match(/\/\w*\/Forms$/) ){ // FORMS MODULE INSTRUCTIONS		    
			$('.addy').attr({'data-position': 'top', 'data-intro' : "Crea tu formulario"});
			localStorage.FormsHome = 'Yes';
			// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
			
	    }else if ( !localStorage.NewForm && document.location.pathname.match(/\/\w*\/Forms\/NewForm/) ){
	    	$('.form-usage:first').attr({'data-position' : 'right', 'data-intro' : 'Selecciona una plantilla.<br/><br>Recuerda que al subir tu logo en la sección de ajustes, las plantillas se adaptan a los colores.' });			
	    	localStorage.NewForm = 'Yes';
	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.FormEditor && document.location.pathname.match(/\/\w*\/Forms\/FormEditor/) ) {
			$('.elements-wrapper').attr({'data-position' : 'top', 'data-intro' : 'Arrastra los elementos.'});
			$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Agrega un fondo y guarda.<br/><br/>Da clic en siguiente para editar tu página de respuesta.'});
			$('.row-wrapper:nth-child(2)').attr({'data-position': 'bottom', 'data-intro' : 'Edita tu contenido'});
			localStorage.FormEditor = 'Yes';

			// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.FormResponseEditor && document.location.pathname.match(/\/\w*\/Forms\/FormResponseEditor/) ){
	    	$('#bob-editor').attr({'data-position' : 'top', 'data-intro' : 'Está es la página que aparecerá después de que contesten tu formulario.'});
	    	$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Da clic en siguiente para editar un email de respuesta.'});
			localStorage.FormResponseEditor = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.FormEmeEditor && document.location.pathname.match(/\/\w*\/Forms\/FormEmeEditor/) ){
	    	$('.editor-box').attr({'data-position' : 'top', 'data-intro' : 'Está es el email que se enviará automáticamente a quienes respondan tu formulario.'});
	    	$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Da clic en siguiente para finalizar los detalles de tu página.<br/><br/>Recuerda que te puedes enviar un ejemplo del email.'});
			localStorage.FormEmeEditor = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.FormConfEdit && document.location.pathname.match(/\/\w*\/Forms\/FormConfEdit/) ){
	    	
	    	$('label[for="add_pipeline"]').attr({'data-position' : "right", 'data-intro' : 'Selecciona para añadir los prospectos a tu modulo de seguimiento.'});
	    	$('label[for="publish"]').attr({'data-position' : "left", 'data-intro' : 'Pública tu formulario y da clic en finalizar'});
			localStorage.FormConfEdit = 'Yes';

		    // INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.FormDetails && document.location.pathname.match(/\/\w*\/Forms\/FormDetails/)  ){
	    	$('.lp-link').attr({'data-position' : 'top', 'data-intro' : 'Esta es la dirección de tu página'});
	    	$('.shrbtn').attr({'data-position' : 'bottom', 'data-intro' : 'Pública en tus redes o añade el código a tu sitio web.'});
	    	$('#cg_table_cg_list').attr({'data-position' : 'top', 'data-intro' : 'Estas son las respuestas de tu formulario'});
			localStorage.FormDetails = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.EmailMkt && document.location.pathname.match(/\/\w*\/EmailMkt$/) ){
	    	$('#cg_table_cg_list').attr({'data-position' : 'top', 'data-intro' : 'Aquí aparecerán todos tus mensajes.'});
	    	$('.addy').attr({'data-position': 'top', 'data-intro' : "Crea tu mensaje"});
			localStorage.EmailMkt = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.MktMessage && document.location.pathname.match(/\/\w*\/EmailMkt\/Message$/) ){
	    	$('.custom-usage:first').attr({'data-position' : 'right', 'data-intro' : 'Selecciona una plantilla.<br/><br>Recuerda que al subir tu logo las plantillas se adaptan a los colores.' });
			localStorage.MktMessage = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.MessageEditor && document.location.pathname.match(/\/\w*\/EmailMkt\/MessageEditor/) ){
	    	$('.editor-tools').attr({'data-position' : 'top', 'data-intro' : 'Arrastra los elementos.'});
			$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Guarda, usa la vista previa o envía un ejemplo antes de continuar con el envío.'});
			// $('.row-wrapper:nth-child(3)').attr({'data-position': 'bottom', 'data-intro' : 'Edita tu contenido'});
			localStorage.MessageEditor = 'Yes';

			// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.CRMHome && document.location.pathname.match(/\/\w*\/CRM$/) ){
	    	$('.addy').attr({'data-position': 'top', 'data-intro' : "Crea un nuevo contacto."});
	    	$('#main-pipeline').attr({'data-position' : 'top', 'data-intro' : 'Aquí aparecerán tus contactos.'});
	    	$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Mira tus ventas, busca un contacto, ve tus grupos o mira tu agenda.'});

			localStorage.CRMHome = 'Yes';

			// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }
	} else {
	// Sorry! No Web Storage support..
	}
});




