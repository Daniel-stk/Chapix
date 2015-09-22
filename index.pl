#!/usr/bin/perl

use strict;
use CGI qw/:cgi/;
use CGI::Carp qw(fatalsToBrowser);

use Chapix::Conf;
use Chapix::Com;
use Chapix::Controller;

Chapix::Controller::handler();
Chapix::Com::app_end();
exit;
