package Chapix::Xaa::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);
use Color::Rgb;
use Math::Complex;
use List::Util qw(min max);

use Chapix::Conf;
use Chapix::Com;

use Chapix::Xaa::Actions;
use Chapix::Xaa::API;
use Chapix::Xaa::View;

use Chapix::Mail::Controller;

# Language
use Chapix::Xaa::L10N;
my $lh = Chapix::Xaa::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

#
sub new {
    my $class = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;

    # Init app ENV
    $self->_init();

    return $self;
}

# Initialize ENV
sub _init {
    my $self = shift;
}


# API
sub api {
    my $JSON = {
	error   => '',
	success => '',
	msg     => ''
    };
     
    if($_REQUEST->{mode} eq 'get_all_countries'){
	   $JSON = Chapix::Xaa::API::get_all_countries();
    }else{
	   $JSON->{error} = 'Not implemented';
    }
    
    $JSON->{redirect} = '';
    $JSON->{msg} = msg_get();
    print Chapix::Com::header_out('application/json');
    print JSON::XS->new->encode($JSON);
}


# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;
    my $results = {};

    if($_REQUEST->{View} eq 'PaypalIPN'){
	Chapix::Xaa::Actions::process_paypal_ipn();
	return;
    }elsif(defined $_REQUEST->{_submitted_login}){
        $results = Chapix::Xaa::Actions::login();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_password_reset}){
        $results = Chapix::Xaa::Actions::password_reset();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_password_reset_check}){
        $results = Chapix::Xaa::Actions::password_reset_update();
        process_results($results);
        return;
    }elsif($_REQUEST->{View} eq 'Logout'){
        $results = Chapix::Xaa::Actions::logout();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_domain_settings}){
        # Change domain settings
        $results = Chapix::Xaa::Actions::save_domain_settings();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_change_password}){
        # Change password
        $results = Chapix::Xaa::Actions::save_new_password();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_edit_account}){
        # Change account settings
        $results = Chapix::Xaa::Actions::save_account_settings();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_user}){
        if($_REQUEST->{_submit} eq loc('Restablecer Contraseña')){
            # Reset user password
            $results = Chapix::Xaa::Actions::reset_user_password();
            process_results($results);
        return;
        }elsif($_REQUEST->{_submit} eq loc('Eliminar')){
            # Delete user
            $results = Chapix::Xaa::Actions::delete_user();
            process_results($results);
        return;
        }else{
            # Save user data
            $results = Chapix::Xaa::Actions::save_user();
            process_results($results);
        return;
        }
    }elsif(defined $_REQUEST->{_submitted_register}){
        #Register new account
        $results = Chapix::Xaa::Actions::create_account();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_upload_logo}){
        $results = Chapix::Xaa::Actions::save_logo();
        process_results($results);
        return;
    }
}


sub process_results {
    my $results = shift;
    http_redirect($results->{redirect}) if($results->{redirect});
}

# Main display function, this function prints the required view.
sub view {
    my $self = shift;

    if($sess{user_id}){
        print Chapix::Com::header_out();
        if($_REQUEST->{View} eq 'YourAccount'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_your_account() );
        }elsif($_REQUEST->{View} eq 'ChangePassword'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_password_form() );
        }elsif($_REQUEST->{View} eq 'EditAccount'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_edit_account_form() );
        }elsif($_REQUEST->{View} eq 'Settings'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_settings() );
        }elsif($_REQUEST->{View} eq 'DomainSettings'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_domain_settings() );
        }elsif($_REQUEST->{View} eq 'Subscription'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_subscription_details() );
        }elsif($_REQUEST->{View} eq 'BillingHistory'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_billing_history() );
        }elsif($_REQUEST->{View} eq 'EditLogo'){
           print Chapix::Layout::print( Chapix::Xaa::View::display_logo_form() );
        }else{
            if($_REQUEST->{View}){
                print Chapix::Xaa::View::default();
            }else{
              print Chapix::Layout::print( Chapix::Xaa::View::display_home() );
            }
        }
    }else{
        # Validate if the user is logged in
        if($_REQUEST->{View} eq 'Login'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_login() );
            return;
        }elsif($_REQUEST->{View} eq 'Register'){
	    #Chapix::Com::http_redirect('/Register');
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_register() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordReset'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_password_reset() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordResetSent'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_password_reset_sent() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordResetCheck'){
            if (Chapix::Xaa::Actions::validate_password_reset_key()) {
                print Chapix::Com::header_out();
                print Chapix::Layout::print( Chapix::Xaa::View::display_password_reset_form() );
                return;
            }else{
                msg_add('danger','Tu clave de recuperación de contraseña a caducado. Favor de intentar de nuevo.');
                http_redirect("/Xaa/PasswordReset");
            }
        }elsif($_REQUEST->{View} eq 'PasswordResetSuccess'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_password_reset_success() );
            return;
        }
        msg_add('warning', loc('Inicia sesión en tu cuenta para continuar.'));
        Chapix::Com::http_redirect('/Xaa/Login');
    }
}

1;
