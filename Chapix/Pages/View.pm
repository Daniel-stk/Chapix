package Chapix::Pages::View;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::List;
use Chapix::Com;
use Chapix::Layout;

# View functions
sub display_page {
    my $file = $_REQUEST->{View};
    if (-e ('templates/'.$conf->{Template}->{TemplateID}.'/'.$file.'.html')) {
        
    }else{
        $file = 'NotFound'
    }

    my $HTML = '';    
    open(FILE, 'templates/'.$conf->{Template}->{TemplateID}.'/'.$file.'.html');
    while (<FILE>) {
        $HTML .= $_;
    }
    close FILE;

    return $HTML;
}

1;