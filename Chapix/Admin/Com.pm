package Chapix::Admin::Com;

#use strict;
use CGI qw/:cgi/;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Apache::Session::MySQL;
use Template;


# use Image::Size;
# use Image::Thumbnail;
# use Encode;
# use File::Copy;

use Chapix::Conf;

BEGIN {
  use Exporter();
  use vars qw( @ISA @EXPORT @EXPORT_OK );
  @ISA = qw( Exporter );
  @EXPORT = qw(
		  $dbh
		  %sess
		  $cookie
		  &msg_add
		  &msg_print
		  &admin_log
		  &http_redirect
          &set_path_route
		  &toolbar
		  &set_toolbar
		  $Q
		  $Template
        );
}

	  # 	  &get_thumbnail
	  # 	  &get_url
          # &ws_date
          # &get_search_box
          # &is_domain_admin
          # $_DOMAIN



use vars @EXPORT;

#################################################################################
# App Init
#################################################################################

# CGI params
$Q = CGI->new;

# Default template
$Template = Template->new(RELATIVE=>1);

# DataBase
$dbh = DBI->connect( $conf->{DBI}->{conection}, $conf->{DBI}->{user_name}, $conf->{DBI}->{password},
             {RaiseError => 1,AutoCommit=>1}) or die "Can't Connect to database.";
$dbh->do("SET CHARACTER SET 'utf8'");

# Session
my $session_id;
if (defined $ENV{'HTTP_COOKIE'}){
    my %cookies = map {$_ =~ /\s*(.+)=(.+)/g} ( split( /;/, $ENV{'HTTP_COOKIE'} ) );
    $session_id = $cookies{$conf->{SESSION}->{name}};
}

eval {
    tie %sess, 'Apache::Session::MySQL', $session_id, {
    	Handle     => $dbh,
    	LockHandle => $dbh,
    };
};

if ($@) {
    eval {
    	$session_id = '';
    	tie %sess, 'Apache::Session::MySQL' , $session_id,{
    	    Handle     => $dbh,
    	    LockHandle => $dbh,
    	};
    };
    die "Can't create session data $@" if($@);
}

defined $sess{admin_id}        or $sess{admin_id} = '';
defined $sess{admin_name}      or $sess{admin_name} = '';
defined $sess{admin_email}     or $sess{admin_email} = '';
defined $sess{admin_time_zone} or $sess{admin_time_zone} = '';
defined $sess{admin_language}  or $sess{admin_language}  = "$conf->{App}->{Language}";

$cookie = cookie(-name    => $conf->{SESSION}->{name},
		 -value   => $sess{_session_id},
		 -path    => $conf->{SESSION}->{path},
		 -expires => $conf->{SESSION}->{life},
	     );
#Sessión END

# Time Zone
if($sess{admin_time_zone}){
	$dbh->do("SET time_zone=?",{},$sess{admin_time_zone});
}else{
	$dbh->do("SET time_zone=?",{},$conf->{DBI}->{time_zone});
}

# Language
if($sess{admin_language}){
	$dbh->do("SET lc_time_names = ?",{},$sess{admin_language});
}else{
	$dbh->do("SET lc_time_names = ?",{},$conf->{App}->{Language});	
}


# Load basic config
conf_load('WebSite');


#################################################################################
# Common Functions
#################################################################################

# #Basic functions


# Print the httpheader including cookie and characterset
sub header_out {
    return header(-cookie=>$cookie,-charset=>"utf-8",-Expires=>-1);
}

sub msg_add {
    my $type = shift;
    my $text = shift;
    $dbh->do("INSERT IGNORE INTO sessions_msg (session_id, type, msg) values(?,?,?)",{},$sess{_session_id},$type, $text);
}

sub msg_print {
    my $HTML = "";
    my $msgs = $dbh->selectall_arrayref("SELECT m.type, m.msg FROM sessions_msg m WHERE m.session_id=?",{},$sess{_session_id});
    foreach my $msg (@$msgs){
		my $class = '';
		$HTML .= '<div class="card-panel msg msg-'.$msg->[0].'">' . $msg->[1] . '</div>';
    }
    $dbh->do("DELETE FROM sessions_msg WHERE session_id=?",{},$sess{_session_id}) if($msgs->[0]);
    return $HTML;
}

# Web browser redirect
sub http_redirect {
    my $dest = shift;
    untie %sess;
    $dbh->disconnect();
    print redirect($dest);
    exit 0;
}

# Save session data and disconect from DB
sub app_end {
    untie %sess;
    $dbh->disconnect();
    exit 0;
}

sub selectbox_data{
    my %data = (
        values => [],
        labels => {},
    );
    my $select = shift || "";
    my $params = shift;
    my $sth = $dbh->prepare($select);
    if($params){
        if(ref($params) eq 'ARRAY'){
            $sth->execute(@$params);
        }else{
            $sth->execute($params);
        }
    }else{
        $sth->execute();
    }
    while ( my $rec = $sth->fetchrow_arrayref() ) {
        push(@{$data{values}},$rec->[0]);
        $data{labels}{$rec->[0]} = $rec->[1];
    }
    return %data;
}

# sub create_url {
#     my $url = shift || "";
#     $url =~ s/\W/_/g;
#     return $url;
# }

# sub my_template {
#     my $layout = shift;
#     my $vars = shift;
#     my $HTML = "";
#     my $template = Template->new();
#     $template->process($layout, $vars,\$HTML) or $HTML = $template->error();
#     return $HTML;
# }

sub set_path_route {
	my @items = @_;
    my $route = '';
    foreach my $item(@items){
	    my $name = $item->[0];
		$name = CGI::a({-href=>$item->[1]},$name) if($item->[1]);
		$route .= ' <li>'.$name.'<span class="divider"><i class="icon-angle-right"></i></span></li> ';
     }
     $conf->{Page}->{Path} = '<ul class="path"><li><a href="/">Home</a><span class="divider"><i class="glyphicon glyphicon-menu-right"></i></span></li>' . $route.'</ul>';
 }

# sub security {
#     http_redirect("login.pl") if(!$sess{account_id});
# }

# sub upload_image {
#     my $cgi_param = shift || "";
#     my $dir = shift || "";
#     my $filename = param($cgi_param);
#     my $save_as = shift || "";
#     if($filename){
# 	my $type = uploadInfo($filename)->{'Content-Type'};
# 	my $file = '';
# 	my ($name, $ext) = split(/\./,$filename);
# 	$name =~ s/\W/_/g;
# 	if($type eq "image/jpeg" or $type eq "image/x-jpeg"  or $type eq "image/pjpeg"){
# 	    $ext = ".jpg";
# 	}elsif($type eq "image/png" or $type eq "image/x-png"){
# 	    $ext = ".png";
# 	}elsif($type eq "image/gif" or $type eq "image/x-gif"){
# 	    $ext = ".gif";
# 	}elsif($type =~ "flash"){
# 	    $ext = ".swf";
# 	}else{
# 	    msg_add("error","Solo imagenes jpeg, png y gif son soportadas");
# 	    return "";
# 	}
# 	if($ext){
# 	    #Directory
# 	    if(!(-e $_DOMAIN->{directory}."/html/img/$dir/")){
# 		mkdir($_DOMAIN->{directory}."/html/img/$dir/") or die 'No se puede crear el directorio de datos.';
# 	    }

# 	    $file = substr($name,0,35) . $ext;
# 	    if(-e $_DOMAIN->{directory}."/html/img/$dir/" . $file){
# 		foreach my $it (1 .. 100000000){
# 		    $file = $name.'_'.$it.$ext;
# 		    if(!(-e $_DOMAIN->{directory}."/html/img/$dir/" . $file)){
# 			last;
# 		    }
# 		}
# 	    }
# 	    open (OUTFILE,">".$_DOMAIN->{directory}."/html/img/$dir/" . $file) or die "$!";
# 	    binmode(OUTFILE);
# 	    my $bytesread;
# 	    my $buffer;
# 	    while ($bytesread=read($filename,$buffer,1024)) {
# 		print OUTFILE $buffer;
# 	    }
# 	    close(OUTFILE);
# 	    return $file;
# 	}
#     }
#     return "";
# }


# sub upload_file {
#     my $cgi_param = shift || "";
#     my $dir = shift || "";
#     my $filename = param($cgi_param);
#     my $mime = '';
#     my $save_as = shift || "";

#     if(!(-e $_DOMAIN->{directory}."/html/img/$dir/")){
# 	mkdir ($_DOMAIN->{directory}."/html/img/$dir/");
#     }

#     if($filename){
# 	my $type = uploadInfo($filename)->{'Content-Type'};
# 	my $file = $save_as || (time() . int(rand(9999999)));
# 	if($type eq "image/jpeg" or $type eq "image/x-jpeg"  or $type eq "image/pjpeg"){
# 	    $file .= ".jpg";
# 	    $mime = 'img';
# 	}elsif($type eq "image/png" or $type eq "image/x-png"){
# 	    $file .= ".png";
# 	    $mime = 'img';
# 	}elsif($type eq "image/gif" or $type eq "image/x-gif"){
# 	    $file .= ".gif";
# 	    $mime = 'img';
# 	}elsif($filename =~ /\.pdf$/i){
# 	    $file .= ".pdf";
# 	    $mime = 'pdf';
# 	}elsif($filename =~ /\.doc$/i){
# 	    $file .= ".doc";
# 	    $mime = 'doc';
# 	}elsif($filename =~ /\.xls$/i){
# 	    $file .= ".xls";
# 	    $mime = 'xls';
# 	}elsif($filename =~ /\.csv$/i){
# 	    $file .= ".csv";
# 	    $mime = 'csv';
# 	}elsif($filename =~ /\.ppt$/i){
# 	    $file .= ".ppt";
# 	    $mime = 'ppt';
# 	}elsif($filename =~ /\.docx$/i){
# 	    $file .= ".docx";
# 	    $mime = 'docx';
# 	}elsif($filename =~ /\.xlsx$/i){
# 	    $file .= ".xlsx";
# 	    $mime = 'xlsx';
# 	}elsif($filename =~ /\.pptx$/i){
# 	    $file .= ".pptx";
# 	    $mime = 'pptx';
#         }elsif($filename =~ /\.swf$/i){
# 	    $file .= ".swf";
# 	    $mime = 'swf';
#         }elsif($filename =~ /\.mp4$/i){
# 	    $file .= ".mp4";
# 	    $mime = 'mp4';
# 	}elsif($filename =~ /\.zip$/i){
# 	    $file .= ".zip";
# 	    $mime = 'zip';
# 	}else{
# 	    msg_add("error","Solo imagenes y archivos pdf y zip son soportados.");
# 	    return "";
# 	}
# 	if($file){
# 	    open (OUTFILE,">".$_DOMAIN->{directory}."/html/img/$dir/" . $file) or die "$!";
# 	    binmode(OUTFILE);
# 	    my $bytesread;
# 	    my $buffer;
# 	    while ($bytesread=read($filename,$buffer,1024)) {
# 		print OUTFILE $buffer;
# 	    }
# 	    close(OUTFILE);
# 	    return $file;
# 	}
#     }
#     return "";
# }

# sub upload_video {
#     my $cgi_param = shift || "";
#     my $dir = shift || "";
#     my $filename = param($cgi_param);
#     my $save_as = shift || "";
#     if($filename){
# 	my $type = uploadInfo($filename)->{'Content-Type'};
# 	my $file = '';
# 	my ($name, $ext) = split(/\./,$filename);
# 	$name =~ s/\W/_/g;
# 	if($type =~ /video/){
# 	    $ext = '.'.$ext;
# 	}else{
# 	    msg_add("error","Solo archivos de video son soportados.");
# 	    return "";
# 	}
# 	if($ext){
# 	    #Directory
# 	    if(!(-e $_DOMAIN->{directory}."/html/img/$dir/")){
# 		mkdir($_DOMAIN->{directory}."/html/img/$dir/") or die 'No se puede crear el directorio de datos.';
# 	    }

# 	    $file = $name . $ext;
# 	    if(-e $_DOMAIN->{directory}."/html/img/$dir/" . $name . '.mp4'){
# 		foreach my $it (1 .. 1000000){
# 		    $file = $name.'_'.$it.$ext;
# 		    if(!(-e $_DOMAIN->{directory}."/html/img/$dir/" . $name.'_'.$it.'.mp4')){
# 			last;
# 		    }
# 		}
# 	    }
# 	    open (OUTFILE,">".$_DOMAIN->{directory}."/html/img/$dir/" . $file) or die "$!";
# 	    binmode(OUTFILE);
# 	    my $bytesread;
# 	    my $buffer;
# 	    while ($bytesread=read($filename,$buffer,1024)) {
# 		print OUTFILE $buffer;
# 	    }
# 	    close(OUTFILE);
# 	    return $file;
# 	}
#     }
#     return "";
# }

# sub upload_audio {
#     my $cgi_param = shift || "";
#     my $dir = shift || "";
#     my $filename = param($cgi_param);
#     my $save_as = shift || "";
#     if($filename){
# 	my $type = uploadInfo($filename)->{'Content-Type'};
# 	my $file = '';
# 	my ($name, $ext) = split(/\./,$filename);
# 	$name =~ s/\W/_/g;
# 	if($type =~ /mp3/){
# 	    $ext = '.'.$ext;
# 	}else{
# 	    msg_add("error","Solo archivos mp3 son soportados.".$type);
# 	    return "";
# 	}
# 	if($ext){
# 	    #Directory
# 	    if(!(-e $_DOMAIN->{directory}."/html/img/$dir/")){
# 		mkdir($_DOMAIN->{directory}."/html/img/$dir/") or die 'No se puede crear el directorio de datos.';
# 	    }

# 	    $file = $name . $ext;
# 	    if(-e $_DOMAIN->{directory}."/html/img/$dir/" . $name . '.mp3'){
# 		foreach my $it (1 .. 1000000){
# 		    $file = $name.'_'.$it.$ext;
# 		    if(!(-e $_DOMAIN->{directory}."/html/img/$dir/" . $name.'_'.$it.'.mp3')){
# 			last;
# 		    }
# 		}
# 	    }
# 	    open (OUTFILE,">".$_DOMAIN->{directory}."/html/img/$dir/" . $file) or die "$!";
# 	    binmode(OUTFILE);
# 	    my $bytesread;
# 	    my $buffer;
# 	    while ($bytesread=read($filename,$buffer,1024)) {
# 		print OUTFILE $buffer;
# 	    }
# 	    close(OUTFILE);
# 	    return $file;
# 	}
#     }
#     return "";
# }

sub conf_load {
    my $module = shift;
    my $vars = $dbh->selectall_arrayref("SELECT c.module, c.name, c.value FROM conf c WHERE c.module = ?",{Slice=>{}},$module);
    foreach my $var(@$vars){
    	defined $conf->{$var->{module}} or $conf->{$var->{module}} = {};
    	$conf->{$var->{module}}->{$var->{name}} = $var->{value};
    }
}

# sub conf_set {
#     my $group = shift;
#     my $name  = shift;
#     my $value = shift;

#     $dbh->do("UPDATE conf c SET c.value=? WHERE c.group=? AND c.name=?",{},$value, $group, $name);
# }

# sub get_display_key {
#     my $salt = shift || rand(999);
#     require Digest::SHA1;
#     return substr(Digest::SHA1::sha1_hex($salt.time().$conf->{Misc}->{Key}),10,30);
# }

# sub tabs {
#     my @items = @_;
#     my $tab = $conf->{tab_key} || 'tab';
#     my $tabs = '';
#     foreach my $item(@items){
#     	if($item->[2] eq '1' or (param($tab) and param($tab) eq $item->[2])){
#     	    $tabs .= qq{<li class="active"><a href="$item->[1]" class="active">$item->[0]</a></li>};
#     	}else{
#     	    $tabs .= qq{<li><a href="$item->[1]">$item->[0]</a></li>};
#     	}
#     }
#     $tabs = '<ul class="nav nav-tabs">'.$tabs.'</ul>';
#     return $tabs;
# }

# sub thumbnail {
#     my $new_size = shift;
#     my $source   = shift;
#     my $target   = shift;
#     my $file     = shift;
#     my ($new_width, $new_height) = split(/x/,$new_size);

#     #existe la fuente
#     if(! (-e $_DOMAIN->{directory}."/html/img/$source/$file")){
# 	msg_add('error','No se pudo crear imagen chica, no existe la fuente');
# 	return;
#     }

#     #Target directory
#     if(!(-e $_DOMAIN->{directory}."/html/img/$target/")){
# 	mkdir($_DOMAIN->{directory}."/html/img/$target/") or die 'No se puede crear el directorio de datos.';
#     }
#     my ($width, $height) = imgsize($_DOMAIN->{directory}."/html/img/$source/".$file);
#     if($file =~ /\.gif/i){
#         copy($_DOMAIN->{directory}."/html/img/$source/".$file, $_DOMAIN->{directory}."/html/img/$target/".$file);
#     }else{
#         if($width > $new_width or $height > $new_height){
#             my $t = new Image::Thumbnail(
#                 size       => $new_size,
#                 module     => "Image::Magick",
#                 attr       => {colorspace=>'RGB'},
#                 create     => 1,
#                 input      => $_DOMAIN->{directory}."/html/img/$source/".$file,
#                 quality    => 90,
#                 outputpath => $_DOMAIN->{directory}."/html/img/$target/".$file,
#             );
#         }else{
#             my $t = new Image::Thumbnail(
#                 size       => $width.'x'.$height,
#                 module     => "Image::Magick",
#                 attr       => {colorspace=>'RGB'},
#                 create     => 1,
#                 input      => $_DOMAIN->{directory}."/html/img/$source/".$file,
#                 quality    => 90,
#                 outputpath => $_DOMAIN->{directory}."/html/img/$target/".$file,
#             );
#         }
#     }
# }

# sub upload_images {
#     my $cgi_param = shift || "";
#     my $dir = shift || "";
#     my @files = upload($cgi_param);
#     my $save_as = shift || "";
#     my @result;
#     foreach my $fh (@files) {
#         if($fh){
#             my ($name, $ext) = split(/\./,$fh);
#             $name =~ s/\W/_/g;
#             if($ext eq 'jpg' or $ext eq 'JPG'){
#                 $ext = ".jpg";
#             }elsif($ext eq 'png' or $ext eq 'PNG'){
#                 $ext = ".png";
#             }elsif($ext eq 'gif' or $ext eq 'GIF'){
#                 $ext = ".gif";
#             }else{
#                 next;
#             }
#             if($ext){
#                 #Directory
#                 if(!(-e $_DOMAIN->{directory}."/html/img/$dir/")){
#                     mkdir($_DOMAIN->{directory}."/html/img/$dir/") or die 'No se puede crear el directorio de datos.';
#                 }
                
#                 my $file = substr($name,0,35) . $ext;
#                 if(-e $_DOMAIN->{directory}."/html/img/$dir/" . $file){
#                     foreach my $it (1 .. 100000000){
#                         $file = $name.'_'.$it.$ext;
#                         if(!(-e $_DOMAIN->{directory}."/html/img/$dir/" . $file)){
#                             last;
#                         }
#                     }
#                 }
#                 open (OUTFILE,">".$_DOMAIN->{directory}."/html/img/$dir/" . $file) or die "$!";
#                 binmode(OUTFILE);
#                 my $bytesread;
#                 my $buffer;
#                 my $io_handle = $fh->handle;
#                 while ($bytesread= $io_handle->read(my $buffer,1024) ) {
#                     print OUTFILE $buffer;
#                 }
#                 close(OUTFILE);
#                 push(@result, $file);
#             }
#         }
#     }
#     return @result;
# }

# sub get_thumbnail {
#     my $field = shift;
#     my $current = shift || '';

#     my $image = ChapixAdm::Com::upload_image($field,'thumbnails');
#     return $current if(!$image);

#     # Resize image
#     my ($width, $height) = imgsize($_DOMAIN->{directory}."/html/img/thumbnails/".$image);
#     #if($width >= 500){
#     ChapixAdm::Com::thumbnail("640x50000",'thumbnails','thumbnails_l',$image);
#     #}
#     ChapixAdm::Com::thumbnail("130x130",'thumbnails','thumbnails',$image);
#     # Delete previous image
#     unlink $_DOMAIN->{directory}.'/html/img/thumbnails/'.$current if($current);
#     unlink $_DOMAIN->{directory}.'/html/img/thumbnails_l/'.$current if($current);

#     return $image;
# }

# sub get_url {
#     my $title = shift;
#     my $key_field = shift || 'entry_id';
#     my $table     = shift || 'entries';
#     $table =~ s/\W//g;

#     my $id = param($key_field) || 0;
#     $title = substr($title,0,41);
#     $title =~ s/á/a/g;
#     $title =~ s/é/e/g;
#     $title =~ s/í/i/g;
#     $title =~ s/ó/o/g;
#     $title =~ s/ú/u/g;
#     $title =~ s/Á/A/g;
#     $title =~ s/É/E/g;
#     $title =~ s/Í/I/g;
#     $title =~ s/Ó/O/g;
#     $title =~ s/Ú/U/g;
#     $title =~ s/ñ/n/g;
#     $title =~ s/Ñ/N/g;
#     $title =~ s/\W/-/g;
#     $title =~ s/\-+$//g;
#     $title =~ s/\-\-+/-/g;
#     my $exist = $dbh->selectrow_array("SELECT COUNT(*) FROM $table WHERE url=? AND $key_field <>?",{},$title,$id);
#     if($exist){
# 	my $original_title = $title;
# 	for(my $it=1;$it <=10000 ; $it++){
# 	    $title = $original_title.'-'.$it;
# 	    my $exist = $dbh->selectrow_array("SELECT COUNT(*) FROM $table WHERE url=? AND $key_field <>?",{},$title,$id);
# 	    last if(!$exist);
# 	}
#     }
#     return $title;
# }

# sub str_clean {
#     my $str = shift;
#     $str =~ s/\s+$//g;
#     $str =~ s/^\s+//g;
#     return $str;
# }

# sub ws_date {
#     return $dbh->selectrow_array("SELECT DATE(NOW())");
# }

sub admin_log {
    my $module = shift;
    my $action = shift;
    my $admin_id = shift || $sess{admin_id};

    $dbh->do("INSERT INTO admins_log (admin_id, date, module, comments, ip_address) VALUES(?,NOW(),?,?,?)",{},
	  $admin_id, $module, $action, $ENV{REMOTE_ADDR});
}

# sub get_search_box {
#     my $action = shift || $ENV{SCRIPT_NAME};
#     my $hidden_fields = shift || '';
#     my $form = '<form method="get" action="'.$action.'" class="form-search"><span class="nav-search-span">' .
# 	CGI::textfield(-name=>'q', -size=>'40', -id=> "nav-search-input", -class=>'input-small search-query', -placeholder=>'Buscar ...') .
# 	'<button type="submit" id="nav-search-btn"><i id="nav-search-icon" class="icon-search"></i></button></span>'.$hidden_fields.'</form>';
#     return $form;
# }

sub set_toolbar {
     my @actions = @_;
     my $LeftHTML = '';
     my $RightHTML = '';
	 my $HTML = '';

    foreach my $action (@actions){
		my $btn = '';
		my $alt = '';
     	my ($script, $label, $side, $icon, $class, $type) = @$action;
        $class = 'btn btn-default btn-sm' if(!$class);
     	if($script eq 'index.pl' or ($label eq '')){
     	    $alt = 'Level up';
     	    $icon  = 'level-up';
			$side  = 'right';
     	}
     	$btn .= ' <a href="'.$script.'" class="'.$class.'" alt="'.$alt.'" title="'.$alt.'" >';
     	if($icon){
     	    $btn .= '<i class="glyphicon glyphicon-'.$icon.'"></i> ';
     	}
     	$btn .= $label.'</a>';
		if($side eq 'right'){
			$RightHTML .= $btn;
		}else{
			$LeftHTML .= $btn;			
		}
	}

	$HTML .= $LeftHTML;
	$HTML .= '<div class="pull-right">' . $RightHTML .'</div>' if($RightHTML);

    $conf->{Page}->{Toolbar} = $HTML;
}

1;
