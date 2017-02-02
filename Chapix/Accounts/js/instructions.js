$(function(){
	
});

var regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
$(window).load(function(){
    if(typeof(Storage) !== "undefined") {
	
	if ( !localStorage.FormsHome && document.location.pathname.match(/\/\w*\/Forms$/) ){ // FORMS MODULE INSTRUCTIONS	
            
	    $('body').on('chardinJs:start', function(){
		$('.chardinjs-overlay').before('<img class="instr-lp1" src="/assets/img/mkt_others/instr-lp1.png" />');
	    });
            
	    $('body').on('chardinJs:stop', function(){
		$('.instr-lp1').fadeOut(function(){
		    $(this).remove();
		});
	    });
            
	    $('.addy').attr({'data-position': 'top', 'data-intro' : "Crea tu formulario"});
	    localStorage.FormsHome = 'Yes';	
	    // INIT TUTORIAL OVERLAY
	    $('body').chardinJs('start');
	}else if ( !localStorage.NewForm && document.location.pathname.match(/\/\w*\/Forms\/NewForm/) ){
	    $('.form-usage:first').attr({'data-position' : 'right', 'data-intro' : 'Selecciona una plantilla.<br/><br>Recuerda que al <a target="_blank" href="/'+Domain+'/Xaa/EditLogo">subir tu logo</a> las plantillas se adaptan a los colores.' });			
	    localStorage.NewForm = 'Yes';
	    // INIT TUTORIAL OVERLAY
	    $('body').chardinJs('start');
	}else if ( !localStorage.FormEditor && document.location.pathname.match(/\/\w*\/Forms\/FormEditor/) ) {
	    $('body').on('chardinJs:stop', function(){
		$('.element-tools').removeClass('some-hover');
	    });
            
	    $('.elements-wrapper').attr({'data-position' : 'top', 'data-intro' : 'Arrastra los elementos.'});
	    $('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Usa estas funciones cuando termines tu página.'});
	    
	    $('.row-wrapper:nth-child(2)').attr({'data-position': 'bottom', 'data-intro' : 'Edita tu contenido'}).find('.element-tools').addClass('some-hover').find('.right-tools').attr({'data-position' : 'bottom', 'data-intro' : 'Usa el lapiz para editar los elementos.' });
	    
	    localStorage.FormEditor = 'Yes';
            
	    // INIT TUTORIAL OVERLAY
	    $('body').chardinJs('start');
	    }else if ( !localStorage.FormResponseEditor && document.location.pathname.match(/\/\w*\/Forms\/FormResponseEditor/) ){
	    	$('#bob-editor').attr({'data-position' : 'top', 'data-intro' : 'Dale las gracias a tu contacto por haberse registrado.'});
	    	$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Da clic en siguiente para editar un email de respuesta.'});
			localStorage.FormResponseEditor = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.FormEmeEditor && document.location.pathname.match(/\/\w*\/Forms\/FormEmeEditor/) ){
	    	$('.editor-box').attr({'data-position' : 'top', 'data-intro' : 'Esta es el email que se enviará automáticamente a quienes respondan tu formulario.'});
	    	$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Da clic en siguiente para finalizar los detalles de tu página.<br/><br/>Recuerda que te puedes enviar un ejemplo del email.'});
			localStorage.FormEmeEditor = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.FormConfEdit && document.location.pathname.match(/\/\w*\/Forms\/FormConfEdit/) ){
	    	
	    	$('label[for="add_pipeline"]').attr({'data-position' : "right", 'data-intro' : 'Selecciona para añadir los prospectos a tu modulo de seguimiento de ventas.'});
	    	$('label[for="publish"]').attr({'data-position' : "left", 'data-intro' : 'Pública tu formulario y da clic en finalizar'});
			localStorage.FormConfEdit = 'Yes';

		    // INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.FormDetails && document.location.pathname.match(/\/\w*\/Forms\/FormDetails/)  ){

	    	$('body').on('chardinJs:start', function(){
				$('.chardinjs-overlay').before('<img class="instr-lp2" src="/assets/img/mkt_others/instr-lp3.png" />');
			});

			$('body').on('chardinJs:stop', function(){
				$('.instr-lp2').fadeOut(function(){
					$(this).remove();
				});
			});

	    	$('.lp-link').attr({'data-position' : 'top', 'data-intro' : 'Esta es la dirección de tu página'});
	    	$('.shrbtn').attr({'data-position' : 'bottom', 'data-intro' : 'Pública en tus redes o añade el código a tu sitio web.'});
	    	$('#cg_table_cg_list').attr({'data-position' : 'top', 'data-intro' : 'Estas son las respuestas de tu formulario'});
			localStorage.FormDetails = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( document.location.pathname.match(/\/\w*\/EmailMkt$/) ){

	    	if ( !localStorage.EmailMktSend && $('.sendys').length ){
		    	$('body').on('chardinJs:start', function(){
					$('.chardinjs-overlay').before('<img class="instr-eme3" src="/assets/img/mkt_others/instr-eme3.png" />');
				});

				$('body').on('chardinJs:stop', function(){
					$('.instr-eme3').fadeOut(function(){
						$(this).remove();
					});
				});

		    	$('.sendys .row:first').attr({'data-position' : 'bottom', 'data-intro' : 'Ve el estado de tu mensaje, puedes cancelar el envío.'});
				localStorage.EmailMktSend = 'Yes';

		    	// INIT TUTORIAL OVERLAY
				$('body').chardinJs('start');
	    	}else if ( !localStorage.EmailMkt ){
	    	    $('body').on('chardinJs:start', function(){
			$('.chardinjs-overlay').before('<img class="instr-eme1" src="/assets/img/mkt_others/instr-eme1.png" />');
		    });
                    
		    $('body').on('chardinJs:stop', function(){
			$('.instr-eme1').fadeOut(function(){
			    $(this).remove();
			});
		    });
                    
		    $('#cg_table_cg_list').attr({'data-position' : 'top', 'data-intro' : 'Aquí aparecerán todos tus mensajes.'});
		    $('.addy').attr({'data-position': 'top', 'data-intro' : "Crea tu primer mensaje"});
		    localStorage.EmailMkt = 'Yes';
                    
		    // INIT TUTORIAL OVERLAY
		    $('body').chardinJs('start');
	    	}
	    }else if ( !localStorage.MktMessage && document.location.pathname.match(/\/\w*\/EmailMkt\/Message$/) ){
	    	$('.custom-usage:first').attr({'data-position' : 'right', 'data-intro' : 'Selecciona una plantilla.<br/><br>Recuerda que al <a target="_blank" href="/'+Domain+'/Xaa/EditLogo">subir tu logo</a> las plantillas se adaptan a los colores.' });
			localStorage.MktMessage = 'Yes';

	    	// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( !localStorage.MessageEditor && document.location.pathname.match(/\/\w*\/EmailMkt\/MessageEditor/) ){

	    	$('body').on('chardinJs:start', function(){
				$('.chardinjs-overlay').before('<img class="instr-eme2" src="/assets/img/mkt_others/instr-eme2.png" />');
			});

			$('body').on('chardinJs:stop', function(){
				$('.element-tools').removeClass('some-hover');
				$('.instr-eme2').fadeOut(function(){
					$(this).remove();
				});
			});

			$('.overlay-contenedor:nth-child(2)').attr({'data-position': 'bottom', 'data-intro' : 'Edita tu contenido'}).find('.element-tools').addClass('some-hover').find('.right-tools').attr({'data-position' : 'bottom', 'data-intro' : 'Usa el lapiz para editar los elementos.' });

	    	$('.editor-tools').attr({'data-position' : 'top', 'data-intro' : 'Arrastra los elementos al área de trabajo.'});
			$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Usa la vista previa o envía un ejemplo antes de continuar con el envío.'});
			// $('.row-wrapper:nth-child(3)').attr({'data-position': 'bottom', 'data-intro' : 'Edita tu contenido'});
			localStorage.MessageEditor = 'Yes';

			// INIT TUTORIAL OVERLAY
			$('body').chardinJs('start');
	    }else if ( document.location.pathname.match(/\/\w*\/CRM$/) ){
	    	
	    	if (!localStorage.CRMHome && !$('.contact-item').length ){
		    	$('body').on('chardinJs:start', function(){
					$('.chardinjs-overlay').before('<img class="instr-crm1" src="/assets/img/mkt_others/instr-crm1.png" />');
				});

				$('body').on('chardinJs:stop', function(){
					$('.instr-crm1').fadeOut(function(){
						$(this).remove();
					});
				});

		    	$('.addy').attr({'data-position': 'top', 'data-intro' : "Crea un nuevo contacto."});
		    	$('#main-pipeline').attr({'data-position' : 'top', 'data-intro' : 'Aquí aparecerán tus contactos.'});
		    	$('.toolbar-actions').attr({'data-position' : 'bottom', 'data-intro' : 'Consulta tus ventas, busca un contacto, ve tus grupos o mira tu agenda.'});

				localStorage.CRMHome = 'Yes';

				// INIT TUTORIAL OVERLAY
				$('body').chardinJs('start');
	    	}else if ( !localStorage.CRMHomeTwo && $('.contact-item').length ){
				$('body').on('chardinJs:start', function(){
					$('.chardinjs-overlay').before('<img class="instr-crm2" src="/assets/img/mkt_others/instr-crm2.png" />');
				});

				$('body').on('chardinJs:stop', function(){
					$('.instr-crm2').fadeOut(function(){
						$(this).remove();
					});
				});

		    	$('.contact-item:first').attr({'data-position' : 'right', 'data-intro' : 'Arrástralo para ubicarlo en su fase, eliminarlo o cerrar venta.'});

				localStorage.CRMHomeTwo = 'Yes';

				// INIT TUTORIAL OVERLAY
				$('body').chardinJs('start');

	    	}

	    }else if ( document.location.pathname.match(/\/\w*\/CRM\/Contact$/) ){

	    	if ( $('.historial').length && !localStorage.CRMContactTwo ){
		    	$('.historial').attr({'data-position' : 'top', 'data-intro' : 'Revisa el historial.'});
				localStorage.CRMContactTwo = 'Yes';

				// INIT TUTORIAL OVERLAY
				$('body').chardinJs('start');
	    	}else if (!localStorage.CRMContact){
		    	$('#add-new-action').attr({'data-position' : 'bottom', 'data-intro' : 'Agrega una tarea al contacto'});
		    	$('.c-edit-btn').attr({'data-position' : 'bottom', 'data-intro' : 'Edita los datos.'});

				localStorage.CRMContact = 'Yes';

				// INIT TUTORIAL OVERLAY
				$('body').chardinJs('start');
	    	}
	    }
	} else {
		console.log('no soporta web storage');
	// Sorry! No Web Storage support..
	}
});




