#!/usr/bin/perl

use lib('../');
use lib('../cpan/');
use strict;
use CGI qw/:cgi/;
use CGI::Carp qw(fatalsToBrowser);

use Chapix::Conf;
use Chapix::Admin::Com;
use Chapix::Admin::Controller;

Chapix::Admin::Controller::handler();

Chapix::Admin::Com::app_end();
exit;
