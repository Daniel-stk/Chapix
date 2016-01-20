package Chapix::Xaa::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);

use Chapix::Conf;
use Chapix::Com;
use Chapix::Xaa::View;
use Chapix::Mail::Controller;

# Language
use Chapix::Xaa::L10N;
my $lh = Chapix::Xaa::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

#
sub new {
    my $class = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;

    # Init app ENV
    $self->_init();

    return $self;
}

# Initialize ENV
sub _init {
    my $self = shift;
    $self->{main_db} = $conf->{Xaa}->{DB};
    $conf->{Domain} = $dbh->selectrow_hashref(
        "SELECT d.domain_id, d.name, d.folder, d.database, d.country_id, d.time_zone, d.language " .
	"FROM $self->{main_db}.xaa_domains d WHERE folder = ?",{},$_REQUEST->{Domain});
}

# Main display function, this function prints the required view.
sub display {
    my $self = shift;

    if($sess{user_id}){
        print Chapix::Com::header_out();
        if($_REQUEST->{View} eq 'YourAccount'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_your_account() );
        }elsif($_REQUEST->{View} eq 'ChangePassword'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_password_form() );
        }elsif($_REQUEST->{View} eq 'EditAccount'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_edit_account_form() );
        }elsif($_REQUEST->{View} eq 'Settings'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_settings() );
        }elsif($_REQUEST->{View} eq 'DomainSettings'){
            print Chapix::Layout::print( Chapix::Xaa::View::display_domain_settings() );
        }elsif($_REQUEST->{View} eq 'EditLogo'){
           print Chapix::Layout::print( Chapix::Xaa::View::display_logo_form() );
        }else{
            if($_REQUEST->{View}){
                print Chapix::Xaa::View::default();
            }else{
                print Chapix::Layout::print( Chapix::Xaa::View::display_home() );
            }
        }
    }else{
        # Validate if the user is logged in
        if($_REQUEST->{View} eq 'Login'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_login() );
            return;
        }elsif($_REQUEST->{View} eq 'Register'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_register() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordReset'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_password_reset() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordResetSent'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_password_reset_sent() );
            return;
        }elsif($_REQUEST->{View} eq 'PasswordResetCheck'){
            if ($self->validate_password_reset_key()) {
                print Chapix::Com::header_out();
                print Chapix::Layout::print( Chapix::Xaa::View::display_password_reset_form() );
                return;
            }else{
                msg_add('danger','Tu clave de recuperación de contraseña a caducado. Favor de intentar de nuevo.');
                http_redirect("/Xaa/PasswordReset");
            }
        }elsif($_REQUEST->{View} eq 'PasswordResetSuccess'){
            print Chapix::Com::header_out();
            print Chapix::Layout::print( Chapix::Xaa::View::display_password_reset_success() );
            return;
        }
        msg_add('warning',loc('To continue, log into your account.->' . " $_REQUEST->{Domain} - $_REQUEST->{Controller}  - $_REQUEST->{View} "));
        Chapix::Com::http_redirect('/Xaa/Login');
    }
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;

    if(defined $_REQUEST->{_submitted_login}){
        $self->login();
    }elsif(defined $_REQUEST->{_submitted_password_reset}){
        $self->password_reset();
    }elsif(defined $_REQUEST->{_submitted_password_reset_check}){
        $self->password_reset_update();
    }elsif($_REQUEST->{View} eq 'Logout'){
    	$self->logout();
    }elsif(defined $_REQUEST->{_submitted_domain_settings}){
        # Change domain settings
        $self->save_domain_settings();
    }elsif(defined $_REQUEST->{_submitted_change_password}){
        # Change password
        $self->save_new_password();
    }elsif(defined $_REQUEST->{_submitted_edit_account}){
        # Change account settings
        $self->save_account_settings();
    }elsif(defined $_REQUEST->{_submitted_user}){
        if($_REQUEST->{_submit} eq loc('Resset Password')){
            # Reset user password
            $self->reset_user_password();
        }elsif($_REQUEST->{_submit} eq loc('Delete')){
            # Delete user
            $self->delete_user();
        }else{
            # Save user data
            $self->save_user();
        }
    }elsif(defined $_REQUEST->{_submitted_register}){
    	#Register new account
    	$self->create_account();
    }elsif(defined $_REQUEST->{_submitted_upload_logo}){
    	$self->save_logo();
    }
}

sub login {
    my $self = shift;
    my $user = $dbh->selectrow_hashref(
        "SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
	    "FROM $self->{main_db}.xaa_users u " .
        "WHERE u.email=? AND u.password=?",{},
        $_REQUEST->{email}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}));

    if($user and $_REQUEST->{email}){
        # Write session data and redirect to index
    	   $sess{user_id}    = "$user->{user_id}";
        $sess{user_name}  = "$user->{name}";
        $sess{user_email} = "$user->{email}";
        $sess{user_time_zone} = "$user->{time_zone}";
        $sess{user_language}  = "$user->{language}";

	my $domain_id = $dbh->selectrow_array("SELECT domain_id FROM $self->{main_db}.xaa_users_domains WHERE user_id=? AND active=1 ORDER BY default_domain DESC, added_on LIMIT 1 ",{},$user->{user_id}) || 0;
	if($domain_id){
	    my $domain = $dbh->selectrow_hashref("SELECT name, folder FROM $self->{main_db}.xaa_domains WHERE domain_id=? ",{},$domain_id);
	    Chapix::Com::http_redirect('/'.$domain->{folder});
	}else{
            msg_add('warning',loc('Your account is not linked to any business account.'));
        }
        Chapix::Com::http_redirect('/Xaa/Login');
    }else{
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
        msg_add("warning","Email or password incorrect.");
        Chapix::Com::http_redirect('/Xaa/Login?email='.$_REQUEST->{email});
        # if ($failed_logins > 3) {
        #     msg_add("danger","You have " . (10 - $failed_logins) . " attemps left before being blocked.");
        # }
    }
}

sub logout {
    my $self = shift;

    $sess{user_id}        = "";
    $sess{user_name}      = "";
    $sess{user_email}     = "";
    $sess{user_time_zone} = "";
    $sess{user_language}  = "";

    Chapix::Com::http_redirect('/');
}

sub save_new_password {
    my $self = shift;
    my $current_password = $dbh->selectrow_array("SELECT u.password FROM $self->{main_db}.xaa_users u WHERE u.user_id=?",{},$sess{user_id}) || '';
    my $new_password = sha384_hex($conf->{Security}->{key} . $_REQUEST->{new_password});

    # Old password match?
    if($current_password ne sha384_hex($conf->{Security}->{key} . $_REQUEST->{current_password})){
        msg_add('warning',loc('Current password does not match'));
        return '';
    }

    # new passwords match?
    if($_REQUEST->{new_password} ne $_REQUEST->{new_password_repeat}){
        msg_add('warning', loc('The "New password" and "Repeat new password" fields must match'));
        return '';
    }

    eval {
        $dbh->do("UPDATE $self->{main_db}.xaa_users u SET u.password=? WHERE u.user_id=?",{},
                 $new_password, $sess{user_id});
    };
    if($@){
        msg_add('danger',$@);
    }else{
        msg_add('success',loc('Password successfully updated'));
        http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/YourAccount');
    }
}

sub save_domain_settings {
    my $self = shift;
    eval {
        $dbh->do("UPDATE $self->{main_db}.xaa_domains d SET d.name=?, d.time_zone=?, d.language=? WHERE d.domain_id=?",{},
                 $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $conf->{Domain}->{domain_id});
    };
    if($@){
        msg_add('danger',$@);
    }else{
        msg_add('success',loc('Business account updated'));
        http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Settings');
    }
}


sub save_account_settings {
    my $self = shift;
    eval {
        $dbh->do("UPDATE $self->{main_db}.xaa_users u SET u.name=?, u.time_zone=?, u.language=? WHERE u.user_id=?",{},
                 $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $sess{user_id});
        $sess{user_name}      = $_REQUEST->{name};
        $sess{user_time_zone} = $_REQUEST->{time_zone};
        $sess{user_language}  = $_REQUEST->{language};
    };
    if($@){
        msg_add('danger',$@);
    }else{
        msg_add('success',loc('Account successfully updated'));
        http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/YourAccount');
    }
}


sub create_account {
    my $self = shift;

    # email validation
    if($_REQUEST->{email} !~ /^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/){
    	msg_add('warning',loc('Please enter a valid email address'));
    	return '';
    }

    my $exist = $dbh->selectrow_hashref(
    	"SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
    	"FROM $self->{main_db}.xaa_users u " .
    	"WHERE u.email=?",{},
    	$_REQUEST->{email});

    if($exist){
    	msg_add("warning", loc("This email already exist"));
    	return '';
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
    my $exist_folder_on_db = $dbh->selectrow_array("SELECT COUNT(*) FROM $self->{main_db}.xaa_domains WHERE folder=?",{},$domain_to_use) || 0;
    my $exist_folder_on_fs = (-e('data/'.$domain_to_use));
    my $exist_db = $dbh->selectrow_array("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?",{},'xaa_'.$domain_to_use) || 0;

    if($exist_folder_on_db or $exist_folder_on_fs or $exist_db){
    	foreach my $it(1 .. 9999999){
    	    my $current_domain_to_use = $domain_to_use . $it;
    	    $exist_folder_on_db = $dbh->selectrow_array("SELECT COUNT(*) FROM $self->{main_db}.xaa_domains WHERE folder=?",{},$current_domain_to_use) || 0;
    	    $exist_folder_on_fs = (-e('data/'.$current_domain_to_use));
    	    $exist_db = $dbh->selectrow_array("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?",{},'xaa_'.$current_domain_to_use) || 0;
    	    if(!$exist_folder_on_db and !$exist_folder_on_fs and !$exist_db){
        		$domain_to_use = $current_domain_to_use;
        		last;
    	    }
    	}
    }

    # User creation
    my $password = $_REQUEST->{password};
    $dbh->do("INSERT INTO $self->{main_db}.xaa_users (name, email, time_zone, language, password, last_login_on) VALUES(?,?,?,?,?,NOW())",{},
	     $_REQUEST->{name}, $_REQUEST->{email}, $conf->{App}->{TimeZone}, $conf->{App}->{Language}, sha384_hex($conf->{Security}->{key} . $password) );
    my $user_id = $dbh->last_insert_id('','',"$self->{main_db}.xaa_users",'user_id');

    $dbh->do("INSERT INTO $self->{main_db}.xaa_domains (`name`, `folder`, `database`) VALUES (?,?,?)",{}, ucfirst($domain_to_use), $domain_to_use, 'xaa_'.$domain_to_use);
    my $domain_id = $dbh->last_insert_id('','',"$self->{main_db}.xaa_domains",'domain_id');

    $dbh->do("INSERT IGNORE INTO $self->{main_db}.xaa_users_domains (user_id, domain_id, added_by, added_on, active, default_domain) VALUES (?,?,1,NOW(),1,1)",{},$user_id, $domain_id);

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
        subject  => $conf->{App}->{Name} . ': '. loc('Your new account is ready'),
        template => {
            file => 'Chapix/Xaa/tmpl/account-creation-letter.html',
            vars => {
                name     => $_REQUEST->{'name'},
                email    => $_REQUEST->{email},
                password => $password,
                loc => \&loc,
            }
        }
    });

    # Welcome msg
    msg_add('success','Tu cuenta fue creada con éxito.');

    # Redirect to personal homepage
    http_redirect("/$domain_to_use/");
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

sub save_logo {
    my $self = shift;

    Chapix::Com::conf_load("Xaa");

    my $current = $conf->{Xaa}->{Logo};

    my $logo = upload_logo('logo', 'site');

    if($logo) {
    	$dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='Logo'",{},$logo);

        my $comando = 'convert data/'.$_REQUEST->{Domain}.'/site/'.$logo.' -colors 16 -depth 8 -format "%c" histogram:info: | sort -r -k 1 | head -n 3';
        my @posibles = `$comando`;
        my $colores = '';

        foreach my $linea (@posibles) {
            if ($linea =~ /#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/) {
            	my $hex = $1;
            	$colores .= "," if($colores);
            	$colores .= '#'.$hex
            }
        }

    	$dbh->do("UPDATE conf SET value=? WHERE module='Xaa' AND name='LogoColors'",{},$colores) if($colores);

    	unlink("data/".$_REQUEST->{Domain}."/site/".$current);
    }

    http_redirect("/".$_REQUEST->{Domain}."/Xaa/EditLogo");
}

sub password_reset {
    my $self = shift;
    my $user = $dbh->selectrow_hashref(
        "SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
	    "FROM $self->{main_db}.xaa_users u " .
		"WHERE u.email=?",{},
        $_REQUEST->{email});

    if($user and $_REQUEST->{email}){
        # Actualizar DB.
        my $key = substr(sha384_hex($conf->{Security}->{key} . time() . 'PasswordReset'),10,20);
        $dbh->do("UPDATE $self->{main_db}.xaa_users SET password_reset_expires=DATE_ADD(NOW(), INTERVAL 12 HOUR), password_reset_key=? WHERE user_id=?",{},
                 $key, $user->{user_id});

        # Enviar correo.
        my $Mail = Chapix::Mail::Controller->new();
        my $enviado = $Mail->html_template({
            to       => $user->{'email'},
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
        http_redirect("/Xaa/PasswordResetSent");
    }else{
        msg_add("danger",'Verifica tu dirección de correo.');
    }
}

sub validate_password_reset_key {
    my $self = shift;
    my $key = $_REQUEST->{key};
    my $email = $_REQUEST->{email};
    if ($email and length($key) == 20) {
        my $user_id = $dbh->selectrow_array(
            "SELECT user_id FROM $self->{main_db}.xaa_users WHERE email=? AND password_reset_key=? AND password_reset_expires > NOW()",{},$email, $key) || 0;
        if ($user_id) {
            return $user_id;
        }
    }

    # To avoid bruteforce attacks cut the expiration time by 1 hour.
    $dbh->do("UPDATE $self->{main_db}.xaa_users SET password_reset_expires=DATE_SUB(password_reset_expires, INTERVAL 1 HOUR) WHERE email=?",{},$email);
    return 0;
}

sub password_reset_update {
    my $self = shift;
    my $user_id = $self->validate_password_reset_key();
    if ($user_id) {
        # Actualizar DB.
        $dbh->do("UPDATE $self->{main_db}.xaa_users SET password=? WHERE user_id=?",{},
                 sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}), $user_id);

        my $user = $dbh->selectrow_hashref("SELECT user_id, name, email FROM $self->{main_db}.xaa_users WHERE user_id=?",{},$user_id);

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
        http_redirect("/Xaa/PasswordResetSuccess");
    }else{
        msg_add('danger','Tu clave de recuperación de contraseña a caducado. Favor de intentar de nuevo.');
        http_redirect("/Xaa/PasswordReset");
    }
}

1;
