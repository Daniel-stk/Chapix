package Chapix::Notifications::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);

use Chapix::Conf;
use Chapix::Com;
use Chapix::Notifications::View;
use Chapix::Mail::Controller;

# Language
use Chapix::Notifications::L10N;
my $lh = Chapix::Notifications::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub new {
    my $class = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;

    # Logged user is required
    if(!$sess{user_id}){
    	msg_add('warning','To continue, log into your account.');
    	Chapix::Com::http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Login');
    }

    # init app ENV
    $self->_init();
    
    return $self;
}

sub _init {
    my $self = shift;
    $self->{main_db} = $conf->{Xaa}->{DB};
    $conf->{Domain} = $dbh->selectrow_hashref(
        "SELECT d.domain_id, d.name, d.folder, d.database, d.country_id, d.language, d.time_zone FROM $self->{main_db}.xaa_domains d WHERE folder = ?",{},
        $_REQUEST->{Domain});
}

# Main display function, this function prints the required view.
sub display {
    my $self = shift;

    print Chapix::Com::header_out();
    
    if($_REQUEST->{View} eq ''){
        print Chapix::Layout::print( Chapix::Notifications::View::display_home() );
    }else{
        msg_add('warning',loc('Not Found'));
        print Chapix::Notifications::View::default();
    }
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;
    
    if($_REQUEST->{_view} eq 'Notification'){
	$self->set_view_and_redirect();
    }
}

sub add {
    my $self = shift;
    my $user_id = shift || $sess{user_id};
    my $title = shift || '';
    my $url = shift || '';
    
    if(!$title){
	return '';
    }
    
    if(!$url){
	return '';
    }
    
    $dbh->do("INSERT INTO $self->{main_db}.notifications (user_id, title, expiration, url, readed) VALUES (?,?, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 5 DAY) ,?,0)",{},$user_id, $title, $url);        
    my $id = $dbh->last_insert_id("","","$self->{main_db}.notifications","notification_id");
    
    return $id;
}


sub delete {
    my $self = shift;
    my $notification_id = shift;
    my $t = 0;
    
    $t = int($dbh->do("DELETE FROM $self->{main_db}.notifications WHERE notification_id=? AND user_id=?",{},$notification_id, $sess{user_id}));
    
    return $t;
}

sub set_view {
    my $self = shift;
    my $notification_id = shift;
    my $t = 0;

    $t = int($dbh->do("UPDATE $self->{main_db}.notifications SET readed=1 WHERE notification_id=? AND user_id=?".{}.$notification_id, $sess{user_id}));
    
    return $t;
}


sub set_view_and_redirect {
    my $self = shift;
    my $notification_id = shift || $_REQUEST->{notification_id};
    
    $dbh->do("UPDATE $self->{main_db}.notifications SET readed=1 WHERE notification_id=? AND user_id=?",{},$notification_id, $sess{user_id});
    
    my $url = $dbh->selectrow_array("SELECT url FROM $self->{main_db}.notifications WHERE notification_id=? AND user_id=?",{},$notification_id, $sess{user_id});
    
    http_redirect($url);
}

1;
