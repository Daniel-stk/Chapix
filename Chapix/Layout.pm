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
    my $controller = $Q->param('controller') || '';
    my $view       = $Q->param('view') || 'Default';
        
    my $l_vars = {
    	content => $content,
    	vars    => $vars,
    	sess    => \%sess,
    	conf    => $conf,
        controller => $controller,
    	msg => msg_print()
    };
    $Template->process($template_file, $l_vars,\$HTML) or $HTML = $Template->error();
    return $HTML;
}

1;
