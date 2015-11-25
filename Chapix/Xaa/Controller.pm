package Chapix::Xaa::Controller;

use lib('cpan/');
use warnings;
use strict;
use Digest::SHA qw(sha384_hex);
use Carp;

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
    $conf->{Domain} = $dbh->selectrow_hashref("SELECT d.domain_id, d.name, d.folder, d.database, d.country_id FROM $self->{main_db}.xaa_domains d WHERE folder = ?",{},$_REQUEST->{Domain});
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
    }elsif($_REQUEST->{View} eq 'Users'){
        if($_REQUEST->{user_id}){
            print Chapix::Layout::print( Chapix::Xaa::View::display_user_form() );
        }else{
            print Chapix::Layout::print( Chapix::Xaa::View::display_users_list() );
        }
    }elsif($_REQUEST->{View} eq 'User'){
        print Chapix::Layout::print( Chapix::Xaa::View::display_user_form() );
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
		#"WHERE u.email=?",{},
        #$_REQUEST->{email});
                "WHERE u.email=? AND u.password=?",{},
        $_REQUEST->{email}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}));
    
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
 
sub save_user {
    my $self = shift;
    my $user_id = $_REQUEST->{user_id} || '';
    if($user_id){
        # Update

        # The user are from this domain?
        $user_id = $dbh->selectrow_array("SELECT user_id FROM $self->{main_db}.xaa_users_domains WHERE user_id=? AND domain_id=?",{},$user_id, $conf->{Domain}->{domain_id}) || 0;
        if(!$user_id){
            msg_add('danger',loc('User does not exist'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Users');
        }

        eval {
            $dbh->do("UPDATE $self->{main_db}.xaa_users SET name=?, time_zone=?, language=? WHERE user_id=?",{},
                     $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $user_id);
            $dbh->do("UPDATE $self->{main_db}.xaa_users_domains SET active=? WHERE user_id=? AND domain_id=?",{},
                 ($_REQUEST->{active} || 0), $user_id, $conf->{Domain}->{domain_id});
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success', loc('User successfully updated'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Users');
        }
       
    }else{
        # Add
        my $password = substr(sha384_hex(time.$conf->{Site}->{Name}.'- Te deseamos el mayor éxito en todo lo que hagas -'),3,7);
        eval {
            # The email is in the database?
            $user_id = $dbh->selectrow_array("SELECT user_id FROM $self->{main_db}.xaa_users WHERE email=?",{},$_REQUEST->{email});
            
            if($user_id){
                # Add user to the domain
                $dbh->do("INSERT INTO $self->{main_db}.xaa_users_domains (user_id, domain_id, added_on, added_by, active, default_domain) VALUES(?,?,NOW(), ?,1,1)",{},
                             $user_id, $conf->{Domain}->{domain_id}, $sess{user_id});
                $_REQUEST->{user_id} = $user_id;
                
                $dbh->do("UPDATE $self->{main_db}.xaa_users SET password=? WHERE user_id=?",{},
                         sha384_hex($conf->{Security}->{key} . $password), $user_id);
            }else{
                # Add user
                $dbh->do("INSERT INTO $self->{main_db}.xaa_users (name, email, time_zone, language, password) VALUES(?,?,?,?,?)",{},
                         $_REQUEST->{name}, $_REQUEST->{email}, $_REQUEST->{time_zone}, $_REQUEST->{language}, sha384_hex($conf->{Security}->{key} . $password) );
                $user_id = $dbh->last_insert_id('','',"$self->{main_db}.xaa_users",'user_id');
                
                # Add user to the domain
                $dbh->do("INSERT IGNORE INTO $self->{main_db}.xaa_users_domains (user_id, domain_id, added_on, added_by, active, default_domain) VALUES(?,?,NOW(), ?,1,1)",{},
                         $user_id, $conf->{Domain}->{domain_id}, $sess{user_id});
            }

            # Send welcome email to the user
        };
        if($@){
            msg_add('warning',"The email address $_REQUEST->{email} is already in use.".$@);
        }else{
            msg_add('success', loc('User successfully added, the user have been notified by email'));

            # Send the new password by email
            my $Mail = Chapix::Mail::Controller->new();
            my $enviado = $Mail->html_template({
                to       => $_REQUEST->{'email'},
                subject  => $conf->{App}->{Name} . ': '. loc('Your new account is ready'),
                template => {
                    file => 'Chapix/Xaa/tmpl/user-creation-letter.html',
                    vars => {
                        name     => $_REQUEST->{'name'},
                        email    => $_REQUEST->{email},
                        password => $password,
                        loc => \&loc,
                    }
                }
            });

            
            http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Users');
        }
    }
}

sub reset_user_password {
    my $self = shift;
    my $user_id = $_REQUEST->{user_id} || '';
    my $user;
    if($user_id){
        # Update

        # The user are from this domain?
        $user = $dbh->selectrow_hashref(
            "SELECT ud.user_id, u.email, u.name FROM $self->{main_db}.xaa_users_domains ud INNER JOIN $self->{main_db}.xaa_users u ON ud.user_id=u.user_id " .
                "WHERE ud.user_id=? AND ud.domain_id=?",{},
            $user_id, $conf->{Domain}->{domain_id}) || 0;
        if(!$user->{user_id}){
            msg_add('danger','User does not exist.');
            http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Users');
        }

        my $password = substr(sha384_hex(time.$conf->{Site}->{Name}.'- Te deseamos el mayor exito en todo loq ue hagas -'),3,7);
        eval {
            $dbh->do("UPDATE $self->{main_db}.xaa_users SET password=? WHERE user_id=?",{},
                     sha384_hex($conf->{Security}->{key} . $password), $user->{user_id});
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success','User successfully updated.');

            # Send the new password by email
            my $Mail = Chapix::Mail::Controller->new();
            my $enviado = $Mail->html_template({
                to       => $user->{'email'},
                subject  => $conf->{App}->{Name} . ': Your password has been reset',
                template => {
                    file => 'Chapix/Xaa/tmpl/user-password-reset.html',
                    vars => {
                        name  => $_REQUEST->{'name'},
                        email => $user->{'email'},
                        new_password      => $password,
                    }
                }
            });
                        
            http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Users');
        }
    }
}

sub delete_user {
    my $self = shift;
    my $user_id = $_REQUEST->{user_id} || '';
    my $user;
    if($user_id){
        # Update

        # The user are from this domain?
        $user = $dbh->selectrow_hashref(
            "SELECT ud.user_id, u.email, u.name FROM $self->{main_db}.xaa_users_domains ud INNER JOIN $self->{main_db}.xaa_users u ON ud.user_id=u.user_id " .
                "WHERE ud.user_id=? AND ud.domain_id=?",{},
            $user_id, $conf->{Domain}->{domain_id}) || 0;
        if(!$user->{user_id}){
            msg_add('danger','User does not exist.');
            http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Users');
        }

        eval {
            $dbh->do("DELETE FROM $self->{main_db}.xaa_users_domains WHERE user_id=? AND domain_id=?",{},
                     $user->{user_id}, $conf->{Domain}->{domain_id});
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success','User successfully deleted.');
            http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Users');
        }
    }
}

1;
