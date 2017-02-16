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

sub display_settings_form {
    $conf->{Page}->{Title} = 'Email Settings';
    set_path_route(['Mail','?controller=Mail']);
    set_toolbar(['?controller=Mail']);

    my @submit = ('Save');
    my $params = $conf->{Mail};
    $params->{Password} = "*" x length($params->{Password});

    my $form = CGI::FormBuilder->new(
        name     => 'settings',
        method   => 'post',
        fields   => [qw/controller view Server Port SecureConnection User Password/],
        submit   => \@submit,
        submit_class => ['primary'],
        values   => $params,
        materialize => '1',
        jsfunc    => q|
      if (form._submit.value == 'Cancel') {
         // skip validation since we're cancelling
         return true;
      }
      |,
    );

    $form->field(name => 'controller', type=>'hidden');
    $form->field(name => 'view', type=>'hidden');
    $form->field(name => 'Server', label => 'Server', required=>1);
    $form->field(name => 'Port', label => 'Port number');
    $form->field(name => 'SecureConnection', type=>'select', options => [0, 1], labels=>{0=>'Plain text', 1=>'Secure connection'}, label=>'Use a secure connection?');
    $form->field(name => 'User', label => 'User name');
    $form->field(name => 'Password', label => 'Password');


    return $form->render(
        template => {
            type => 'TT2',
            engine => {RELATIVE=>1},
            template => '../Chapix/Admin/tmpl/form.html',
            variable => 'form',
            data => {
                conf => $conf,
                msg  => msg_print(),
            },
        },
    );
}

1;
