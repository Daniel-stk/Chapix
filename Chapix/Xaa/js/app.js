$(function() {
    $('select').material_select();
    $(".button-collapse").sideNav();

    // Focus any form on the first element
    $('form.fb').find('input:text').first().focus();
    $('form.fb').find('input:text').first().keypress(function () {
        $(this).siblings('label').addClass('active');
    });
    
});

function xaaTooggleSearch () {
    $('#xaa-search').toggle('slow',function() {
        $('#xaa-search').find('#q').focus();
    });
}
