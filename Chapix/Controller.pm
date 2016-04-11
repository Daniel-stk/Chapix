package Chapix::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::Com;
use Chapix::View;

sub handler {
    #msg_add('danger'," -- $_REQUEST->{Controller} -- $_REQUEST->{View}  -- ");	
    if($_REQUEST->{Controller}){
        my $module = $_REQUEST->{Controller};
        my $is_installed = $dbh->selectrow_array("SELECT module FROM modules WHERE module=? AND installed=1",{},$module);
	
    	if(!$is_installed){
            msg_add('danger',"The module $module is not installed.");
            view();
            return '';
        }

        # Load module
        my $Module;
        eval {
            require "Chapix/".$module ."/Controller.pm";
            my $module_name ='Chapix::'.$module.'::Controller';
            $Module = $module_name->new();
        };
        if($@){
            msg_add('danger', $@);
            Chapix::Controller::display_error();
            return '';
        }

    	if ($_REQUEST->{View} eq 'API') {
    	    # API
    	    $Module->api();
    	}else{
    	    # Actions
    	    $Module->actions();

    	    # Views
    	    $Module->view();
    	}
    }else{
        Chapix::Controller::actions();
        Chapix::Controller::view();
    }
}

# Main view function, this function prints the required view.
sub view {
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
		$Module->view();
		return;
	    }
        }else{
            msg_add('danger','The main module is not installed');
        }
    }
    print Chapix::Com::header_out();
    print Chapix::View::default();
}

sub display_error {
    print Chapix::Com::header_out();
    print Chapix::View::default();
}

# Each action is detected by the "_submitted" param prefix
sub actions {

}

1;
