package Chapix::Mail::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Mail::Sender;
use Template;
use MIME::Base64;
use LEOCHARRE::HTML::Text qw/html2txt/;

use Chapix::Conf;
use Chapix::Com;
#use Chapix::Mail::Admin::View;

sub new {
    my $class = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;
    return $self;
}

sub sender {
    my $self = shift;
    $Mail::Sender::NO_X_MAILER = 1;
    $self->{sender} = new Mail::Sender {
        smtp        => $conf->{Mail}->{Server},
            from        => $conf->{Mail}->{From},
                fake_from   => $conf->{Mail}->{From},
                    TLS_allowed => $conf->{Mail}->{Secure},
                        on_errors => 'die',
                            debug => 'data/mailsender.txt',
    };
}

sub encode_subject {
    my $subject = shift;
    $subject = '=?utf-8?B?'. encode_base64($subject). '?=';
    return $subject;
}

sub template {
    my $self = shift;
    my $layout = shift;
    my $vars = shift;
    my $HTML = "";
    my $template = Template->new();
    $template->process($layout, $vars,\$HTML) or $HTML = $template->error();
    return $HTML;
}

sub html_message {
    my $self = shift;
    my $data = shift;
    $self->{from} = $data->{from} if($data->{from});
    $self->sender();

    my $msg = $self->template('Chapix/Mail/tmpl/html-message.html',{
        conf=>$conf,
        msg => $data->{msg}});

    if(($self->{sender}->OpenMultipart({
     	to      => $data->{to},
     	cc      => ($data->{cc} || ""),
     	bcc     => ($data->{bcc} || ""),
     	replyto => ($data->{replyto} || $self->{replyto}),
     	subject => encode_subject($data->{subject}),
    	multipart => 'mixed',
				      })->Part({ctype => 'multipart/alternative'})->Part({
					  ctype => 'text/plain', disposition => 'NONE', msg => html2txt($msg)})->Part({
					      ctype => 'text/html', disposition => 'NONE', msg => '<html>'.$msg.'</html>'})->EndPart("multipart/alternative")->Close()) < 0){
    	return $Mail::Sender::Error;
    }else{
    	return 1;
    }
}

sub html_template {
    my $self = shift;
    my $data = shift;
    $self->{from} = $data->{from} if($data->{from});
    $data->{template}->{vars}->{conf} = $conf;
    $data->{msg} = $self->template($data->{template}->{file},$data->{template}->{vars});

    return $self->html_message($data);
}

1;
