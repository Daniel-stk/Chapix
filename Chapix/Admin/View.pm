package Chapix::Admin::View;

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
use Chapix::Admin::L10N;
my $lh = Chapix::Admin::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub default {
    msg_add('warning',"Admin module");
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
sub display_home{

    my $HTML = "";
    my $template = Template->new();
    my $vars = {
        REQUEST => $_REQUEST,
        conf => $conf,
        sess => \%sess,
     	msg  => msg_print(),
        loc => \&loc,
    };
    $template->process("Chapix/Admin/tmpl/home.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub display_login {
    my @submit = (loc("Iniciar sesión"));

    my $form = CGI::FormBuilder->new(
        name     => 'login',
        method   => 'post',
        fields   => [qw/controller email password/],
        action   => '/Admin/Login',
        submit   => \@submit,
        materialize => '1',
    );

    $form->field(name => 'email', label=> loc('Correo Electrónico'), comment=>'<i class="icon-envelope"></i>', type=>'email',
		 maxlength=>"100", required=>"1", class=>"", jsmessage => loc('Escribe tu correo electrónico'));

    $form->field(name => 'password', label=> loc('Contraseña'), class=>"",maxlength=>"100", required=>"1",value=>"",
		 override=>1,jsmessage => loc('Escribe tu contraseña'), type=>"password", comment=>'<i class="icon-lock"></i>');

    my $HTML = $form->render(
	template => {
	    template => 'Chapix/Admin/tmpl/login-form.html',
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

sub display_admins {
    $conf->{Page}->{Title} = 'Administradores';
    
    set_add_btn('/Admin/Admins?_mode=new', loc('Nuevo administrador'));
    
    my $WHERE = "";
    my @params;

    if ($_REQUEST->{search}){
        $WHERE = " (a.name LIKE ? OR a.email LIKE ?) ";
        push(@params,'%'.$_REQUEST->{search}.'%', '%'.$_REQUEST->{search}.'%');
    }

    my $list = Chapix::List->new(
        dbh => $dbh,
        pagination => 1,
        auto_order => 1,
        sql => {
            select => "account_id, name, email, IF(active=1, 'Si', 'No') AS activo, '' AS editar ",
            from => "accounts a",
            limit => 50,
            where => $WHERE,
            params => \@params,
        },
        link => {
            key => 'account_id',
            hidde_key_col => 1,
            transit_params => {'search' => $_REQUEST->{search}},
        },
        );
    
    $list->get_data();
    $list->set_label('is_admin', 'Administrador');

    foreach my $rec(@{$list->{rs}}){
        $rec->{editar} = CGI::a({-href=>"/Admin/Admins?account_id=$rec->{account_id}", -class=>"waves-effect waves-light btn green accent-4"},'<i class="material-icons tiny">mode_edit</i>');
    }

    my $HTML = "";
    my $template = Template->new();
    my $vars = {
        REQUEST     => $_REQUEST,
        conf        => $conf,
        sess        => \%sess,
        msg         => msg_print(),
        list        => $list->print(),
        loc         => \&loc,
    };
    $template->process("Chapix/Admin/tmpl/list.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub display_admin_form {
    $conf->{Page}->{Title} = loc('Nuevo administrador');

    my @submit = (loc('Guardar'));

    my $params = $dbh->selectrow_hashref("SELECT * FROM accounts WHERE account_id=?",{},$_REQUEST->{account_id});
    if ($_REQUEST->{account_id} and $_REQUEST->{account_id} ne $sess{account_id}){
        push(@submit, 'Eliminar');
        $conf->{Page}->{Title} = loc('Administrador');
    }
    if(!$params){
        $params = {
            active => 1,
            is_admin => 1,
        };
    }

    my $form = CGI::FormBuilder->new(
        name     => 'admin',
        action   => '/Admin/Admins',
        method   => 'post',
        fields   => [qw/account_id name email is_admin active/],
        submit   => \@submit,
        values   => $params,
        );
    
    $form->field(name => 'account_id', type=>'hidden');
    $form->field(name => 'name', label=>loc('Nombre'), type=>'text', required=>1);
    $form->field(name => 'email', label=>loc('Email'), type=>'text', required=>1, validate=>'EMAIL');
    
    $form->field(name => 'is_admin', label=>loc(''), options=>[1], labels=>{1 => 'Es administrador'}, type=>'checkbox');
    $form->field(name => 'active', label=>loc(''), options=>[1], labels=>{1 => 'Activo'}, type=>'checkbox');
    
    if ($_REQUEST->{account_id}){
        $form->field(name => 'email', disabled=>1);
    }
    
    return $form->render(
        template => {
            type => 'TT2',
            engine => {},
            template => 'Chapix/Admin/tmpl/form.html',
            variable => 'form',
            data => {
                loc => \&loc,
                conf => $conf,
                msg => msg_print()
            },
        },
        );
}


1;
