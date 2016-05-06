CKEDITOR.plugins.add( 'xaandiaphone', {
  icons: 'xaandiaphone',
  init: function( editor ) {
    // Plugin logic goes here...

    editor.addCommand( 'xaandiaphone', new CKEDITOR.dialogCommand('xaandiaphoneDialog') );

    editor.ui.addButton('XaandiaPhone', {
      label : 'Agregar URL de un télefono (dispositivos móviles)',
      command : 'xaandiaphone',
      toolbar : 'insert,100'
    });

    CKEDITOR.dialog.add( 'xaandiaphoneDialog' , this.path + 'dialogs/xaandiaphone.js');

    // editor.addCommand( 'xaandiaunlink', new CKEDITOR.unlinkCommand() );
    //
    // editor.ui.addButton('XaandiaUnlink', {
    //   label : 'Eliminar URL',
    //   command : 'xaandiaunlink',
    //   toolbar : 'insert,100',
    //   icon : this.path + "icons/xaandiaphone.png"
    // });

  }
});
