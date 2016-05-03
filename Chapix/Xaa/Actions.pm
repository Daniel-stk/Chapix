package Chapix::Xaa::Actions;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use CGI::FormBuilder;
use Digest::SHA qw(sha384_hex);
use JSON::XS;
use List::Util qw(min max);
use Business::PayPal::IPN;

use Chapix::Conf;
use Chapix::Com;

use Chapix::EmailMkt::MKT::Email;

# Language
use Chapix::Xaa::L10N;
my $lh = Chapix::Xaa::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }


sub login {
    my $results = {};

    my $user = $dbh->selectrow_hashref(
        "SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
	    "FROM $conf->{Xaa}->{DB}.xaa_users u " .
        "WHERE u.email=? AND u.password=?",{},
        $_REQUEST->{email}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}));

    if($user and $_REQUEST->{email}){
        # Write session data and redirect to index
    	$sess{user_id}    = "$user->{user_id}";
        $sess{user_name}  = "$user->{name}";
        $sess{user_email} = "$user->{email}";
        $sess{user_time_zone} = "$user->{time_zone}";
        $sess{user_language}  = "$user->{language}";

        $dbh->do("UPDATE $conf->{Xaa}->{DB}.xaa_users SET last_login_on=NOW() WHERE user_id=?",{},$user->{user_id});

        my $domain_id = $dbh->selectrow_array("SELECT domain_id FROM $conf->{Xaa}->{DB}.xaa_users_domains WHERE user_id=? AND active=1 ORDER BY default_domain DESC, added_on LIMIT 1 ",{},$user->{user_id}) || 0;
        if($domain_id){
            my $domain = $dbh->selectrow_hashref("SELECT name, folder FROM $conf->{Xaa}->{DB}.xaa_domains WHERE domain_id=? ",{},$domain_id);
            $results->{redirect} = '/'.$domain->{folder};
            $results->{success} = 1;
            return $results;
        }else{
        	msg_add('warning',loc('Tu cuenta no está ligada a ninguna empresa.'));
        	$results->{error} = 1;            
        }
        $results->{redirect} = '/Xaa/Login';
        return $results;
    }else{
    	$results->{error} = 1;
    	$results->{redirect} = '/Xaa/Login?email='.$_REQUEST->{email};
		return $results;
        # Record login attemp
        # my $updated = $dbh->do(
        #     "UPDATE $self->{main_db}.ip_security ips SET ips.failed_logins=ips.failed_logins + 1 WHERE ips.ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",
        #     {},$ENV{REMOTE_ADDR});
        # if(!int($updated)){
        #     $dbh->do("DELETE FROM $self->{main_db}.ip_security WHERE ip_address=?",{},$ENV{REMOTE_ADDR});
        #     $dbh->do("INSERT INTO $self->{main_db}.ip_security (ip_address, date, failed_logins) VALUES(?,NOW(),1)",
        #          {},$ENV{REMOTE_ADDR});
        # }
        # my $failed_logins = $dbh->selectrow_array("SELECT failed_logins FROM $self->{main_db}.ip_security ips WHERE ip_address=? AND DATE_ADD(ips.date,INTERVAL 1 HOUR) > NOW()",{},$ENV{REMOTE_ADDR});
        # msg_add("warning","Email or password incorrect.");
        # Chapix::Com::http_redirect('/Xaa/Login?email='.);
        # if ($failed_logins > 3) {
        #     msg_add("danger","You have " . (10 - $failed_logins) . " attemps left before being blocked.");
        # }
    }
}

sub logout {
    my $results = {};

    $sess{user_id}        = "";
    $sess{user_name}      = "";
    $sess{user_email}     = "";
    $sess{user_time_zone} = "";
    $sess{user_language}  = "";

    $results->{error} = 1;
    $results->{redirect} = '/';
    return $results;
}


sub save_new_password {
    my $results = shift;

    my $current_password = $dbh->selectrow_array("SELECT u.password FROM $conf->{Xaa}->{DB}.xaa_users u WHERE u.user_id=?",{},$sess{user_id}) || '';
    my $new_password = sha384_hex($conf->{Security}->{key} . $_REQUEST->{new_password});

    # Old password match?
    if($current_password ne sha384_hex($conf->{Security}->{key} . $_REQUEST->{current_password})){
        msg_add('warning',loc('El password actual es incorrecto.'));
        $results->{error} = 1;
        $results->{redirect} = '/'.$conf->{Domain}->{folder}.'/Xaa/ChangePassword';
        return $results;
    }

    # new passwords match?
    if($_REQUEST->{new_password} ne $_REQUEST->{new_password_repeat}){
        msg_add('warning', loc('Las contraseñas deben de coincidir'));
        $results->{error} = 1;
        $results->{redirect} = '/'.$conf->{Domain}->{folder}.'/Xaa/ChangePassword';
        return $results;
    }

    eval {
        $dbh->do("UPDATE $conf->{Xaa}->{DB}.xaa_users u SET u.password=? WHERE u.user_id=?",{},
                 $new_password, $sess{user_id});
    };
    if($@){    	
        msg_add('danger',$@);
        $results->{error} = 1;
        $results->{redirect} = '/'.$conf->{Domain}->{folder}.'/Xaa/ChangePassword';    
    }else{
        msg_add('success',loc('Contraseña actualizada satisfactoriamente'));
        $results->{success} = 1;
        $results->{redirect} = '/'.$conf->{Domain}->{folder}.'/Xaa/YourAccount';
    }
    return $results;
}

sub save_domain_settings {
    my $results = {};

    eval {
        $dbh->do("UPDATE $conf->{Xaa}->{DB}.xaa_domains d SET d.name=?, d.time_zone=?, d.language=? WHERE d.domain_id=?",{},
                 $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $conf->{Domain}->{domain_id});
    };
    if($@){
        msg_add('danger',$@);
        $results->{error} = 1;
        $results->{redirect} = '/'.$conf->{Domain}->{folder}.'/Xaa/Settings';
    }else{
        msg_add('success',loc('Ajustes actualizados'));
        $results->{success} = 1;
        $results->{redirect} = '/'.$conf->{Domain}->{folder}.'/Xaa/Settings';
    }
    return $results;
}


sub save_account_settings {
    my $results = {};

    eval {
        $dbh->do("UPDATE $conf->{Xaa}->{DB}.xaa_users u SET u.name=?, u.time_zone=?, u.language=? WHERE u.user_id=?",{},
                 $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $sess{user_id});
        $sess{user_name}      = $_REQUEST->{name};
        $sess{user_time_zone} = $_REQUEST->{time_zone};
        $sess{user_language}  = $_REQUEST->{language};
    };
    if($@){
        msg_add('danger',$@);
        $results->{error} = 1;
        $results->{redirect} = '/'.$conf->{Domain}->{folder}.'/Xaa/YourAccount';         
    }else{
        msg_add('success',loc('Datos actualizados correctamente'));
        $results->{success} = 1;
         $results->{redirect} = '/'.$conf->{Domain}->{folder}.'/Xaa/YourAccount';
    }
   return $results;
}


sub create_account {
    my $results = {};

    # email validation
    if($_REQUEST->{email} !~ /^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/){
    	msg_add('warning',loc('Please enter a valid email address'));
    	$results->{error} = 1;
    	$results->{redirect} = '/Xaa/Register';
    	return $results;
    }

    my $exist = $dbh->selectrow_hashref(
    	"SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
    	"FROM $conf->{Xaa}->{DB}.xaa_users u " .
    	"WHERE u.email=?",{},
    	$_REQUEST->{email});

    if($exist){
    	msg_add("warning", loc("El correo electrónico ya esta registrado"));
    	$results->{error} = 1;
    	$results->{redirect} = '/Xaa/Register';
    	return $results;
    }

    my ($user_mail, $user_domain) = split('@', $_REQUEST->{email});
    $user_mail   = lc($user_mail);
    $user_domain = lc($user_domain);
    $user_mail =~ s/\W//g;
    $user_domain =~ s/\..*//g;
    $user_domain =~ s/\W//g;

    my $domain_to_use = $user_domain;
    my @invalids_domains = qw/gmail hotmail yahoo outlook live/;

    foreach my $invalid (@invalids_domains) {
    	if($invalid eq $domain_to_use) {
    	    $domain_to_use = $user_mail;
    	    last;
    	}
    }

    my @sistem_subdomains =
	[qw/root bin daemon adm lp sync shutdown halt mail uucp operator games gopher ftp
            nobody vcsa saslauth mailnull smmsp sshd tcpdump rpc nscd apache dbus ntp mysql
            postfix named dovecot dovenull test dkim-milter opendkim www app webmaster abuse jmrp
            postmaster news radiusd nut vcsa canna wnn rpm pcap webalizer fax quagga radvd pvm
            amanda privoxy ident xfs gdm mailnull postgres smmsp netdump ldap squid ntp
            desktop rpcuser rpc nfsnobody ingres system toor manager dumper newsadm
            newsadmin usenet ftpadm ftpadmin ftp-adm ftp-admin webmaster noc security
            hostmaster info marketing sales support decode notificaciones notifications dev dmarc
            ns1 ns2 test mail default xaandia marketero mail smtp pop pop3 pop3s imap imapd
            isabel isabelborunda david davidromero cesar cesarrodriguez monica monicaborunda
            contacto comunicacion soporte facturas pagos servicios atencionalcliente informacion contabilidad
            mariadb httpd http https ssl
            ventas sales venta sale comunicacion clientes soporte support customers xandia marketero
            /];

    foreach my $sis_user (@sistem_subdomains){
    	if($sis_user eq $domain_to_use){
    	    $domain_to_use = 'mark';
    	    last;
    	}
    }

    # Check folder and db
    my $exist_folder_on_db = $dbh->selectrow_array("SELECT COUNT(*) FROM $conf->{Xaa}->{DB}.xaa_domains WHERE folder=?",{},$domain_to_use) || 0;
    my $exist_folder_on_fs = (-e('data/'.$domain_to_use));
    my $exist_db           = $dbh->selectrow_array("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?",{},'xaa_'.$domain_to_use) || 0;
    my $exist_alias        = $dbh->selectrow_array("SELECT 1 FROM xaa.virtual_aliases va WHERE va.source=?",{},($domain_to_use . '@marketero.com.mx')) || 0;
    my $exist_mailbox      = $dbh->selectrow_array("SELECT 1 FROM xaa.virtual_users vu WHERE vu.email=?",{},('eme_'.$domain_to_use . '@marketero.com.mx')) || 0;
    
    if($exist_folder_on_db or $exist_folder_on_fs or $exist_db or $exist_alias or $exist_mailbox){
    	foreach my $it(1 .. 9999999){
    	    my $current_domain_to_use = $domain_to_use . $it;
    	    $exist_folder_on_db = $dbh->selectrow_array("SELECT COUNT(*) FROM $conf->{Xaa}->{DB}.xaa_domains WHERE folder=?",{},$current_domain_to_use) || 0;
    	    $exist_folder_on_fs = (-e('data/'.$current_domain_to_use));
    	    $exist_db           = $dbh->selectrow_array("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?",{},'xaa_'.$current_domain_to_use) || 0;
            $exist_alias        = $dbh->selectrow_array("SELECT 1 FROM xaa.virtual_aliases va WHERE va.source=?",{},($current_domain_to_use . '@marketero.com.mx')) || 0;
            $exist_mailbox      = $dbh->selectrow_array("SELECT 1 FROM xaa.virtual_users vu WHERE vu.email=?",{},('eme_'.$current_domain_to_use . '@marketero.com.mx')) || 0;
    	    if(!$exist_folder_on_db and !$exist_folder_on_fs and !$exist_db and !$exist_alias and !$exist_mailbox){
                $domain_to_use = $current_domain_to_use;
                last;
    	    }
    	}
    }

    # User creation
    my $password = 'M'.substr(sha384_hex(time().$_REQUEST->{email}), 0, 8).'!';

    $dbh->do("INSERT INTO $conf->{Xaa}->{DB}.xaa_users (name, email, time_zone, language, password, last_login_on) VALUES(?,?,?,?,?,NOW())",{},
	     $_REQUEST->{name}, $_REQUEST->{email}, $conf->{App}->{TimeZone}, $conf->{App}->{Language}, sha384_hex($conf->{Security}->{key} . $password) );
    my $user_id = $dbh->last_insert_id('','',"$conf->{Xaa}->{DB}.xaa_users",'user_id');

    $dbh->do("INSERT INTO $conf->{Xaa}->{DB}.xaa_domains (`name`, `folder`, `database`, added_on) VALUES (?,?,?, NOW())",{}, ucfirst($domain_to_use), $domain_to_use, 'xaa_'.$domain_to_use);
    my $domain_id = $dbh->last_insert_id('','',"$conf->{Xaa}->{DB}.xaa_domains",'domain_id');

    $dbh->do("INSERT IGNORE INTO $conf->{Xaa}->{DB}.xaa_users_domains (user_id, domain_id, added_by, added_on, active, default_domain) VALUES (?,?,1,NOW(),1,1)",{},$user_id, $domain_id);

    # Email
    $dbh->do("INSERT INTO xaa.virtual_aliases(domain_id, source, destination) VALUES(1,?,?) ",{},$domain_to_use . '@marketero.com.mx', $_REQUEST->{email});
    $dbh->do("INSERT INTO xaa.virtual_users(domain_id, password, email) VALUES(1,'',?)",{},('eme_'.$domain_to_use . '@marketero.com.mx'));
    
    # Add contact to marketero pipeline
    add_new_customer_to_pipeline();

    # Database init
    my $DB = 'xaa_' . $domain_to_use;
    database_init($DB);

    # Domain setup
    # $dbh->do("UPDATE $DB.`conf` SET `value` = ? WHERE `group` = 'Site' AND `name` = 'Address'",{},$address);

    # User session
    $sess{user_id}        = "$user_id";
    $sess{user_name}      = "$_REQUEST->{name}";
    $sess{user_email}     = "$_REQUEST->{email}";
    $sess{user_time_zone} = "$conf->{App}->{TimeZone}";
    $sess{user_language}  = "$conf->{App}->{Language}";

    # Send Welcome Email
    my $Mail = Chapix::Mail::Controller->new();
    my $enviado = $Mail->html_template({
        to       => $_REQUEST->{'email'},
        subject  => $conf->{App}->{Name} . ': '. loc('Tu cuenta esta lista'),
        template => {
            file => 'Chapix/Xaa/tmpl/account-creation-letter.html',
            vars => {
                name     => format_short_name($_REQUEST->{'name'}),
                email    => $_REQUEST->{email},
                password => $password,
                loc => \&loc,
            }
        }
    });

    send_welcome_email($_REQUEST->{'name'}, $_REQUEST->{email});

    # Welcome msg
    msg_add('success','Tu cuenta fue creada con éxito.');

    # Redirect to personal homepage
    $results->{success} = 1;
    $results->{redirect} = '/'.$domain_to_use.'/Xaa/Welcome';
    return $results;
    #http_redirect("/$domain_to_use/");
}


sub send_welcome_email {
    my $name = shift;
    my $email = shift;

    my $Mail = Chapix::Mail::Controller->new();
    my $enviado = $Mail->html_template({
        to       => $email,
        bcc      => 'ventas@xaandia.com', 
        subject  => '¡Bienvenido(a), los primeros catorce días corren por nuestra cuenta!',
        template => {
            file => 'Chapix/Xaa/tmpl/account-welcome-letter.html',
            vars => {
                name => format_short_name($name),
                loc => \&loc,
            }
        }
    });

}

sub database_init {
    my $db_name = shift;
    $dbh->do("CREATE DATABASE " .$db_name);
    $dbh->do("USE $db_name ");
    $dbh->do("SET foreign_key_checks = 0");

    open (SQL, $conf->{App}->{Resources} . "sql/base_db.sql") or die "Can't open SQL file..\n\n";
    my $SQL = '';
    while(<SQL>){
        my $line = $_;
        next if($line =~ /^\-\-/);
        next if($line =~ /^\/\*/);
        $SQL .= $line;
    }
    close SQL;
    my @instructions = split(/;/,$SQL);
    foreach my $sql (@instructions){
        $sql =~ s/\n/ /g;
        next if($sql eq ' ' or $sql eq '  ' or $sql eq '   ' or $sql eq '     ');
        $dbh->do("$sql") if($sql);
    }
    $dbh->do("SET foreign_key_checks = 1");
}


sub add_new_customer_to_pipeline {

    my $exist = $dbh->selectrow_array("SELECT contact_id FROM xaa_marketero.contacts WHERE email=?",{},$_REQUEST->{email}) || 0;
    
    if ($exist){
        $dbh->do("INSERT IGNORE INTO xaa_marketero.contacts_stages (contact_id, stage_id, tag, dateline) VALUES (?, 30, 'NuevoRegistro', DATE_ADD(NOW(), INTERVAL 15 DAY))",{},
            $exist);

        $dbh->do("INSERT IGNORE INTO xaa_marketero.contacts_stages (contact_id, stage_id, tag, dateline) VALUES (?, 30, 'NuevoRegistro', DATE_ADD(NOW(), INTERVAL 15 DAY))",{},
            $exist);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'call', 'Llamar al cliente', 'Llamar al cliente para ponerse a la orden', CURDATE(), CURTIME())",{},
            $exist);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar primer email', 'Enviar un correo electrónico personalizado al prospecto, incluir ebook y mencionar el blog de marketero.', DATE_ADD(CURDATE(), INTERVAL 2 DAY), CURTIME())",{},
            $exist);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email uso de plataforma', 'Enviar un correo electrónico del uso general de la plataforma', DATE_ADD(CURDATE(), INTERVAL 4 DAY), CURTIME())",{},
            $exist);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email uso de LP', 'Enviar un correo electrónico del uso de los formularios', DATE_ADD(CURDATE(), INTERVAL 6 DAY), CURTIME())",{},
            $exist);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email uso de CRM', 'Enviar un correo electrónico del uso de el CRM', DATE_ADD(CURDATE(), INTERVAL 8 DAY), CURTIME())",{},
            $exist);
        
        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email uso de Email', 'Enviar un correo electrónico del uso de el email masivo', DATE_ADD(CURDATE(), INTERVAL 10 DAY), CURTIME())",{},
            $exist);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email solicitud sugerencias', 'Enviar un correo electrónico solicitando sugerencias y notificando el final de la version demo.', DATE_ADD(CURDATE(), INTERVAL 13 DAY), CURTIME())",{},
            $exist);

    }else{
        $dbh->do("INSERT IGNORE INTO xaa_marketero.contacts (email, name, phone, added_on, updated_on) VALUES (?, ?, ?, NOW(), NOW())",{}, $_REQUEST->{email}, $_REQUEST->{name}, $_REQUEST->{phone});

        my $contact_id = $dbh->last_insert_id('', '', 'xaa_marketero.contacts', 'contact_id');

        $dbh->do("INSERT IGNORE INTO xaa_marketero.contacts_stages (contact_id, stage_id, tag, dateline) VALUES (?, 30, 'NuevoRegistro', DATE_ADD(NOW(), INTERVAL 15 DAY))",{},
            $contact_id);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'call', 'Llamar al cliente', 'Llamar al cliente para ponerse a la orden', CURDATE(), CURTIME())",{},
            $contact_id);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar primer email', 'Enviar un correo electrónico personalizado al prospecto, incluir ebook y mencionar el blog de marketero.', DATE_ADD(CURDATE(), INTERVAL 2 DAY), CURTIME())",{},
            $contact_id);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email uso de plataforma', 'Enviar un correo electrónico del uso general de la plataforma', DATE_ADD(CURDATE(), INTERVAL 4 DAY), CURTIME())",{},
            $contact_id);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email uso de LP', 'Enviar un correo electrónico del uso de los formularios', DATE_ADD(CURDATE(), INTERVAL 6 DAY), CURTIME())",{},
            $contact_id);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email uso de CRM', 'Enviar un correo electrónico del uso de el CRM', DATE_ADD(CURDATE(), INTERVAL 8 DAY), CURTIME())",{},
            $contact_id);
        
        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email uso de Email', 'Enviar un correo electrónico del uso de el email masivo', DATE_ADD(CURDATE(), INTERVAL 10 DAY), CURTIME())",{},
            $contact_id);

        $dbh->do("INSERT INTO xaa_marketero.contacts_activities (contact_id, action, title, comments, action_date, action_time) "
                ."VALUES (?, 'email', 'Enviar email solicitud sugerencias', 'Enviar un correo electrónico solicitando sugerencias y notificando el final de la version demo.', DATE_ADD(CURDATE(), INTERVAL 13 DAY), CURTIME())",{},
            $contact_id);

    }

}

sub save_logo {
  my $results = {};

  Chapix::Com::conf_load("Xaa");

  my $current = $conf->{Xaa}->{Logo};

  my $logo = upload_file('logo', 'site');

  if($logo) {

    $dbh->do("UPDATE conf SET value='' WHERE module='Xaa' AND name='AccentColor'");
    $dbh->do("UPDATE conf SET value='' WHERE module='Xaa' AND name='AccentColorFont'");
    $dbh->do("UPDATE conf SET value='' WHERE module='Xaa' AND name='LogoBG'");
    $dbh->do("UPDATE conf SET value='' WHERE module='Xaa' AND name='LogoColors'");
    $dbh->do("UPDATE conf SET value='' WHERE module='Xaa' AND name='PrimaryColor'");
    $dbh->do("UPDATE conf SET value='' WHERE module='Xaa' AND name='PrimaryColorFont'");
    $dbh->do("UPDATE conf SET value='' WHERE module='Xaa' AND name='PrimaryComplement'");


    $dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='Logo'",{},$logo);
    unlink("data/".$_REQUEST->{Domain}."/img/site/".$current);

    eval {
      my $size_cmd = 'convert data/'.$_REQUEST->{Domain}.'/img/site/'.$logo.' -format "%w x %h" info:';
      my $size = `$size_cmd`;

      my ($w, $h) = split('x', $size);

      $w =~ s/ //g;
      $h =~ s/ //g;

      my $cmd1 = 'convert data/'.$_REQUEST->{Domain}.'/img/site/'.$logo.'[1x1+5+5] -format "%[fx:floor(255*u.r)],%[fx:floor(255*u.g)],%[fx:floor(255*u.b)],%[fx:u.a]" info:';
      my $cmd2 = 'convert data/'.$_REQUEST->{Domain}.'/img/site/'.$logo.'[1x1+'.($w-5).'+5] -format "%[fx:floor(255*u.r)],%[fx:floor(255*u.g)],%[fx:floor(255*u.b)],%[fx:u.a]" info:';
      my $cmd3 = 'convert data/'.$_REQUEST->{Domain}.'/img/site/'.$logo.'[1x1+5+'.($h-5).'] -format "%[fx:floor(255*u.r)],%[fx:floor(255*u.g)],%[fx:floor(255*u.b)],%[fx:u.a]" info:';
      my $cmd4 = 'convert data/'.$_REQUEST->{Domain}.'/img/site/'.$logo.'[1x1+'.($w-5).'+'.($h-5).'] -format "%[fx:floor(255*u.r)],%[fx:floor(255*u.g)],%[fx:floor(255*u.b)],%[fx:u.a]" info:';

      my $c1 = `$cmd1`;
      my $c2 = `$cmd2`;
      my $c3 = `$cmd3`;
      my $c4 = `$cmd4`;

      my ($r, $g, $b, $a) = split(',', $c1);

      if ($a >= 0 && $a < 1){
        # TRANSLUCENT BACKGROUND
        $conf->{Xaa}->{LogoBG} = 'transparent';
        $dbh->do("UPDATE conf SET value='transparent' WHERE module='Xaa' AND name='LogoBG'");
      } elsif($a == 1){
        # B/W
        my $rgb = new Color::Rgb(rgb_txt=>'Chapix/Xaa/tmpl/rgb.txt') or die 'error '.$!;
        my $color_hex = $rgb->rgb2hex($r,$g,$b);
        my $bw = getClosestColor($color_hex, qw/#ffffff #000000/);

        if ($bw eq '#ffffff') {
          $conf->{Xaa}->{LogoBG} = 'white';
          $dbh->do("UPDATE conf SET value='white' WHERE module='Xaa' AND name='LogoBG'");
        } elsif($bw eq '#000000') {
          $conf->{Xaa}->{LogoBG} = 'black';
          $dbh->do("UPDATE conf SET value='black' WHERE module='Xaa' AND name='LogoBG'");
        }
      }


      my $colores_prior_cmd = 'convert data/'.$_REQUEST->{Domain}.'/img/site/'.$logo.' -colors 16 -depth 8 -format "%c" histogram:info:|sort -rn|head -8';
      my @posibles = qx/$colores_prior_cmd/;
      my $colores = '';

      foreach my $linea (@posibles) {
        if ($linea =~ /#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/) {
          my $hex = $1;

          my $avoid_bg = getClosestColor($hex, qw/#FFFFFF #F44336 #E91E63 #9C27B0 #673AB7 #3F51B5 #2196F3 #03A9F4 #00BCD4 #009688 #4CAF50 #8BC34A #CDDC39 #FFEB3B #FFC107 #FF9800 #FF5722 #795548 #9E9E9E #607D8B #000000/);

          if ( ($avoid_bg eq '#000000') || ($avoid_bg eq '#FFFFFF') ){
            next;
          }

          $hex = getClosestColor($hex, qw/#F44336 #E91E63 #9C27B0 #673AB7 #3F51B5 #2196F3 #03A9F4 #00BCD4 #009688 #4CAF50 #8BC34A #CDDC39 #FFEB3B #FFC107 #FF9800 #FF5722 #795548 #9E9E9E #607D8B/);

          if ($colores =~ $hex) {
            next;
          }

          $colores .= "," if($colores);
          $colores .= $hex;

          Chapix::Com::conf_load('Xaa');

          #SAVING PRIMARY COLOR
          if (!$conf->{Xaa}->{PrimaryColor}){
            $dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='PrimaryColor'",{},$hex);
          }elsif ($conf->{Xaa}->{PrimaryColor} && !$conf->{Xaa}->{AccentColor}) {
            $dbh->do("UPDATE conf SET value=(SELECT accent_color FROM $conf->{Xaa}->{DB}.material_colors WHERE primary_color=?) WHERE module='Xaa' AND name='AccentColor'",{},$hex);
          }elsif(!$conf->{Xaa}->{AccentColor}){
            $dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='AccentColor'",{},$hex);
          }
        }
      }

      Chapix::Com::conf_load('Xaa');

      if(!$conf->{Xaa}->{PrimaryColor}){
        my $random_palette = $dbh->selectrow_hashref("SELECT * FROM $conf->{Xaa}->{DB}.material_colors ORDER BY RAND() LIMIT 1");

        $dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='PrimaryColor'",{},$random_palette->{primary_color});
        $dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='PrimaryColorFont'",{},$random_palette->{font_color});

        $dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='AccentColor'",{},$random_palette->{accent_color_b});
        $dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='AccentColorFont'",{},$random_palette->{accent_font_b});

        Chapix::Com::conf_load('Xaa');
      }

      #SAVING DARKER AND LIGHTEN COLORS
      if ($conf->{Xaa}->{LogoBG} eq 'black'){
        $dbh->do("UPDATE conf SET value=(SELECT primary_light FROM $conf->{Xaa}->{DB}.material_colors WHERE primary_color=?)
        WHERE module='Xaa' AND name='PrimaryComplement'",{},$conf->{Xaa}->{PrimaryColor});
      }else{
        $dbh->do("UPDATE conf SET value=(SELECT primary_dark FROM $conf->{Xaa}->{DB}.material_colors WHERE primary_color=?)
        WHERE module='Xaa' AND name='PrimaryComplement'",{},$conf->{Xaa}->{PrimaryColor});
      }

      # SAVING FONT COLORS
      $dbh->do("UPDATE conf SET value=(SELECT font_color FROM $conf->{Xaa}->{DB}.material_colors WHERE primary_color=?)
      WHERE module='Xaa' AND name='PrimaryColorFont'",{},$conf->{Xaa}->{PrimaryColor});

      $dbh->do("UPDATE conf SET value=(SELECT accent_font FROM $conf->{Xaa}->{DB}.material_colors WHERE primary_color=? AND accent_color=?)
      WHERE module='Xaa' AND name='AccentColorFont'",{},$conf->{Xaa}->{PrimaryColor}, $conf->{Xaa}->{AccentColor});

      if (!$conf->{Xaa}->{AccentColor}){
        $dbh->do("UPDATE conf SET value=(SELECT accent_color_a FROM $conf->{Xaa}->{DB}.material_colors WHERE primary_color=?)
        WHERE module='Xaa' AND name='AccentColor'",{},$conf->{Xaa}->{PrimaryColor});

        Chapix::Com::conf_load('Xaa');

        $dbh->do("UPDATE conf SET value=(SELECT accent_font_a FROM $conf->{Xaa}->{DB}.material_colors WHERE primary_color=? AND accent_color_a=?)
        WHERE module='Xaa' AND name='AccentColorFont'",{},$conf->{Xaa}->{PrimaryColor}, $conf->{Xaa}->{AccentColor});
      }

      if ( !$conf->{Xaa}->{AccentColorFont} ) {
        $dbh->do("UPDATE conf SET value=(SELECT accent_font_a FROM $conf->{Xaa}->{DB}.material_colors WHERE accent_color_a=? LIMIT 1)
        WHERE module='Xaa' AND name='AccentColorFont'",{}, $conf->{Xaa}->{AccentColor});
      }

      Chapix::Com::conf_load('Xaa');


      if (!$conf->{Xaa}->{AccentColorFont} ) {
        $dbh->do("UPDATE conf SET value='#FFFFFF' WHERE module='Xaa' AND name='AccentColorFont'",{});
      }

      $dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='LogoColors'",{},$colores) if($colores);

    };
    if ($@) {
      msg_add('danger', 'Error al obtener colores principales '.$@);
    }
  }

  $results->{success} = 1;
  $results->{redirect} = '/'.$_REQUEST->{Domain}.'/Xaa/EditLogo';
  return $results;
}

sub password_reset {
    my $results = {};

    my $user = $dbh->selectrow_hashref(
        "SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
	    "FROM $conf->{Xaa}->{DB}.xaa_users u " .
		"WHERE u.email=?",{},
        $_REQUEST->{email});

    if($user and $_REQUEST->{email}){
        # Actualizar DB.
        my $key = substr(sha384_hex($conf->{Security}->{key} . time() . 'PasswordReset'),10,20);

        $dbh->do("UPDATE $conf->{Xaa}->{DB}.xaa_users SET password_reset_expires=DATE_ADD(NOW(), INTERVAL 12 HOUR), password_reset_key=? WHERE user_id=?",{},
                 $key, $user->{user_id});

        # Enviar correo.
        my $Mail = Chapix::Mail::Controller->new();
        my $enviado = $Mail->html_template({
            to       => $user->{'email'},
            bcc      => 'cesarrodriguez@xaandia.com', 
            subject  => loc('Restablece tu contraseña de ') . $conf->{App}->{Name},
            template => {
                file => 'Chapix/Xaa/tmpl/password-reset-email.html',
                vars => {
                    name  => $user->{name},
                    email => $user->{email},
                    key   => $key,
                    loc   => \&loc,
                }
            }
        });

        # Reenviar a mensaje
        $results->{success} = 1;
        $results->{redirect} = '/Xaa/PasswordResetSent';
    }else{
        msg_add("danger",'Verifica tu dirección de correo.');
        $results->{error} = 1;
        $results->{redirect} = '/Xaa/PasswordReset';
    }
    return $results;
}


sub validate_password_reset_key {
    my $key = $_REQUEST->{key};
    my $email = $_REQUEST->{email};

    if ($email and length($key) == 20) {
        my $user_id = $dbh->selectrow_array(
            "SELECT user_id FROM $conf->{Xaa}->{DB}.xaa_users WHERE email=? AND password_reset_key=? AND password_reset_expires > NOW()",{},$email, $key) || 0;
        if ($user_id) {
            return $user_id;
        }
    }

    # To avoid bruteforce attacks cut the expiration time by 1 hour.
    $dbh->do("UPDATE $conf->{Xaa}->{DB}.xaa_users SET password_reset_expires=DATE_SUB(password_reset_expires, INTERVAL 1 HOUR) WHERE email=?",{},$email);
    return 0;
}

sub password_reset_update {
    my $results = {};

    my $user_id = validate_password_reset_key();

    if ($user_id) {
        # Actualizar DB.
        $dbh->do("UPDATE $conf->{Xaa}->{DB}.xaa_users SET password=? WHERE user_id=?",{},
                 sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}), $user_id);

        my $user = $dbh->selectrow_hashref("SELECT user_id, name, email FROM $conf->{Xaa}->{DB}.xaa_users WHERE user_id=?",{},$user_id);

        # Enviar correo.
        my $Mail = Chapix::Mail::Controller->new();
        my $enviado = $Mail->html_template({
            to       => $user->{'email'},
            subject  => "Tu contraseña de $conf->{App}->{Name} ha sido cambiada",
            template => {
                file => 'Chapix/Xaa/tmpl/password-reset-success-email.html',
                vars => {
                    name  => $user->{name},
                    email => $user->{email},
                    loc   => \&loc,
                }
            }
        });

        # Reenviar a mensaje
        $results->{success} = 1;
        $results->{redirect} = '/Xaa/PasswordResetSuccess';
    }else{
        msg_add('danger','Tu clave de recuperación de contraseña a caducado. Favor de intentar de nuevo.');
        $results->{error} = 1;
        $results->{redirect} = '/Xaa/PasswordReset';
    }
    return $results;
}

sub getClosestColor {
    my $color = shift;
    my @paleta = @_;
    
    if ($color !~ /ˆ#/) {
	$color = '#'.$color;
    }
    
    my $rgb = new Color::Rgb(rgb_txt=>'Chapix/Xaa/tmpl/rgb.txt') or die 'error '.$!;
    my $color_rgb = $rgb->hex2rgb($color, ',');
    
    my ($color_r, $color_g, $color_b)= split(',', $color_rgb);
    
    my @differenceArray = [];
    
    my @palette = @paleta;
    
    my $index = 0;
    foreach my $palette_color (@palette) {
	$palette_color = $palette_color;
	
	my $palette_rgb = new Color::Rgb(rgb_txt=>'Chapix/Xaa/tmpl/rgb.txt');
	my $pcolor_rgb = $palette_rgb->hex2rgb($palette_color, ',');
	
	my ($base_color_r, $base_color_g, $base_color_b)= split(',', $pcolor_rgb);
	
	push(@differenceArray, sqrt(
		 ($color_r - $base_color_r) * ($color_r - $base_color_r) +
		 ($color_g - $base_color_g) * ($color_g - $base_color_g) +
		 ($color_b - $base_color_b) * ($color_b - $base_color_b)
	     ));
	$index++;
    }
    
    my $lowest = min(@differenceArray);
    
    my $idx = 0;
    foreach my $palette_color (@differenceArray) {
	if ($palette_color eq $lowest) {
	    last;
	}
	$idx++;
    }
    
    return $palette[$idx-1];
}

sub process_paypal_ipn {
    my $HTML ;
    open (DEBUG, ">>data/PayPal-IPN.txt") or die "Can't open PayPal.txt file. $!";

    my $error  = '';
    my $status = '';
    my $txn_type    = $_REQUEST->{'txn_type'} || '';
    my $subscr_id   = $_REQUEST->{'subscr_id'} || '';
    my $verify_sign = $_REQUEST->{'verify_sign'} || '';
    my $item_number = $_REQUEST->{'item_number'} || '';
    my $domain_id   = $_REQUEST->{'custom'} || '';

    print DEBUG "$txn_type  -- $subscr_id  --  $verify_sign  --  $item_number  -- $domain_id\n";

    my $IPN = new Business::PayPal::IPN() or $error = Business::PayPal::IPN->error();
    eval { $status = $IPN->status();  };
    print DEBUG "Err -- $error \n";
    print DEBUG "Status -- $status \n";
    if ( !$error ) {
	print DEBUG "IPN completed\n";
	print DEBUG "TXTType  -- $txn_type \n";
	if($txn_type eq 'subscr_cancel'){
	    # Cancelar Subscripción
	    print DEBUG "Cancelando 1 \n";
	    
	    # Get the domain to update
	    my $domain = $dbh->selectrow_hashref("SELECT * FROM xaa.xaa_domains WHERE service_key=?",{},$subscr_id);
	    if(!$domain->{domain_id}){
		print CGI::header(-type=>'text/plain', -status=> '200 OK');
		exit 0;
	    }
	    $dbh->do("USE $domain->{database}");
	    print DEBUG "Cancelando 2 \n";
	    
	    # Balance
	    my $Balance = WSAdm::Balance->new($domain->{domain_id});
	    $Balance->charge(0, 'Cancelar Suscripción',$verify_sign);
	    print DEBUG "Cancelando 3 \n";
	    
	    # Master account options
	    $dbh->do(
		"UPDATE xaa.xaa_domains ".
                "SET is_free_account=1, license_type='', " .
		"next_bill_on=NULL, service_id=0, service_cycle='', service_price=0, service_payment_method_id=0  ".
		"WHERE domain_id=?",{},$domain->{domain_id});
	    print DEBUG "Cancelando 4 \n";
	    
	    # Domain options
	    WSAdm::Com::conf_set('EME', 'SendLimit', '20000');
	    WSAdm::Com::conf_set('EME', 'EmailsLimit', '500');
	    WSAdm::Com::conf_set('Site', 'IsFreeAccount', '1');
	    WSAdm::Com::conf_set('Site', 'Unbranded', '0');
	    WSAdm::Com::conf_set('Site', 'Service', '');
	    print DEBUG "Cancelando 1 \n";
	    $dbh->commit();
	}
	
	if($txn_type eq 'subscr_signup'){
	    # Activar Subscripción
	    print DEBUG "Activando subscripcion\n";
	    
	    # Get the domain to update
	    my $domain = $dbh->selectrow_hashref("SELECT * FROM xaa.xaa_domains WHERE domain_id=?",{},$domain_id);
	    if($domain->{domain_id}){
		$dbh->do("USE $domain->{database}");
		my $service = $dbh->selectrow_hashref("SELECT * FROM xaa.xaa_services WHERE code=?",{},$item_number);
	    
		print DEBUG "Activando subscripcion 2 \n";
		# Balance
		my $Balance = Chapix::Xaa::Balance->new($domain->{domain_id});
		$Balance->charge($service->{montly_price}, 'Suscripción '.$service->{service_name},$verify_sign);
		print DEBUG "Activando subscripcion 3 \n";        
		# Master account options
		$dbh->do(
		    "UPDATE xaa.xaa_domains ".
		    "SET payment_method_id=1, subscription=1, subscription_date=NOW(), subscription_cancel_date=NULL  ".
		    "WHERE domain_id=?",{},
		    $subscr_id, $domain->{domain_id});

		# Service data
		$dbh->do("INSERT INTO xaa_domains_services (domain_id, service_id, app_name, next_bill_on, service_cycle, price) VALUES(?,?,?,DATE_ADD(NOW(), INTERVAL 1 MONTH),?,?) ",
			 $domain->{domain_id}, $service->{service_id}, $service->{service_name}, 'MONTHLY',$service->{montly_price});
		

		print DEBUG "Activando subscripcion 4 \n";
		# Domain options

		print DEBUG "Activando subscripcion 5 \n";
		$dbh->commit();
	    }
	}
	
	if($txn_type eq 'subscr_payment'){
	    # Pago de Subscripción
	    print DEBUG "Registrando pago 1 \n";
	    # Get the domain to update
	    my $domain = $dbh->selectrow_hashref("SELECT * FROM xaa.xaa_domains WHERE service_key=?",{},$subscr_id);
	    if(!$domain->{domain_id}){
		print CGI::header();
		# print CGI::header(-type=>'text/plain', -status=> '200 OK');
		# exit 0;
	    }
	    $dbh->do("USE $domain->{database}");
	    
	    print DEBUG "Registrando pago 2 \n";
	    # Balance
	    my $Balance = WSAdm::Balance->new($domain->{domain_id});
	    $Balance->payment($domain->{service_price}, 'Pago Paypal',$verify_sign);
	    
	    print DEBUG "Registrando pago 3 \n";
	    
	    # Master account options
	    if($domain->{next_bill_on}){
		print DEBUG "Registrando pago 4 \n";
		
		$dbh->do(
		    "UPDATE xaa.xaa_domains ".
		    "SET next_bill_on=DATE_ADD(next_bill_on,INTERVAL 1 MONTH) WHERE domain_id=?",{},$domain->{domain_id});
	    }else{
		print DEBUG "Registrando pago 5 \n";
		
		$dbh->do(
		    "UPDATE xaa.xaa_domains ".
		    "SET next_bill_on=DATE_ADD(NOW(), INTERVAL 1 MONTH) WHERE domain_id=?",{},$domain->{domain_id});
	    }
	    $dbh->commit();
	    print DEBUG "Registrando pago 6 \n";
	    
	}
    }   
    
    
    
    
    print DEBUG "Error\n=========================================\n$error\n";
    $HTML .= "Error<br>======================================<br>$error<br>\n";
    print DEBUG "\n\n\nVARS\n=========================================\n";
    $HTML .= "<br><br><br>VARS<br>======================================<br>\n";
#    foreach my $key (keys %vars){
#	print DEBUG "$key = ".param($key) . "\n";
#	$HTML .= "$key = ".param($key) . "<br>\n";
#    }

    print DEBUG "\n\nENV\n=========================================\n";
    $HTML .= "<br><br>ENV<br>======================================<br>\n";
    foreach my $key (keys %ENV){
	print DEBUG "$key = ".$ENV{key} . "\n";
	$HTML .= "$key = ".$ENV{$key} . "<br>\n";
    }

    print DEBUG "\n=========================================\n\n\n\n\n";
    close DEBUG;

    #print WSAdm::Layout::print($HTML);

    print CGI::header(-type=>'text/plain', -status=> '200 OK');
    exit 0;
}

1;
