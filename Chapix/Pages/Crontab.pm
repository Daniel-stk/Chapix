package Chapix::Pages::Crontab;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::Com;

sub new {
    my $class = shift;
    my $DEBUG = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;
    $self->{DEBUG} = $DEBUG || 0;
    # Init app ENV
    $self->_init();

    return $self;
}

# Initialize ENV
sub _init {
    my $self = shift;
    $self->{main_db} = $conf->{Xaa}->{DB};
}

sub run_minute {
    my $self = shift;
}

sub run_daily {
    my $self = shift;
}

1;
