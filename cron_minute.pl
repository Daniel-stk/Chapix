#!/usr/bin/perl

use strict;
use lib ('/var/www/html');
use lib ('/usr/local/WS/Chapix');
use CGI qw/:cgi/;
use CGI::Carp qw(fatalsToBrowser);
chdir ('/usr/local/WS/Chapix/');
use Chapix::Conf;
use Chapix::Com;
use Chapix::Crontab;

my $DEBUG = 0;
Chapix::Crontab::run_minute($DEBUG);
Chapix::Com::app_end();
exit;
