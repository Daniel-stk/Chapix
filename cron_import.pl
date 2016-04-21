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
my $domains = $dbh->selectall_arrayref("SELECT * FROM ws.domains WHERE domain_id > 726 ORDER BY domain_id",{Slice=>{}});
my $especiales = "";
foreach my $domain (@$domains){
    print "----------------------------------------------------\n";
    print "$domain->{domain_id} $domain->{name}\n";
    # Registro de dominio.
    # -
    $dbh->do("DELETE FROM xaa.xaa_domains WHERE domain_id=?",{},$domain->{domain_id});
    # +
    my $subscription = 1;
    $subscription = 0 if($domain->{is_free_account} == 1);
    $domain->{address} = $dbh->selectrow_array("SELECT `conf`.`value` FROM `$domain->{database}`.`conf` WHERE `conf`.`group`='Site' AND `conf`.`name`='Address'") || '';
    $domain->{city} = $dbh->selectrow_array("SELECT `conf`.`value` FROM `$domain->{database}`.`conf` WHERE `conf`.`group`='Site' AND `conf`.`name`='City'") || '';
    $domain->{phone} = $dbh->selectrow_array("SELECT `conf`.`value` FROM `$domain->{database}`.`conf` WHERE `conf`.`group`='Site' AND `conf`.`name`='Phone'") || '';
    # Marcar como paquete especial
    if($domain->{service_payment_method_id} > 1){
        $especiales .= "$domain->{domain_id} $domain->{name}\n";
    }
    
    if($domain->{service_payment_method_id} == 1){
        $domain->{service_payment_method_id} = 0;
        $subscription = 0;
        $domain->{eme_emails_limit} = 500;
        $domain->{eme_send_limit}   = 2500;
    }
    $dbh->do("INSERT INTO xaa.xaa_domains (domain_id, name, folder, `database`, added_on, active, country_id, " .
             "payment_method_id, eme_emails_limit, eme_send_limit, cc_name, cc_data, time_zone, language, address, " .
             "phone, subscription, subscription_date) " .
             "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",{},
             $domain->{domain_id}, $domain->{name}, $domain->{subdomain}, "xaa_$domain->{subdomain}",$domain->{created_on}, $domain->{active},
             $domain->{country_id}, $domain->{service_payment_method_id}, $domain->{eme_emails_limit}, $domain->{eme_send_limit}, '','','','es_MX',
             $domain->{address} . ', '.$domain->{city},$domain->{phone},$subscription, $domain->{created_on}, );
    
    # Crear nueva base de datos
#    $dbh->do("DROP DATABASE xaa_$domain->{subdomain}");
    $dbh->do("CREATE DATABASE xaa_$domain->{subdomain}");
    $dbh->do("USE xaa_$domain->{subdomain}");
    open (SQL,"base_db.sql") or die "Can't open SQL file.\n\n";
    my $SQL = '';
    while(<SQL>){
        $SQL .= $_;
    }
    close SQL;
    my @instructions = split(/;/,$SQL);
    foreach my $sql (@instructions){
        $sql =~ s/\n/ /g;
        next if($sql eq ' ' or $sql eq '  ' or $sql eq '   ' or $sql eq '     ');
        $dbh->do("$sql") if(length( $sql ) > 0);
    }
    
    # importar listas o grupos
    my $listas = $dbh->selectall_arrayref("SELECT * FROM $domain->{database}.eme_lists",{Slice=>{}});
    foreach my $list (@$listas){
        $dbh->do("INSERT INTO contacts_groups (group_id, group_name, contacts, group_key, active, sent_messages) " .
                 "VALUES(?,?,?,?,?,?)",{},
                 ($list->{list_id} + 1000), $list->{name}, $list->{subscriptors}, $list->{list_key}, $list->{active}, $list->{sent_emails});
    }
    
    # Importar contactos
    my $emails = $dbh->selectall_arrayref("SELECT * FROM $domain->{database}.eme_emails",{Slice=>{}});
    foreach my $email (@$emails){
        $dbh->do("INSERT INTO `contacts` (`contact_id`, `email`, `name`, `age`, `gender`, `country`, `state`, `city`, `cp`, `address`, `phone`, " .
                 "`cellphone`, `company`, `department`, `ocupation`, `custom1`, `custom2`, `custom3`, `custom4`, `custom5`, `added_on`, `updated_on`, ".
                 " `sent_messages`,`open_messages`,`clicked_messages`) " .
                 "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ",{},
                 $email->{email_id}, $email->{email}, $email->{name}, $email->{age}, $email->{gender}, $email->{country}, $email->{state}, $email->{city},
                 $email->{cp}, $email->{address}, $email->{phone}, $email->{cellphone}, $email->{company}, $email->{department}, $email->{ocupation},
                 $email->{custom1}, $email->{custom2}, $email->{custom3}, $email->{custom4}, $email->{custom5}, $email->{added_on}, $email->{updated_on},
                 $email->{sent_messages}, $email->{open_messages}, $email->{clicked_messages});
    }
    
    # Suscripciones a cada grupo
    my $emails_lists = $dbh->selectall_arrayref("SELECT * FROM $domain->{database}.eme_emails_lists",{Slice=>{}});
    foreach my $det (@$emails_lists){
        $dbh->do("INSERT INTO `contacts_to_groups` (`group_id`, `contact_id`, `added_on`, `status_id`, `removed_on`, `removed_by`, `removed_reason`) ".
                 "VALUES (?,?,?,?,?,?,?)",{},
                 ($det->{list_id} + 1000), $det->{email_id}, $det->{added_on}, $det->{status_id}, $det->{removed_on}, $det->{removed_by}, $det->{removed_reason});
    }

    # Paquete de 500 contactos siempre grátis
    $dbh->do("DELETE FROM xaa.xaa_domains_services WHERE domain_id=?",{},$domain->{domain_id});
    $dbh->do("INSERT INTO xaa.xaa_domains_services (domain_id, service_id, app_name, next_bill_on, service_cycle, price) " .
             "VALUES(?,1,'Marketero', ?,'MONTH', 0)",{},
             $domain->{domain_id}, ('2016-05-'. (int(rand(25))+1)) );
    print '2016-05-'.(int(rand(25))+1);
    print "----------------------------------------------------\n";
}

# Registro de usuarios
my $accounts = $dbh->selectall_arrayref("SELECT * FROM ws.accounts",{Slice=>{}});
foreach my $account (@$accounts){
    $dbh->do("INSERT INTO `xaa`.`xaa_users` (`user_id`, `email`, `password`, `name`, `last_login_on`, `time_zone`, `language`, `created_on`) " .
             "VALUES (?,?,?,?,?,?,?,?)",{},
             $account->{account_id}, $account->{email}, $account->{password}, $account->{name}, $account->{last_login_on}, '','es_MX', $account->{added_on});
}



# Relación usuario, dominio
my $accounts = $dbh->selectall_arrayref("SELECT * FROM ws.accounts_domains",{Slice=>{}});
foreach my $account (@$accounts){
    $dbh->do("INSERT INTO `xaa`.`xaa_users_domains` (`user_id`, `domain_id`, `active`, `default_domain`) ".
             "VALUES (?,?,?,?)",{},
             $account->{account_id}, $account->{domain_id}, $account->{active}, $account->{default_domain});
}

$dbh->do("SET foreign_key_checks = 1");

# Imprimir lista de especiales
print $especiales . "\n\n";


exit;
