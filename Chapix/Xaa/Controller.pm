package Chapix::Xaa::Controller;

use lib('cpan/');
use warnings;
use strict;
use Digest::SHA qw(sha384_hex);
use Carp;

use Chapix::Conf;
use Chapix::Com;
use Chapix::Xaa::View;

sub new {
    my $class = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;

    # Init app ENV
    $self->{main_db} = $conf->{Xaa}->{DB};
	
    return $self;
}

# Main display function, this function prints the required view.
sub display {
    my $self = shift;
    print Chapix::Com::header_out();
    
    # Validate if the user is logge in
    if(!$sess{user_id}){
	print Chapix::Layout::print( Chapix::Xaa::View::display_login() );
	return;
    }

    if($_REQUEST->{view} eq 'MyAccount'){
        print Chapix::Layout::print( Chapix::Xaa::View::display_my_account() );
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
    #}elsif(defined $_REQUEST->{_submitted_logout}){
    #    Chapix::Admin::Controller::logout();
    }
}

# sub save_data {
#     my $self = shift;
#     if($_REQUEST->{view} eq 'add'){
#         my $id;
#         eval {
#             $dbh->do("INSERT INTO blocks (name, content) VALUES(?,?)",{},
#                      $_REQUEST->{name}, $_REQUEST->{content});
#             $id = $dbh->last_insert_id('','','blocks','block_id');
#         };
#         if($@){
#             msg_add('warning',$@);
#         }else{
#             msg_add('success','The record were successfully updated.');
#             http_redirect('?controller=Blocks&q=&view=edit&block_id='.$id);
#         }
#     }elsif($_REQUEST->{_submit} eq 'Delete'){
#         eval {
#             # Delete record
#             $dbh->do("DELETE FROM blocks WHERE block_id=?",{},
#                  $_REQUEST->{block_id});
#         };
#         if($@){
#             msg_add('danger',$@);
#         }else{
#             msg_add('success','The record were successfully deleted.');
#             http_redirect('?controller=Blocks');            
#         }
#     }else{
#         eval {
#             # Update record
#             $dbh->do("UPDATE blocks SET name=?, content=? WHERE block_id=?",{},
#                  $_REQUEST->{name}, $_REQUEST->{content}, $_REQUEST->{block_id});
#         };
#         if($@){
#             msg_add('danger',$@);
#         }else{
#             msg_add('success','The record were successfully updated.');
            
#         }
#     }
# }

sub login {
    my $self = shift;
    my $user = $dbh->selectrow_hashref(
        "SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
	    "FROM $self->{main_db}.xaa_users u " .
		"WHERE u.email=?",{},
        $_REQUEST->{email});
    #"WHERE u.email=? AND u.password=?",{},
    #$_REQUEST->{email}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}));
    
    if($user and $_REQUEST->{email}){
        # Write session data and redirect to index
        $sess{user_id}    = "$user->{user_id}";
        $sess{user_name}  = "$user->{name}";
        $sess{user_email} = "$user->{email}";
        $sess{user_time_zone} = "$user->{time_zone}";
        $sess{user_language}  = "$user->{language}";
        #user_log('WebSite','Log in');
        Chapix::Com::http_redirect($conf->{ENV}->{BaseURL} . 'Xaa');
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
    #user_log('WebSite','Log out');
    $sess{user_id}        = "";
    $sess{user_name}      = "";
    $sess{user_email}     = "";
    $sess{user_time_zone} = "";
    $sess{user_language}  = "";

    Chapix::Com::http_redirect($conf->{ENV}->{BaseURL});
}

1;
