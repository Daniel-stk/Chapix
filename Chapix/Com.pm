package Chapix::Com;

use strict;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Apache::Session::MySQL;
use Template;
use Image::Thumbnail;
use Image::Size;

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
        &msg_get
        &upload_file
        &upload_usr_file
        &http_redirect
        $_REQUEST
        $Template
        &format_short_name
        &format_name
        &get_display_key
        );
}

use vars @EXPORT;

#################################################################################
# App Init
#################################################################################

# CGI params
my $Q = CGI->new;

foreach my $key (keys %{$Q->Vars()}){
    $_REQUEST->{$key} = $Q->param($key);
}

my $URL = $ENV{SCRIPT_URL};
my $BaseURL = $conf->{ENV}->{BaseURL};

# DataBase
$dbh = DBI->connect( $conf->{DBI}->{conection}, $conf->{DBI}->{user_name}, $conf->{DBI}->{password},{RaiseError => 1,AutoCommit=>1}) or die "Can't Connect to database.";
$dbh->do("SET CHARACTER SET 'utf8'");
$dbh->do("SET time_zone=?",{},$conf->{DBI}->{time_zone});
#$dbh->do("SET lc_time_names = ?",{},$conf->{DBI}->{lc_time_names});

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
	TableName  => $conf->{Xaa}->{DB} . '.sessions',
    };
};

if ($@) {
    eval {
	$session_id = '';
	tie %sess, 'Apache::Session::MySQL' , $session_id,{
	    Handle     => $dbh,
	    LockHandle => $dbh,
	    TableName  => $conf->{Xaa}->{DB} . '.sessions',
	};
    };
    die "Can't create session data $@" if($@);
}

defined $sess{user_id}    or $sess{user_id} = '';
defined $sess{user_name}  or $sess{user_name} = '';
defined $sess{user_email} or $sess{user_email} = '';

$cookie = cookie(-name    => $conf->{SESSION}->{name},
		 -value   => $sess{_session_id},
		 -path    => $conf->{SESSION}->{path},
		 -expires => $conf->{SESSION}->{life},
    );
#Session END


$URL =~ s/^$BaseURL//g;
($_REQUEST->{Domain}, $_REQUEST->{Controller}, $_REQUEST->{View}) = split(/\//, $URL);
$_REQUEST->{Domain}     =~ s/\W//g;
$_REQUEST->{Controller} =~ s/\W//g;
$_REQUEST->{View}       =~ s/\W//g;
$_REQUEST->{View}       = '' if(!$_REQUEST->{View});



if (!($_REQUEST->{Domain}) and !($_REQUEST->{Controller}) and !($_REQUEST->{View})) {
    if($sess{user_id}){
	 # if we have a session lets redirect to home folder
	 my $folder_path = $dbh->selectrow_array("SELECT d.folder FROM xaa.xaa_domains d INNER JOIN xaa.xaa_users_domains ud ON d.domain_id=ud.domain_id " .
						"WHERE ud.user_id=? AND ud.active=1 AND ud.default_domain=1 LIMIT 1",{},$sess{user_id}) || '';
	 if($folder_path){
	   http_redirect('/'.$folder_path);
	 }else{
	    $sess{user_id}        = "";
	    $sess{user_name}      = "";
	    $sess{user_email}     = "";
	    $sess{user_time_zone} = "";
	    $sess{user_language}  = "";
	    http_redirect('/'.$folder_path);
	 }
    }else{
	   $_REQUEST->{Domain}     = 'Home';
	   $_REQUEST->{Controller} = '';
	   $_REQUEST->{View}       = '';
    }
}

# DataBase
$dbh = DBI->connect( $conf->{DBI}->{conection}, $conf->{DBI}->{user_name}, $conf->{DBI}->{password},{RaiseError => 1,AutoCommit=>1}) or die "Can't Connect to database." . $!;
$dbh->do("SET CHARACTER SET 'utf8'");
$dbh->do("SET time_zone=?",{},$conf->{DBI}->{time_zone});
#$dbh->do("SET lc_time_names = ?",{},$conf->{DBI}->{lc_time_names});

$_REQUEST->{Domain} = 'Xaa' if (! ($_REQUEST->{Domain}) );

# Change to domain database
if($_REQUEST->{Domain} eq 'Xaa'){
    $_REQUEST->{View} = $_REQUEST->{Controller};
    $_REQUEST->{Controller} = $_REQUEST->{Domain};
}elsif($_REQUEST->{Domain} =~ /[A-Z]/){
    $_REQUEST->{View} = $_REQUEST->{Domain};
    $_REQUEST->{Domain} = 'Xaa';
    $_REQUEST->{Controller} = 'Pages';
}else{
    eval {
	     $dbh->do("USE " . $conf->{Xaa}->{DB}."_".$_REQUEST->{Domain} );
    };
    if($@){
    	msg_add('danger','Data not found.');
    	http_redirect('/');
    }
}

# Load basic config
conf_load('Website');
conf_load('Domain');
conf_load('Template');

# Default template
$Template = Template->new(
  INCLUDE_PATH => 'templates/'.$conf->{Template}->{TemplateID}.'/',
);

#################################################################################
# Common Functions
#################################################################################

# Print the httpheader including cookie and characterset
sub header_out {
  return header(-cookie=>$cookie,-charset=>"utf-8",-Expires=>-1);
}

sub msg_add {
  my $type = shift;
  my $text = shift;
  $dbh->do("INSERT IGNORE INTO $conf->{Xaa}->{DB}.sessions_msg (session_id, type, msg) values(?,?,?)",{},$sess{_session_id},$type, $text);
}

sub msg_print {
  my $HTML = "";
  my $msgs = $dbh->selectall_arrayref("SELECT m.type, m.msg FROM $conf->{Xaa}->{DB}.sessions_msg m WHERE m.session_id=?",{},$sess{_session_id});
  foreach my $msg (@$msgs){
    my $class = '';
    $HTML .= '<div class="card-panel msg msg-'.$msg->[0].'">' . $msg->[1] . '</div>';
  }
  $dbh->do("DELETE FROM $conf->{Xaa}->{DB}.sessions_msg WHERE session_id=?",{},$sess{_session_id}) if($msgs->[0]);
  return $HTML;
}

sub msg_get {
  my $HTML = "";
  my $msgs = $dbh->selectall_arrayref("SELECT m.type, m.msg FROM $conf->{Xaa}->{DB}.sessions_msg m WHERE m.session_id=?",{},$sess{_session_id});
#  foreach my $msg (@$msgs){
#    my $class = '';
#    $HTML .= '<div class="card-panel msg-'.$msg->[0].'">' . $msg->[1] . '</div>';
#  }
  $dbh->do("DELETE FROM $conf->{Xaa}->{DB}.sessions_msg WHERE session_id=?",{},$sess{_session_id}) if($msgs->[0]);
  return $msgs;
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

sub conf_load {
  my $module = shift;
  my $vars = $dbh->selectall_arrayref("SELECT c.module, c.name, c.value FROM conf c WHERE c.module=? AND value IS NOT NULL",{Slice=>{}},$module);
  foreach my $var (@$vars){
    defined $conf->{$var->{module}} or $conf->{$var->{module}} = {};
    $conf->{$var->{module}}->{$var->{name}} = $var->{value} || '';
  }
}

sub selectbox_data {
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

sub admin_log {
  my $module = shift;
  my $action = shift;
  my $admin_id = shift || $sess{admin_id};

  $dbh->do("INSERT INTO admins_log (admin_id, date, module, comments, ip_address) VALUES(?,NOW(),?,?,?)",{},
  $admin_id, $module, $action, $ENV{REMOTE_ADDR});
}

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

sub upload_file {
  my $cgi_param = shift || "";
  my $dir = shift || "";
  my $filename = param($cgi_param);
  my $mime = '';
  my $save_as = shift || "";


  if(!(-e "data/$conf->{Domain}->{folder}")){
    mkdir ("data/$conf->{Domain}->{folder}");
  }
  
  if(!(-e "data/$conf->{Domain}->{folder}/img")){
    mkdir ("data/$conf->{Domain}->{folder}/img");
  }  
  
  if(!(-e "data/$conf->{Domain}->{folder}/img/$dir/")){
    mkdir ("data/$conf->{Domain}->{folder}/img/$dir/");
  }

  if($filename){
    my $type = uploadInfo($filename)->{'Content-Type'};
    my $file = $save_as || (time() . int(rand(9999999)));
    if($type eq "image/jpeg" or $type eq "image/x-jpeg"  or $type eq "image/pjpeg"){
      $file .= ".jpg";
      $mime = 'img';
    }elsif($type eq "image/png" or $type eq "image/x-png"){
      $file .= ".png";
      $mime = 'img';
    }elsif($type eq "image/gif" or $type eq "image/x-gif"){
      $file .= ".gif";
      $mime = 'img';
    }elsif($filename =~ /\.pdf$/i){
      $file .= ".pdf";
      $mime = 'pdf';
    }elsif($filename =~ /\.doc$/i){
      $file .= ".doc";
      $mime = 'doc';
    }elsif($filename =~ /\.xls$/i){
      $file .= ".xls";
      $mime = 'xls';
    }elsif($filename =~ /\.csv$/i){
      $file .= ".csv";
      $mime = 'csv';
    }elsif($filename =~ /\.ppt$/i){
      $file .= ".ppt";
      $mime = 'ppt';
    }elsif($filename =~ /\.docx$/i){
      $file .= ".docx";
      $mime = 'docx';
    }elsif($filename =~ /\.xlsx$/i){
      $file .= ".xlsx";
      $mime = 'xlsx';
    }elsif($filename =~ /\.pptx$/i){
      $file .= ".pptx";
      $mime = 'pptx';
    }elsif($filename =~ /\.swf$/i){
      $file .= ".swf";
      $mime = 'swf';
    }elsif($filename =~ /\.mp4$/i){
      $file .= ".mp4";
      $mime = 'mp4';
    }elsif($filename =~ /\.zip$/i){
      $file .= ".zip";
      $mime = 'zip';
    }elsif($filename =~ /\.txt$/i){
      $file .= ".txt";
      $mime = 'txt';
    }else{
      msg_add("danger","Solo imagenes y archivos pdf y zip son soportados.");
      return "";
    }
    if($file){
      open (OUTFILE,">data/$conf->{Domain}->{folder}/img/$dir/" . $file) or die "$!";
      binmode(OUTFILE);
      my $bytesread;
      my $buffer;
      while ($bytesread=read($filename,$buffer,1024)) {
        print OUTFILE $buffer;
      }
      close(OUTFILE);
      return $file;
    }
  }
  return "";
}


sub thumbnail {
  my $new_size = shift;
  my $source   = shift;
  my $target   = shift;
  my $file     = shift;
  my ($new_width, $new_height) = split(/x/,$new_size);

  #existe la fuente
  if(! (-e "data/$_REQUEST->{Domain}/img/$source/$file")){
    msg_add('error','No se pudo crear imagen chica, no existe la fuente');
    return;
  }

  #Target directory
  if(!(-e "data/$_REQUEST->{Domain}/img/$target/")){
    mkdir("data/$_REQUEST->{Domain}/img/$target/") or die 'No se puede crear el directorio de datos.';
  }
  my ($width, $height) = imgsize("data/$_REQUEST->{Domain}/img/$source/".$file);
  if($file =~ /\.gif/i){
    copy("data/$_REQUEST->{Domain}/img/$source/".$file, "data/$_REQUEST->{Domain}/img/$target/".$file);
  }else{
    if($width > $new_width or $height > $new_height){
      my $t = new Image::Thumbnail(
      size       => $new_size,
      module     => "Image::Magick",
      attr       => {colorspace=>'RGB'},
      create     => 1,
      input      => "data/$_REQUEST->{Domain}/img/$source/".$file,
      quality    => 90,
      outputpath => "data/$_REQUEST->{Domain}/img/$target/".$file,
      );
    }else{
      my $t = new Image::Thumbnail(
      size       => $width.'x'.$height,
      module     => "Image::Magick",
      attr       => {colorspace=>'RGB'},
      create     => 1,
      input      => "data/$_REQUEST->{Domain}/img/$source/".$file,
      quality    => 90,
      outputpath => "data/$_REQUEST->{Domain}/img/$source/".$file,
      );
    }
  }
}


sub get_display_key {
    my $salt = shift || rand(999);
    require Digest::SHA1;
    return substr(Digest::SHA1::sha1_hex($salt.time().$conf->{Misc}->{Key}),10,30);
}

sub format_name {
  my $str = shift;
  $str =~ s/,//g;
  $str =~ s/<//g;
  $str =~ s/>//g;
  return (join " ", map {ucfirst} split " ", $str),
}


sub format_short_name {
    my $str = shift;
    $str =~ s/,//g;
    $str =~ s/<//g;
    $str =~ s/>//g;
    my @words = split(" ",$str);
    my $name = '';
    foreach my $word (@words){
        if($name){
            $name .= ' '.ucfirst($word);
            return $name;
        }else{
            $name = ucfirst($word);
        }
    }
    return $name;
}


sub upload_usr_file {
  my $cgi_param = shift || "";
  my $dir = shift || "";
  my $filename = param($cgi_param);
  my $mime = '';
  my $save_as = shift || "";


  if(!(-e "data/$conf->{Domain}->{folder}")){
    mkdir ("data/$conf->{Domain}->{folder}");
  }

  if(!(-e "data/$conf->{Domain}->{folder}/img")){
      mkdir ("data/$conf->{Domain}->{folder}/img");
  }
  
  if(!(-e "data/$conf->{Domain}->{folder}/$dir")){
    mkdir ("data/$conf->{Domain}->{folder}/$dir");
  }

  if($filename){
    my $type = uploadInfo($filename)->{'Content-Type'};
    my ($name, $extension) = split(/\./, $filename);

    my $file = clean_str($name);

    if($type eq "image/jpeg" or $type eq "image/x-jpeg"  or $type eq "image/pjpeg"){
      $file .= ".jpg";
      $mime = 'img';
    }elsif($type eq "image/png" or $type eq "image/x-png"){
      $file .= ".png";
      $mime = 'img';
    }elsif($type eq "image/gif" or $type eq "image/x-gif"){
      $file .= ".gif";
      $mime = 'img';
    }elsif($filename =~ /\.pdf$/i){
      $file .= ".pdf";
      $mime = 'pdf';
    }elsif($filename =~ /\.doc$/i){
      $file .= ".doc";
      $mime = 'doc';
    }elsif($filename =~ /\.xls$/i){
      $file .= ".xls";
      $mime = 'xls';
    }elsif($filename =~ /\.csv$/i){
      $file .= ".csv";
      $mime = 'csv';
    }elsif($filename =~ /\.ppt$/i){
      $file .= ".ppt";
      $mime = 'ppt';
    }elsif($filename =~ /\.docx$/i){
      $file .= ".docx";
      $mime = 'docx';
    }elsif($filename =~ /\.xlsx$/i){
      $file .= ".xlsx";
      $mime = 'xlsx';
    }elsif($filename =~ /\.pptx$/i){
      $file .= ".pptx";
      $mime = 'pptx';
    }elsif($filename =~ /\.swf$/i){
      $file .= ".swf";
      $mime = 'swf';
    }elsif($filename =~ /\.mp4$/i){
      $file .= ".mp4";
      $mime = 'mp4';
    }elsif($filename =~ /\.zip$/i){
      $file .= ".zip";
      $mime = 'zip';
    }elsif($filename =~ /\.txt$/i){
      $file .= ".txt";
      $mime = 'txt';
    }else{
      msg_add("danger","Solo documentos y zip son soportados.");
      return "";
    }
    if($file){

      if (-e "data/$conf->{Domain}->{folder}/$dir/$file") {
        foreach my $it (1 .. 1000000) {
          $file = $name.'_'.$it.$extension;
          if(!(-e "data/$conf->{Domain}->{folder}/$dir/$file")){
            last;
          }
        }
      }

      open (OUTFILE,">data/$conf->{Domain}->{folder}/$dir/" . $file) or die "$!";
      binmode(OUTFILE);
      my $bytesread;
      my $buffer;
      while ($bytesread=read($filename,$buffer,1024)) {
        print OUTFILE $buffer;
      }
      close(OUTFILE);
      return $file;
    }
  }
  return "";
}


sub clean_str {
  my $cadena = shift;

    $cadena =~ s/\s+/ /g;
    $cadena =~ s/^\W//g;
    $cadena =~ s/\W+$//g;
    $cadena =~ s/\s/_/g;
    
    return $cadena;
}

1;
