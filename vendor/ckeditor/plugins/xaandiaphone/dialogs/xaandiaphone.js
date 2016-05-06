CKEDITOR.dialog.add( 'xaandiaphoneDialog', function( editor ) {
  return {
    title : 'Agregar Vinculo a Télefono (Dispositivos móviles)',
    minWidth: 400,
    minHeight: 70,
    contents : [
      {
        id : 'tab-basic',
        label : 'Información de vinculo',
        elements : [
          {
            type : 'text',
            id : 'url',
            label : 'URL',
            validate : CKEDITOR.dialog.validate.notEmpty( "El campo URL no puede estar vacio." ),
            required : true,
            setup : function ( element ) {
              this.setValue( element.getAttribute('href') );
            },
            commit : function ( element ) {
              element.setAttribute('href', this.getValue() );
            }
          }
        ]
      }
    ],
    onOk: function () {
      var dialog = this;
      var a = this.element;

      this.commitContent(a);

      if( this.insertMode ) {
        var d = dialog.getParentEditor();
        var txt = d.getSelection().getSelectedText();
        if( txt == ''){
          txt = "(614) 4 13-37-81";
        }
        var url = editor.document.createElement('a');
        var liga = dialog.getValueOf('tab-basic', 'url');

        liga.replace(/^\s+/g,'');

        var regexTel = /^tel.*/;

        if( liga && liga.match(regexTel) ) {
          liga = liga;
        }else{
          liga = 'tel:' + liga;
        }

        url.setAttribute( 'href', liga);
        url.setText(txt);
        editor.insertElement(url);
      }
    },
    onShow: function () {
      var selection = editor.getSelection();
      var element = selection.getStartElement();

      if ( element ) {
        element = element.getAscendant( 'a', true );
      }
      if ( !element || element.getName() != 'a' ) {
        element = editor.document.createElement( 'abbr' );
        this.insertMode = true;
      }
      else {
        this.insertMode = false;
      }
      this.element = element;

      if ( !this.insertMode ) {
        this.setupContent( this.element );
      }
    }

  };
});
