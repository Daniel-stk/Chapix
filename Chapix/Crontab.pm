package Chapix::Crontab;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::Com;

sub run_minute {
    my $DEBUG = shift;
    print time() . " Chapix Cron RUN \n" if ($DEBUG);
    print time() . "\n" if ($DEBUG);
    print time() . "\n" if ($DEBUG);
    my $modules = $dbh->selectcol_arrayref("SELECT m.module FROM xaa.modules m WHERE m.installed=1");
    foreach my $module (@$modules){
        print time() . " Module $module\n" if ($DEBUG);
        # Load module
        my $Module;
        eval {
            require "Chapix/" . $module ."/Crontab.pm";
            my $module_name ='Chapix::'.$module.'::Crontab';
            $Module = $module_name->new($DEBUG);
        };
        if($@){
            print time() . " Module $module error $@\n" if ($DEBUG);
            next;
        }

        # Actions
        $Module->run_minute();
        
        print time() . " Module $module END\n" if ($DEBUG);
        print time() . "\n" if ($DEBUG);
        print time() . "\n" if ($DEBUG);
    }
}

sub run_daily {
    my $DEBUG = shift;
    print time() . " Chapix Cron RUN \n" if ($DEBUG);
    print time() . "\n" if ($DEBUG);
    print time() . "\n" if ($DEBUG);
    my $modules = $dbh->selectcol_arrayref("SELECT m.module FROM modules m WHERE m.installed=1");
    foreach my $module (@$modules){
        print time() . " Module $module\n" if ($DEBUG);
        # Load module
        my $Module;
        eval {
            require "Chapix/" . $module ."/Crontab.pm";
            my $module_name ='Chapix::'.$module.'::Crontab';
            $Module = $module_name->new($DEBUG);
        };
        if($@){
            print time() . " Module $module error $@\n" if ($DEBUG);
            next;
        }

        # Actions
        $Module->run_daily();
        
        print time() . " Module $module END\n" if ($DEBUG);
        print time() . "\n" if ($DEBUG);
        print time() . "\n" if ($DEBUG);
    }
}

1;
