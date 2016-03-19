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
	}
	return $results;	
}


1;