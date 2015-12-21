package Chapix::Pages::Controller;

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
sub display {
    my $self = shift;
    $_REQUEST->{View} = 'Home' if(!$_REQUEST->{View});

    print Chapix::Com::header_out();
    print Chapix::Layout::print( Chapix::Pages::View::display_page() );
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;
#    if(defined $_REQUEST->{_submitted_user}){
#    }
}

1;
