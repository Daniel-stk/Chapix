package Chapix::Mail::Admin::View;

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

sub default {
    return Chapix::Admin::Layout::print(msg_print());
}

sub display_dashboard {
    $conf->{Page}->{Title} = 'Mail';
    set_path_route();
    set_toolbar(['?controller=Mail&view=edit-settings','Cambiar Configuración'],
                ['?']);
    
    my $HTML = "";
    my $vars = {
        Mail => $conf->{Mail},
    	msg     => msg_print(),
    };
    $Template->process("../Chapix/Mail/tmpl/admin-dashboard.html", $vars,\$HTML) or $HTML = $Template->error();
    return $HTML;
}

sub display_settings_form {
    $conf->{Page}->{Title} = 'Configuración de Correo';
    set_path_route(['Mail','?controller=Mail']);
    set_toolbar(['?controller=Mail']);

    my @submit = ('Save');
    my $params = $conf->{Mail};
    $params->{Password} = "*" x length($params->{Password});

    my $form = CGI::FormBuilder->new(
        name     => 'settings',
        method   => 'post',
        fields   => [qw/controller view Mode Server Port Secure User Password/],
        submit   => \@submit,
        submit_class => ['primary'],
        values   => $params,
        bootstrap => '1',
        jsfunc    => q|
      if (form._submit.value == 'Cancel') {
         // skip validation since we're cancelling
         return true;
      }
      |,
    );

    $form->field(name => 'controller', type=>'hidden');
    $form->field(name => 'view', type=>'hidden');
    $form->field(name => 'Mode', type=>'select', options => [qw/LOCAL SMTP/], labels=>{LOCAL=>'Local SMTP server', SMTP=>'Remote SMTP server'});
    $form->field(name => 'Secure', type=>'select', options => [0, 1], labels=>{0=>'Plain text', 1=>'Secure connection'});

    return $form->render(
        template => {
            type => 'TT2',
            engine => {RELATIVE=>1},
            template => '../Chapix/Admin/tmpl/form.html',
            variable => 'form',
            data => {
            },
        },
    );
}

1;
