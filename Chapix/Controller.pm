package Chapix::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Com;
use Chapix::View;

sub handler {
    #if($Q->param('controller') eq ''){
        Chapix::Controller::actions();
        Chapix::Controller::display();        
    #}elsif($Q->param('controller')){
    #    my $module = $Q->param('controller');
    #    my $is_installed = $dbh->selectrow_array("SELECT module FROM modules WHERE module=? AND installed=1",{},$module);
    #    if(!$is_installed){
    #        msg_add('danger',"The module $module is not installed.");
    #        display();
    #        return '';
    #    }
    #    
    #    # Load module
    #    my $Module;
    #    eval {
    #        require "Chapix/" . $module ."/Admin/Controller.pm";
    #        my $module_name ='Chapix::'.$module.'::Admin::Controller';
    #        $Module = $module_name->new();
    #    };
    #    if($@){
    #        print CGI::header();
    #        msg_add('danger', $@);
    #        Chapix::Admin::Controller::display();
    #        return '';
    #    }
    #
    #    # Actions
    #    $Module->actions();
    #    
    #    # Views
    #    $Module->display();
    #}else{
    #    actions();
    #    display();
    #}
}

# Main display function, this function prints the required view.
sub display {
    print Chapix::Com::header_out();
    #if($Q->param('view') eq 'Credits'){
    #    print Chapix::Admin::Layout::print( Chapix::Admin::View::display_credits() );
    #}elsif($Q->param('view') eq 'Settings'){
    #    print Chapix::Admin::Layout::print( Chapix::Admin::View::display_settings_form() );
    #}elsif($Q->param('view') eq 'Modules'){
    #    print Chapix::Admin::Layout::print( Chapix::Admin::View::display_modules_list() );
    #}else{
        print Chapix::View::default();
    #}
}


# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {

}

1;
