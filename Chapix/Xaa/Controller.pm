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
    $self->_init();
	
    return $self;
}

# Initialize ENV
sub _init {
    my $self = shift;
    $self->{main_db} = $conf->{Xaa}->{DB};

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
	msg_add('warning','To continue, log into your account..');
	Chapix::Com::http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Login');
    }

    print Chapix::Com::header_out();
    if($_REQUEST->{View} eq 'MyAccount'){
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
    }elsif($_REQUEST->{View} eq 'Logout'){
	$self->logout();
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

	my $domain_id = $dbh->selectrow_array("SELECT domain_id FROM $self->{main_db}.xaa_users_domains WHERE user_id=? AND active=1 ORDER BY default_domain DESC, added_on LIMIT 1 ",{},$user->{user_id}) || 0;
	if($domain_id){
	    my $domain = $dbh->selectrow_hashref("SELECT name, folder FROM $self->{main_db}.xaa_domains WHERE domain_id=? ",{},$domain_id);
	    Chapix::Com::http_redirect('/'.$domain->{folder});
	}
	
        Chapix::Com::http_redirect('/Xaa');
    }else{
        # Record login attemp
        my $updated = $dbh->do(
            "UPDATE $self->{main_db}.ip_security ips SET ips.failed_logins=ips.failed_logins + 1 WHERE ips.ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",
            {},$ENV{REMOTE_ADDR});
        if(!int($updated)){
            $dbh->do("DELETE FROM $self->{main_db}.ip_security WHERE ip_address=?",{},$ENV{REMOTE_ADDR});
            $dbh->do("INSERT INTO $self->{main_db}.ip_security (ip_address, date, failed_logins) VALUES(?,NOW(),1)",
                 {},$ENV{REMOTE_ADDR});
        }
        my $failed_logins = $dbh->selectrow_array("SELECT failed_logins FROM $self->{main_db}.ip_security ips WHERE ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",{},$ENV{REMOTE_ADDR});
        msg_add("warning","Email or password incorrect.");
        if ($failed_logins > 3) {
            msg_add("danger","You have " . (10 - $failed_logins) . " attemps left before being blocked.");
        }
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

1;
