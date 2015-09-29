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
    return Chapix::Layout::print(msg_print());
}

sub display_login {
    my @submit = (loc("Login"));
    
    my $form = CGI::FormBuilder->new(
        name     => 'login',
        method   => 'post',
        fields   => [qw/controller email password/],
	action   => $conf->{ENV}->{BaseURL} . 'Xaa',
        submit   => \@submit,
        bootstrap => '1',
    );

    $form->field(name => 'email', label=> loc('Email'), comment=>'<i class="icon-envelope"></i>',
		 maxlength=>"100", required=>"1", class=> "span12", jsmessage => loc('Please enter your email'));
    $form->field(name => 'password', label=> loc('Password'), class=>"span12",maxlength=>"100", required=>"1",value=>"",
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
	    },
	},
    );
    return $HTML;
}

sub display_my_account {
    my $HTML = "";
    my $template = Template->new();
    my $vars = {
     	msg   => msg_print(),
    };
    $template->process("Chapix/Xaa/tmpl/my-account.html", $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}


#sub display_list {
#     $conf->{Page}->{Title} = 'Blocks';
#     set_path_route();
#     set_toolbar(['?controller=Blocks&view=add','Add new block','left','plus'],['?']);
#
#    my $where = "";
#    my @params;
#    if($Q->param('q')){
#     	$where .=' AND (b.name LIKE ? OR b.content LIKE ?) ';
#     	push(@params,'%'.$Q->param('q').'%','%'.$Q->param('q').'%');
#    }
#    my $list = Chapix::List->new(
#        dbh => $dbh,
#        sql => {
#            select => "b.block_id, b.name ",
#            from =>"blocks b ",
#            order_by => "b.name",
#            where => $where,
#            params => \@params,
#            limit => "30",
#        },
#        link => {
#            key => "block_id",
#            hidde_key_col => 1,
#            location => "index.pl",
#            transit_params => {'controller'=>'Blocks','view'=>'edit','q' => $Q->param('q')},
#        },
#    );
#
##    $conf->{Page}->{Forms} = get_search_box();
#    my $HTML = "";
#    my $vars = {
#    	list => $list->print(),
#    	msg  => msg_print(),
#    };
#    $Template->process("../Chapix/Admin/tmpl/list.html", $vars,\$HTML) or $HTML = $Template->error();
#    return $HTML;
#}
#
#sub display_form {
#    $conf->{Page}->{Title} = 'Block';
#    set_path_route(['Blocks','?controller=Blocks']);
#    set_toolbar(['?controller=Blocks&view=add','Add new block','left','plus'],['?controller=Blocks']);
#    set_toolbar(['?controller=Blocks'])  if($Q->param('view') eq 'add');
#
#    my @submit = ('Save','Delete');
#    my $params;
#    if($Q->param("block_id")){
#    	$params = $dbh->selectrow_hashref(
#	    "SELECT * FROM blocks WHERE block_id=?",{},$Q->param("block_id"));
#    }
#    my $form = CGI::FormBuilder->new(
#        name     => 'blocks',
#        method   => 'post',
#        fields   => [qw/controller view block_id name content/],
#        submit   => \@submit,
#        submit_class => ['primary','danger'],
#        values   => $params,
#        bootstrap => '1',
#        jsfunc    => q|
#      if (form._submit.value == 'Delete') {
#         if (confirm("Really DELETE this entry?")) return true;
#         return false;
#      } else if (form._submit.value == 'Cancel') {
#         // skip validation since we're cancelling
#         return true;
#      }
#      |,
#    );
#
#    $form->field(name => 'controller', type=>'hidden');
#    $form->field(name => 'view', type=>'hidden');
#    $form->field(name => 'block_id', type=>"hidden");
#    $form->field(name => 'name',label=>"Name", maxlength=>"45", required=>1);
#    $form->field(name => 'content',label=>"Content",type=>'textarea', cols=>'80', rows=>10, rte=>1);
#
##    $conf->{Page}->{Forms} = get_search_box();
#    return $form->render(
#        template => {
#            type => 'TT2',
#            engine => {RELATIVE=>1},
#            template => '../Chapix/Admin/tmpl/form.html',
#            variable => 'form',
#            data => {
#            },
#        },
#    );
#}

1;
