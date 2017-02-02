package Chapix::Accounts::View;

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
use Chapix::Accounts::L10N;
my $lh = Chapix::Accounts::L10N->get_handle($sess{user_language}) || die "Language?";
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
    $conf->{Page}->{Path} = '<ul class="path"><li><a href="/">Home</a><span class="divider"><i class="glyphicon glyphicon-menu-right"></i></span></li>' .
	$route.'</ul>';
}

sub display_home {
    my $HTML = "";
    my $template = Template->new();
    $conf->{Page}->{ShowSettings} = '1';

    set_toolbar(
        #['Accounts/Subscription','Contratar Marketero','grey-text','favorite'],
	);
    
    my $vars = {
        REQUEST => $_REQUEST,
        conf => $conf,
        sess => \%sess,
	    msg  => msg_print(),
        loc => \&loc,
    };
    $template->process("Chapix/Accounts/tmpl/home.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub set_toolbar {
    my @actions = @_;
    my $HTML = '';
    
    foreach my $action (@actions){
	my $btn = '<li>';
	my ($script, $label, $class, $icon) = @$action;
	
	if($script !~ /^\//){
	    $script = '/' . $script;
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
    my $label   = shift || loc('Agregar');
    my @actions = @_;
    my $HTML = '';

    if($script !~ /^\//){
        $script = '/' . $script;
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

  # if ($ENV{HTTP_REFERER} =~ /^http(?:s)?:\/\/[$conf->{App}->{URL}][^\/]+(\/.*)$/gm) {
  #     $script = $1;
  # }

  if($script !~ /^\//){
    $script = '/' . $script;
  }

  my $class = 'waves-effect waves-light ';
  my $icon  = 'keyboard_backspace';

  if ($label){
    $class .= ' tooltipped ';
  }

  my $btn = ' <a href="'.$script.'" class="'.$class.'"  data-position="bottom" data-delay="50" data-tooltip="'.$label.'">';
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
    my @submit = (loc("Iniciar sesión"));

    my $form = CGI::FormBuilder->new(
        name     => 'login',
        method   => 'post',
        fields   => [qw/controller email password/],
        action   => '/Accounts/Accounts',
        submit   => \@submit,
        materialize => '1',
    );

    $form->field(name => 'email', label=> loc('Correo Electrónico'), comment=>'<i class="icon-envelope"></i>', type=>'email',
		 maxlength=>"100", required=>"1", class=>"", jsmessage => loc('Escribe tu correo electrónico'));

    $form->field(name => 'password', label=> loc('Contraseña'), class=>"",maxlength=>"100", required=>"1",value=>"",
		 override=>1,jsmessage => loc('Escribe tu contraseña'), type=>"password", comment=>'<i class="icon-lock"></i>');

    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Accounts/tmpl/login-form.html',
	    type => 'TT2',
	    variable => 'form',
	    data => {
    		conf  => $conf,
        	loc => \&loc,
    		msg   => msg_print(),
            buttons => '<a href="/Accounts/PasswordReset" class="right"><small>¿Olvidaste tu contraseña?</small></a>',
	    },
	},
    );
    return $HTML;
}

sub display_password_reset {
    my @submit = (loc("Siguiente"));

    my $form = CGI::FormBuilder->new(
        name     => 'password_reset',
        method   => 'post',
        fields   => [qw/controller email/],
        action   => '/Accounts/PasswordReset',
        submit   => \@submit,
        materialize => '1',
    );

    $form->field(name => 'email', label=> loc('Correo electrónico'), comment=>'<i class="icon-envelope"></i>', type=>'email',
		 maxlength=>"100", required=>"1", class=>"", jsmessage => loc('Ingresa tu email'));
    $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Accounts/tmpl/password-reset-form.html',
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
    $template->process("Chapix/Accounts/tmpl/your-account.html", $vars,\$HTML) or $HTML = $template->error();
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
    $template->process("Chapix/Accounts/tmpl/settings.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub display_password_form {
    $conf->{Page}->{Title} = loc('Cambiar Contraseña');
    set_back_btn('Accounts/YourAccount',loc('Tu cuenta'));

  $conf->{Page}->{ShowSettings} = 'true';

    my @submit = (loc('Guardar'));
    my $params = {};
    my $form = CGI::FormBuilder->new(
        name     => 'change_password',
        action   => '/Accounts/ChangePassword',
        method   => 'post',
        fields   => [qw/current_password new_password new_password_repeat/],
        submit   => \@submit,
        values   => $params,
        materialize => 1,
    );
    $form->field(name => 'current_password', label=> loc("Contraseña actual"), maxlength=>"45", required=>1, type=>'password', group=>loc('Actual'));
    $form->field(name => 'new_password', label=> loc("Nueva contraseña"), maxlength=>"45", required=>1, type=>'password', group=> loc('Nueva'));
    $form->field(name => 'new_password_repeat', label=> loc("Repite la nueva contraseña"), maxlength=>"45", required=>1, type=>'password');

    return $form->render(
        template => {
            type => 'TT2',
            engine => {},
            template => 'Chapix/Accounts/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}

sub display_edit_account_form {
    $conf->{Page}->{Title} = loc('Cambia tus ajustes');

    set_back_btn('Accounts/YourAccount',loc('Tu cuenta'));

    my @submit = (loc('Guardar'));

    my $params = {
        name => $sess{user_name},
        time_zone => $sess{user_time_zone},
        language  => $sess{user_language},
    };

    my $form = CGI::FormBuilder->new(
        name     => 'edit_account',
        action   => '/Accounts/EditAccount',
        method   => 'post',
        fields   => [qw/name time_zone language/],
        submit   => \@submit,
        values   => $params,
        materialize => 1,
    );

    $form->field(name => 'name', required=>1, label=>loc('Nombre'));

    my %time_zones = Chapix::Com::selectbox_data("SELECT SUBSTR(Name,7) AS id, SUBSTR(Name,7) AS name FROM mysql.time_zone_name tzn WHERE tzn.Name LIKE 'posix%'");

    $form->field(name => 'time_zone', required=>1, label=> loc('Zona horaria'), options=>$time_zones{values}, type=>'select');

    $form->field(name => 'language', required=>1, label=> loc('Languaje'), options=>['es_MX','en_US'], type=>'select',
		 labels => {'es_MX'=>'Español', 'en_US'=>'English'});

    return $form->render(
        template => {
            type => 'TT2',
            engine => {},
            template => 'Chapix/Accounts/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}

sub display_user_form {
    my @submit = (loc("Guardar"), loc('Restablecer Contraseña'), loc('Eliminar'));

    my $params = {};
    $conf->{Page}->{Title} = loc('User');
    set_back_btn('Accounts/Users',loc('Users'));

    if($_REQUEST->{user_id}){
        $params = $dbh->selectrow_hashref(
            "SELECT u.user_id, u.name, u.email, u.time_zone, u.language " .
            "FROM users u " .
            "WHERE ud.user_id=? ",{},$_REQUEST->{user_id});
        if(!$params->{user_id}){
            msg_add('warning',loc('User does not exist'));
            return display_users_list();
        }
    }

    my $form = CGI::FormBuilder->new(
        name     => 'user',
        method   => 'post',
        fields   => [qw/user_id name email time_zone language active/],
	action   => '/Accounts/User',
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
	    template => 'Chapix/Accounts/tmpl/form.html',
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
    my @submit = "Crea tu cuenta";

    my $form = CGI::FormBuilder->new(
        name     => 'register',
        method   => 'post',
        fields   => [qw/controller name email phone/],
    	action   => '/Accounts/Register',
        submit   => \@submit,
        materialize => '1'
	);

    $form->field(name => 'controller', type=>'hidden', label=>'');
    $form->field(name => 'name', label=> loc('Nombre'), class=>"", maxlength=>"100", required=>"1",value=>"",
		 jsmessage => loc('Escribe tu nombre'), type=>"text", icon=>'account_circle');
    $form->field(name => 'email', label=> loc('Correo electrónico'), type=>'email', icon=>'email',
		 maxlength=>"100", required=>"1", class=> "", jsmessage => loc('Escribe tu correo electrónico'));
    $form->field(name => 'phone', label=> loc('Teléfono'), type=>'text', icon=>'phone',
		 maxlength=>"100", required=>"1", class=> "", jsmessage => loc('Ingresa tu número telefónico'),
         validate=>'/[\d\s\-]{10,15}/');

   #  $form->field(name => 'password', label=> loc('Contraseña'), type=>'password', icon=>'lock',
		 # maxlength=>"30", required=>"1", class=> "", jsmessage => loc('Usa porfavor una contraseña mas compleja. Agrega números, mayusculas y minúsculas.'),
   #       validate=>'/^(?:(?=.*[a-z])(?:(?=.*[A-Z])(?=.*[\d\W])|(?=.*\W)(?=.*\d))|(?=.*\W)(?=.*[A-Z])(?=.*\d)).{6,}$/');
   #  $form->stylesheet('1');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Accounts/tmpl/register-form.html',
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
    $template->process("Chapix/Accounts/tmpl/password-reset-sent.html", $vars,\$HTML) or $HTML = $template->error();
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
    $template->process("Chapix/Accounts/tmpl/password-reset-success.html", $vars,\$HTML) or $HTML = $template->error();
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
        action   => '/Accounts/PasswordResetCheck',
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
            template => 'Chapix/Accounts/tmpl/pub-form.html',
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
