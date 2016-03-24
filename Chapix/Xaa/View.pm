package Chapix::Xaa::View;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;
use CGI::FormBuilder;

use Chapix::Conf;
use Chapix::List;
use Chapix::Com;
use Chapix::Layout;

# Language
use Chapix::Xaa::L10N;
my $lh = Chapix::Xaa::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub default {
    msg_add('warning',loc('Not implemented'));
    return Chapix::Layout::print(msg_print());
}

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

sub display_home {
    my $HTML = "";
    my $template = Template->new();
    $conf->{Page}->{ShowSettings} = '1';
    set_toolbar(
        #['Xaa/Subscription','Contratar Marketero','grey-text','favorite'],
	);
    
    my $vars = {
        REQUEST => $_REQUEST,
        Domain  => $conf->{Domain},
        conf => $conf,
        sess => \%sess,
	msg  => msg_print(),
        loc => \&loc,
    };
    $template->process("Chapix/Xaa/tmpl/home.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub display_subscription_details {
    if($conf->{Domain}->{subscription}){

    }else{
	my $HTML = "";

	my $services = $dbh->selectall_arrayref("SELECT * FROM xaa.xaa_services ORDER BY service_id",{Slice=>{}});

	my $template = Template->new();
	my $vars = {
	    REQUEST => $_REQUEST,
	    Domain  => $conf->{Domain},
	    conf => $conf,
	    sess => \%sess,
	    msg  => msg_print(),
	    loc => \&loc,
	    services => $services,
	};

	$template->process("Chapix/Xaa/tmpl/subscription-create.html", $vars,\$HTML) or $HTML = $template->error();
	return $HTML;
    }
}

sub set_toolbar {
    my @actions = @_;
    my $HTML = '';
    
    foreach my $action (@actions){
	my $btn = '<li>';
	my ($script, $label, $class, $icon) = @$action;
	
	if($script !~ /^\//){
	    $script = '/'.$_REQUEST->{Domain}.'/' . $script;
	}
	
	$class = 'waves-effect waves-light ' if(!$class);
	my $id = '';

	if ($label) {
	    $class .= ' tooltipped ';
	    
	    $id = loc($label);
	    $id =~ s/\s/_/g;
	    $id = lc($id).'_action';
	}
	
	$btn .= ' <a id="'.$id.'" href="'.$script.'" class="'.$class.'" data-position="bottom" data-delay="50" data-tooltip="'.$label.'">';
	
	if($icon){
	    $btn .= '<i class="material-icons">'.$icon.'</i> ';
	}
	
	# $btn .= $label;
	$btn .= '</a>';
	$btn .= '</li>';
	$HTML .= $btn;
    }
    if($HTML){
	$HTML = '<ul>' . $HTML . '</ul>';
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


sub display_login {
    my @submit = (loc("Login"));

    my $form = CGI::FormBuilder->new(
        name     => 'login',
        method   => 'post',
        fields   => [qw/controller email password/],
        action   => '/Xaa/Xaa',
        submit   => \@submit,
        materialize => '1',
    );

    $form->field(name => 'email', label=> loc('Email'), comment=>'<i class="icon-envelope"></i>', type=>'email',
		 maxlength=>"100", required=>"1", class=>"", jsmessage => loc('Please enter your email'));

    $form->field(name => 'password', label=> loc('Password'), class=>"",maxlength=>"100", required=>"1",value=>"",
		 override=>1,jsmessage => loc('Please enter your password'), type=>"password", comment=>'<i class="icon-lock"></i>');

    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Xaa/tmpl/login-form.html',
	    type => 'TT2',
	    variable => 'form',
	    data => {
    		conf  => $conf,
        	loc => \&loc,
    		msg   => msg_print(),
            buttons => '<a href="/Xaa/PasswordReset" class="right"><small>¿Olvidaste tu contraseña?</small></a>',
	    },
	},
    );
    return $HTML;
}

sub display_password_reset {
    my @submit = (loc("Next"));

    my $form = CGI::FormBuilder->new(
        name     => 'password_reset',
        method   => 'post',
        fields   => [qw/controller email/],
        action   => '/Xaa/PasswordReset',
        submit   => \@submit,
        materialize => '1',
    );

    $form->field(name => 'email', label=> loc('Email'), comment=>'<i class="icon-envelope"></i>', type=>'email',
		 maxlength=>"100", required=>"1", class=>"", jsmessage => loc('Please enter your email'));
    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Xaa/tmpl/password-reset-form.html',
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

sub display_your_account {
    my $HTML = "";
    my $template = Template->new();
    set_back_btn('','Inicio');
    $conf->{Page}->{ShowSettings} = 'true';

    my $vars = {
        REQUEST => $_REQUEST,
        conf => $conf,
        sess => \%sess,
     	msg  => msg_print(),
        loc => \&loc,
    };
    $template->process("Chapix/Xaa/tmpl/your-account.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub display_settings {
    my $HTML = "";
    my $template = Template->new();
    set_back_btn('','Inicio');
    $conf->{Page}->{ShowSettings} = 'true';

    my $vars = {
        REQUEST => $_REQUEST,
        conf => $conf,
        sess => \%sess,
     	msg  => msg_print(),
        loc => \&loc,
    };
    $template->process("Chapix/Xaa/tmpl/settings.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub display_users_list {
    $conf->{Page}->{Title} = loc('Users');
    set_back_btn('Xaa/Settings',loc('Settings'));
    set_add_btn('Xaa/User',loc('Add user'));
    set_search_action();
    set_toolbar(['Xaa/User','',loc('Add user'),'add','waves-effect waves-light add']);

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
            location => "/".$_REQUEST->{Domain}."/Xaa/Users",
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

sub display_password_form {
    $conf->{Page}->{Title} = loc('Change your password');
    set_back_btn('Xaa/YourAccount',loc('Your account'));

  $conf->{Page}->{ShowSettings} = 'true';

    my @submit = (loc('Save'));
    my $params = {};
    my $form = CGI::FormBuilder->new(
        name     => 'change_password',
        action   => '/'.$_REQUEST->{Domain} . '/Xaa/ChangePassword',
        method   => 'post',
        fields   => [qw/current_password new_password new_password_repeat/],
        submit   => \@submit,
        values   => $params,
        materialize => 1,
    );
    $form->field(name => 'current_password', label=> loc("Current password"), maxlength=>"45", required=>1, type=>'password', group=>loc('Current'));
    $form->field(name => 'new_password', label=> loc("New password"), maxlength=>"45", required=>1, type=>'password', group=> loc('New'));
    $form->field(name => 'new_password_repeat', label=> loc("Repeat new password"), maxlength=>"45", required=>1, type=>'password');

    return $form->render(
        template => {
            type => 'TT2',
            engine => {},
            template => 'Chapix/Xaa/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}

sub display_domain_settings {
    $conf->{Page}->{Title} = loc('Business Settigs');
    set_back_btn('Xaa/Settings',loc('Settings'));

  $conf->{Page}->{ShowSettings} = '1';

    my @submit = (loc('Save'));
    my $params = $conf->{Domain};
    my $form = CGI::FormBuilder->new(
        name     => 'domain_settings',
        action   => '/'.$_REQUEST->{Domain} . '/Xaa/DomainSettings',
        method   => 'post',
        fields   => [qw/name time_zone language/],
        submit   => \@submit,
        values   => $params,
        materialize => 1,
    );

    $form->field(name => 'name', label=>loc('Name'), required=>1, validate=>'/[a-zA-Z]{5,}/');
    my %time_zones = Chapix::Com::selectbox_data(
        "SELECT SUBSTR(Name,7) AS id, SUBSTR(Name,7) AS name FROM mysql.time_zone_name tzn WHERE tzn.Name LIKE 'posix%' ORDER BY tzn.Name");# WHERE tzn.Name LIKE 'posix%' AND tzn.Name LIKE '%America%'");
    $form->field(name => 'time_zone', required=>1, label=>loc('Time zone'), options=>$time_zones{values}, type=>'select');

    $form->field(name => 'language', required=>1, label=>loc('Language'), options=>['es_MX','en_US'], type=>'select',
                 labels => {'es_MX'=>'Español', 'en_US'=>'English'});

    return $form->render(
        template => {
            type => 'TT2',
            engine => {},
            template => 'Chapix/Xaa/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}


sub display_edit_account_form {
    $conf->{Page}->{Title} = loc('Edit your settings');
    set_back_btn('Xaa/YourAccount',loc('Your account'));

    my @submit = (loc('Save'));

    my $params = {
        name => $sess{user_name},
        time_zone => $sess{user_time_zone},
        language  => $sess{user_language},
    };

    my $form = CGI::FormBuilder->new(
        name     => 'edit_account',
        action   => '/'.$_REQUEST->{Domain} . '/Xaa/EditAccount',
        method   => 'post',
        fields   => [qw/name time_zone language/],
        submit   => \@submit,
        values   => $params,
        materialize => 1,
    );

    $form->field(name => 'name', required=>1, label=>loc('Name'));

    my %time_zones = Chapix::Com::selectbox_data("SELECT SUBSTR(Name,7) AS id, SUBSTR(Name,7) AS name FROM mysql.time_zone_name tzn WHERE tzn.Name LIKE 'posix%'");

    $form->field(name => 'time_zone', required=>1, label=> loc('Time zone'), options=>$time_zones{values}, type=>'select');

    $form->field(name => 'language', required=>1, label=> loc('Language'), options=>['es_MX','en_US'], type=>'select',
		 labels => {'es_MX'=>'Español', 'en_US'=>'English'});

    return $form->render(
        template => {
            type => 'TT2',
            engine => {},
            template => 'Chapix/Xaa/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}

sub display_user_form {
    my @submit = (loc("Save"),loc('Resset Password'), loc('Delete'));
    my $params = {};
    $conf->{Page}->{Title} = loc('User');
    set_back_btn('Xaa/Users',loc('Users'));

    if($_REQUEST->{user_id}){
        $params = $dbh->selectrow_hashref(
            "SELECT u.user_id, u.name, u.email, u.time_zone, u.language, ud.active " .
                "FROM $conf->{Xaa}->{DB}.xaa_users u " .
                    "INNER JOIN $conf->{Xaa}->{DB}.xaa_users_domains ud ON u.user_id=ud.user_id " .
                        "WHERE ud.user_id=? AND ud.domain_id=?",{},$_REQUEST->{user_id}, $conf->{Domain}->{domain_id});
        if(!$params->{user_id}){
            msg_add('warning',loc('User does not exist'));
            return display_users_list();
        }
    }

    my $form = CGI::FormBuilder->new(
        name     => 'user',
        method   => 'post',
        fields   => [qw/user_id name email time_zone language active/],
	action   => '/'.$_REQUEST->{Domain} . '/Xaa/User',
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
    my %time_zones = Chapix::Com::selectbox_data("SELECT SUBSTR(Name,7) AS id, SUBSTR(Name,7) AS name FROM mysql.time_zone_name tzn WHERE tzn.Name LIKE 'posix%'");
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

sub display_register {
    my @submit = (loc("Register"));

    my $form = CGI::FormBuilder->new(
        name     => 'register',
        method   => 'post',
        fields   => [qw/controller name phone email password/],
    	action   => '/Xaa/Register',
        submit   => \@submit,
        materialize => '1'
	);

    $form->field(name => 'controller', type=>'hidden', label=>'');
    $form->field(name => 'name', label=> loc('Name'), class=>"", maxlength=>"100", required=>"1",value=>"",
		 jsmessage => loc('Please enter your name'), type=>"text", icon=>'account_circle');
    $form->field(name => 'email', label=> loc('Email'), type=>'email', icon=>'email',
		 maxlength=>"100", required=>"1", class=> "", jsmessage => loc('Please enter your email'));
    $form->field(name => 'phone', label=> loc('Phone'), type=>'text', icon=>'phone',
		 maxlength=>"100", required=>"1", class=> "", jsmessage => loc('Please enter your full phone number'),
         validate=>'/[\d\s\-]{10,15}/');
    $form->field(name => 'password', label=> loc('Password'), type=>'password', icon=>'lock',
		 maxlength=>"30", required=>"1", class=> "", jsmessage => loc('Please use a more complex password. Use numbers, upper and lower case.'),
         validate=>'/^(?:(?=.*[a-z])(?:(?=.*[A-Z])(?=.*[\d\W])|(?=.*\W)(?=.*\d))|(?=.*\W)(?=.*[A-Z])(?=.*\d)).{6,}$/');
    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Xaa/tmpl/register-form.html',
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


sub display_logo_form {
    $conf->{Page}->{Title} = loc('Upload logo');
    $conf->{Page}->{ShowSettings} = '1';
    
    set_back_btn('Xaa/Settings',loc('Your account'));

    my @submit = (loc('Save'));

    Chapix::Com::conf_load("Xaa");

    my $params = {
    	logo => $conf->{Xaa}->{Logo}
    };

    my $form = CGI::FormBuilder->new(
        name     => 'upload_logo',
        action   => '/'.$_REQUEST->{Domain} . '/Xaa/EditLogo',
        method   => 'post',
        fields   => [qw/logo/],
        submit   => \@submit,
        values   => $params,
        materialize => 1,
	);

    $form->field(name => 'logo', label=> loc("Logo"), required=>1, type=>'file');

    if($params->{logo}){
    	my $img = CGI::img({-src=>"/data/".$_REQUEST->{Domain}.'/img/site/'.$params->{logo}, -class=>'responsive-img'});
    	$form->field(name=>'logo', comment=> $img);
    }
    return $form->render(
        template => {
            type => 'TT2',
            engine => {},
            template => 'Chapix/Xaa/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}

sub display_password_reset_sent {
    my $HTML = "";
    my $template = Template->new();
    my $vars = {
        REQUEST => $_REQUEST,
        conf => $conf,
        sess => \%sess,
     	msg  => msg_print(),
        loc => \&loc,
    };
    $template->process("Chapix/Xaa/tmpl/password-reset-sent.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub display_password_reset_success {
    my $HTML = "";
    my $template = Template->new();
    my $vars = {
        REQUEST => $_REQUEST,
        conf => $conf,
        sess => \%sess,
     	msg  => msg_print(),
        loc => \&loc,
    };
    $template->process("Chapix/Xaa/tmpl/password-reset-success.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub display_password_reset_form {
    my @submit = (loc("Guardar"));
    $conf->{Page}->{Title} = 'Restablece tu contraseña';
    $conf->{Page}->{Help}  = 'Las contraseñas fuertes incluyen números, letras mayúsculas, letras minúsculas y signos de puntuación.';

    my $form = CGI::FormBuilder->new(
        name     => 'password_reset_check',
        method   => 'post',
        fields   => [qw/key email password password_confirm/],
        action   => '/Xaa/PasswordResetCheck',
        submit   => \@submit,
        materialize => '1',
    );

    $form->field(name => 'key', type=>'hidden');
    $form->field(name => 'email', label=> loc('Email'), comment=>'<i class="icon-envelope"></i>', type=>'email',
        maxlength=>"100", required=>"1", class=>"", jsmessage => loc('Please enter your email'), readonly=>1);
    $form->field(name => 'password', type=>'password', value=>'', label=>loc('Nueva Contraseña'), required=>1,
                 jsmessage => loc('Please use a more complex password. Use numbers, upper and lower case.'),
                 validate=>'/^(?:(?=.*[a-z])(?:(?=.*[A-Z])(?=.*[\d\W])|(?=.*\W)(?=.*\d))|(?=.*\W)(?=.*[A-Z])(?=.*\d)).{6,}$/');
    $form->field(name => 'password_confirm', type=>'password', value=>'', label=>loc('Confirmar Contraseña'), required=>1,
                 jsmessage => loc('Please use a more complex password. Use numbers, upper and lower case.'),
                 validate=>'/^(?:(?=.*[a-z])(?:(?=.*[A-Z])(?=.*[\d\W])|(?=.*\W)(?=.*\d))|(?=.*\W)(?=.*[A-Z])(?=.*\d)).{6,}$/');

    my $HTML = $form->render(
        template => {
            template => 'Chapix/Xaa/tmpl/pub-form.html',
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
