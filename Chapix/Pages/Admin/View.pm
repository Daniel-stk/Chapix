package Chapix::Pages::Admin::View;

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

sub display_list {
     $conf->{Page}->{Title} = 'Pages';
     set_path_route();
     set_toolbar(['?controller=Pages&view=add','Add new page','left','plus'],['?']);

    my $where = "";
    my @params;
    if($_REQUEST->{'q'}){
     	$where .=' AND (b.name LIKE ? OR b.content LIKE ?) ';
     	push(@params,'%'.$_REQUEST->{'q'}.'%','%'.$_REQUEST->{'q'}.'%');
    }
    my $list = Chapix::List->new(
        dbh => $dbh,
        sql => {
            select => "p.page_id, p.title, description, '' AS actions ",
            from =>"pages p ",
            order_by => "p.title",
            where => $where,
            params => \@params,
            limit => "30",
        },
        link => {
            key => "page_id",
            hidde_key_col => 1,
            location => "index.pl",
            transit_params => {'controller'=>'Pages','view'=>'edit','q' => $_REQUEST->{'q'}},
        },
    );

#    $conf->{Page}->{Forms} = get_search_box();
    my $HTML = "";
    my $vars = {
    	list => $list->print(),
    	msg  => msg_print(),
    };
    $Template->process("../Chapix/Admin/tmpl/list.html", $vars,\$HTML) or $HTML = $Template->error();
    return $HTML;
}

sub display_form {
#    $conf->{Page}->{Title} = 'Page';
#    set_path_route(['Pages','?controller=Pages']);
#    set_toolbar(['?controller=Pages&view=add','Add new page','left','plus'],['?controller=Pages']);
#    set_toolbar(['?controller=Pages'])  if($_REQUEST->{'view'} eq 'add');
#
#    my @submit = ('Save','Delete');
#    my $params;
#    if($_REQUEST->{"page_id"}){
#    	$params = $dbh->selectrow_hashref(
#	    "SELECT * FROM pages WHERE page_id=?",{},$_REQUEST->{"page_id"});
#    }
#    my $form = CGI::FormBuilder->new(
#        name     => 'pages',
#        method   => 'post',
#        fields   => [qw/controller view page_id title publish description keywords content/],
#        submit   => \@submit,
#        submit_class => ['primary','danger'],
#        values   => $params,
#        materialize => '1',
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
#    $form->field(name => 'page_id', type=>"hidden");
#    $form->field(name => 'title',label=>"Title", maxlength=>"45", required=>1);
#    $form->field(name => 'publish',label=>"Publish", type=>'checkbox', options=>[1], labels=>{1=>'Yes, publish this page.'});
#    $form->field(name => 'description',label=>"Description", required=>1, type=>'textarea');
#    $form->field(name => 'keywords',label=>"Keywords", required=>1, type=>'textarea');
#    $form->field(name => 'content', label=>'Content', required=>1, type=>'textarea');
#
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
}

1;
