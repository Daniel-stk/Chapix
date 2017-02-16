package Chapix::GoogleConnect;

use strict;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use Digest::SHA1 qw(sha1_hex);
use URI::Encode qw(uri_encode uri_decode);
use LWP::UserAgent;
use JSON;
use URI;

use Chapix::Conf;
use Chapix::Com;

sub new {
    my $class = shift;
    my (%params) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _init {
    my $self = shift;
    
    Chapix::Com::conf_load("Google");
    
    $self->{client_id} = $dbh->selectrow_array("SELECT c.value FROM $conf->{Xaa}->{DB}.conf c WHERE c.group='Google' AND c.name='client_id'") || '';
    $self->{client_secret} = $dbh->selectrow_array("SELECT c.value FROM $conf->{Xaa}->{DB}.conf c WHERE c.group='Google' AND c.name='client_secret'") || '';
    $self->{redirect_uri} = "https://".$conf->{App}->{URL}."/Xaa/API/GoogleConnect";
    
    $self->{access_token} = $dbh->selectrow_array("SELECT access_token FROM $conf->{Xaa}->{DB}.user_access_tokens WHERE service='Google' AND account_id=?",{},$sess{admin_id}) || '';
}

sub authorized {
    my $self = shift;     
    
    return 0 if(!$self->{access_token});
    
    my $get = LWP::UserAgent->new;
    my $response = $get->get("https://www.googleapis.com/oauth2/v2/tokeninfo?access_token=".$self->{access_token});    

    if($response->is_success){
        my $json = decode_json($response->content);
        
        if($json->{issued_to}){
            return 1;
        }else{
            if($self->refresh_token()){
                return 1
            }else{
                return 0;
            }
        }
    }else{
        return 0;
    }
}


sub get_authorization_url {
    my $self = shift;
    my $vars = shift || {};
    
    my $uri = URI->new('https://accounts.google.com/o/oauth2/auth');

    $uri->query_form(
        response_type    => 'code',
        client_id        => $self->{client_id},
        redirect_uri     => $self->{redirect_uri},
        scope            => $vars->{scope},
        state            => $vars->{state} || int(rand(9999999999)),
        access_type      => 'offline',
        approval_prompt  => 'auto',
    );
    return $uri;
}

sub save_token {
    my $self = shift;
    
    eval {
        my $uri = URI->new('https://accounts.google.com/o/oauth2/token');
        my $post = LWP::UserAgent->new;
        
        my $response = $post->post($uri, {
            code          => param('code'),
            client_id     => $self->{client_id},
            client_secret => $self->{client_secret},
            redirect_uri  => $self->{redirect_uri},
            grant_type    => 'authorization_code'
        });
        
        if ($response->is_success) {
            my $json = decode_json($response->content);
            $self->{access_token} = $json->{access_token};            
            my $refresh = $json->{refresh_token};
            my $expires_in = $json->{expires_in};
                        
            my $upd = int($dbh->do("UPDATE $conf->{Xaa}->{DB}.accounts_access_tokens SET access_token=?, refresh_token=?, expires_in=DATE_ADD(NOW(), INTERVAL ? SECOND) WHERE account_id=?",{},$self->{access_token}, $refresh, $expires_in, $sess{admin_id}));

            if(!$upd) {
                $dbh->do("INSERT INTO $conf->{Xaa}->{DB}.accounts_access_tokens (account_id, service, access_token, refresh_token, expires_in) VALUES (?, 'Google', ?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))",{},
                         $sess{admin_id}, $self->{access_token}, $refresh, $expires_in);
            }
            
            Chapix::Com::http_redirect(uri_decode(param('state')));
        }else{
            msg_add("warning","Hubo un problema al conectar con Google, Error: ".$response->status_line);
        }
    };
    if ($@) {
        msg_add("danger","Error: ".$@);
    }
}


sub refresh_token {
    my $self = shift;

    my $refresh_token = $dbh->selectrow_array("SELECT refresh_token FROM $conf->{Xaa}->{DB}.accounts_access_tokens WHERE service='Google' AND account_id=?",{},$sess{admin_id}) || 0;
    
    return 0 if(!$refresh_token);
    
    eval {
        my $uri = URI->new('https://www.googleapis.com/oauth2/v4/token');
        my $post = LWP::UserAgent->new;
        
        my $response = $post->post($uri, {
            refresh_token => $refresh_token,
            client_id     => $self->{client_id},
            client_secret => $self->{client_secret},
            grant_type    => 'refresh_token'
        });
        
        if ($response->is_success) {
            my $json = decode_json($response->content);
            $self->{access_token} = $json->{access_token};
            
            $dbh->do("UPDATE $conf->{Xaa}->{DB}.accounts_access_tokens SET access_token=?, expires_in=DATE_ADD(NOW(), INTERVAL ? SECOND) WHERE service='Google' AND account_id=?",{},$self->{access_token}, $json->{expires_in}, $sess{admin_id});
            return 1;
        }else{
            return 0;
        }
    };
    if ($@) {
        return 0;
    }
}

sub get_contacts {
    my $self = shift;
    my $contactos;

    my $get = LWP::UserAgent->new;           
    my $contact_response = $get->get("https://www.google.com/m8/feeds/contacts/default/full?max-results=50000&alt=json&v=3.0&access_token=".$self->{access_token});
        
    if ($contact_response->is_success) {
        my $contacts = decode_json($contact_response->content);
        my $entries = $contacts->{feed}->{entry};
        my @users;
        my $total = 0;
        
        foreach my $entry (@{$entries}) {
            my $nombre = $entry->{title}->{'$t'};
            my $mail = $entry->{'gd$email'}[0]->{address};
            
            if($mail =~ /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/ ){
                push(@{$contactos}, {name => $nombre, email => $mail} );
            }
        }
        return $contactos;
    }else{
        return "Hubo un error al conectar con google: ".$contact_response->as_string;
    }
}

1;