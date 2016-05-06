CKEDITOR.plugins.add( 'xaandialink', {
  icons: 'xaandialink',
  init: function( editor ) {
    // Plugin logic goes here...

    editor.addCommand( 'xaandialink', new CKEDITOR.dialogCommand('xaandialinkDialog') );
    
    editor.ui.addButton('XaandiaLink', {
      label : 'Agregar URL',
      command : 'xaandialink',
      toolbar : 'insert,100'
    });

    CKEDITOR.dialog.add( 'xaandialinkDialog' , this.path + 'dialogs/xaandialink.js');

    editor.addCommand( 'xaandiaunlink', new CKEDITOR.unlinkCommand() );

    editor.ui.addButton('XaandiaUnlink', {
      label : 'Eliminar URL',
      command : 'xaandiaunlink',
      toolbar : 'insert,100',
      icon : this.path + "icons/xaandialink.png"
    });

  }
});
