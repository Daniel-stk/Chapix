package Chapix::Accounts::API;

use lib('../');
use lib('../cpan/');
use warnings;
use strict;
use Carp;

use Chapix::Conf;
use Chapix::Com;

# Language
use Chapix::Accounts::L10N;
my $lh = Chapix::Accounts::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub signup {
    my $results = shift;
    # email validation

    if($_REQUEST->{email} !~ /^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/){
    	$results->{msg} = loc('Please enter a valid email address');
    	$results->{error} = 1;
    	return $results;
    }

    my $exist = $dbh->selectrow_hashref(
    	"SELECT u.user_id, u.email, u.name, u.time_zone, u.language " .
    	"FROM users u " .
    	"WHERE u.email=?",{},
    	$_REQUEST->{email});

    if($exist){
        $results->{msg} = loc("El correo electrónico ya esta registrado.");
    	$results->{error} = 1;
    	return $results;
    }

    # User creation
    my $password = 'M'.substr(sha384_hex(time().$_REQUEST->{email}), 0, 8).'!';
    eval {
        $dbh->do("INSERT INTO users (name, email, phone, time_zone, language, password, last_login_on) VALUES(?,?,?,?,?,NOW())",{},
                 $_REQUEST->{name}, $_REQUEST->{email}, $conf->{App}->{TimeZone}, $conf->{App}->{Language}, sha384_hex($conf->{Security}->{key} . $password) );
        my $user_id = $dbh->last_insert_id('','',"users",'user_id');
        
        # my $request_token = sha1_hex($conf->{Security}->{Key} . time() . rand(999) . $_REQUEST->{device_id});
        # my $exist = int($dbh->do("UPDATE devices SET last_request_on=NOW(), request_token=?, push_token=? WHERE device_id=? AND account_id=?",{},
        #                          $request_token, $_REQUEST->{push_token}, $_REQUEST->{device_id}, $account->{account_id}));
        # if(!$exist){
        #     $dbh->do("INSERT INTO devices(device_id, account_id, added_on, last_request_on, platform, request_token, push_token) VALUES(?,?,NOW(),NOW(),?,?,?)",{},
        #              $_REQUEST->{device_id}, $account->{account_id}, $_REQUEST->{platform}, $request_token, $_REQUEST->{push_token});
        # }
        # $JSON->{data} = $account;
        # $JSON->{data}->{request_token} = $request_token;
        
    };
    if ($@) {
        $results->{error} = 1;
        $results->{msg} = $@;
        return $results;
    }

    # # Send Welcome Email
    # my $Mail = Chapix::Mail::Controller->new();
    # my $enviado = $Mail->html_template({
    #     to       => $_REQUEST->{'email'},
    #     bcc      => 'davidromero@xaandia.com', 
    #     subject  => $conf->{App}->{Name} . ': '. loc('Tu cuenta esta lista'),
    #     template => {
    #         file => 'Chapix/Accounts/tmpl/account-creation-letter.html',
    #         vars => {
    #             name     => format_short_name($_REQUEST->{'name'}),
    #             email    => $_REQUEST->{email},
    #             password => $password,
    #             loc => \&loc,
    #         }
    #     }
    # });

    # Welcome msg
    $results->{msg} = 'Tu cuenta fue creada con éxito. ' .
        'Recibirás un correo electrónico con tus datos de acceso.';
    
    return $results;	
}


sub get_all_states {
	my $results = {};

	eval {
		my $WHERE = '';

		if ($_REQUEST->{country_id}){
			$WHERE = "WHERE country_id='$_REQUEST->{country_id}'";
		}
		$results->{states} = $dbh->selectall_arrayref("SELECT * FROM $conf->{Accounts}->{DB}.states $WHERE",{Slice=>{}});
	};
	if ($@){
		$results->{error} = 1;
		$results->{message} = $@;
	}
	return $results;
}


1;
