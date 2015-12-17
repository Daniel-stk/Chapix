package Chapix::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
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
    if($conf->{Xaa}->{MainModule}){
        my $module = $conf->{Xaa}->{MainModule};
        $_REQUEST->{Controller} = $module;
        my $is_installed = $dbh->selectrow_array("SELECT module FROM modules WHERE module=? AND installed=1",{},$module);
        
        if($is_installed){
            # Load module
             my $Module;
             eval {
                 require "Chapix/" . $module ."/Controller.pm";
                 my $module_name ='Chapix::'.$module.'::Controller';
                 $Module = $module_name->new();
             };
             if($@){
                 msg_add('danger', $@);
             }else{
                 $Module->display();
                 return;
             }
        }else{
            msg_add('danger','The main module is not installed');
        }
    }
    print Chapix::Com::header_out();
    print Chapix::View::default();
}


# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {

}

1;
