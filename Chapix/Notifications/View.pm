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
    
    set_back_btn('EmailMkt/Settings',loc('Settings'));
    set_add_btn('EmailMkt/Place',loc('Add place'));    
    set_search_action();
    set_toolbar(['EmailMkt/Place','',loc('Add place'),'add','waves-effect waves-light add']);
    
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

# View functions
sub display_settings {
    $conf->{Page}->{Title} = loc('Settings');
    set_back_btn('Notifications',loc('Dashboard'));

    my $HTML = "";
    my $template = Template->new();
    my $vars = {
        REQUEST => $_REQUEST,
        conf => $conf,
        sess => \%sess,
     	msg  => msg_print(),
        loc => \&loc,
    };
    $template->process("Chapix/Notifications/tmpl/settings.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}


# Places
sub display_places_list {
    $conf->{Page}->{Title} = loc('Places');
    set_back_btn('EmailMkt/Settings',loc('Settings'));
    set_add_btn('EmailMkt/Place',loc('Add place'));
    set_search_action();
    set_toolbar(['EmailMkt/Place','',loc('Add place'),'add','waves-effect waves-light add']);
    
    my $where = " p.active=1 ";
    my @params;
    if($_REQUEST->{q}){
        $where .=' AND (p.place LIKE ? OR p.address LIKE ? OR p.city LIKE ? OR p.state LIKE ?) ';
        push(@params,'%'.$_REQUEST->{q}.'%','%'.$_REQUEST->{q}.'%','%'.$_REQUEST->{q}.'%','%'.$_REQUEST->{q}.'%');
    }
    my $list = Chapix::List->new(
        dbh => $dbh,
        pagination => 0,
        sql => {
            select => "p.place_id, p.place, p.city, p.state",
            from =>"places p",
            order_by => "",
            where => $where,
            params => \@params,
        },
        link => {
            key => "place_id",
            hidde_key_col => 1,
            location => "/".$_REQUEST->{Domain}."/EmailMkt/Places",
            transit_params => {'q' => $_REQUEST->{q}},
        },
    );

    $list->set_label('place',loc('Place'));
    $list->set_label('city',loc('City'));
    $list->set_label('State',loc('State'));
    
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

sub display_place_form {
    my @submit = (loc("Save"));
    my $params = {};
    $conf->{Page}->{Title} = loc('Place');
    set_back_btn('EmailMkt/Places',loc('Places'));
    
    if($_REQUEST->{place_id}){
        $params = $dbh->selectrow_hashref(
            "SELECT * FROM places WHERE place_id=?",{},$_REQUEST->{place_id});
        push(@submit, loc('Delete'));
    }else{
        $params = {
            time_zone => $conf->{Domain}->{time_zone},
        };
    }
    
    my $form = CGI::FormBuilder->new(
        name     => 'place',
        method   => 'post',
        fields   => [qw/place_id place time_zone place_type_id manager_id address city state/],
    	action   => '/'.$_REQUEST->{Domain} . '/Notifications/Place',
        submit   => \@submit,
        values   => $params,
        materialize => '1',
    );

    $form->field(name => 'place_id', type=>'hidden');
    $form->field(name => 'place', label=>loc('Place'), required=>1, validate=>'/[a-zA-Z]{5,}/');
    my %time_zones = Chapix::Com::selectbox_data(
        "SELECT SUBSTR(Name,7) AS id, SUBSTR(Name,7) AS name FROM mysql.time_zone_name tzn WHERE tzn.Name LIKE 'posix%' and tzn.Name LIKE '%America%'");
    $form->field(name => 'time_zone', required=>1, label=>loc('Time zone'), options=>$time_zones{values}, type=>'select');
    my %types = Chapix::Com::selectbox_data("SELECT place_type_id AS id, place_type FROM places_types ORDER BY 2");
    $form->field(name => 'place_type_id', required=>1, label=>loc('Type'), options=>$types{values}, type=>'select', labels=>$types{labels});
    my %managers = Chapix::Com::selectbox_data(
        "SELECT u.user_id, u.name FROM user_accounts ua " .
            "INNER JOIN  $conf->{Xaa}->{DB}.xaa_users u ON ua.user_id=u.user_id ");
    $form->field(name => 'manager_id', required=>1, label=>loc('Manager'), options=>$managers{values}, type=>'select', labels => $managers{labels});
    $form->field(name => 'address', label=>loc('Address'), required => 1);
    $form->field(name => 'city', label=>loc('City'), required=>1 );
    $form->field(name => 'state', label=>loc('State'), required=>1 );
        
    $form->stylesheet('1');

    # Location button
    my $buttons = '';
    if($params->{place_id}){
        $buttons = CGI::a({-href=>'/'.$_REQUEST->{Domain} . '/EmailMkt/PlaceLocation?place_id='.$params->{place_id}, -class=>'btn btn-primary'},
                          loc('Set location'));
    }
    
    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Xaa/tmpl/form.html',
	    type => 'TT2',
	    variable => 'form',
	    data => {
                buttons => $buttons,
    		conf  => $conf,
                loc => \&loc,
    		msg   => msg_print(),
	    },
	},
    );
    return $HTML;
}

sub display_place_location_form {
    $conf->{Page}->{Title} = loc('Place Location');
    set_back_btn('EmailMkt/Place?place_id='.$_REQUEST->{place_id},loc('Place'));
    # set_toolbar(['EmailMkt/Place','',loc('Add place'),'add','waves-effect waves-light add']);
    my $place = $dbh->selectrow_hashref(
            "SELECT * FROM places WHERE place_id=?",{},$_REQUEST->{place_id});
    
    my $HTML = "";
    my $vars = {
        place => $place,
        conf => $conf,
        loc => \&loc,
        sess => \%sess,
    	msg  => msg_print(),
    };
    my $Template = Template->new();
    $Template->process("Chapix/EmailMkt/tmpl/place-location.html", $vars,\$HTML) or $HTML = $Template->error();
    return $HTML;
}



# Sections
sub display_sections_list {
    $conf->{Page}->{Title} = loc('Sections');
    set_back_btn('EmailMkt/Settings',loc('Settings'));
    set_add_btn('EmailMkt/Section',loc('Add section'));
    set_search_action();
    set_toolbar(['EmailMkt/Section','',loc('Add section'),'add','waves-effect waves-light add']);
    
    my $where = "";
    my @params;
    if($_REQUEST->{q}){
        $where .=' (s.section LIKE ? OR u.name LIKE ?) ';
        push(@params,'%'.$_REQUEST->{q}.'%','%'.$_REQUEST->{q}.'%');
    }
    my $list = Chapix::List->new(
        dbh => $dbh,
        pagination => 0,
        sql => {
            select => "s.section_id, s.section, u.name AS manager ",
            from =>"sections s ".
                "LEFT JOIN $conf->{Xaa}->{DB}.xaa_users u ON s.manager_id=u.user_id ",
            order_by => "",
            where => $where,
            params => \@params,
        },
        link => {
            key => "section_id",
            hidde_key_col => 1,
            location => "/".$_REQUEST->{Domain}."/EmailMkt/Sections",
            transit_params => {'q' => $_REQUEST->{q}},
        },
    );

    $list->set_label('section',loc('Section'));
    $list->set_label('manager',loc('Manager'));
    
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

sub display_section_form {
    my @submit = (loc("Save"));
    my $params = {};
    $conf->{Page}->{Title} = loc('Section');
    set_back_btn('EmailMkt/Sections',loc('Sections'));
    
    if($_REQUEST->{section_id}){
        $params = $dbh->selectrow_hashref(
            "SELECT * FROM sections WHERE section_id=?",{},$_REQUEST->{section_id});
        push(@submit, loc('Delete'));
    }else{
        $params = {
        };
    }
    
    my $form = CGI::FormBuilder->new(
        name     => 'section',
        method   => 'post',
        fields   => [qw/section_id section manager_id/],
    	action   => '/'.$_REQUEST->{Domain} . '/EmailMkt/Section',
        submit   => \@submit,
        values   => $params,
        materialize => '1',
    );

    $form->field(name => 'section_id', type=>'hidden');
    $form->field(name => 'section', label=>loc('Section'), required=>1, validate=>'/[a-zA-Z]{2,}/');
    my %managers = Chapix::Com::selectbox_data(
        "SELECT u.user_id, u.name FROM user_accounts ua " .
            "INNER JOIN  $conf->{Xaa}->{DB}.xaa_users u ON ua.user_id=u.user_id ");
    $form->field(name => 'manager_id', required=>1, label=>loc('Manager'), options=>$managers{values}, type=>'select', labels => $managers{labels});
    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Xaa/tmpl/form.html',
	    type => 'TT2',
	    variable => 'form',
	    data => {
    		conf  => $conf,
            loc => \&loc,
    		msg   => msg_print(),
	    },
	},
    );
    return $HTML;
}

# Points
sub display_points_list {
    $conf->{Page}->{Title} = loc('Check Points');
    set_back_btn('EmailMkt/Settings',loc('Settings'));
    set_add_btn('EmailMkt/Point',loc('Add point'));
    set_search_action();
    set_toolbar(['EmailMkt/Point','',loc('Add point'),'add','waves-effect waves-light add']);
    
    my $where = "";
    my @params;
    if($_REQUEST->{q}){
        $where .=' (s.point LIKE ? OR u.name LIKE ?) ';
        push(@params,'%'.$_REQUEST->{q}.'%','%'.$_REQUEST->{q}.'%');
    }
    my $list = Chapix::List->new(
        dbh => $dbh,
        pagination => 0,
        sql => {
            select => "cp.point_id, cp.point, s.section ",
            from =>"check_points cp ".
                "LEFT JOIN sections s ON cp.section_id=s.section_id ",
            order_by => "",
            where => $where,
            params => \@params,
        },
        link => {
            key => "point_id",
            hidde_key_col => 1,
            location => "/".$_REQUEST->{Domain}."/EmailMkt/Points",
            transit_params => {'q' => $_REQUEST->{q}},
        },
    );

    $list->set_label('point',loc('Point'));
    $list->set_label('manager',loc('Manager'));
    
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

sub display_point_form {
    my @submit = (loc("Save"));
    my $params = {};
    $conf->{Page}->{Title} = loc('Check Point');
    set_back_btn('EmailMkt/Points',loc('Points'));
    
    if($_REQUEST->{point_id}){
        $params = $dbh->selectrow_hashref(
            "SELECT * FROM check_points WHERE point_id=?",{},$_REQUEST->{point_id});
        push(@submit, loc('Delete'));
    }else{
        $params = {
        };
    }
    
    my $form = CGI::FormBuilder->new(
        name     => 'point',
        method   => 'post',
        fields   => [qw/point_id point answer_group_id section_id/],
    	action   => '/'.$_REQUEST->{Domain} . '/EmailMkt/Point',
        submit   => \@submit,
        values   => $params,
        materialize => '1',
    );

    $form->field(name => 'point_id', type=>'hidden');
    $form->field(name => 'point', label=>loc('Point'), required=>1, validate=>'/[a-zA-Z]{5,}/');
    my %sections = Chapix::Com::selectbox_data(
        "SELECT s.section_id, s.section FROM sections s");
    $form->field(name => 'section_id', required=>1, label=>loc('Section'), options=>$sections{values}, type=>'select', labels => $sections{labels});
    my %answers_groups = Chapix::Com::selectbox_data(
        "SELECT answer_group_id, answer_group FROM answers_groups ORDER BY 2");
    $form->field(name => 'answer_group_id', required=>1, label=>loc('Answers'), options=>$answers_groups{values}, type=>'select', labels => $answers_groups{labels});
    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Xaa/tmpl/form.html',
	    type => 'TT2',
	    variable => 'form',
	    data => {
    		conf  => $conf,
            loc => \&loc,
    		msg   => msg_print(),
	    },
	},
    );
    return $HTML;
}

# Formats
sub display_formats_list {
    $conf->{Page}->{Title} = loc('Check Formats');
    set_back_btn('EmailMkt/Settings',loc('Settings'));
    set_add_btn('EmailMkt/Format',loc('Add format'));
    set_search_action();
    set_toolbar(['EmailMkt/Format','',loc('Add format'),'add','waves-effect waves-light add']);
    
    my $where = "";
    my @params;
    if($_REQUEST->{q}){
        $where .=' (s.format LIKE ? OR u.name LIKE ?) ';
        push(@params,'%'.$_REQUEST->{q}.'%','%'.$_REQUEST->{q}.'%');
    }
    my $list = Chapix::List->new(
        dbh => $dbh,
        pagination => 0,
        sql => {
            select => "f.format_id, f.name ",
            from =>"formats f ",
            order_by => "",
            where => $where,
            params => \@params,
        },
        link => {
            key => "format_id",
            hidde_key_col => 1,
            location => "/".$_REQUEST->{Domain}."/EmailMkt/Formats",
            transit_params => {'q' => $_REQUEST->{q}},
        },
    );

    $list->set_label('name',loc('Format'));
    
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

sub display_format_form {
    my @submit = (loc("Save"));
    my @fields = ('format_id', 'name');
    my $params = {};
    $conf->{Page}->{Title} = loc('Check Format');
    set_back_btn('EmailMkt/Formats',loc('Formats'));
    
    if($_REQUEST->{format_id}){
        $params = $dbh->selectrow_hashref(
            "SELECT * FROM formats WHERE format_id=?",{},$_REQUEST->{format_id});
        push(@submit, loc('Delete'));
	push(@fields, 'point_id', 'ponderation', 'requires_evidence');
    }else{
        $params = {
        };
    }
    
    my $form = CGI::FormBuilder->new(
        name     => 'format',
        method   => 'post',
        fields   => \@fields,
    	action   => '/'.$_REQUEST->{Domain} . '/EmailMkt/Format',
        submit   => \@submit,
        values   => $params,
        materialize => '1',
    );

    $form->field(name => 'format_id', type=>'hidden');
    $form->field(name => 'name', label=>loc('Format'), required=>1, validate=>'/[a-zA-Z]{3,}/');
    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/EmailMkt/tmpl/format-form.html',
	    type => 'TT2',
	    variable => 'form',
	    data => {
    		conf  => $conf,
            loc => \&loc,
    		msg   => msg_print(),
	    },
	},
    );
    return $HTML;
}


# Users
sub display_users_list {
    $conf->{Page}->{Title} = loc('Users');
    set_back_btn('EmailMkt/Settings',loc('Settings'));
    set_add_btn('EmailMkt/User',loc('Add user'));
    set_search_action();
    set_toolbar(['EmailMkt/User','',loc('Add user'),'add','waves-effect waves-light add']);
    
    my $where = "ud.domain_id=? AND ud.active=1 ";
    my @params;
    push(@params,$conf->{Domain}->{domain_id});
    if($_REQUEST->{q}){
     	$where .=' AND (u.name LIKE ? OR u.email LIKE ?) ';
     	push(@params,'%'.$_REQUEST->{q}.'%','%'.$_REQUEST->{q}.'%');
    }
    my $list = Chapix::List->new(
        dbh => $dbh,
        pagination => 0,
        sql => {
            select => "ud.user_id, u.name, u.email, ud.added_on, IF(ud.active=1,'".loc('Yes')."','".loc('No')."') AS active",
            from =>"$conf->{Xaa}->{DB}.xaa_users_domains ud " .
                "INNER JOIN $conf->{Xaa}->{DB}.xaa_users u ON u.user_id=ud.user_id",
            order_by => "",
            where => $where,
            params => \@params,
        },
        link => {
            key => "user_id",
            hidde_key_col => 1,
            location => "/".$_REQUEST->{Domain}."/EmailMkt/Users",
            transit_params => {'controller'=>'Blocks','view'=>'edit','q' => $_REQUEST->{q}},
        },
    );

    $list->set_label('name',loc('Name'));
    $list->set_label('email',loc('Correo'));
    $list->set_label('added_on',loc('Added on'));
    $list->set_label('active',loc('Active'));
    
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

sub display_user_form {
    my @submit = (loc("Save"),loc('Resset Password'), loc('Delete'));
    my $params = {};
    $conf->{Page}->{Title} = loc('User');
    set_back_btn('EmailMkt/Users',loc('Users'));
    
    if($_REQUEST->{user_id}){
        $params = $dbh->selectrow_hashref(
            "SELECT u.user_id, u.name, u.email, u.time_zone, u.language, ud.active, ua.group_id " .
                "FROM $conf->{Xaa}->{DB}.xaa_users u " .
                    "INNER JOIN $conf->{Xaa}->{DB}.xaa_users_domains ud ON u.user_id=ud.user_id " .
                        "INNER JOIN user_accounts ua ON ua.user_id=u.user_id " .
                            "WHERE ud.user_id=? AND ud.domain_id=?",{},$_REQUEST->{user_id}, $conf->{Domain}->{domain_id});
        if(!$params->{user_id}){
            msg_add('warning',loc('User does not exist'));
            return display_users_list();
        }
    }else{
        $params = {
            time_zone => 'America/Mexico_City',
            language  => 'es_mx',
            group_id  => 60,
        };
    }
    
    my $form = CGI::FormBuilder->new(
        name     => 'user',
        method   => 'post',
        fields   => [qw/user_id name email group_id time_zone language active/],
	action   => '/'.$_REQUEST->{Domain} . '/Notifications/User',
        submit   => \@submit,
        values   => $params,
        materialize => '1',
    );

    $form->field(name => 'user_id', type=>'hidden');
    $form->field(name => 'name', label=>loc('Name'), required=>1, validate=>'/[a-zA-Z]{5,}/');
    if($params->{user_id}){
        $form->field(name => 'email', label=> loc('Email'), disabled=>1,class=> "span12", jsmessage => loc('Please enter your email'));
        $form->field(name => 'active', type=>'checkbox', label=> '', class=>'filled-in', options=>[1], labels=>{1=>loc('Active')});
    }else{
        $form->field(name => 'email', label=> loc('Email'), comment=>'<i class="icon-envelope"></i>',type=>'email', maxlength=>"100", required=>"1",
                     class=> "span12", jsmessage => loc('Please enter your email'), validate=>'EMAIL');
        $form->field(name => 'active', type=>'hidden');
    }
    my %group = Chapix::Com::selectbox_data("SELECT group_id, group_name FROM user_groups ORDER BY 2");
    $form->field(name => 'group_id', required=>1, label=>loc('Group'), options=>$group{values}, labels=>$group{labels},type=>'select');
    
    my %time_zones = Chapix::Com::selectbox_data("SELECT SUBSTR(Name,7) AS id, SUBSTR(Name,7) AS name FROM mysql.time_zone_name tzn WHERE tzn.Name LIKE 'posix%' AND tzn.Name LIKE '%America%'");
    $form->field(name => 'time_zone', required=>1, label=>loc('Time zone'), options=>$time_zones{values}, type=>'select');
    
    $form->field(name => 'language', required=>1, label=>loc('Language'), options=>['es_MX','en_US'], type=>'select',
                 labels => {'es_MX'=>'Español', 'en_US'=>'English'});
    
    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Xaa/tmpl/form.html',
	    type => 'TT2',
	    variable => 'form',
	    data => {
    		conf  => $conf,
		loc => \&loc,
    		msg   => msg_print(),
	    },
	},
    );
    return $HTML;
}


1;
