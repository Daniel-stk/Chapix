package Chapix::Xaa::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);

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

# Main display function, this function prints the required view.
sub display {
    my $self = shift;
    
    # Validate if the user is logge in
    if($_REQUEST->{View} eq 'Login'){
        print Chapix::Com::header_out();
        print Chapix::Layout::print( Chapix::Xaa::View::display_login() );
        return;
    }
    if(!$sess{user_id}){
        msg_add('warning',loc('To continue, log into your account..'));
        Chapix::Com::http_redirect('/Xaa/Login');
    }

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
    # }elsif($_REQUEST->{View} eq 'Users'){
    #     if($_REQUEST->{user_id}){
    #         print Chapix::Layout::print( Chapix::Xaa::View::display_user_form() );
    #     }else{
    #         print Chapix::Layout::print( Chapix::Xaa::View::display_users_list() );
    #     }
    # }elsif($_REQUEST->{View} eq 'User'){
    #     print Chapix::Layout::print( Chapix::Xaa::View::display_user_form() );
    }else{
        print Chapix::Xaa::View::default();
    }
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;

    if(defined $_REQUEST->{_submitted_login}){
        $self->login();
    }elsif($_REQUEST->{View} eq 'Logout'){
	$self->logout();
    }elsif(defined $_REQUEST->{_submitted_domain_settings}){
        # Change domain settings
        $self->save_domain_settings();
    }elsif(defined $_REQUEST->{_submitted_change_password}){
        # Change password
        $self->save_new_password();
    }elsif(defined $_REQUEST->{_submitted_edit_account}){
        # Change account settings
        $self->save_account_settings();
    }elsif(defined $_REQUEST->{_submitted_user}){
        if($_REQUEST->{_submit} eq loc('Resset Password')){
            # Reset user password
            $self->reset_user_password();
        }elsif($_REQUEST->{_submit} eq loc('Delete')){
            # Delete user
            $self->delete_user();
        }else{
            # Save user data
            $self->save_user();
        }
    }
}

sub login {
    my $self = shift;
    my $user = $dbh->selectrow_hashref(
        "SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
	    "FROM $self->{main_db}.xaa_users u " .
		"WHERE u.email=?",{},
        $_REQUEST->{email});
        #        "WHERE u.email=? AND u.password=?",{},
       # $_REQUEST->{email}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}));
    
    if($user and $_REQUEST->{email}){
        # Write session data and redirect to index
	$sess{user_id}    = "$user->{user_id}";
        $sess{user_name}  = "$user->{name}";
        $sess{user_email} = "$user->{email}";
        $sess{user_time_zone} = "$user->{time_zone}";
        $sess{user_language}  = "$user->{language}";

	my $domain_id = $dbh->selectrow_array("SELECT domain_id FROM $self->{main_db}.xaa_users_domains WHERE user_id=? AND active=1 ORDER BY default_domain DESC, added_on LIMIT 1 ",{},$user->{user_id}) || 0;
	if($domain_id){
	    my $domain = $dbh->selectrow_hashref("SELECT name, folder FROM $self->{main_db}.xaa_domains WHERE domain_id=? ",{},$domain_id);
	    Chapix::Com::http_redirect('/'.$domain->{folder});
	}else{
            msg_add('warning','Your account is not linked to any business account.');
        }
	
        Chapix::Com::http_redirect('/Xaa');
    }else{
        # Record login attemp
        # my $updated = $dbh->do(
        #     "UPDATE $self->{main_db}.ip_security ips SET ips.failed_logins=ips.failed_logins + 1 WHERE ips.ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",
        #     {},$ENV{REMOTE_ADDR});
        # if(!int($updated)){
        #     $dbh->do("DELETE FROM $self->{main_db}.ip_security WHERE ip_address=?",{},$ENV{REMOTE_ADDR});
        #     $dbh->do("INSERT INTO $self->{main_db}.ip_security (ip_address, date, failed_logins) VALUES(?,NOW(),1)",
        #          {},$ENV{REMOTE_ADDR});
        # }
        # my $failed_logins = $dbh->selectrow_array("SELECT failed_logins FROM $self->{main_db}.ip_security ips WHERE ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",{},$ENV{REMOTE_ADDR});
        msg_add("warning","Email or password incorrect.");
        # if ($failed_logins > 3) {
        #     msg_add("danger","You have " . (10 - $failed_logins) . " attemps left before being blocked.");
        # }
    }
}   

sub logout {
    my $self = shift;
    
    $sess{user_id}        = "";
    $sess{user_name}      = "";
    $sess{user_email}     = "";
    $sess{user_time_zone} = "";
    $sess{user_language}  = "";

    Chapix::Com::http_redirect('/');
}

sub save_new_password {
    my $self = shift;
    my $current_password = $dbh->selectrow_array("SELECT u.password FROM $self->{main_db}.xaa_users u WHERE u.user_id=?",{},$sess{user_id}) || '';
    my $new_password = sha384_hex($conf->{Security}->{key} . $_REQUEST->{new_password}); 

    # Old password match?
    if($current_password ne sha384_hex($conf->{Security}->{key} . $_REQUEST->{current_password})){
        msg_add('warning',loc('Current password does not match'));
        return '';
    }
    
    # new passwords match?
    if($_REQUEST->{new_password} ne $_REQUEST->{new_password_repeat}){
        msg_add('warning', loc('The "New password" and "Repeat new password" fields must match'));
        return '';
    }
    
    eval {
        $dbh->do("UPDATE $self->{main_db}.xaa_users u SET u.password=? WHERE u.user_id=?",{},
                 $new_password, $sess{user_id});
    };
    if($@){
        msg_add('danger',$@);
    }else{
        msg_add('success',loc('Password successfully updated'));
        http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/YourAccount');
    }
}

sub save_domain_settings {
    my $self = shift;
    eval {
        $dbh->do("UPDATE $self->{main_db}.xaa_domains d SET d.name=?, d.time_zone=?, d.language=? WHERE d.domain_id=?",{},
                 $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $conf->{Domain}->{domain_id});
    };
    if($@){
        msg_add('danger',$@);
    }else{
        msg_add('success',loc('Business account updated'));
        http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Settings');
    }
}


sub save_account_settings {
    my $self = shift;
    eval {
        $dbh->do("UPDATE $self->{main_db}.xaa_users u SET u.name=?, u.time_zone=?, u.language=? WHERE u.user_id=?",{},
                 $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $sess{user_id});
        $sess{user_name}      = $_REQUEST->{name};
        $sess{user_time_zone} = $_REQUEST->{time_zone};
        $sess{user_language}  = $_REQUEST->{language};
    };
    if($@){
        msg_add('danger',$@);
    }else{
        msg_add('success',loc('Account successfully updated'));
        http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/YourAccount');
    }
}
 
1;
