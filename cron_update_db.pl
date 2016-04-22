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

    $dbh->do("USE $domain->{database}");
    open (SQL,"sql/update.sql") or die "Can't open SQL file.\n\n";
    my $SQL = '';
    while(<SQL>){
        $SQL .= $_;
    }
    close SQL;
    my @instructions = split(/;/,$SQL);
    foreach my $sql (@instructions){
        $sql =~ s/\n/ /g;
        next if($sql eq ' ' or $sql eq '  ' or $sql eq '   ' or $sql eq '     ');
        eval {
            $dbh->do("$sql") if(length( $sql ) > 0);
        };
        print "   --  $sql \n";
        if($@){
            print "           $@\n";
        }

    }
    print "----------------------------------------------------\n";
}

$dbh->do("SET foreign_key_checks = 1");

exit;
