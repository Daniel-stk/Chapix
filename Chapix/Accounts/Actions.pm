package Chapix::Accounts::Actions;

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
use Chapix::Accounts::L10N;
my $lh = Chapix::Accounts::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }


sub login {
    my $results = {};

    my $user = $dbh->selectrow_hashref(
        "SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
	    "FROM users u " .
        "WHERE u.email=? AND u.password=?",{},
        $_REQUEST->{email}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}));

    if($user and $_REQUEST->{email}){
        # Write session data and redirect to index
    	$sess{user_id}    = "$user->{user_id}";
        $sess{user_name}  = "$user->{name}";
        $sess{user_email} = "$user->{email}";
        $sess{user_time_zone} = "$user->{time_zone}";
        $sess{user_language}  = "$user->{language}";

        $dbh->do("UPDATE users SET last_login_on=NOW() WHERE user_id=?",{},$user->{user_id});

        $results->{success} = 1;
        return $results;
    }else{
    	$results->{error} = 1;
    	$results->{redirect} = '/Accounts/Login?email='.$_REQUEST->{email};
        return $results;
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

    my $current_password = $dbh->selectrow_array("SELECT u.password FROM users u WHERE u.user_id=?",{},$sess{user_id}) || '';
    my $new_password = sha384_hex($conf->{Security}->{key} . $_REQUEST->{new_password});
    
    # Old password match?
    if($current_password ne sha384_hex($conf->{Security}->{key} . $_REQUEST->{current_password})){
        msg_add('warning',loc('El password actual es incorrecto.'));
        $results->{error} = 1;
        $results->{redirect} = '/Accounts/ChangePassword';
        return $results;
    }

    # new passwords match?
    if($_REQUEST->{new_password} ne $_REQUEST->{new_password_repeat}){
        msg_add('warning', loc('Las contraseñas deben de coincidir'));
        $results->{error} = 1;
        $results->{redirect} = '/Accounts/ChangePassword';
        return $results;
    }

    eval {
        $dbh->do("UPDATE users u SET u.password=? WHERE u.user_id=?",{},
                 $new_password, $sess{user_id});
    };
    if($@){    	
        msg_add('danger',$@);
        $results->{error} = 1;
        $results->{redirect} = '/Accounts/ChangePassword';    
    }else{
        msg_add('success',loc('Contraseña actualizada satisfactoriamente'));
        $results->{success} = 1;
        $results->{redirect} = '/Accounts/YourAccount';
    }
    return $results;
}

sub save_account_settings {
    my $results = {};

    eval {
        $dbh->do("UPDATE users u SET u.name=?, u.time_zone=?, u.language=? WHERE u.user_id=?",{},
                 $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $sess{user_id});
        $sess{user_name}      = $_REQUEST->{name};
        $sess{user_time_zone} = $_REQUEST->{time_zone};
        $sess{user_language}  = $_REQUEST->{language};
    };
    if($@){
        msg_add('danger',$@);
        $results->{error} = 1;
        $results->{redirect} = '/Accounts/YourAccount';         
    }else{
        msg_add('success',loc('Datos actualizados correctamente'));
        $results->{success} = 1;
         $results->{redirect} = '/Accounts/YourAccount';
    }
   return $results;
}


sub create_account {
    my $results = {};

    # email validation
    if($_REQUEST->{email} !~ /^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/){
    	msg_add('warning',loc('Please enter a valid email address'));
    	$results->{error} = 1;
    	$results->{redirect} = '/Accounts/Register';
    	return $results;
    }

    my $exist = $dbh->selectrow_hashref(
    	"SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
    	"FROM users u " .
    	"WHERE u.email=?",{},
    	$_REQUEST->{email});

    if($exist){
    	msg_add("warning", loc("El correo electrónico ya esta registrado"));
    	$results->{error} = 1;
    	$results->{redirect} = '/Accounts/Register';
    	return $results;
    }

    # User creation
    my $password = 'M'.substr(sha384_hex(time().$_REQUEST->{email}), 0, 8).'!';

    $dbh->do("INSERT INTO users (name, email, time_zone, language, password, last_login_on) VALUES(?,?,?,?,?,NOW())",{},
	     $_REQUEST->{name}, $_REQUEST->{email}, $conf->{App}->{TimeZone}, $conf->{App}->{Language}, sha384_hex($conf->{Security}->{key} . $password) );
    my $user_id = $dbh->last_insert_id('','',"users",'user_id');

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
        bcc      => 'ventas@xaandia.com, davidromero@xaandia.com, cesarrodriguez@xaandia.com', 
        subject  => $conf->{App}->{Name} . ': '. loc('Tu cuenta esta lista'),
        template => {
            file => 'Chapix/Accounts/tmpl/account-creation-letter.html',
            vars => {
                name     => format_short_name($_REQUEST->{'name'}),
                email    => $_REQUEST->{email},
                password => $password,
                loc => \&loc,
            }
        }
    });


    # Welcome msg
    msg_add('success','Tu cuenta fue creada con éxito.');
    msg_add('success','Recibirás un correo electrónico con tus datos de acceso.');
    
    # Redirect to personal homepage
    $results->{success} = 1;
    $results->{redirect} = '/Accounts/Welcome';
    return $results;
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
            file => 'Chapix/Accounts/tmpl/account-welcome-letter.html',
            vars => {
                name => format_short_name($name),
                loc => \&loc,
            }
        }
    });

}

sub password_reset {
    my $results = {};

    my $user = $dbh->selectrow_hashref(
        "SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
	    "FROM users u " .
		"WHERE u.email=?",{},
        $_REQUEST->{email});

    if($user and $_REQUEST->{email}){
        # Actualizar DB.
        my $key = substr(sha384_hex($conf->{Security}->{key} . time() . 'PasswordReset'),10,20);

        $dbh->do("UPDATE users SET password_reset_expires=DATE_ADD(NOW(), INTERVAL 12 HOUR), password_reset_key=? WHERE user_id=?",{},
                 $key, $user->{user_id});

        # Enviar correo.
        my $Mail = Chapix::Mail::Controller->new();
        my $enviado = $Mail->html_template({
            to       => $user->{'email'},
            bcc      => 'cesarrodriguez@xaandia.com', 
            subject  => loc('Restablece tu contraseña de ') . $conf->{App}->{Name},
            template => {
                file => 'Chapix/Accounts/tmpl/password-reset-email.html',
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
        $results->{redirect} = '/Accounts/PasswordResetSent';
    }else{
        msg_add("danger",'Verifica tu dirección de correo.');
        $results->{error} = 1;
        $results->{redirect} = '/Accounts/PasswordReset';
    }
    return $results;
}


sub validate_password_reset_key {
    my $key = $_REQUEST->{key};
    my $email = $_REQUEST->{email};

    if ($email and length($key) == 20) {
        my $user_id = $dbh->selectrow_array(
            "SELECT user_id FROM users WHERE email=? AND password_reset_key=? AND password_reset_expires > NOW()",{},$email, $key) || 0;
        if ($user_id) {
            return $user_id;
        }
    }

    # To avoid bruteforce attacks cut the expiration time by 1 hour.
    $dbh->do("UPDATE users SET password_reset_expires=DATE_SUB(password_reset_expires, INTERVAL 1 HOUR) WHERE email=?",{},$email);
    return 0;
}

sub password_reset_update {
    my $results = {};

    my $user_id = validate_password_reset_key();

    if ($user_id) {
        # Actualizar DB.
        $dbh->do("UPDATE users SET password=? WHERE user_id=?",{},
                 sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}), $user_id);

        my $user = $dbh->selectrow_hashref("SELECT user_id, name, email FROM users WHERE user_id=?",{},$user_id);

        # Enviar correo.
        my $Mail = Chapix::Mail::Controller->new();
        my $enviado = $Mail->html_template({
            to       => $user->{'email'},
            subject  => "Tu contraseña de $conf->{App}->{Name} ha sido cambiada",
            template => {
                file => 'Chapix/Accounts/tmpl/password-reset-success-email.html',
                vars => {
                    name  => $user->{name},
                    email => $user->{email},
                    loc   => \&loc,
                }
            }
        });

        # Reenviar a mensaje
        $results->{success} = 1;
        $results->{redirect} = '/Accounts/PasswordResetSuccess';
    }else{
        msg_add('danger','Tu clave de recuperación de contraseña a caducado. Favor de intentar de nuevo.');
        $results->{error} = 1;
        $results->{redirect} = '/Accounts/PasswordReset';
    }
    return $results;
}

1;
