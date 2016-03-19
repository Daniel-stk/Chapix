package Chapix::Xaa::Crontab;

use lib('cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::Com;

sub new {
    my $class = shift;
    my $DEBUG = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;
    $self->{DEBUG} = $DEBUG || 0;
    # Init app ENV
    $self->_init();

    return $self;
}

# Initialize ENV
sub _init {
    my $self = shift;
    $self->{main_db} = $conf->{Xaa}->{DB};
}

sub run {
    my $self = shift;
    my $date = $dbh->selectrow_array("SELECT DATE(DATE_SUB(NOW(), INTERVAL 1 DAY))");
    print time() . " Running Xaa \n" if ($self->{DEBUG});
    
    # Get date SAAS metrics
    my $exist = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.date_metrics dm WHERE dm.date=?",{},$date) || 0;
    if(!$exist){
        # If does not exist, lets create them
        print time() . " SAAS date metrics for $date\n" if ($self->{DEBUG});

        my $previous = $dbh->selectrow_hashref("SELECT * FROM xaa.date_metrics dm WHERE dm.date = DATE_SUB(?,INTERVAL 1 DAY) ",{},$date);
        my $users_total  = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.xaa_users") || 0;
        my $users_new    = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.xaa_users WHERE created_on BETWEEN ? AND ?",{},
						 "$date 00:00:00","$date 23:59:59") || 0;
        my $users_active = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.xaa_users WHERE last_login_on > DATE_SUB(NOW(), INTERVAL 30 DAY)") || 0;

        my $domains_total  = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.xaa_domains") || 0;
        my $domains_new    = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.xaa_domains WHERE added_on BETWEEN ? AND ?",{},
                                                "$date 00:00:00","$date 23:59:59") || 0;
        my $domains_active = $dbh->selectrow_array(
            "SELECT COUNT(DISTINCT ud.domain_id) " .
            "FROM xaa.xaa_users u " .
            "INNER JOIN xaa.xaa_users_domains ud ON u.user_id=ud.user_id " .
            "WHERE u.last_login_on > DATE_SUB(NOW(), INTERVAL 30 DAY)") || 0;
        
        my $customers_total  = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.xaa_domains WHERE subscription=1") || 0;
        my $customers_new    = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.xaa_domains WHERE subscription_date BETWEEN ? AND ?",{},
                                                "$date 00:00:00","$date 23:59:59") || 0;
        my $customers_active = $dbh->selectrow_array(
            "SELECT COUNT(DISTINCT ud.domain_id) " .
            "FROM xaa.xaa_users u " .
            "INNER JOIN xaa.xaa_users_domains ud ON u.user_id=ud.user_id " .
            "INNER JOIN xaa.xaa_domains d ON d.domain_id=ud.domain_id " .
            "WHERE u.last_login_on > DATE_SUB(NOW(), INTERVAL 30 DAY) AND d.subscription=1") || 0;
        my $customers_churned = $dbh->selectrow_array("SELECT COUNT(*) FROM xaa.xaa_domains WHERE subscription_cancel_date BETWEEN ? AND ? AND subscription=1",{},
                                                "$date 00:00:00","$date 23:59:59") || 0;

        my $revenue = $dbh->selectrow_array("SELECT SUM(payment) FROM xaa.xaa_domains_balance xdb WHERE xdb.date BETWEEN ? AND ? ",{},
                                            "$date 00:00:00","$date 23:59:59") || 0;        
        print time() . "     Users\n" if ($self->{DEBUG});
        print time() . "         Total: $users_total\n" if ($self->{DEBUG});
        print time() . "         New: $users_new\n" if ($self->{DEBUG});
        print time() . "         Active: $users_active\n" if ($self->{DEBUG});
        print time() . "     Domains\n" if ($self->{DEBUG});
        print time() . "         Total: $domains_total\n" if ($self->{DEBUG});
        print time() . "         New: $domains_new\n" if ($self->{DEBUG});
        print time() . "         Active: $domains_active\n" if ($self->{DEBUG});
        print time() . "     Customers\n" if ($self->{DEBUG});
        print time() . "         Total: $customers_total\n" if ($self->{DEBUG});
        print time() . "         New: $customers_new\n" if ($self->{DEBUG});
        print time() . "         Active: $customers_active\n" if ($self->{DEBUG});
        print time() . "         Churned: $customers_churned\n" if ($self->{DEBUG});
        print time() . "     Revenue\n" if ($self->{DEBUG});
        print time() . "         This day: $revenue\n" if ($self->{DEBUG});
        

        $dbh->do("INSERT INTO xaa.date_metrics (date, users_total, users_new, users_active, " .
                "domains_total, domains_new, domains_active, " .
                "customers_total, customers_new, customers_active, customers_churned, revenue) " .
                "VALUE (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",{},
                $date, $users_total, $users_new, $users_active,
                $domains_total, $domains_new, $domains_active,
                $customers_total, $customers_new, $customers_active, $customers_churned, $revenue
                );

    }
}

1;
