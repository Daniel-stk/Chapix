package Chapix::Mail::Admin::Controller;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Admin::Com;
use Chapix::Admin::View;
use Chapix::Mail::Admin::View;

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
    Chapix::Admin::Com::conf_load('Mail');
    print Chapix::Admin::Com::header_out();
    if($Q->param('view') eq 'edit-settings'){
        print Chapix::Admin::Layout::print( Chapix::Mail::Admin::View::display_settings_form() );
    }else{
        print Chapix::Admin::Layout::print( Chapix::Mail::Admin::View::display_dashboard() );
    }
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;
    if(defined $Q->param('_submitted_settings')){
        $self->save_settings();
    }
}

sub save_settings {
    my $self = shift;
    if($Q->param('view') eq 'edit-settings'){
        eval {
            $dbh->do("UPDATE conf c SET c.value=? WHERE c.module='Mail' AND c.name='Mode'",{},
                     $Q->param('Mode'));
            $dbh->do("UPDATE conf c SET c.value=? WHERE c.module='Mail' AND c.name='Server'",{},
                     $Q->param('Server'));
            $dbh->do("UPDATE conf c SET c.value=? WHERE c.module='Mail' AND c.name='Port'",{},
                     $Q->param('Port'));
            $dbh->do("UPDATE conf c SET c.value=? WHERE c.module='Mail' AND c.name='Secure'",{},
                     $Q->param('Secure'));
            $dbh->do("UPDATE conf c SET c.value=? WHERE c.module='Mail' AND c.name='User'",{},
                     $Q->param('User'));
            if($Q->param('Password') !~ /^\*+$/){
                $dbh->do("UPDATE conf c SET c.value=? WHERE c.module='Mail' AND c.name='Password'",{},
                         $Q->param('Password'));
            }
        };
        if($@){
            msg_add('warning',$@);
        }else{
            msg_add('success','The record were successfully updated.');
            http_redirect('?controller=Mail');
        }
    }
}

1;
