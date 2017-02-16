package Chapix::Pages::Controller;

# This module read pages from the base URL /Precios -> templates/ID/Precios.html

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);

use Chapix::Conf;
use Chapix::Com;
use Chapix::Pages::View;

sub new {
    my $class = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;

    return $self;
}

# Main display function, this function prints the required view.
sub view {
    my $self = shift;
    $_REQUEST->{View} = 'Home' if(!$_REQUEST->{View});

    print Chapix::Com::header_out();
    print Chapix::Layout::print( Chapix::Pages::View::display_page() );
}

# Admin actions.
sub actions {
    my $self = shift;
}

1;
