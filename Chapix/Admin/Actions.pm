package Chapix::Admin::Actions;

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

use Chapix::Conf;
use Chapix::Com;

# Language
use Chapix::Admin::L10N;
my $lh = Chapix::Admin::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }


sub login {
    my $results = {};

    my $account = $dbh->selectrow_hashref(
        "SELECT a.account_id, a.email, a.name, a.time_zone, a.language " .
        "FROM accounts a " .
#        "WHERE a.email=? AND is_admin=1",{},
#        $_REQUEST->{email});
        "WHERE a.email=? AND a.password=? and is_admin=1",{},
        $_REQUEST->{email}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}));

    if($account and $_REQUEST->{email}){
        # Write session data and redirect to index
    	$sess{account_id}    = "$account->{account_id}";
        $sess{account_name}  = "$account->{name}";
        $sess{account_email} = "$account->{email}";
        $sess{account_time_zone} = "$account->{time_zone}";
        $sess{account_language}  = "$account->{language}";

        $dbh->do("UPDATE accounts SET last_login_on=NOW() WHERE account_id=?",{},$account->{account_id});
    	$results->{redirect} = '/Admin';
        $results->{success} = 1;
        return $results;
    }else{
        msg_add('danger','Correo o contraseña incorrecto.');
    	$results->{error} = 1;
    	$results->{redirect} = '/Admin/Login?email='.$_REQUEST->{email};
        return $results;
    }
}

sub logout {
    my $results = {};

    $sess{account_id}        = "";
    $sess{account_name}      = "";
    $sess{account_email}     = "";
    $sess{account_time_zone} = "";
    $sess{account_language}  = "";

    $results->{error} = 1;
    $results->{redirect} = '/';
    return $results;
}

sub save_new_password {
    my $results = shift;

    my $current_password = $dbh->selectrow_array("SELECT a.password FROM accounts a WHERE a.account_id=?",{},$sess{account_id}) || '';
    my $new_password = sha384_hex($conf->{Security}->{key} . $_REQUEST->{new_password});
    
    # Old password match?
    if($current_password ne sha384_hex($conf->{Security}->{key} . $_REQUEST->{current_password})){
        msg_add('warning',loc('El password actual es incorrecto.'));
        $results->{error} = 1;
        $results->{redirect} = '/Admin/ChangePassword';
        return $results;
    }

    # new passwords match?
    if($_REQUEST->{new_password} ne $_REQUEST->{new_password_repeat}){
        msg_add('warning', loc('Las contraseñas deben de coincidir'));
        $results->{error} = 1;
        $results->{redirect} = '/Admin/ChangePassword';
        return $results;
    }

    eval {
        $dbh->do("UPDATE accounts a SET a.password=? WHERE a.account_id=?",{},
                 $new_password, $sess{account_id});
    };
    if($@){    	
        msg_add('danger',$@);
        $results->{error} = 1;
        $results->{redirect} = '/Admin/ChangePassword';    
    }else{
        msg_add('success',loc('Contraseña actualizada satisfactoriamente'));
        $results->{success} = 1;
        $results->{redirect} = '/Admin/YourAccount';
    }
    return $results;
}

sub save_account_settings {
    my $results = {};

    eval {
        $dbh->do("UPDATE accounts a SET a.name=?, a.time_zone=?, a.language=? WHERE a.account_id=?",{},
                 $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $sess{account_id});
        $sess{account_name}      = $_REQUEST->{name};
        $sess{account_time_zone} = $_REQUEST->{time_zone};
        $sess{account_language}  = $_REQUEST->{language};
    };
    if($@){
        msg_add('danger',$@);
        $results->{error} = 1;
        $results->{redirect} = '/Admin/YourAccount';         
    }else{
        msg_add('success',loc('Datos actualizados correctamente'));
        $results->{success} = 1;
         $results->{redirect} = '/Admin/YourAccount';
    }
   return $results;
}

sub password_reset {
    my $results = {};

    my $account = $dbh->selectrow_hashref(
        "SELECT a.account_id, a.email, a.name, a.time_zone, a.language " .
	    "FROM accounts a " .
		"WHERE a.email=?",{},
        $_REQUEST->{email});

    if($account and $_REQUEST->{email}){
        # Actualizar DB.
        my $key = substr(sha384_hex($conf->{Security}->{key} . time() . 'PasswordReset'),10,20);

        $dbh->do("UPDATE accounts SET password_reset_expires=DATE_ADD(NOW(), INTERVAL 12 HOUR), password_reset_key=? WHERE account_id=?",{},
                 $key, $account->{account_id});

        # Enviar correo.
        my $Mail = Chapix::Mail::Controller->new();
        my $enviado = $Mail->html_template({
            to       => $account->{'email'},
            bcc      => 'cesarrodriguez@xaandia.com', 
            subject  => loc('Restablece tu contraseña de ') . $conf->{App}->{Name},
            template => {
                file => 'Chapix/Admin/tmpl/password-reset-email.html',
                vars => {
                    name  => $account->{name},
                    email => $account->{email},
                    key   => $key,
                    loc   => \&loc,
                }
            }
        });

        # Reenviar a mensaje
        $results->{success} = 1;
        $results->{redirect} = '/Admin/PasswordResetSent';
    }else{
        msg_add("danger",'Verifica tu dirección de correo.');
        $results->{error} = 1;
        $results->{redirect} = '/Admin/PasswordReset';
    }
    return $results;
}


sub validate_password_reset_key {
    my $key = $_REQUEST->{key};
    my $email = $_REQUEST->{email};

    if ($email and length($key) == 20) {
        my $account_id = $dbh->selectrow_array(
            "SELECT account_id FROM accounts WHERE email=? AND password_reset_key=? AND password_reset_expires > NOW()",{},$email, $key) || 0;
        if ($account_id) {
            return $account_id;
        }
    }

    # To avoid bruteforce attacks cut the expiration time by 1 hour.
    $dbh->do("UPDATE accounts SET password_reset_expires=DATE_SUB(password_reset_expires, INTERVAL 1 HOUR) WHERE email=?",{},$email);
    return 0;
}

sub password_reset_update {
    my $results = {};

    my $account_id = validate_password_reset_key();

    if ($account_id) {
        # Actualizar DB.
        $dbh->do("UPDATE accounts SET password=? WHERE account_id=?",{},
                 sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}), $account_id);

        my $account = $dbh->selectrow_hashref("SELECT account_id, name, email FROM accounts WHERE account_id=?",{},$account_id);

        # Enviar correo.
        my $Mail = Chapix::Mail::Controller->new();
        my $enviado = $Mail->html_template({
            to       => $account->{'email'},
            subject  => "Tu contraseña de $conf->{App}->{Name} ha sido cambiada",
            template => {
                file => 'Chapix/Admin/tmpl/password-reset-success-email.html',
                vars => {
                    name  => $account->{name},
                    email => $account->{email},
                    loc   => \&loc,
                }
            }
        });

        # Reenviar a mensaje
        $results->{success} = 1;
        $results->{redirect} = '/Admin/PasswordResetSuccess';
    }else{
        msg_add('danger','Tu clave de recuperación de contraseña a caducado. Favor de intentar de nuevo.');
        $results->{error} = 1;
        $results->{redirect} = '/Admin/PasswordReset';
    }
    return $results;
}

sub save_admin{
    my $results = {};

    eval {

        my $activo = 0;
        $activo = 1 if ($_REQUEST->{active});

        my $is_admin = 0;
        $is_admin = 1 if ($_REQUEST->{is_admin});

        if ($_REQUEST->{_submit} eq 'Guardar'){
            if ($_REQUEST->{account_id}){
                $dbh->do("UPDATE accounts SET name=?, is_admin=?, active=? WHERE account_id=?",{}, $_REQUEST->{name}, $is_admin, $activo, $_REQUEST->{account_id});
            }else{
                my $password = substr(sha384_hex(time().$_REQUEST->{email}), 0, 8).'!';
                $dbh->do("INSERT INTO accounts (name, email, password, is_admin, active) VALUES (?, ?, ?, ?, ?)",{}, $_REQUEST->{name}, $_REQUEST->{email},
                         sha384_hex($conf->{Security}->{key} . $password), $is_admin, $activo);

                # Enviar correo.
                 my $Mail = Chapix::Mail::Controller->new();
                 my $enviado = $Mail->html_template({
                     to       => $_REQUEST->{email},
                     from     => $conf->{Mail}->{From},
                     subject  => format_short_name($sess{account_name}). " te agrego a ".$conf->{App}->{Name},
                     template => {
                         file => 'Chapix/Admin/tmpl/user-creation-letter.html',
                         vars => {
                             conf  => $conf,
                             creator_name => $sess{account_name},
                             name  => $_REQUEST->{name},
                             email => $_REQUEST->{email},
                             password => $password,
                             loc   => \&loc,
                         }
                     }});
            }
        }elsif ($_REQUEST->{_submit} eq 'Eliminar'){
            $dbh->do("DELETE FROM accounts WHERE account_id=?",{},$_REQUEST->{account_id});
        }
    };
    if ($@){
        msg_add('danger', 'Hubo un error al guardar los datos '.$@);
        $results->{redirect} = '/Admin/Admins';
    }else{
        msg_add('success', 'Datos guardados.');
        $results->{redirect} = '/Admin/Admins';
    }

    return $results;
}


1;


