package Chapix::Pages::Admin::Controller;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Admin::Com;
use Chapix::Admin::View;
use Chapix::Pages::Admin::View;

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
    print Chapix::Admin::Com::header_out();
    if($_REQUEST->{'view'} eq 'edit' or $_REQUEST->{'view'} eq 'add'){
        print Chapix::Admin::Layout::print( Chapix::Pages::Admin::View::display_form() );        
    }else{
        print Chapix::Admin::Layout::print( Chapix::Pages::Admin::View::display_list() );
    }
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    #my $self = shift;
    #if(defined $_REQUEST->{'_submitted_pages'}){
    #    $self->save_data();
    #}
}

sub save_data {
    #my $self = shift;
    #if($_REQUEST->{'view'} eq 'add'){
    #    my $id;
    #    eval {
    #        $dbh->do("INSERT INTO pages (name, content) VALUES(?,?)",{},
    #                 $_REQUEST->{'name'}, $_REQUEST->{'content'});
    #        $id = $dbh->last_insert_id('','','pages','block_id');
    #    };
    #    if($@){
    #        msg_add('warning',$@);
    #    }else{
    #        msg_add('success','The record were successfully updated.');
    #        http_redirect('?controller=Pages&q=&view=edit&block_id='.$id);
    #    }
    #}elsif($_REQUEST->{'_submit'} eq 'Delete'){
    #    eval {
    #        # Delete record
    #        $dbh->do("DELETE FROM pages WHERE block_id=?",{},
    #             $_REQUEST->{'block_id'});
    #    };
    #    if($@){
    #        msg_add('danger',$@);
    #    }else{
    #        msg_add('success','The record were successfully deleted.');
    #        http_redirect('?controller=Pages');            
    #    }
    #}else{
    #    eval {
    #        # Update record
    #        $dbh->do("UPDATE pages SET name=?, content=? WHERE block_id=?",{},
    #             $_REQUEST->{'name'}, $_REQUEST->{'content'}, $_REQUEST->{'block_id'});
    #    };
    #    if($@){
    #        msg_add('danger',$@);
    #    }else{
    #        msg_add('success','The record were successfully updated.');
    #        
    #    }
    #}
}

1;
