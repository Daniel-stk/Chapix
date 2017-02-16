package Chapix::View;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use CGI::FormBuilder;

use Chapix::Conf;
use Chapix::List;
use Chapix::Com;
use Chapix::Layout;

sub default {
    return Chapix::Layout::print(msg_print());
}

1;
