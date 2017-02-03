package Chapix::Accounts::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);
use List::Util qw(min max);

use Chapix::Conf;
use Chapix::Com;

use Chapix::Accounts::Actions;
use Chapix::Accounts::API;
use Chapix::Accounts::View;

use Chapix::Mail::Controller;

# Language
use Chapix::Accounts::L10N;
my $lh = Chapix::Accounts::L10N->get_handle($sess{user_language}) || die "Language?";
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
     
    if($_REQUEST->{Object} eq 'Signup'){
        $JSON = Chapix::Accounts::API::signup($JSON);
    }elsif($_REQUEST->{Object} eq 'PasswordReset'){
        $JSON = Chapix::Accounts::API::password_reset($JSON);
    }elsif($_REQUEST->{Object} eq 'Login'){
        $JSON = Chapix::Accounts::API::login($JSON);
    }else{
        $JSON->{error} = "1";
        $JSON->{msg} = 'Not implemented';
    }
   
    print Chapix::Com::header_out('application/json');
    print JSON::XS->new->encode($JSON);
}


# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;
    my $results = {};

    if(defined $_REQUEST->{_submitted_login}){
        $results = Chapix::Accounts::Actions::login();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_password_reset}){
        $results = Chapix::Accounts::Actions::password_reset();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_password_reset_check}){
        $results = Chapix::Accounts::Actions::password_reset_update();
        process_results($results);
        return;
    }elsif($_REQUEST->{View} eq 'Logout'){
        $results = Chapix::Accounts::Actions::logout();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_change_password}){
        # Change password
        $results = Chapix::Accounts::Actions::save_new_password();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_edit_account}){
        # Change account settings
        $results = Chapix::Accounts::Actions::save_account_settings();
        process_results($results);
        return;
    }elsif(defined $_REQUEST->{_submitted_user}){
        if($_REQUEST->{_submit} eq loc('Restablecer Contraseña')){
            # Reset user password
            $results = Chapix::Accounts::Actions::reset_user_password();
            process_results($results);
        return;
        }elsif($_REQUEST->{_submit} eq loc('Eliminar')){
            # Delete user
            $results = Chapix::Accounts::Actions::delete_user();
            process_results($results);
        return;
        }else{
            # Save user data
            $results = Chapix::Accounts::Actions::save_user();
            process_results($results);
        return;
        }
    }elsif(defined $_REQUEST->{_submitted_register}){
        #Register new account
        $results = Chapix::Accounts::Actions::create_account();
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
            print Chapix::Layout::print( Chapix::Accounts::View::display_your_account() );
        }elsif($_REQUEST->{View} eq 'ChangePassword'){
            print Chapix::Layout::print( Chapix::Accounts::View::display_password_form() );
        }elsif($_REQUEST->{View} eq 'EditAccount'){
            print Chapix::Layout::print( Chapix::Accounts::View::display_edit_account_form() );
        }elsif($_REQUEST->{View} eq 'Settings'){
            print Chapix::Layout::print( Chapix::Accounts::View::display_settings() );
        }elsif($_REQUEST->{View} eq 'Welcome'){
            print Chapix::Layout::print( Chapix::Accounts::View::display_home() );
        }else{
            if($_REQUEST->{View}){
                print Chapix::Accounts::View::default();
            }else{
                print Chapix::Layout::print( Chapix::Accounts::View::display_home() );
            }
        }
    }else{
        # Validate if the user is logged in
        if($_REQUEST->{View} eq 'Login'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Accounts::View::display_login() );
            return;
        }elsif($_REQUEST->{View} eq 'Register'){
	    #Chapix::Com::http_redirect('/Register');
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Accounts::View::display_register() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordReset'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Accounts::View::display_password_reset() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordResetSent'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Accounts::View::display_password_reset_sent() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordResetCheck'){
            if (Chapix::Accounts::Actions::validate_password_reset_key()) {
                print Chapix::Com::header_out();
                print Chapix::Layout::print( Chapix::Accounts::View::display_password_reset_form() );
                return;
            }else{
                msg_add('danger','Tu clave de recuperación de contraseña a caducado. Favor de intentar de nuevo.');
                http_redirect("/Accounts/PasswordReset");
            }
        }elsif($_REQUEST->{View} eq 'PasswordResetSuccess'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Accounts::View::display_password_reset_success() );
            return;
        }
        msg_add('warning', loc('Inicia sesión en tu cuenta para continuar.'));
        Chapix::Com::http_redirect('/Accounts/Login');
    }
}

1;
