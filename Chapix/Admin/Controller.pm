package Chapix::Admin::Controller;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);

use Chapix::Conf;
use Chapix::Admin::Com;
use Chapix::Admin::View;
use Chapix::Admin::L10N;

# Language Object
my $lh = Chapix::Admin::L10N->get_handle($sess{admin_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub handler {
    if($_REQUEST->{Controller} eq 'Admin'){
        Chapix::Admin::Controller::actions();
        Chapix::Admin::Controller::display();
    }elsif($_REQUEST->{Controller}){
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
            require "Chapix/" . $module ."/Admin/Controller.pm";
            my $module_name ='Chapix::'.$module.'::Admin::Controller';
            $Module = $module_name->new();
        };
        if($@){
            msg_add('danger', $@);
            Chapix::Admin::Controller::display();
            return '';
        }
 
        # Actions
        $Module->actions();
        
        # Views
        $Module->display();
    }else{
        actions();
        display();
    }
}

# Main display function, this function prints the required View.
sub display {
    print Chapix::Admin::Com::header_out();
    if($sess{admin_id}){
        if($_REQUEST->{View} eq 'Credits'){
            print Chapix::Admin::Layout::print( Chapix::Admin::View::display_credits() );
        }elsif($_REQUEST->{View} eq 'Settings'){
            print Chapix::Admin::Layout::print( Chapix::Admin::View::display_settings_form() );
        }elsif($_REQUEST->{View} eq 'YourAccount'){
            print Chapix::Admin::Layout::print( Chapix::Admin::View::display_account_form() );
        }elsif($_REQUEST->{View} eq 'ChangePassword'){
            print Chapix::Admin::Layout::print( Chapix::Admin::View::display_password_form() );
        }elsif($_REQUEST->{View} eq 'Modules'){
            print Chapix::Admin::Layout::print( Chapix::Admin::View::display_modules_list() );
        }else{
            if($conf->{Xaa}->{MainModule} and !$_REQUEST->{Controller}){
                my $module = $conf->{Xaa}->{MainModule};
                $_REQUEST->{Controller} = $module;
                my $is_installed = $dbh->selectrow_array("SELECT module FROM modules WHERE module=? AND installed=1",{},$module);
                if($is_installed){
                    # Load module
                     my $Module;
                     eval {
                        require "Chapix/" . $module ."/Admin/Controller.pm";
                        my $module_name ='Chapix::'.$module.'::Admin::Controller';
                        $Module = $module_name->new();
                    };
                    if($@){
                       msg_add('danger', 'Error: '.$@);
                    }else{
                        $Module->display();
                        return;
                    }
                }else{
                    msg_add('danger','The main module is not installed');
                }
            }else{
                msg_add('danger',loc('View does not exist'));
            }
        	print Chapix::Admin::View::default();
        }
    }else{
    	print Chapix::Admin::View::display_login();
    }
}


# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    # Check for brute force attacks.
    my $failed_logins = $dbh->selectrow_array("SELECT failed_logins FROM ip_security ips WHERE ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",{},$ENV{REMOTE_ADDR});
    if ($failed_logins >= 10) {
        msg_add('danger','Your ip address is blocked, you must wait for 1 hour to try again.');
        return '';
    }
    
    # Actions that not require an active session
    if(defined $_REQUEST->{'_submitted_login'}){
        Chapix::Admin::Controller::login();
    }elsif(defined $_REQUEST->{'_submitted_logout'}){
        Chapix::Admin::Controller::logout();
    }
    
    # Actions who need an active session.
    if($sess{admin_id}){
        
        # Save settings
        if(defined $_REQUEST->{'_submitted_settings'}){
            Chapix::Admin::Controller::save_settings();
        }
        
        # Save accounts details
        if(defined $_REQUEST->{'_submitted_account'}){
            Chapix::Admin::Controller::save_account();
        }

        # Change password
        if(defined $_REQUEST->{'_submitted_change_password'}){
            Chapix::Admin::Controller::save_new_password();
        }
    }    
}

# The real work
sub login {
    my $admin = $dbh->selectrow_hashref(
        "SELECT a.admin_id, a.email, a.name, a.time_zone, a.language FROM $conf->{Xaa}->{DB}.admins a " .
        "WHERE a.email=? ",{},
        $_REQUEST->{'email'});
#        "WHERE a.email=? AND a.password=?",{},
#        $_REQUEST->{'email'}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{'password'}));

    if($admin and $_REQUEST->{"email"}){
        # Write session data and redirect to index
        $sess{admin_id}    = "$admin->{admin_id}";
        $sess{admin_name}  = "$admin->{name}";
        $sess{admin_email} = "$admin->{email}";
        $sess{admin_time_zone} = "$admin->{time_zone}";
        $sess{admin_language}  = "$admin->{language}";
        admin_log('Admin','Log in');
        Chapix::Admin::Com::http_redirect("index.pl");
    }else{
        # Record login attemp
        my $updated = $dbh->do(
            "UPDATE ip_security ips SET ips.failed_logins=ips.failed_logins + 1 WHERE ips.ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",
            {},$ENV{REMOTE_ADDR});
        if(!int($updated)){
            $dbh->do("DELETE FROM ip_security WHERE ip_address=?",{},$ENV{REMOTE_ADDR});
            $dbh->do("INSERT INTO ip_security (ip_address, date, failed_logins) VALUES(?,NOW(),1)",
                 {},$ENV{REMOTE_ADDR});
        }
        my $failed_logins = $dbh->selectrow_array("SELECT failed_logins FROM ip_security ips WHERE ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",{},$ENV{REMOTE_ADDR});
        msg_add("warning","Email or password incorrect.");
        if ($failed_logins > 3) {
            msg_add("danger","You have " . (10 - $failed_logins) . " attemps left before being blocked.");
        }
    }
}   

sub logout {
    admin_log('Admin','Log out');
    $sess{admin_id}        = "";
    $sess{admin_name}      = "";
    $sess{admin_email}     = "";
    $sess{admin_time_zone} = "";
    $sess{admin_language}  = "";

    Chapix::Admin::Com::http_redirect("index.pl");
}

sub save_settings {
    eval {
        my @keys = qw/Name Description Keywords Language/;
        foreach my $key (@keys){
            $dbh->do("UPDATE `conf` SET `value`=? WHERE `module`=? AND `name`=?",{},
                 $_REQUEST->{$key}, 'WebSite', $key);
        }
    };
    if($@){
        msg_add('danger',$@);
    }else{
        msg_add('success','The record were successfully updated.');
    }
}

# Save current account details
sub save_account {
    eval {
        $dbh->do("UPDATE admins a SET a.name=?, a.email=?, a.time_zone=?, a.language=? WHERE a.admin_id=?",{},
                 $_REQUEST->{'name'}, $_REQUEST->{'email'}, $_REQUEST->{'time_zone'}, $_REQUEST->{'language'}, $sess{admin_id});
    };
    if($@){
        msg_add('danger','Enter a diferent email address. '.$@);
    }else{
        msg_add('success','The record were successfully updated.');
    }
}

# Save current account details
sub save_new_password {
    my $current_password = $dbh->selectrow_array("SELECT a.password FROM admins a WHERE admin_id=?",{},$sess{admin_id}) || 'ss';
    my $new_password = sha384_hex($conf->{Security}->{key} . $_REQUEST->{'new_password'}); 

    # Old password match?
    if($current_password ne sha384_hex($conf->{Security}->{key} . $_REQUEST->{'current_password'})){
        msg_add('warning','Current password does not match.');
        return '';
    }
    
    # new passwords match?
    if($_REQUEST->{'new_password'} ne $_REQUEST->{'new_password_repeat'}){
        msg_add('warning','The "New password" and "Repeat new password" fields must match.');
        return '';
    }
    
    eval {
        $dbh->do("UPDATE admins a SET a.password=? WHERE a.admin_id=?",{},
                 $new_password, $sess{admin_id});
    };
    if($@){
        msg_add('danger',$@);
    }else{
        msg_add('success','Password successfully updated.');
        http_redirect('?');
    }
}

1;
