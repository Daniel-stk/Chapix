CKEDITOR.plugins.add( 'mktreservedwords', {
  icons: 'mktreservedwords',
  init: function( editor ) {
    var pluginDirectory = this.path;

    editor.addContentsCss( pluginDirectory + 'styles/mktreservedwords.css' );
    
    editor.addCommand( 'insertEmailWord', {
      exec: function( editor ) {
        editor.insertHtml('___SUSCRIPTOR.CORREO____');
      }
    });

    editor.ui.addButton( 'mktEmailWord', {
      label: 'Correo electrónico del contacto',
      command: 'insertEmailWord',
      toolbar: 'insert',
      icon : pluginDirectory + "icons/mailmktreservedwords.png"
    });

    editor.addCommand( 'insertNameWord', {
      exec: function( editor ) {
        editor.insertHtml('___SUSCRIPTOR.NOMBRE____');
      }
    });

    editor.ui.addButton( 'mktNameWord', {
      label: 'Nombre del contacto',
      command: 'insertNameWord',
      toolbar: 'insert',
      icon : pluginDirectory + "icons/facemktreservedwords.png"
    });

  }
});
