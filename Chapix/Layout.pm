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
        if($sess{account_id}){
            $template_file = 'layout-app.html'
        }else{
            $template_file = 'layout.html'
        }
    }
        
    my $l_vars = {
    	content => $content,
    	vars    => $vars,
    	sess    => \%sess,
    	conf    => $conf,
        Domain     => ($_REQUEST->{Domain} || ''),
        Controller => ($_REQUEST->{Controller} || ''),
        View       => ($_REQUEST->{View} || 'Default'),
    	msg => msg_print(),
    };
    $Template->process($template_file, $l_vars,\$HTML) or $HTML = $Template->error();
    
    return $HTML;
}

1;
