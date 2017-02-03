package Chapix::Accounts::API;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex sha1_hex);

use Chapix::Conf;
use Chapix::Com;

# Language
use Chapix::Accounts::L10N;
my $lh = Chapix::Accounts::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub signup {
    my $JSON = shift;
    # email validation
    $_REQUEST->{email} = lc($_REQUEST->{email});
    
    if($_REQUEST->{email} !~ /^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/){
    	$JSON->{msg} = loc('Please enter a valid email address');
    	$JSON->{error} = 1;
    	return $JSON;
    }

    my $exist = $dbh->selectrow_hashref(
        "SELECT a.account_id, a.email, a.name, a.time_zone, a.language " .
        "FROM accounts a " .
        "WHERE a.email=?",{},
        $_REQUEST->{email});

    if($exist){
        $JSON->{msg} = loc("El correo electrónico ya esta registrado.");
    	$JSON->{error} = 1;
    	return $JSON;
    }

    # Account creation
    eval {
        $dbh->do("INSERT INTO accounts (name, email, phone, time_zone, language, password, last_login_on) VALUES(?,?,?,?,?,?,NOW())",{},
                 $_REQUEST->{name}, $_REQUEST->{email}, ($_REQUEST->{phone} || ''), $conf->{App}->{TimeZone}, $conf->{App}->{Language}, sha384_hex($conf->{Security}->{key} . $_REQUEST->{password}) );
        my $account_id = $dbh->last_insert_id('','',"accounts",'account_id');
        
        my $request_token = sha1_hex($conf->{Security}->{Key} . time() . rand(999) . $_REQUEST->{device_id});
        my $exist = int($dbh->do("UPDATE devices SET last_request_on=NOW(), request_token=?, push_token=? WHERE device_id=? AND account_id=?",{},
                                 $request_token, $_REQUEST->{push_token}, $_REQUEST->{device_id}, $account_id));
        if(!$exist){
            $dbh->do("INSERT INTO devices(device_id, account_id, added_on, last_request_on, platform, request_token, push_token) VALUES(?,?,NOW(),NOW(),?,?,?)",{},
                     $_REQUEST->{device_id}, $account_id, $_REQUEST->{platform}, $request_token, $_REQUEST->{push_token});
        }
        my $account = $dbh->selectrow_hashref("SELECT account_id, name, email, time_zone, language FROM accounts WHERE account_id=?",{},$account_id);
        $JSON->{data} = $account;
        $JSON->{data}->{request_token} = $request_token;
    };
    if ($@) {
        $JSON->{error} = 1;
        $JSON->{msg} = $@;
        return $JSON;
    }

    # # # Send Welcome Email
    # # my $Mail = Chapix::Mail::Controller->new();
    # # my $enviado = $Mail->html_template({
    # #     to       => $_REQUEST->{'email'},
    # #     bcc      => 'davidromero@xaandia.com', 
    # #     subject  => $conf->{App}->{Name} . ': '. loc('Tu cuenta esta lista'),
    # #     template => {
    # #         file => 'Chapix/Accounts/tmpl/account-creation-letter.html',
    # #         vars => {
    # #             name     => format_short_name($_REQUEST->{'name'}),
    # #             email    => $_REQUEST->{email},
    # #             password => $password,
    # #             loc => \&loc,
    # #         }
    # #     }
    # # });

    # Welcome msg
    $JSON->{msg} = 'Tu cuenta fue creada con éxito. ' .
        'Recibirás un correo electrónico con tus datos de acceso.';
    
    return $JSON;	
}

sub password_reset {
    my $JSON = shift;
    $_REQUEST->{email} = lc($_REQUEST->{email});
    eval {
        my $user = $dbh->selectrow_hashref("SELECT account_id, name, email FROM accounts WHERE email=?",{},$_REQUEST->{email});
        
        if($user and $_REQUEST->{email}){
            # Actualizar DB.
            my $key = substr(sha384_hex($conf->{Security}->{Key}.time().'PasswordReset'), 10, 20);
            
            $dbh->do("UPDATE accounts SET password_reset_expires=DATE_ADD(NOW(), INTERVAL 12 HOUR), password_reset_key=? WHERE account_id=?",{},$key, $user->{account_id});
            
            # Enviar correo.
            my $Mail = Chapix::Mail::Controller->new();
            my $enviado = $Mail->html_template({
                to       => $user->{'email'},
                subject  => $conf->{App}->{Name} . ' - ' . 'Recuperar contraseña',
                template => {
                    file => 'Chapix/Accounts/tmpl/password-reset-email.html',
                    vars => {
                        name  => $user->{name},
                        email => $user->{email},
                        key   => $key,
                        loc   => \&loc,
                    }
                }});
        }else{
            $JSON->{error} = 1;
        }
    };
    if ($@) {
        $JSON->{error} = 1;
        $JSON->{msg}   = $@;
    }else{
        $JSON->{success} = 1;
    }
    return $JSON;
}

sub login {
    my $JSON = shift;

    eval {
    my $account = $dbh->selectrow_hashref("SELECT account_id, name, email FROM accounts WHERE email=? AND password=? AND active=1",{},
                                          $_REQUEST->{email}, sha384_hex($conf->{Security}->{Key} . $_REQUEST->{password}));

    if(!$account){
        $JSON->{success} = 0;
        $JSON->{error} = 1;
        $JSON->{msg}   = 'Nombre de usuario o contraseña incorrectos. ' . $_REQUEST->{email};
        return $JSON;
    }


        $dbh->do("UPDATE accounts SET last_login_on=NOW() WHERE account_id=?",{}, $account->{account_id});
        my $request_token = sha1_hex($conf->{Security}->{Key} . time() . rand(999) . $_REQUEST->{device_id});
        my $exist = int($dbh->do("UPDATE devices SET last_request_on=NOW(), request_token=?, push_token=? WHERE device_id=? AND account_id=?",{},
                                 $request_token, $_REQUEST->{push_token}, $_REQUEST->{device_id}, $account->{account_id}));
        if(!$exist){
            $dbh->do("INSERT INTO devices(device_id, account_id, added_on, last_request_on, platform, request_token, push_token) VALUES(?,?,NOW(),NOW(),?,?,?)",{},
                     $_REQUEST->{device_id}, $account->{account_id}, $_REQUEST->{platform}, $request_token, $_REQUEST->{push_token});
        }
        $JSON->{data} = $account;
        $JSON->{data}->{request_token} = $request_token;
    };
    if ($@) {
        $JSON->{error} = 1;
        $JSON->{msg}   = $@;
    }else{
        $JSON->{success} = 1;
    }
    return $JSON;
}

1;
