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

my $DEBUG = 1;
$dbh->do("SET foreign_key_checks = 0");
my $domains = $dbh->selectall_arrayref("SELECT * FROM xaa.xaa_domains ORDER BY domain_id",{Slice=>{}});
my $especiales = "";
foreach my $domain (@$domains){
    print "----------------------------------------------------\n";
    print "$domain->{domain_id} $domain->{name}\n";
    # Registro de dominio.
    # +
    $domain->{email} = $dbh->selectrow_array("SELECT `conf`.`value` FROM `ws_$domain->{folder}`.`conf` WHERE `conf`.`group`='Site' AND `conf`.`name`='Email'") || '';
    
    $dbh->do("INSERT INTO xaa.virtual_aliases(domain_id, source, destination) VALUES(1, ?, ?)",{},
             $domain->{folder} . '@marketero.com.mx',$domain->{email});
}

exit;
