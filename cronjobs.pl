#!/usr/bin/perl

use strict;
use lib ('/var/www/html');
use CGI qw/:cgi/;
use CGI::Carp qw(fatalsToBrowser);


use Chapix::Conf;
use Chapix::Com;
use Chapix::Crontab;

my $DEBUG = 1;
Chapix::Crontab::run($DEBUG);
Chapix::Com::app_end();
exit;
