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
    $self->{main_db} = $conf->{Xaa}->{DB};
    $conf->{Domain} = $dbh->selectrow_hashref(
        "SELECT d.domain_id, d.name, d.folder, d.database, d.country_id, d.time_zone, d.language " .
	"FROM $self->{main_db}.xaa_domains d WHERE folder = ?",{},$_REQUEST->{Domain});
}

sub actions {
    my $self = shift;
    my $results = {};

    if(defined $_REQUEST->{_submitted_login}){
        $results = Chapix::Xaa::Actions::login();
    }elsif(defined $_REQUEST->{_submitted_password_reset}){
        $results = Chapix::Xaa::Actions::password_reset();
    }elsif(defined $_REQUEST->{_submitted_password_reset_check}){
        $results = Chapix::Xaa::Actions::password_reset_update();
    }elsif($_REQUEST->{View} eq 'Logout'){
    	$results = Chapix::Xaa::Actions::logout();
    }elsif(defined $_REQUEST->{_submitted_domain_settings}){
        # Change domain settings
        $results = Chapix::Xaa::Actions::save_domain_settings();
    }elsif(defined $_REQUEST->{_submitted_change_password}){
        # Change password
        $results = Chapix::Xaa::Actions::save_new_password();
    }elsif(defined $_REQUEST->{_submitted_edit_account}){
        # Change account settings
        $results = Chapix::Xaa::Actions::save_account_settings();
    }elsif(defined $_REQUEST->{_submitted_user}){
        if($_REQUEST->{_submit} eq loc('Resset Password')){
            # Reset user password
            $results = Chapix::Xaa::Actions::reset_user_password();
        }elsif($_REQUEST->{_submit} eq loc('Delete')){
            # Delete user
            $results = Chapix::Xaa::Actions::delete_user();
        }else{
            # Save user data
            $results = Chapix::Xaa::Actions::save_user();
        }
    }elsif(defined $_REQUEST->{_submitted_register}){
    	#Register new account
    	$results = Chapix::Xaa::Actions::create_account();
    }elsif(defined $_REQUEST->{_submitted_upload_logo}){
    	$results = Chapix::Xaa::Actions::save_logo();
    }

    process_results($results);
    return;
}

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
            if ($self->validate_password_reset_key()) {
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
        msg_add('warning',loc('To continue, log into your account.->' . " $_REQUEST->{Domain} - $_REQUEST->{Controller}  - $_REQUEST->{View} "));
        Chapix::Com::http_redirect('/Xaa/Login');
    }
}


1;
