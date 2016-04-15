package Chapix::Notifications::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);

use Chapix::Conf;
use Chapix::Com;

use Chapix::Mail::Controller;

use Chapix::Notifications::API;
use Chapix::Notifications::Actions;
use Chapix::Notifications::View;

# Language
use Chapix::Notifications::L10N;
my $lh = Chapix::Notifications::L10N->get_handle($sess{user_language}) || die "Language?";
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
    	Chapix::Com::http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Login');
    }

    # init app ENV
    $self->_init();
    
    return $self;
}

sub _init {
    my $self = shift;
    $self->{main_db} = $conf->{Xaa}->{DB};
    # $conf->{Domain} = $dbh->selectrow_hashref(
    #     "SELECT d.domain_id, d.name, d.folder, d.database, d.country_id, d.language, d.time_zone FROM $self->{main_db}.xaa_domains d WHERE folder = ?",{},
    #     $_REQUEST->{Domain});
}


# API
sub api {
        my $JSON = {
        error   => '',
        success => '',
        msg     => ''
    };

    if ($_REQUEST->{_submitted}){
        $JSON = Chapix::Notifications::API::get_notification();
    }else{
        $JSON->{error} = 'Not implemented';
        $JSON->{redirect} = '';
        $JSON->{msg} = msg_get();
    }

    print Chapix::Com::header_out('application/json');
    print JSON::XS->new->encode($JSON);
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;
    my $results = {};
    
    if($_REQUEST->{_view} eq 'Notification'){
       $results = Chapix::Notifications::Actions::set_view_and_redirect();
       process_results($results);
       return;
    }
}

sub process_results {
    my $results = shift;
    http_redirect($results->{redirect}) if($results->{redirect});
}

# Main display function, this function prints the required view.
sub view {
    my $self = shift;

    print Chapix::Com::header_out();
    
    if($_REQUEST->{View} eq ''){
        print Chapix::Layout::print( Chapix::Notifications::View::display_home() );
    }else{
        msg_add('warning',loc('Not Found'));
        print Chapix::Notifications::View::default();
    }
}


1;
