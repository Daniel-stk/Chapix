package Chapix::Admin::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);
use JSON::XS;

use Chapix::Conf;
use Chapix::Com;
use Chapix::Admin::View;
use Chapix::Mail::Controller;

# Language
use Chapix::Admin::L10N;
my $lh = Chapix::Admin::L10N->get_handle($sess{user_language}) || die "Language?";
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
    	Chapix::Com::http_redirect('/Xaa/Login');
    }

    # init app ENV
    $self->_init();
    
    return $self;
}

sub _init {
    my $self = shift;
}

sub actions {
    my $self = shift;
}

sub view {
    my $self = shift;
    print Chapix::Com::header_out();
    
    if($_REQUEST->{View} eq ''){
        print Chapix::Layout::print( Chapix::Admin::View::display_home() );
    }else{
        msg_add('warning',loc('Not Found'));
        print Chapix::Admin::View::default();
    }
}

1;
