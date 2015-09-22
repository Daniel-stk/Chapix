package Chapix::Admin::Layout;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;
use Readonly;
use Template;

use Chapix::Conf;
use Chapix::Admin::Com;

sub print {
    my $HTML = "";
    my $content = shift || "";
    my $vars    = shift || {};
    my $template_file = shift || 'layout.html';
    my $menus      = $dbh->selectall_arrayref(
                        "SELECT SQL_CACHE * FROM menus WHERE menu_group='Admin' AND parent_id=0 AND publish=1 ORDER BY sort_order",
                        {Slice=>{}});
    my $controller = $Q->param('controller') || 'Admin';
    my $view       = $Q->param('view') || 'Default';
    
    foreach my $menu (@$menus){
        $menu->{active} = 0;
        if($menu->{module} eq $controller){
            $menu->{active} = 1 if($menu->{views} eq '*');
            $menu->{active} = 1 if($menu->{views} =~ /$view/);
        }
    }
    
    my $vars = {
    	content => $content,
    	vars    => $vars,
    	sess    => \%sess,
    	conf    => $conf,
    	menus   => $menus,
        controller => $controller,
    	msg => msg_print()
    };
    my $template = Template->new(RELATIVE=>1);
    $template->process('../Chapix/Admin/tmpl/'.$template_file, $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

1;
