package Chapix::Notifications::View;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;
use CGI::FormBuilder;
use Digest::SHA qw(sha384_hex);

use Chapix::Conf;
use Chapix::List;
use Chapix::Com;
use Chapix::Layout;

# Language
use Chapix::Notifications::L10N;
my $lh = Chapix::Notifications::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub default {
    return Chapix::Layout::print(msg_print());
}

# Common functions
 sub set_path_route {
     my @items = @_;
     my $route = '';
     foreach my $item(@items){
         my $name = $item->[0];
         $name = CGI::a({-href=>$item->[1]},$name) if($item->[1]);
         $route .= ' <li>&raquo; '.$name.'</li> ';
     }
     $conf->{Page}->{Path} = '<ul class="path"><li><a href="/'.$_REQUEST->{Domain}.'">Home</a><span class="divider"><i class="glyphicon glyphicon-menu-right"></i></span></li>' .
         $route.'</ul>';
 }

sub set_toolbar {
    my @actions = @_;
    my $HTML = '';
    
    foreach my $action (@actions){
        my $btn = '';
     	my ($script, $label, $alt, $icon, $class, $type) = @$action;
        if($script !~ /^\//){
            $script = '/'.$_REQUEST->{Domain}.'/' . $script;
        }
        $class = 'waves-effect waves-light ' if(!$class);
     	if($script eq 'index.pl'){
     	    $alt = 'Go back';
            #$label = 'Go back';
     	    $icon  = 'arrow_back';
     	}
     	$btn .= ' <a href="'.$script.'" class="'.$class.'" alt="'.$alt.'" title="'.$alt.'" >';
     	if($icon){
     	    $btn .= '<i class="material-icons">'.$icon.'</i> ';
     	}
     	$btn .= $label;
        $btn .= '</a>';
        $HTML .= $btn;			
    }   
    $conf->{Page}->{Toolbar} .= $HTML;
}

sub set_add_btn {
    my $script  = shift;
    my $label   = shift || loc('Add');
    my @actions = @_;
    my $HTML = '';
    
    if($script !~ /^\//){
        $script = '/'.$_REQUEST->{Domain}.'/' . $script;
    }
    my $class = 'waves-effect waves-light ';
    my $icon  = 'keyboard_backspace';

    my $btn = '<div class="fixed-action-btn" style="bottom: 45px; right: 24px;">' .
        '<a href="'.$script.'" alt="'.$label.'" title="'.$label.'"  class="btn-floating btn-large waves-effect waves-light red"><i class="material-icons">add</i></a></div>';
    $conf->{Page}->{AddBtn} = $btn;
}


sub set_back_btn {
    my $script  = shift;
    my $label   = shift || loc('Go back');
    my @actions = @_;
    my $HTML = '';
    
    if($script !~ /^\//){
        $script = '/'.$_REQUEST->{Domain}.'/' . $script;
    }
    my $class = 'waves-effect waves-light ';
    my $icon  = 'keyboard_backspace';

    my $btn = ' <a href="'.$script.'" class="'.$class.'" alt="'.$label.'" title="'.$label.'" >';
    $btn   .= '<i class="material-icons">'.$icon.'</i>';
    $btn   .= '</a>';
    $conf->{Page}->{BackBtn} = $btn;
}

sub set_search_action {
    my $label   = shift || loc('Search');
    my $class = 'waves-effect waves-dark ';
    my $icon  = 'keyboard_backspace';

    my $btn = ' <a href="javascript:xaaTooggleSearch();" class="'.$class.'" alt="'.$label.'" title="'.$label.'" >';
    $btn   .= '<i class="material-icons">search</i>';
    $btn   .= '</a>';
    $conf->{Page}->{Toolbar} .= $btn;
    
    $conf->{Page}->{Search} = {
        Field => (CGI::textfield({-name=>'q', -id=>'q'})),
        Show => ($_REQUEST->{'q'} || ''),
        Label => loc('Search'),
    };
}

# View functions
sub display_home {
    my $HTML = "";
    my $template = Template->new();
    
    my $vars = {
        REQUEST => $_REQUEST,
        conf => $conf,
        sess => \%sess,
     	msg  => msg_print(),
        loc => \&loc,
        list => display_notification_list(),
    };
    $template->process("Chapix/Notifications/tmpl/home.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

# Notification
sub display_notification_list {
    $conf->{Page}->{Title} = loc('Notifications');
    
    set_back_btn('',loc('Dashboard'));
    set_search_action();
    
    my $where = "";
    my @params;
    if($_REQUEST->{q}){
        $where .=' n.title LIKE ? ';
        push(@params,'%'.$_REQUEST->{q}.'%');
    }

    my $list = Chapix::List->new(
        dbh => $dbh,
        pagination => 0,
        sql => {
            select => "n.notification_id, n.title, n.readed, n.url, '' AS actions ",
            from => "$conf->{Xaa}->{DB}.notifications n",
            order_by => "created_on DESC",
            where => $where,
            params => \@params,
        },
        link => {
            key => "notification_id",
            hidde_key_col => 1,
            # location => "/".$_REQUEST->{Domain}."/Notifications/Notification",
            transit_params => {'q' => $_REQUEST->{q}},
        },
	);
    
    $list->set_label('title',loc('Title'));
    $list->set_label('description',loc('Description'));
    $list->set_label('readed',loc('Readed'));
    $list->set_label('actions',' ');
    
    $list->hidde_column('url');

    $list->get_data();
    
    foreach my $row (@{$list->{rs}}) {
	$row->{actions} = '<div class="fixed-btn-wrapper">
          <div class="fixed-action-btn horizontal">
            <a class="btn-floating btn-large red">
              <i class="large material-icons">mode_edit</i>
            </a>
            <ul>
              <li><a onclick="deleteNotification('.$row->{notification_id}.');" href="javascript:void(0);" class="btn-floating red"><i class="material-icons">delete</i></a></li>
              <li><a href="/'.$_REQUEST->{Domain}.'/Notifications?_view=Notification&notification_id='.$row->{notification_id}.'" class="btn-floating green"><i class="material-icons">launch</i></a></li>
            </ul>
          </div>
        </div>';
	
	if($row->{readed}) {
	    $row->{readed} = loc('Yes');
	}else{
	    $row->{readed} = loc('No');
	}	    
    }

    my $HTML = "";
    my $vars = {
    	list => $list->print(),
        conf => $conf,
    	msg  => msg_print(),
    };

    my $Template = Template->new();
    $Template->process("Chapix/Xaa/tmpl/list.html", $vars,\$HTML) or $HTML = $Template->error();
    return $HTML;
}

1;