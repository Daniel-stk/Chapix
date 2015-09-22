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
    if($Q->param('view') eq 'edit' or $Q->param('view') eq 'add'){
        print Chapix::Admin::Layout::print( Chapix::Pages::Admin::View::display_form() );        
    }else{
        print Chapix::Admin::Layout::print( Chapix::Pages::Admin::View::display_list() );
    }
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;
    if(defined $Q->param('_submitted_pages')){
        $self->save_data();
    }
}

sub save_data {
    my $self = shift;
    if($Q->param('view') eq 'add'){
        my $id;
        eval {
            $dbh->do("INSERT INTO pages (name, content) VALUES(?,?)",{},
                     $Q->param('name'), $Q->param('content'));
            $id = $dbh->last_insert_id('','','pages','block_id');
        };
        if($@){
            msg_add('warning',$@);
        }else{
            msg_add('success','The record were successfully updated.');
            http_redirect('?controller=Pages&q=&view=edit&block_id='.$id);
        }
    }elsif($Q->param('_submit') eq 'Delete'){
        eval {
            # Delete record
            $dbh->do("DELETE FROM pages WHERE block_id=?",{},
                 $Q->param('block_id'));
        };
        if($@){
            msg_add('danger',$@);
        }else{
            msg_add('success','The record were successfully deleted.');
            http_redirect('?controller=Pages');            
        }
    }else{
        eval {
            # Update record
            $dbh->do("UPDATE pages SET name=?, content=? WHERE block_id=?",{},
                 $Q->param('name'), $Q->param('content'), $Q->param('block_id'));
        };
        if($@){
            msg_add('danger',$@);
        }else{
            msg_add('success','The record were successfully updated.');
            
        }
    }
}

1;
