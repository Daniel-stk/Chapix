package Chapix::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Com;
use Chapix::View;

sub handler {
    if($_REQUEST->{Controller}){
        my $module = $_REQUEST->{Controller};
        my $is_installed = $dbh->selectrow_array("SELECT module FROM modules WHERE module=? AND installed=1",{},$module);
        if(!$is_installed){
            msg_add('danger',"The module $module is not installed.");
            display();
            return '';
        }
	
        # Load module
        my $Module;
        eval {
            require "Chapix/" . $module ."/Controller.pm";
            my $module_name ='Chapix::'.$module.'::Controller';
            $Module = $module_name->new();
        };
        if($@){
            print CGI::header();
            msg_add('danger', $@);
            Chapix::Controller::display();
            return '';
        }
    
        # Actions
        $Module->actions();
        
        # Views
        $Module->display();
    }else{
        Chapix::Controller::actions();
        Chapix::Controller::display();        
    }
}

# Main display function, this function prints the required view.
sub display {
    print Chapix::Com::header_out();
    #if($_REQUEST->{_view} eq 'Credits'){
    #    print Chapix::Admin::Layout::print( Chapix::Admin::View::display_credits() );
    #}elsif($_REQUEST->{_view} eq 'Settings'){
    #    print Chapix::Admin::Layout::print( Chapix::Admin::View::display_settings_form() );
    #}elsif($_REQUEST->{_view} eq 'Modules'){
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
