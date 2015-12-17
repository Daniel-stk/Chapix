package Chapix::Admin::View;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;
use CGI::FormBuilder;

use Chapix::Conf;
use Chapix::List;
use Chapix::Admin::Com;
use Chapix::Admin::Layout;
use Chapix::Admin::L10N;

# Language Object
my $lh = Chapix::Admin::L10N->get_handle($sess{admin_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub default {
    return Chapix::Admin::Layout::print(msg_print());
}

sub display_login {
    my @submit = (loc("Login"));
    
    my $form = CGI::FormBuilder->new(
        name     => 'login',
        method   => 'post',
        fields   => [qw/Controller email password/],
        submit   => \@submit,
        bootstrap => '1',
    );

    $form->field(name => 'Controller', type=>'hidden', value=>'Admin', override=>1);
    $form->field(name => 'email', label=> loc('Email'), comment=>'<i class="icon-envelope"></i>',
		maxlength=>"100", required=>"1", class=> "span12", jsmessage => loc('Please enter your email'));
    $form->field(name => 'password', label=> loc('Password'), class=>"span12",maxlength=>"100", required=>"1",value=>"",
        override=>1,jsmessage => loc('Please enter your password'), type=>"password", comment=>'<i class="icon-lock"></i>');
    
    $form->stylesheet('1');
    my $HTML = $form->render(
	template => {
	    template => '../Chapix/Admin/tmpl/login-form.html',
	    type => 'TT2',
	    engine => {RELATIVE=>1},
	    variable => 'form',
	    data => {
    		conf  => $conf,
            loc => \&loc,
    		msg   => msg_print(),
	    },
	},
    );
    return Chapix::Admin::Layout::print($HTML,{},'layout-login.html');
}

sub display_credits {
    my $vars = {
    	conf    => $conf,
    	msg => msg_print()
    };
    my $HTML = '';
    my $template = Template->new(RELATIVE=>1);
    $template->process('../Chapix/Admin/tmpl/credits.html', $vars,\$HTML) or $HTML = $template->error();
    return $HTML;

}

sub display_settings_form {
    
    $conf->{Page}->{Title} = 'Settings';
    set_toolbar(['?']);

    my @submit = ('Save');
    my $params = $conf->{WebSite};
    my $form = CGI::FormBuilder->new(
        name     => 'settings',
        method   => 'post',
        fields   => [qw/Name Language Keywords Description/],
        submit   => \@submit,
        values   => $params,
        bootstrap => 1,
    );
    $form->field(name => 'Controller', type=>'hidden');
    $form->field(name => 'View', type=>'hidden');
    $form->field(name => 'Name',label=>"Name", maxlength=>"45", required=>1);
    $form->field(name => 'Keywords',label=>"Keywords", maxlength=>"245", required=>1, type=>'textarea', class=>'materialize-textarea');
    $form->field(name => 'Description',label=>"Description", maxlength=>"245", required=>1, type=>'textarea', class=>'materialize-textarea');
    $form->field(name => 'Language',label=>"Language", required=>1, type=>'select', options=>['en_US','es_MX'], labels=>{EN=>'English', ES=>'Spanish'});

    return $form->render(
        template => {
            type => 'TT2',
            engine => {RELATIVE=>1},
            template => '../Chapix/Admin/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}

# Your account form
sub display_account_form {
    $conf->{Page}->{Title} = 'Your Account';
    set_toolbar(['?']);

    my @submit = ('Save');
    my $params = $dbh->selectrow_hashref("SELECT name, email, language, time_zone FROM admins WHERE admin_id=?",{},$sess{admin_id});
    my $form = CGI::FormBuilder->new(
        name     => 'account',
        method   => 'post',
        fields   => [qw/name email language time_zone/],
        submit   => \@submit,
        values   => $params,
        bootstrap => 1,
    );
    $form->field(name => 'Controller', type=>'hidden');
    $form->field(name => 'View', type=>'hidden');
    $form->field(name => 'name',label=>"Name", maxlength=>"45", required=>1);
    $form->field(name => 'email',label=>"Email", maxlength=>"45", required=>1, validate=>'EMAIL');
    $form->field(name => 'language',label=>"Language", required=>1, type=>'select', options=>['en_US','es_MX'], labels=>{EN=>'English', ES=>'Spanish'});
    $form->field(name => 'time_zone',label=>"Time zone", required=>1, type=>'select', options=>['-06:00','-07:00'], labels=>{'-06:00'=>'Chihuahua, La Paz, Mazatlan', '-07:00'=>'México, Guadalajara'});

    return $form->render(
        template => {
            type => 'TT2',
            engine => {RELATIVE=>1},
            template => '../Chapix/Admin/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}

# Your password form
sub display_password_form {
    
    $conf->{Page}->{Title} = 'Change your password';
    set_toolbar(['?']);

    my @submit = ('Save');
    my $params = {};
    my $form = CGI::FormBuilder->new(
        name     => 'change_password',
        method   => 'post',
        fields   => [qw/current_password new_password new_password_repeat/],
        submit   => \@submit,
        values   => $params,
        bootstrap => 1,
    );
    $form->field(name => 'Controller', type=>'hidden');
    $form->field(name => 'View', type=>'hidden');
    $form->field(name => 'current_password', label=>"Current password", maxlength=>"45", required=>1, type=>'password', group=>'Current');
    $form->field(name => 'new_password', label=>"New password", maxlength=>"45", required=>1, type=>'password', group=>'New');
    $form->field(name => 'new_password_repeat', label=>"Repeat new password", maxlength=>"45", required=>1, type=>'password');

    return $form->render(
        template => {
            type => 'TT2',
            engine => {RELATIVE=>1},
            template => '../Chapix/Admin/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg => msg_print()
            },
        },
    );
}

sub display_modules_list {
     $conf->{Page}->{Title} = 'Modules';
     #set_path_route();
     set_toolbar(['?View=AddModule','Add new module','left','plus'],['?View=Settings']);

    my $where = "";
    my @params;
    if($_REQUEST->param('q')){
     	$where .=' AND (m.name LIKE ? OR m.description LIKE ?) ';
     	push(@params,'%'.$_REQUEST->param('q').'%','%'.$_REQUEST->param('q').'%');
    }
    my $list = Chapix::List->new(
        dbh => $dbh,
        sql => {
            select => "m.module, m.installed, m.name, m.description, '' AS actions ",
            from =>"modules m ",
            order_by => "m.name",
            where => $where,
            params => \@params,
            limit => "30",
        },
        link => {
            key => "module",
            hidde_key_col => 1,
            location => "index.pl",
            transit_params => {'Controller'=>'Admin','View'=>'ModuleSettings','q' => $_REQUEST->param('q')},
        },
    );

    # Manually define list actions
    $list->get_data();
    foreach my $rec(@{$list->{rs}}){
        if($rec->{installed} eq '1'){
            
        }else{
            $rec->{actions} = CGI::a({-class=>'btn btn-primary btn-xs', -href=>'?action=InstallModule&module='.$rec->{module}},'Install');
        }
    }
    
    # List personalization
    $list->columns_align([qw/center left left center/]);

    my $HTML = "";
    my $vars = {
    	list => $list->print(),
    	msg  => msg_print(),
    };
    $Template->process("../Chapix/Admin/tmpl/list.html", $vars,\$HTML) or $HTML = $Template->error();
    return $HTML;
}

1;
