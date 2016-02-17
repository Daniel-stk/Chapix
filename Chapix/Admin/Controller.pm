package Chapix::Admin::Controller;

use lib('cpan/');
use warnings;
use strict;
use Carp;
use Digest::SHA qw(sha384_hex);
use JSON::XS;

use Chapix::Conf;
use Chapix::Com;
use Chapix::Admin::View;
use Chapix::Mail::Controller;

# Language
use Chapix::Admin::L10N;
my $lh = Chapix::Admin::L10N->get_handle($sess{user_language}) || die "Language?";
sub loc (@) { return ( $lh->maketext(@_)) }

sub new {
    my $class = shift;
    my $self = {
        version  => '0.1',
    };
    bless $self, $class;

    # Logged user is required
#    if(!$sess{user_id}){
#    	msg_add('warning','To continue, log into your account.');
#    	Chapix::Com::http_redirect('/'.$_REQUEST->{Domain}.'/Xaa/Login');
#    }

    # init app ENV
    $self->_init();
    
    return $self;
}

sub _init {
    my $self = shift;
    $self->{main_db} = $conf->{Xaa}->{DB};
    $conf->{Domain} = $dbh->selectrow_hashref(
        "SELECT d.domain_id, d.name, d.folder, d.database, d.country_id, d.language, d.time_zone FROM $self->{main_db}.xaa_domains d WHERE folder = ?",{},
        $_REQUEST->{Domain});
}

# Main display function, this function prints the required view.
sub display {
    my $self = shift;

    if ($_REQUEST->{View} eq 'JSON') {
        print Chapix::Com::header_out('application/json');
        my $action = $_REQUEST->{'_action'};
        if ($action eq 'getPlaceByLocation') {
            print $self->json_get_place_by_location();
        } elsif ($action eq 'getCheckListAttemp') {
            print $self->json_get_check_list_attemp();
        }else{
            print $self->json_fallback();
        }
        return;
    }
    
    
    print Chapix::Com::header_out();
    
    if($_REQUEST->{View} eq ''){
        print Chapix::Layout::print( Chapix::Admin::View::display_home() );
    }elsif($_REQUEST->{View} eq 'Settings'){
        print Chapix::Layout::print( Chapix::Admin::View::display_settings() );
    }elsif($_REQUEST->{View} eq 'Users'){
        if($_REQUEST->{user_id}){
            print Chapix::Layout::print( Chapix::Admin::View::display_user_form() );
        }else{
            print Chapix::Layout::print( Chapix::Admin::View::display_users_list() );
        }
    }elsif($_REQUEST->{View} eq 'User'){
        print Chapix::Layout::print( Chapix::Admin::View::display_user_form() );
    }elsif($_REQUEST->{View} eq 'Places'){
        if($_REQUEST->{place_id}){
            print Chapix::Layout::print( Chapix::Admin::View::display_place_form() );
        }else{
            print Chapix::Layout::print( Chapix::Admin::View::display_places_list() );
        }
    }elsif($_REQUEST->{View} eq 'Place'){
        print Chapix::Layout::print( Chapix::Admin::View::display_place_form() );
    }elsif($_REQUEST->{View} eq 'PlaceLocation'){
        print Chapix::Layout::print( Chapix::Admin::View::display_place_location_form() );
    }elsif($_REQUEST->{View} eq 'Sections'){
        if($_REQUEST->{section_id}){
            print Chapix::Layout::print( Chapix::Admin::View::display_section_form() );
        }else{
            print Chapix::Layout::print( Chapix::Admin::View::display_sections_list() );
        }
    }elsif($_REQUEST->{View} eq 'Section'){
        print Chapix::Layout::print( Chapix::Admin::View::display_section_form() );
    }elsif($_REQUEST->{View} eq 'Points'){
        if($_REQUEST->{point_id}){
            print Chapix::Layout::print( Chapix::Admin::View::display_point_form() );
        }else{
            print Chapix::Layout::print( Chapix::Admin::View::display_points_list() );
        }
    }elsif($_REQUEST->{View} eq 'Point'){
        print Chapix::Layout::print( Chapix::Admin::View::display_point_form() );
    }elsif($_REQUEST->{View} eq 'Formats'){
        if($_REQUEST->{format_id}){
            print Chapix::Layout::print( Chapix::Admin::View::display_format_form() );
        }else{
            print Chapix::Layout::print( Chapix::Admin::View::display_formats_list() );
        }
    }elsif($_REQUEST->{View} eq 'Format'){
        print Chapix::Layout::print( Chapix::Admin::View::display_format_form() );
    }elsif($_REQUEST->{View} eq 'Checklist'){
        if ($_REQUEST->{format_id}) {
            print Chapix::Layout::print( Chapix::Admin::View::display_checklist() );
        }else{
            print Chapix::Layout::print( Chapix::Admin::View::display_checklist_chose_format() );
        }
    }elsif($_REQUEST->{View} =~ /^Set[A-Z]/){
        print CGI::header(-type=>'application/json');
        print '{}';
        exit 0;
    }else{
        msg_add('warning',loc('Not Found'));
        print Chapix::Admin::View::default();
    }
}

# Admin actions.
# Each action is detected by the "_submitted" param prefix
sub actions {
    my $self = shift;
    if(defined $_REQUEST->{_submitted_user}){
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
    }elsif(defined $_REQUEST->{_submitted_place}){
        if($_REQUEST->{_submit} eq loc('Delete')){
            # Delete user
            $self->delete_place();
        }else{
            # Save user data
            $self->save_place();
        }
    }elsif(defined $_REQUEST->{_submitted_section}){
        if($_REQUEST->{_submit} eq loc('Delete')){
            # Delete user
            $self->delete_section();
        }else{
            # Save user data
            $self->save_section();
        }
    }elsif(defined $_REQUEST->{_submitted_point}){
        if($_REQUEST->{_submit} eq loc('Delete')){
            $self->delete_point();
        }else{
            $self->save_point();
        }
    }elsif(defined $_REQUEST->{_submitted_format}){
        if($_REQUEST->{_submit} eq loc('Delete')){
            $self->delete_format();
        }else{
            $self->save_format();
        }

    }elsif($_REQUEST->{View} eq 'SetPlaceLocation'){
        $self->set_place_location();
    }
}


# Place management
sub save_place {
    my $self = shift;
    my $place_id = $_REQUEST->{place_id} || '';
    if($place_id){
        # Update
        eval {
            $dbh->do("UPDATE places SET place=?, time_zone=?, place_type_id=?, manager_id=?, address=?, city=?, state=? WHERE place_id=?",{},
                      $_REQUEST->{place}, $_REQUEST->{time_zone}, $_REQUEST->{place_type_id}, $_REQUEST->{manager_id}, $_REQUEST->{address}, $_REQUEST->{city}, $_REQUEST->{state},
                     $place_id);
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success', loc('Place successfully updated'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Places');
        }
       
    }else{
        # Add
        eval {
            # Add user to the domain
            $dbh->do("INSERT INTO places (place, time_zone, location, place_type_id, manager_id, address, city, state, active) " .
                         "VALUES(?,?,'',?,?,?,?,?,1)",{},
                     $_REQUEST->{place}, $_REQUEST->{time_zone}, $_REQUEST->{place_type_id}, $_REQUEST->{manager_id}, $_REQUEST->{address}, $_REQUEST->{city}, $_REQUEST->{state});
            $place_id = $dbh->last_insert_id('','',"places",'place_id');
        };
        if($@){
            msg_add('warning',"Can't not add the place" . $@);
        }else{
            msg_add('success', loc('Place successfully added, please define the location on the map'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/PlaceLocation?place_id='.$place_id);
        }
    }
}

sub set_place_location {
    my $self = shift;
    my $place_id = $_REQUEST->{place_id} || '';
    if($place_id){
        # Update
        eval {
            $dbh->do("UPDATE places SET longitude=?, latitude=? WHERE place_id=?",{},
                     $_REQUEST->{lng}, $_REQUEST->{lat}, $place_id);
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }
    }
}


sub delete_place {
    my $self = shift;
    my $place_id = $_REQUEST->{place_id} || '';

    http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Places') if(!$place_id);

    # Delete
    eval {
        $dbh->do("DELETE FROM places WHERE place_id=?",{},
                 $place_id);
    };
    if($@){
        # If can't delete, only de-activate
        eval {
            $dbh->do("UPDATE places SET active=0 WHERE place_id=?",{},$place_id);
        };
    }
    msg_add('success','Place successfully deleted.');
    http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Places');
}

# Sections management
sub save_section {
    my $self = shift;
    my $section_id = $_REQUEST->{section_id} || '';
    if($section_id){
        # Update
        eval {
            $dbh->do("UPDATE sections SET section=?, manager_id=? WHERE section_id=?",{},
                      $_REQUEST->{section}, $_REQUEST->{manager_id}, $section_id);
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success', loc('Section successfully updated'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Sections');
        }
       
    }else{
        # Add
        eval {
            # Add user to the domain
            $dbh->do("INSERT INTO sections (section, manager_id) " .
                         "VALUES(?,?)",{},
                     $_REQUEST->{section}, $_REQUEST->{manager_id});
            $section_id = $dbh->last_insert_id('','',"sections",'section_id');
        };
        if($@){
            msg_add('warning',"Can't not add the section");
        }else{
            msg_add('success', loc('Section successfully added'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Sections');
        }
    }
}

sub delete_section {
    my $self = shift;
    my $section_id = $_REQUEST->{section_id} || '';
    
    http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Sections') if(!$section_id);

    # Delete
    eval {
        $dbh->do("DELETE FROM sections WHERE section_id=?",{},
                 $section_id);
    };
    if($@){
        msg_add('Danger','Error '.$@);
        http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Sections');
    }else{
        msg_add('success','Section successfully deleted.');
        http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Sections');
    }
}

# Points management
sub save_point {
    my $self = shift;
    my $point_id = $_REQUEST->{point_id} || '';
    if($point_id){
        # Update
        eval {
            $dbh->do("UPDATE check_points SET point=?, answer_group_id=?, section_id=? WHERE point_id=?",{},
                     $_REQUEST->{point}, $_REQUEST->{answer_group_id}, $_REQUEST->{section_id}, $point_id);
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success', loc('Check point successfully updated'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Points');
        }
       
    }else{
        # Add
        eval {
            # Add user to the domain
            $dbh->do("INSERT INTO check_points (point, answer_group_id, section_id ) " .
                         "VALUES(?,?,?)",{},
                     $_REQUEST->{point}, $_REQUEST->{answer_group_id}, $_REQUEST->{section_id});
            $point_id = $dbh->last_insert_id('','',"check_points",'point_id');
        };
        if($@){
            msg_add('warning',"Can't not add the point");
        }else{
            msg_add('success', loc('Point successfully added'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Points');
        }
    }
}

sub delete_point {
    my $self = shift;
    my $point_id = $_REQUEST->{point_id} || '';
    
    http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Points') if(!$point_id);

    # Delete
    eval {
        $dbh->do("DELETE FROM check_points WHERE point_id=?",{},
                 $point_id);
    };
    if($@){
        msg_add('Danger','Error '.$@);
        http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Points');
    }else{
        msg_add('success','Point successfully deleted.');
        http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Points');
    }
}


# Formats management
sub save_format {
    my $self = shift;
    my $format_id = $_REQUEST->{format_id} || '';
    if($format_id){
        # Update
        eval {
            $dbh->do("UPDATE formats SET name=? WHERE format_id=?",{},
                      $_REQUEST->{name}, $format_id);
            
            # Actualizar Detalles
            my $details = $dbh->selectall_arrayref(
                "SELECT fcp.point_id, fcp.ponderation, fcp.requires_evidence, cp.point, fcp.sort_order " .
                "FROM formats_check_points fcp " .
                "INNER JOIN check_points cp ON fcp.point_id=cp.point_id " .
                "WHERE fcp.format_id=? AND active=1 ORDER BY sort_order",{Slice=>{}}, $_REQUEST->{format_id});
            foreach my $det (@$details) {
                if ($_REQUEST->{'delete_'.$det->{point_id}}) {
                    $dbh->do("UPDATE formats_check_points SET active=0 WHERE format_id=? AND point_id=?",{},
                             $format_id, $det->{point_id});
                }else{
                    $dbh->do("UPDATE formats_check_points SET ponderation=?, requires_evidence=?, sort_order=? WHERE format_id=? AND point_id=?",{},
                             $_REQUEST->{'ponderation_'.$det->{point_id}}, $_REQUEST->{'requires_evidence_'.$det->{point_id}}, $_REQUEST->{'sort_order_'.$det->{point_id}},
                             $format_id, $det->{point_id});
                }
            }
            
            # Insertar nuevo registro
            if ($_REQUEST->{point_id} and $_REQUEST->{ponderation}) {
                my $sort_order = ($dbh->selectrow_array("SELECT sort_order FROM formats_check_points WHERE format_id=? ORDER BY sort_order DESC LIMIT 1",{},$format_id) + 1);
                
                my $ins = $dbh->do("INSERT IGNORE INTO formats_check_points (format_id, point_id, ponderation, requires_evidence, sort_order) ".
                         "VALUES (?,?,?,?,?)",{},
                         $format_id, $_REQUEST->{point_id}, $_REQUEST->{ponderation}, $_REQUEST->{requires_evidence}, $sort_order);
                if (!(int($ins))) {
                    $dbh->do("UPDATE formats_check_points SET active=1, ponderation=?, requires_evidence=?, sort_order=? WHERE format_id=? AND point_id=?",{},
                             $_REQUEST->{ponderation}, $_REQUEST->{requires_evidence}, $sort_order, $format_id, $_REQUEST->{point_id});
                }
            }            
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success', loc('Format successfully updated'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Formats?format_id='.$format_id);
        }
    }else{
        # Add
        eval {
            # Add user to the domain
            $dbh->do("INSERT INTO formats (name, added_by, added_on) " .
		     "VALUES(?,?,NOW())",{},
                     $_REQUEST->{name}, $sess{user_id});
            $format_id = $dbh->last_insert_id('','',"formats",'format_id');
        };
        if($@){
            msg_add('warning',"Can't not add the format".$@);
        }else{
            msg_add('success', loc('Format successfully added'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Formats?format_id='.$format_id);
        }
    }
}

sub delete_format {
    my $self = shift;
    my $format_id = $_REQUEST->{format_id} || '';
    
    http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Formats') if(!$format_id);

    # Delete
    eval {
        $dbh->do("DELETE FROM formats_check_points WHERE format_id=?",{},$format_id);
        $dbh->do("DELETE FROM formats WHERE format_id=?",{},$format_id);
    };
    if($@){
        msg_add('Danger','Error '.$@);
        http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Formats');
    }else{
        msg_add('success','Format successfully deleted.');
        http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Formats');
    }
}




# User management

sub save_user {
    my $self = shift;
    my $user_id = $_REQUEST->{user_id} || '';
    if($user_id){
        # Update

        # The user are from this domain?
        $user_id = $dbh->selectrow_array("SELECT user_id FROM $self->{main_db}.xaa_users_domains WHERE user_id=? AND domain_id=?",{},$user_id, $conf->{Domain}->{domain_id}) || 0;
        if(!$user_id){
            msg_add('danger',loc('User does not exist'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Users');
        }

        eval {
            $dbh->do("UPDATE $self->{main_db}.xaa_users SET name=?, time_zone=?, language=? WHERE user_id=?",{},
                     $_REQUEST->{name}, $_REQUEST->{time_zone}, $_REQUEST->{language}, $user_id);
            $dbh->do("UPDATE $self->{main_db}.xaa_users_domains SET active=? WHERE user_id=? AND domain_id=?",{},
                 ($_REQUEST->{active} || 0), $user_id, $conf->{Domain}->{domain_id});

            # Update user profile
            my $upd = $dbh->do("UPDATE user_accounts SET group_id=? WHERE user_id=?",{}, $_REQUEST->{group_id}, $user_id) || 0;
            if(!int($upd)){
                $dbh->do("INSERT IGNORE INTO user_accounts (user_id, group_id) VALUES(?,?)",{}, $user_id, $_REQUEST->{group_id});
            }
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success', loc('User successfully updated'));
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Users');
        }
       
    }else{
        # Add
        my $password = substr(sha384_hex(time.$conf->{Site}->{Name}.'- Te deseamos el mayor éxito en todo lo que hagas -'),3,7);
        eval {
            # The email is in the database?
            $user_id = $dbh->selectrow_array("SELECT user_id FROM $self->{main_db}.xaa_users WHERE email=?",{},$_REQUEST->{email});
            
            if($user_id){
                # Add user to the domain
                $dbh->do("INSERT INTO $self->{main_db}.xaa_users_domains (user_id, domain_id, added_on, added_by, active, default_domain) VALUES(?,?,NOW(), ?,1,1)",{},
                             $user_id, $conf->{Domain}->{domain_id}, $sess{user_id});
                $_REQUEST->{user_id} = $user_id;
                
                $dbh->do("UPDATE $self->{main_db}.xaa_users SET password=? WHERE user_id=?",{},
                         sha384_hex($conf->{Security}->{key} . $password), $user_id);
            }else{
                # Add user
                $dbh->do("INSERT INTO $self->{main_db}.xaa_users (name, email, time_zone, language, password) VALUES(?,?,?,?,?)",{},
                         $_REQUEST->{name}, $_REQUEST->{email}, $_REQUEST->{time_zone}, $_REQUEST->{language}, sha384_hex($conf->{Security}->{key} . $password) );
                $user_id = $dbh->last_insert_id('','',"$self->{main_db}.xaa_users",'user_id');
                
                # Add user to the domain
                $dbh->do("INSERT IGNORE INTO $self->{main_db}.xaa_users_domains (user_id, domain_id, added_on, added_by, active, default_domain) VALUES(?,?,NOW(), ?,1,1)",{},
                         $user_id, $conf->{Domain}->{domain_id}, $sess{user_id});
            }

            # Update user profile
            my $upd = $dbh->do("UPDATE user_accounts SET group_id=? WHERE user_id=?",{}, $_REQUEST->{group_id}, $user_id) || 0;
            if(!int($upd)){
                $dbh->do("INSERT IGNORE INTO user_accounts (user_id, group_id) VALUES(?,?)",{}, $user_id, $_REQUEST->{group_id});
            }

        };
        if($@){
            msg_add('warning',"The email address $_REQUEST->{email} is already in use.");
        }else{
            msg_add('success', loc('User successfully added, the user have been notified by email'));

            # Send the new password by email
            my $Mail = Chapix::Mail::Controller->new();
            my $enviado = $Mail->html_template({
                to       => $_REQUEST->{'email'},
                subject  => $conf->{App}->{Name} . ': '. loc('Your new account is ready'),
                template => {
                    file => 'Chapix/Xaa/tmpl/user-creation-letter.html',
                    vars => {
                        name     => $_REQUEST->{'name'},
                        email    => $_REQUEST->{email},
                        password => $password,
                        loc => \&loc,
                    }
                }
            });
            
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Users');
        }
    }
}

sub reset_user_password {
    my $self = shift;
    my $user_id = $_REQUEST->{user_id} || '';
    my $user;
    if($user_id){
        # Update

        # The user are from this domain?
        $user = $dbh->selectrow_hashref(
            "SELECT ud.user_id, u.email, u.name FROM $self->{main_db}.xaa_users_domains ud INNER JOIN $self->{main_db}.xaa_users u ON ud.user_id=u.user_id " .
                "WHERE ud.user_id=? AND ud.domain_id=?",{},
            $user_id, $conf->{Domain}->{domain_id}) || 0;
        if(!$user->{user_id}){
            msg_add('danger','User does not exist.');
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Users');
        }

        my $password = substr(sha384_hex(time.$conf->{Site}->{Name}.'- Te deseamos el mayor exito en todo loq ue hagas -'),3,7);
        eval {
            $dbh->do("UPDATE $self->{main_db}.xaa_users SET password=? WHERE user_id=?",{},
                     sha384_hex($conf->{Security}->{key} . $password), $user->{user_id});
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success','User successfully updated.');

            # Send the new password by email
            my $Mail = Chapix::Mail::Controller->new();
            my $enviado = $Mail->html_template({
                to       => $user->{'email'},
                subject  => $conf->{App}->{Name} . ': Your password has been reset',
                template => {
                    file => 'Chapix/Xaa/tmpl/user-password-reset.html',
                    vars => {
                        name  => $_REQUEST->{'name'},
                        email => $user->{'email'},
                        new_password      => $password,
                    }
                }
            });
                        
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Users');
        }
    }
}

sub delete_user {
    my $self = shift;
    my $user_id = $_REQUEST->{user_id} || '';
    my $user;
    if($user_id){
        # Update

        # The user are from this domain?
        $user = $dbh->selectrow_hashref(
            "SELECT ud.user_id, u.email, u.name FROM $self->{main_db}.xaa_users_domains ud INNER JOIN $self->{main_db}.xaa_users u ON ud.user_id=u.user_id " .
                "WHERE ud.user_id=? AND ud.domain_id=?",{},
            $user_id, $conf->{Domain}->{domain_id}) || 0;
        if(!$user->{user_id}){
            msg_add('danger','User does not exist.');
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Users');
        }

        eval {
            $dbh->do("DELETE FROM $self->{main_db}.xaa_users_domains WHERE user_id=? AND domain_id=?",{},
                     $user->{user_id}, $conf->{Domain}->{domain_id});
            $dbh->do("DELETE FROM user_accounts WHERE user_id=? ",{},
                     $user->{user_id});
        };
        if($@){
            msg_add('warning',"Error: ".$@);
        }else{
            msg_add('success','User successfully deleted.');
            http_redirect('/'.$_REQUEST->{Domain}.'/Admin/Users');
        }
    }
}

sub json_fallback {
    my $JSON = {
        error => 'Not implemented',
    };
    
    return  JSON::XS->new->encode($JSON);
}

sub json_get_place_by_location {
    my $JSON = {
        place_id => 0,
    };
    my $longitude = $_REQUEST->{longitude};
    my $latitude  = $_REQUEST->{latitude};
    
    my $place = $dbh->selectrow_hashref("SELECT place_id, (ABS(longitude - ?) + ABS(latitude - ?)) AS distance " .
                                           "FROM places WHERE active=1 AND longitude IS NOT NULL ORDER BY 1 LIMIT 1",{},
                                            $longitude, $latitude);
    if ($place->{distance} < 0.00045) {
        $JSON->{place_id} = $place->{place_id};
    }
    
    return  JSON::XS->new->encode($JSON);
}

sub json_get_check_list_attemp {
    my $place_id = $_REQUEST->{place_id};
    my $format_id = $_REQUEST->{format_id};
    my $JSON = {};
    
    $JSON->{place} = $dbh->selectrow_hashref("SELECT place_id, place, manager_id, address, city, longitude, latitude FROM places WHERE place_id=? AND active=1",{},$place_id);
    $JSON->{format} = $dbh->selectrow_hashref("SELECT format_id, name FROM formats WHERE format_id=?",{},$format_id);
    $JSON->{checkpoints} = $dbh->selectall_arrayref(
        "SELECT fcp.point_id, fcp.ponderation, fcp.requires_evidence, fcp.sort_order, cp.point, cp.answer_group_id, cp. section_id " .
        "FROM formats_check_points fcp " .
        "INNER JOIN check_points cp ON fcp.point_id=cp.point_id " .
        "LEFT JOIN answers_groups ag ON ag.answer_group_id=cp.answer_group_id " .
        "WHERE fcp.format_id=? AND fcp.active=1 ",
        {Slice=>{}},$format_id);
    foreach my $point (@{$JSON->{checkpoints}}){
        $point->{answers} = $dbh->selectall_arrayref("SELECT answer_id, answer FROM answers WHERE answer_group_id=?",{Slice=>{}}, $point->{answer_group_id});
    }

    if(!$JSON->{place} or !$JSON->{format} or !$JSON->{checkpoints}){
        $JSON->{error} = "No se puede realizar el checklist, datos incompletos.";
    }
    return  JSON::XS->new->encode($JSON);
}

1;
