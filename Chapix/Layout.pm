package Chapix::Layout;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Template;

use Chapix::Conf;
use Chapix::Com;

sub print {
    my $HTML = "";
    my $content = shift || "";
    my $vars    = shift || {};
    my $template_file = shift || 'layout.html';
    my $controller = $_REQUEST->{controller} || '';
    my $view       = $_REQUEST->{view} || 'Default';
    my $user_menus = $dbh->selectall_arrayref(
	"SELECT SQL_CACHE * FROM menus WHERE menu_group='UserAccount' AND parent_id=0 AND publish=1 ORDER BY sort_order",{Slice=>{}});
        
    my $l_vars = {
    	content => $content,
    	vars    => $vars,
    	sess    => \%sess,
    	conf    => $conf,
        controller => $controller,
	user_menus => $user_menus,
    	msg => msg_print()
    };
    $Template->process($template_file, $l_vars,\$HTML) or $HTML = $Template->error();
    return $HTML;
}

1;
