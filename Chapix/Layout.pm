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
    my $template_file = shift || '';
    
    if (!$template_file) {
        if($sess{user_id}){
            $template_file = 'layout-app.html'
        }else{
            $template_file = 'layout.html'
        }
    }

    #my $menus  = $dbh->selectall_arrayref(
    #    "SELECT SQL_CACHE * FROM menus WHERE menu_group='UserAccount' AND parent_id=0 AND publish=1 ORDER BY sort_order",{Slice=>{}});

    #my $notifications = $dbh->selectall_arrayref(
    #    "SELECT * FROM $conf->{Xaa}->{DB}.notifications WHERE readed=0 AND user_id=?",{Slice=>{}},$sess{user_id});
        
    my $l_vars = {
    	content => $content,
    	vars    => $vars,
    	sess    => \%sess,
    	conf    => $conf,
        Domain     => ($_REQUEST->{Domain} || ''),
        Controller => ($_REQUEST->{Controller} || ''),
        View       => ($_REQUEST->{View} || 'Default'),
        #menus => $menus,
        #notifications => $notifications,
    	msg => msg_print(),
    };
    $Template->process($template_file, $l_vars,\$HTML) or $HTML = $Template->error();
    
    return $HTML;
}

1;
