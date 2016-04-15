package Chapix::Notifications::API;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::Com;

use Chapix::Mail::Controller;

sub add {
	my $results;

	my $title = shift || $_REQUEST->{title} || '';
	my $url = shift || $_REQUEST->{url} || '';
	my $user = shift || $_REQUEST->{user_id} || $sess{user_id};

	eval {
		$dbh->do("INSERT INTO $conf->{Xaa}->{DB}.notifications (user_id, title, expiration, url) VALUES (?, ?, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 YEAR), ?)",{}, 
			$user, $title, $url );
	};
	if ($@){
		$results->{error} = 1;
	}else{
		$results->{success} = 1;
	}

	return $results;
}

1;