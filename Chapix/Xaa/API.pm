package Chapix::Xaa::API;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::Com;

# Language
use Chapix::Xaa::L10N;
my $lh = Chapix::Xaa::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }



sub get_all_countries {
	my $results = {};
	eval {
		$results->{countries} = $dbh->selectall_arrayref("SELECT * FROM $conf->{Xaa}->{DB}.countries",{Slice=>{}});
	};
	if ($@) {
		$results->{error} = 1;
		$results->{message} = $@;
	}
	return $results;	
}


sub get_all_states {
	my $results = {};

	eval {
		my $WHERE = '';

		if ($_REQUEST->{country_id}){
			$WHERE = "WHERE country_id='$_REQUEST->{country_id}'";
		}
		$results->{states} = $dbh->selectall_arrayref("SELECT * FROM $conf->{Xaa}->{DB}.states $WHERE",{Slice=>{}});
	};
	if ($@){
		$results->{error} = 1;
		$results->{message} = $@;
	}
	return $results;
}


1;