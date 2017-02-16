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
use Chapix::Admin::Actions;
use Chapix::Mail::Controller;

# Language
use Chapix::Admin::L10N;
my $lh = Chapix::Admin::L10N->get_handle($sess{account_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub new {
    my $class = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;

    # Logged account is required
    if(!$sess{account_id} and $_REQUEST->{View} ne 'Login'){
    	msg_add('warning','To continue, log into your account.');
    	Chapix::Com::http_redirect('/Admin/Login');
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
    my $results = {};

    if(defined $_REQUEST->{_submitted_login}){
        $results = Chapix::Admin::Actions::login();
        process_results($results);
        return;
    }elsif($_REQUEST->{_submitted_admin}){
        $results = Chapix::Admin::Actions::save_admin();
        process_results($results);
        return;}
}

sub view {
    my $self = shift;
    print Chapix::Com::header_out();
    
    if($_REQUEST->{View} eq 'Login'){
        print Chapix::Layout::print( Chapix::Admin::View::display_login(),{},'layout-clear.html');
    }elsif($_REQUEST->{View} eq 'Admins'){
        if ($_REQUEST->{account_id} || $_REQUEST->{_mode} eq 'new'){
            print Chapix::Layout::print( Chapix::Admin::View::display_admin_form());
        }else{
            print Chapix::Layout::print( Chapix::Admin::View::display_admins());
        }
    }else{
        print Chapix::Layout::print( Chapix::Admin::View::display_home());
    }
}

sub process_results {
    my $results = shift;
    http_redirect($results->{redirect}) if($results->{redirect});
}

1;
