package Chapix::Notifications::API;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::Com;

use Chapix::Mail::Controller;

sub add {
    my $title = shift || '';
    my $url = shift || '';
    my $user_id = shift || $sess{user_id};
    my $id;

    my $results;
    
    if(!$title){
        $results->{error} = 1;       
	   return $results;
    }
    
    if(!$url){
        $results->{error} = 1;
	   return $results;
    }
    
    eval {
        $dbh->do("INSERT INTO $conf->{Xaa}->{DB}.notifications (user_id, title, expiration, url, readed) VALUES (?,?, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 YEAR) ,?,0)",{},$user_id, $title, $url);        
        $id = $dbh->last_insert_id("","","$conf->{Xaa}->{DB}.notifications","notification_id");
        $results->{id} = $id;
    };
    if ($@) {
        $results->{error} = 1;
    }else{
        $results->{success} = 1;
    }
    
    return $results;
}


1;