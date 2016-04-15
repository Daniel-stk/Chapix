package Chapix::Notifications::Actions;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);

use Chapix::Conf;
use Chapix::Com;

use Chapix::Mail::Controller;

sub add {
    my $results;

    my $title = shift || '';
    my $url = shift || '';
    my $user_id = shift || $sess{user_id};
    my $id;
    
    if(!$title){
        $results->{error} = 1;       
	   return $results;
    }
    
    if(!$url){
        $results->{error} = 1;
	   return $results;
    }
    
    eval {    
        $dbh->do("INSERT INTO $conf->{Xaa}->{DB}.notifications (user_id, title, expiration, url, readed) VALUES (?,?, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 5 DAY) ,?,0)",{},$user_id, $title, $url);        
        $id = $dbh->last_insert_id("","","$conf->{Xaa}->{DB}.notifications","notification_id");
        $results->{id} = $id;
    };
    if ($@) {
        $results->{error} = 1;
        msg_add('danger', loc("No se pudo agregar la notificación"));
    }else{
        $results->{success} = 1;
        $results->{redirect} = '/';
        msg_add('success', "Se agrego la notificación");
    }
    
    return $results;
}


sub delete {
    my $results;
    my $notification_id = shift;
    my $t = 0;
    
    $t = int($dbh->do("DELETE FROM $conf->{Xaa}->{DB}.notifications WHERE notification_id=? AND user_id=?",{},$notification_id, $sess{user_id}));
    
    return $t;
}

sub set_view {
    my $self = shift;
    my $notification_id = shift;
    my $t = 0;

    $t = int($dbh->do("UPDATE $conf->{Xaa}->{DB}.notifications SET readed=1 WHERE notification_id=? AND user_id=?".{}.$notification_id, $sess{user_id}));
    
    return $t;
}


sub set_view_and_redirect {
    my $self = shift;
    my $notification_id = shift || $_REQUEST->{notification_id};
    
    $dbh->do("UPDATE $conf->{Xaa}->{DB}.notifications SET readed=1 WHERE notification_id=? AND user_id=?",{},$notification_id, $sess{user_id});
    
    my $url = $dbh->selectrow_array("SELECT url FROM $conf->{Xaa}->{DB}.notifications WHERE notification_id=? AND user_id=?",{},$notification_id, $sess{user_id});
    
    http_redirect($url);
}


1;