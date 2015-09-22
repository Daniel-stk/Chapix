package Chapix::List;

################################################################################
#
# This is a modified version of the CGI::List CPAN module
#
################################################################################

use strict;
use Carp qw(croak carp);

require 5.004;
use CGI qw/:standard *table/;
use Math::Round(qw/nearest nhimult/);

=head1 NAME

Chapix::List - Easily generate HTML Lists From a DataBase

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

sub new {
    my $class    = shift;
    my (%params) = @_;
    my $self     = {};
    bless $self,$class;

    #Init params
    defined param("cg_list")  or param(-name=>"cg_list", -value=>"");
    defined param("cg_order") or param(-name=>"cg_order",-value=>"");
    defined param("cg_side")  or param(-name=>"cg_side", -value=>"");
    defined param("cg_page")  or param(-name=>"cg_page", -value=>"1");

    #Prevent attacks
    param(-name=>"cg_order",-value=>int(param("cg_order") || 0));
    param(-name=>"cg_page",-value=>int(param("cg_page") || 0));

    #Predefined values
    $self->{name} = "cg_list";
    $self->{debug} = 0;
    $self->{on_errors} = "print";
    $self->{auto_order} = 1;
    $self->{pagination} = 1;
    $self->{nav_pages}  = 5;
    $self->{table_head} = "";
    $self->{after_columns_names} = "";
    $self->{table_footer} = "";
    $self->{custom_labels} = {};
    $self->{hidde_column} = '';
    ($self->{script},$self->{p}) = split(/\?/,$ENV{REQUEST_URI});

    $self->{table} = {
		      width       => "100%",
		      class       => "table table-striped table-bordered table-condensed",
		      align       => "center",
		      cellspacing => "0",
		     };

    $self->{columns}= {params => {}};
    $self->{th} = {params => {align => "center"}};
    $self->{detail_th} = {params => {}};
    $self->{group_th} = {params => {align=>"left",class=>"cg_group_th"}};
    $self->{group_td} = {params => {align=>"left",class=>"cg_group_td"}};

    $self->{group_item_totals} = {td=>{params=>{class=>"cg_group_item_totals"}}};


    $self->{detail}{td}{params} = {};
    $self->{detail}{Tr}{params_a} = {class=> "cg_row_a"};
    $self->{detail}{Tr}{params_b} = {class=> "cg_row_b"};

    $self->{no_data}{params} = {class=>"cg_no_data", align=>"center"};

    $self->{totals}{td}{params} = {align=>"right",class=>"cg_cell_total"};
    $self->{totals}{Tr}{params} = {class=>"cg_row_total"};

    $self->{foother}{params} = {class=>"cg_foother"};

    $self->{nw_params}="width=600,height=500,toolbar=no,scrollbars=yes,top='+((screen.height/2)-250)+',left='+((screen.width/2)-300)+'";

    $self->{orders} = {};

    $self->{labels} = {
        page_of => '',
        no_data   => 'No hay datos',
        link_up   => '&uarr;',
        link_down => '&darr;',
        next_page => '&raquo;',
        previous_page => '&laquo;',
        number_of_rows => "_NUMBER_ registros",
    };
    $self->{display_rows_total} = 1;

    $self->{Number_Format}={THOUSANDS_SEP=>",",DECIMAL_POINT=>".",MON_THOUSANDS_SEP=>",","MON_DECIMAL_POINT"=>".","INT_CURR_SYMBOL"=>''};

    #Put all Parameters on the object
    foreach my $init_param(keys %params){
		$self->{$init_param} = $params{$init_param};
    }

    #Order params and Query
    if ($self->{auto_order} and param('cg_order') and param('cg_list') eq $self->{name}){
		if(param("cg_order") =~ /\w+/){
			$self->{sql}{order_by}  = param("cg_order");
			$self->{sql}{order_by} .= " DESC  " if (param("cg_side"));
			$self->{sql}{order_by} .= " ASC  " if (!param("cg_side"));
		}
    }

    $self->{transit_params} = "";
    $self->{cgi_cg_params} = "";

    if($self->{link} and !$self->{link}{event}){
        $self->{link}{event} = "onClick";
        $self->{detail}{Tr}{params_a} = {class=> "pointer cg_row_a"};
        $self->{detail}{Tr}{params_b} = {class=> "pointer cg_row_b"};
    }
    return $self;
}

sub print {
    my $self = shift;
    my $grid = "";

    $self->transit_params();
    if(!defined $self->{rs}){
		$grid .= $self->get_data();
    }
    if(defined $self->{sn}){
        my $sn_counter = $self->{sn}->{start_on} || 0;
        foreach my $rec (@{$self->{rs}}){
            $sn_counter ++;
            $rec->{$self->{sn}->{field}} = $sn_counter;
        }
    }

    $self->{table}{id} = 'cg_table_' . $self->{name};
    if($self->{opener} or $self->{link}{location}){
        $self->{table}->{class} .= ' table-hover';
    }
    $grid .= start_table($self->{table}) . "\n";
    $grid .= "<caption>$self->{caption}</caption>" if($self->{caption});
    $grid .= $self->{table_head};
    if(defined $self->{groups}){
	$grid .= $self->print_group_columns();
	$grid .= $self->print_group_detail();
	if(!$self->{rows}){
	    $self->{no_data}{params}{colspan} = $self->{colspan};
	    $grid .= "    " . Tr ({},td($self->{no_data}{params},$self->{labels}{no_data})) . "\n";
	}else{
	    $grid .= $self->print_group_totals;
	    $grid .= $self->print_pagination();
	}
    }else{
	$grid .= $self->print_columns();
	$grid .= "<tbody>\n";
	$grid .= $self->{after_columns_names};
	$grid .= $self->print_detail();
	$grid .= "</tbody>\n";
	$grid .= $self->{table_footer};

	if(!$self->{rows}){
	    $self->{no_data}{params}{colspan} = $self->{colspan};
	    $grid .= "    " . Tr ({},td($self->{no_data}{params},$self->{labels}{no_data})) . "\n";
	}else{
	    $grid .= $self->print_totals;
	    $grid .= $self->{below_pagination};
	    $grid .= $self->print_pagination();
	}
    }
    $grid .= "</table>\n";
    $grid .= $self->js_row_effect();
    $self->{total_records} = $self->{rows} if(!$self->{total_records} and $self->{rows});

    return $grid;
}

sub get_data {
    my $self = shift;

    $self->build_query();

    $self->{sth} = $self->{dbh}->prepare($self->{sql}{query});
    eval {
		if($self->{sql}{params}){
			$self->{sth}->execute(@{$self->{sql}{params}});
		}else{
			$self->{sth}->execute();
		}
    };
    #if sql errors
    if($@){
	if($self->{on_errors} eq "die"){
	    if($self->{debug}){
			croak "Chapix::List Error code: ".$self->{dbh}->err.". Error message: ".$self->{dbh}->errstr . " SQL: " . $self->{sql}{query};
	    }else{
			croak "Chapix::List Error code: " . $self->{dbh}->err . ". Error message: " . $self->{dbh}->errstr;
	    }
	    return "";
	}elsif($self->{on_errors} eq "warn"){
	    if($self->{debug}){
			carp "Chapix::List Error code: ".$self->{dbh}->err.". Error message: ".$self->{dbh}->errstr . " SQL: " . $self->{sql}{query};
	    }else{
			carp "Chapix::List Error code: " . $self->{dbh}->err . ". Error message: " . $self->{dbh}->errstr;
	    }
	    return "";
	}elsif($self->{on_errors} eq "print"){
	    if($self->{debug}){
			return "Chapix::List Error code: " . $self->{dbh}->err .". Error message: ".$self->{dbh}->errstr." SQL: ".$self->{sql}{query};
	    }else{
			return "Chapix::List Error code: " . $self->{dbh}->err .". Error message: ".$self->{dbh}->errstr;
	    }
	}
#    }
#
#    if ( defined $self->{dbh}->errstr ) {
#		
    }else{
	while ( my $rec = $self->{sth}->fetchrow_hashref() ) {
	    push (@{$self->{rs}},$rec);
	}
    }
    return "";
}

sub build_query {
    my $self = shift;
    if (ref \$self->{sql} eq "SCALAR"){
		my $query = $self->{sql};
		$self->{sql} = {
			query => $query,
		};
		$self->{auto_order} = 0;
		$self->{pagination} = 0;
    }else{
	defined $self->{sql}{select}   or $self->{sql}{select}   = "";
	defined $self->{sql}{from}     or $self->{sql}{from}     = "";
	defined $self->{sql}{where}    or $self->{sql}{where}    = "";
	defined $self->{sql}{order_by} or $self->{sql}{order_by} = "";
	defined $self->{sql}{limit}    or $self->{sql}{limit}    = "";
	defined $self->{sql}{offset}   or $self->{sql}{offset}   = "";
	if($self->{dbh}->{Driver}->{Name} eq 'Sybase'){
	    if ($self->{sql}{limit}){
		$self->{sql}{query}  = " SELECT TOP ".$self->{sql}{limit}."  " . $self->{sql}{select};
	    }else{
		$self->{sql}{query}  = " SELECT   " . $self->{sql}{select};
	    }
	    $self->{sql}{query} .= " FROM     " . $self->{sql}{from}     if $self->{sql}{from};
	    $self->{sql}{query} .= " WHERE    " . $self->{sql}{where}    if $self->{sql}{where};
	    $self->{sql}{query} .= " GROUP BY " . $self->{sql}{group_by} if $self->{sql}{group_by};
	    $self->{sql}{query} .= " ORDER BY " . $self->{sql}{order_by} if $self->{sql}{order_by};
	    #$self->{sql}{query} .= " LIMIT    " . $self->{sql}{limit}    if $self->{sql}{limit};
	    #if($self->{pagination}){
	    #$self->{sql}{query} .= " OFFSET   " . ($self->{sql}{limit} * (param("cg_page") - 1) );
	    #}else{
	    #$self->{sql}{query} .= " OFFSET   " .  $self->{sql}{offset}   if $self->{sql}{offset};
	    #}

	}else{
	    $self->{sql}{query}  = " SELECT   " . $self->{sql}{select};
	    $self->{sql}{query} .= " FROM     " . $self->{sql}{from}     if $self->{sql}{from};
	    $self->{sql}{query} .= " WHERE    " . $self->{sql}{where}    if $self->{sql}{where};
	    $self->{sql}{query} .= " GROUP BY " . $self->{sql}{group_by} if $self->{sql}{group_by};
	    $self->{sql}{query} .= " ORDER BY " . $self->{sql}{order_by} if $self->{sql}{order_by};
	    $self->{sql}{query} .= " LIMIT    " . $self->{sql}{limit}    if $self->{sql}{limit};
	    if($self->{pagination}){
		$self->{sql}{query} .= " OFFSET   " . ($self->{sql}{limit} * (param("cg_page") - 1) );
	    }else{
		$self->{sql}{query} .= " OFFSET   " .  $self->{sql}{offset}   if $self->{sql}{offset};
	    }
	}
    }
}

sub print_columns {
    my $self = shift;
    $self->get_columns();
    if(defined $self->{headers_groups}){
	my $HTML = "";
	$self->{th}{params}{align} = "center";
	foreach my $hgroup (@{$self->{headers_groups}}){
	    if(ref $hgroup eq "HASH" ){
		$self->{th}{params}{colspan} = $hgroup->{colspan};
		$HTML .= th($self->{th}{params},$hgroup->{label}) . "\n";
		undef $self->{th}{params}{colspan};
	    }else{
		$HTML .= th($self->{th}{params},"") . "\n";
	    }
	}
	my $line1 = Tr ($self->{columns}{params},$HTML);
	$HTML = "";
	undef 	$self->{th}{params}{align};
	my $it = 0;
	foreach my $label (@{$self->{columns}{labels}}){
	    $self->{th}{params}{width} = $self->{columns_width}[$it] if(defined $self->{columns_width}[$it]);
	    $self->{th}{params}{align} = $self->{columns_headers_align}[$it] if(defined $self->{columns_headers_align}[$it]);
	    $HTML .= th($self->{th}{params},$label) . "\n";
	    $it++;
	}
	return $line1 . "\n   " . Tr ($self->{columns}{params},$HTML);
    }else{
	if (defined $self->{columns_width} or defined $self->{columns_headers_align}){
	    my $HTML = "";
	    my $it = 0;
	    foreach my $label (@{$self->{columns}{labels}}){
		$self->{th}{params}{width} = $self->{columns_width}[$it] if(defined $self->{columns_width}[$it]);
		$self->{th}{params}{align} = $self->{columns_headers_align}[$it] if(defined $self->{columns_headers_align}[$it]);
		$HTML .= th($self->{th}{params},$label) . "\n" if($self->{hidde_column} ne $label);
		$it++;
	    }
	    return "   " . Tr ($self->{columns}{params},$HTML);
	};
	my $HTML = "";
	$HTML .= "    <thead>" if(!$self->{table_head});
	my $it = 0;
	foreach my $label (@{$self->{columns}{labels}}){
	    $HTML .= th($self->{th}{params},$label) . "\n" if($self->{hidde_column} ne $label);
	    $it++;
	}
	$HTML .= "    </thead>\n" if(!$self->{table_head}); 
	return "   " . Tr ($self->{columns}{params},$HTML);

	
	#$HTML .= Tr ($self->{columns}{params},[th($self->{th}{params},$self->{columns}{labels})]);
	
	#return $HTML;
    }
}

sub social_buttons {
    my $self = shift;
    my $fb = shift || 0;
    my $tw = shift || 0;
    my $module = shift || 'Blog';
    if($fb or $tw){
        $self->{sql}->{select} .= ", '' AS social";
        $self->{social} = {fb=>$fb, tw=>$tw, module=>$module};
    }
}

sub on_off {
    my $self = shift;
    $self->{on_off_column} = shift;
}

sub actions {
    my $self = shift;
    my @actions = @_;
    $self->{sql}->{select} .= ", '' AS actions";
    $self->{actions} = \@actions;
}

sub get_columns {
    my $self = shift;
    $self->{columns}{names} = ();
    $self->{columns}{labels} = ();
    $self->{colspan} = ($self->{sth}->{NUM_OF_FIELDS}) || 0;
    foreach my $i(0 .. ($self->{colspan} - 1)) {
	defined $self->{sth}->{NAME}->[$i] or $self->{sth}->{NAME}->[$i] = "";
	if ($self->{sth}->{NAME}->[$i] and !($self->{link}{hidde_key_col} and $self->{sth}->{NAME}->[$i] eq $self->{link}{key})){
	    next if(defined $self->{second_row} and $self->{second_row}->{colspan}->{$self->{sth}->{NAME}->[$i]});
	    push(@{$self->{columns}{names}},$self->{sth}->{NAME}->[$i]);
	    my $col_label = $self->{sth}->{NAME}->[$i];
	    if($col_label ne $self->{hidde_column}){
		if($self->{custom_labels}->{$self->{sth}->{NAME}->[$i]}){
		    $col_label = $self->{custom_labels}->{$self->{sth}->{NAME}->[$i]};
		}else{
		    $col_label =~ s/_/ /g;
		    $col_label = ucfirst($col_label);
		}

		#Auto order Links
		my $side = 0;
		$side = 1 if (!param("cg_side"));
		if($self->{auto_order}){
		    if(defined $self->{auto_order_switch}){
			if(defined $self->{auto_order_switch}[$i] and $self->{auto_order_switch}[$i]){
			    if(($i+1) eq param("cg_order")){
				if(param("cg_side") eq "0"){
				    $col_label =       a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=1&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
				}elsif(param("cg_side") eq "1"){
				    $col_label =  a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=0&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
				}
			    }else{
				$col_label = a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=0&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
			    }
			}
		    }else{
			if(($i+1) eq param("cg_order")){
			    if(param("cg_side") eq "0"){
				$col_label =       a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=1&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
			    }elsif(param("cg_side") eq "1"){
				$col_label =  a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=0&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
			    }
			}else{
			    $col_label = a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=0&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
			}
		    }
		}
	    }
	    push(@{$self->{columns}{labels}},$col_label);
   	}
    }
    $self->{colspan} -= 1 if($self->{link}{hidde_key_col});
}

sub print_detail {
    my $self = shift;
    my $HTML = "";

    $self->{link}{event} = 'ondblclick' if($self->{actions});
    $self->{rows} = 0;
	foreach my $rec(@{$self->{rs}}) {
	    $self->{rows} ++;
	    my @fields;
	    my $row_cells = "";
	    my $row_params = "params_b";
	    my $row_html_params = 0;
	    $row_params = "params_a" if (($self->{rows}/2) - int($self->{rows}/2));
	    foreach my $i(0 .. (($self->{colspan}-1))) {
		if(defined $self->{columns_align}){
		    $self->{detail}{td}{params}{align} = $self->{columns_align}[$i];
		}
		if($self->{columns}{names}[$i] ne $self->{hidde_column}){
		    if(defined $self->{cell_format}{$self->{columns}{names}[$i]}){
			#Cell Formats
			my $cell_params = $self->{detail}{td}{params};
			foreach my $cell_format(@{$self->{cell_format}{$self->{columns}{names}[$i]}}){
			    my $check = 0;
			    my $condition = $cell_format->{condition};
			    $condition =~ s/%%/$rec->{$self->{columns}{names}[$i]}/g;
			    $condition =~/([\S\s]+)\s(\S+)\s([\S\s]+)/;
			    my $untained_condition = " $1 $2 $3" || "";
			    eval '$check = 1 if(' . $untained_condition . ');';
			    if( $check ){
				$cell_params = $cell_format->{params};
			    }
			}
			$row_cells .= td($cell_params,$rec->{$self->{columns}{names}[$i]});
                    }elsif($self->{actions} and $self->{columns}{names}[$i] eq 'actions'){
                        my $cell = '<div class="btn-group">';
			my $it = 0;
                        foreach my $action (@{$self->{actions}}){
                            #$cell .= $action;
			    if($it == 1){
				$cell .= '<button class="btn btn-small btn-inverse dropdown-toggle" data-toggle="dropdown">'.
                                    '<span class="caret"></span></button><ul class="dropdown-menu">';
			    }

                            if($action->{onclick} eq 'default'){
                                $cell .= CGI::a({-class=> 'btn btn-small btn-inverse',-href=> $self->{link}{location} . "?" . $self->{link}{key} . "=" .
                                                     $rec->{$self->{link}{key}} . $self->{transit_params}},
                                                '<i class="icon-edit"></i>'.$action->{name});
                            }elsif($action->{onclick} eq 'youtube'){
                                $cell .= '<li>'.CGI::a({
				    -href=>"javascript:wsModal('youtube_share.pl?_ws_l_mode=overlay&module=Youtube&action=edit&module_id=".$rec->{$self->{link}{key}}."');"},
						       '<i class="icon-share"></i>'.$action->{name}).'<li>';
                            }elsif($action->{onclick} eq 'delete'){
                                $cell .= '<li>'.CGI::a({-href=>$self->{link}{location} . "?_cg_action=delete&" . $self->{link}{key} . "=" .
                                                     $rec->{$self->{link}{key}} . $self->{transit_params}},
                                                '<i class="icon-trash"></i>'.$action->{name}).'<li>';
                            }else{
                                $cell .= '<li>';
                                my $ID = $rec->{$self->{link}{key}};
                                my $name = $action->{name};
                                my $href = $action->{href};
                                $href    =~ s/_ID_/$ID/g;
                                $name  = '<i class="icon-' . $action->{icon} . '"></i> ' . $name if($action->{icon});
                                $cell .= CGI::a({-href => $href . $self->{transit_params}},$name);
                                $cell .= '<li>';
                            }
			    $it ++;
                        }
			if($it > 2){
			    $cell .= '</ul>';
			}
                        $cell .= '</div>';
			$row_cells .= td($self->{detail}{td}{params},$cell);
                    }elsif($self->{on_off_column} and $self->{columns}{names}[$i] eq $self->{on_off_column}){
                        my $cell = '';
                        if($rec->{$self->{columns}{names}[$i]}){
                            $cell .= CGI::button(
                                -class=> 'cg-on',
                                -value=> ' ',
                                -onclick=>"document.location.href='" . $self->{link}{location} . "?_cg_action=off&" . $self->{link}{key} . "=" .
                                    $rec->{$self->{link}{key}} . "$self->{transit_params}';");
                        }else{
                            $cell .= CGI::button(
                                -class=> 'cg-off',
                                -value=> '',
                                -onclick=>"document.location.href='" . $self->{link}{location} . "?_cg_action=on&" . $self->{link}{key} . "=" .
                                    $rec->{$self->{link}{key}} . "$self->{transit_params}';");
                        }
			$row_cells .= td($self->{detail}{td}{params},$cell);
                    }elsif($self->{social} and $self->{columns}{names}[$i] eq 'social'){
                        my $cell = '';
                        if($self->{social}->{fb}){
                            $cell .= ' ' .
                                CGI::a({-href=>"javascript:wsModal('facebook_share.pl?_ws_l_mode=overlay&module=".$self->{social}->{module}."&action=edit&module_id=".$rec->{$self->{link}{key}}."');",
                                        -rel=>"#overlay",
                                        -style=>"text-decoration:none"},
				       '<i class="icon-facebook-sign" data-rel="tooltip" title="Publicar en facebook"></i>');
                        }
                        if($self->{social}->{tw}){
                            $cell .= ' ' .
                                CGI::a({-href=>"javascript:wsModal('twitter_share.pl?_ws_l_mode=overlay&module=".$self->{social}->{module}."&action=edit&module_id=".$rec->{$self->{link}{key}}."');",
                                        -style=>"text-decoration:none"},
				'<i class="icon-twitter-sign" data-rel="tooltip" title="Publicar en twitter"></i>');
                        }
			$row_cells .= td($self->{detail}{td}{params},$cell);
		    }else{
			#Normal cell ---------------------------------------------------------------------------
			defined $rec->{$self->{columns}{names}[$i]} or $rec->{$self->{columns}{names}[$i]} = "";

			if($self->{link}->{exclude_rows} and $self->{link}){
			    if($self->{link}->{exclude_rows}->{$self->{columns}{names}[$i]}){
				$self->{detail}{td}{params}->{$self->{link}{event}} = '';
			    }else{
				if($self->{link}{target}){
				    $self->{detail}{td}{params}->{$self->{link}{event}} = "window.open('" . $self->{link}{location} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$self->{transit_params}','" . $self->{key}{target} . "','" . $self->{nw_params} . "');";
				}elsif($self->{opener}){
				    my $opener_transit_params = $self->{transit_params};
				    $opener_transit_params =~ s/opener=[\w]*//g;
				    $self->{detail}{td}{params}->{$self->{link}{event}} = "opener.location.href='" . $self->{opener} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$opener_transit_params'; window.close();";
				}elsif($self->{link}{location}){
				    $self->{detail}{td}{params}->{$self->{link}{event}} = "document.location.href='" . $self->{link}{location} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$self->{transit_params}';";
				}
			    }
			}
			$row_cells .= td($self->{detail}{td}{params},$rec->{$self->{columns}{names}[$i]});
		    }
		}
		if(defined $self->{row_format}{$self->{columns}{names}[$i]}){
		    #Row Format
		    foreach my $row_format(@{$self->{row_format}{$self->{columns}{names}[$i]}}){
			my $check = 0;
			my $condition = $row_format->{condition};
			$condition =~ s/%%/$rec->{$self->{columns}{names}[$i]}/g;
			$condition =~/([\S\s]+)\s(\S+)\s([\S\s]+)/;
			my $untained_condition = " $1 $2 $3" || "";
			eval '$check = 1 if(' . $untained_condition . ');';
			if( $check ){
			    $row_params = $self->{columns}{names}[$i];
			    $self->{detail}{Tr}{$row_params} = $row_format->{params};
			    $row_html_params = 1;
			}
		    }
		}
	    }

	    #Links
	    if(defined $self->{second_row}){
		$row_params = "params_a" if($row_params eq "params_b");
	    }
	    if($self->{link}){
		if(!$self->{link}->{exclude_rows}){
		    if($self->{link}{target}){
			$self->{detail}{Tr}{$row_params}{$self->{link}{event}} = "window.open('" . $self->{link}{location} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$self->{transit_params}','" . $self->{key}{target} . "','" . $self->{nw_params} . "');";
		    }elsif($self->{opener}){
			my $opener_transit_params = $self->{transit_params};
			$opener_transit_params =~ s/opener=[\w]*//g;
			$self->{detail}{Tr}{$row_params}{$self->{link}{event}} = "opener.location.href='" . $self->{opener} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$opener_transit_params'; window.close();";
		    }elsif($self->{link}{location}){
			$self->{detail}{Tr}{$row_params}{$self->{link}{event}} = "document.location.href='" . $self->{link}{location} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$self->{transit_params}';";
		    }
		}
	    }

	    if($rec->{_list_separator}){
		$HTML .= "   " . Tr ({class=>"cg_row_separator", height=>'4'},td({colspan=>$self->{colspan}},'')) . "\n";
	    }
	    $HTML .= "   " . Tr ($self->{detail}{Tr}{$row_params},$row_cells) . "\n";
	    if(defined $self->{second_row}){
		my $colspan = 0;
		my %second_row_params = %{$self->{detail}{td}{params}};
		my $row_cells = "";
		foreach my $field(@{$self->{second_row}->{fields}}){
		    $second_row_params{colspan} = $self->{second_row}->{colspan}->{$field};
		    $colspan +=  $second_row_params{colspan} = $self->{second_row}->{colspan}->{$field};
		    if($field eq "_VOID"){
			$row_cells .= td(\%second_row_params,"");
		    }else{
			$row_cells .= td(\%second_row_params,$rec->{$field});
		    }
		}
		$HTML .= "   " . Tr ({class=>"cg_second_row"},$row_cells) ."\n";
		$HTML .= "   " . Tr ({class=>"cg_separator"},td({colspan=>$colspan},'')) ."\n";
	    }
	}
	
    return $HTML;
}

sub js_row_effect {
    my $self = shift;
    my $HTML = "";
    #Row Efect
    if($self->{opener} or $self->{link}{location}){
	$HTML .= '<script type="text/javascript">
	var cg_table_' . $self->{name} . ' = document.getElementById(\'cg_table_' . $self->{name} . '\');
	for(var i = 0; i < cg_table_' . $self->{name} . '.rows.length; i++){
            cg_row_class_name = cg_table_' . $self->{name} . '.rows[i].className;
            if( cg_row_class_name.substring(0,7) == "cg_row_"){
	        cg_table_' . $self->{name} . '.rows[i].onmouseover = function(){this.className = this.className+\'_hover\';};
	        cg_table_' . $self->{name} . '.rows[i].onmouseout = function(){this.className = this.className.replace(\'_hover\',\'\');};
            }
	}
</script>
'
    }
    return $HTML;
}

sub transit_params {
    my $self = shift;
    #Transit Params
    $self->{cgi_cg_params} =  "cg_order=" . param("cg_order") . 
		"&cg_side=" . param("cg_side") . 
			"&cg_page=" . param("cg_page") . 
				"&cg_list=" . $self->{name};
    if (defined $self->{link}{transit_params}){
		foreach my $k (sort keys %{$self->{link}{transit_params}}){
		    $self->{transit_params} .= "&" . $k . "=" . $self->{link}{transit_params}{$k};
		}
    }
    if($self->{opener}){
		$self->{transit_params} .= "&opener=" . $self->{opener};
    }
}

sub print_pagination {
    my $self = shift;
    my $HTML = "";
    $self->{foother}{params}{colspan} = $self->{colspan}+1;
    if($self->{pagination}){
	#Get total rows
	my $sSQL = "SELECT count(*) AS total FROM " . $self->{sql}{from};
	$sSQL .= " WHERE    " . $self->{sql}{where}    if $self->{sql}{where};
	my $total = $self->{dbh}->selectrow_hashref($sSQL,{},@{$self->{sql}{params}});
	$self->{total_records} = $total->{total} || 0;
	my $pages = ($total->{total} / $self->{sql}{limit});
	my $pages_int = int($pages);
	$pages = $pages_int + 1 if($pages > $pages_int);
	my $pagination = $self->{labels}{page_of};
	my $page = param("cg_page") || 1;
	$pagination =~ s/_PAGE_/$page/;
	$pagination =~ s/_OF_/$pages/;
	$pagination .= "";
	if(param("cg_page") > 1){
	    $pagination .= "<li>" .a({-href => $self->{script} . "?cg_page=" . (param("cg_page")-1) . "&cg_order=" . param("cg_order") . "&cg_side=" . param("cg_side") . "&cg_list=" . $self->{name} . $self->{transit_params}, -alt=>'Previous'},
				     $self->{labels}{previous_page}) . "</li>";
	    foreach(my $ii = $self->{nav_pages} -1;$ii > 0;$ii--){
		$pagination .= "<li>" .a({-href => $self->{script} . "?cg_page=" . (param("cg_page") - $ii) . "&cg_order=" . param("cg_order") . "&cg_side=" . param("cg_side") . "&cg_list=" . $self->{name} . $self->{transit_params}},
					 (param("cg_page") - $ii)).'</li>' if((param("cg_page") - $ii) > 0);
	    }
	}
	$pagination .= '<li class="active"><a href="#">'.param('cg_page').'</a></li>' if($pages > 1);
	if(param("cg_page") < $pages){
	    foreach(my $ii = 1;$ii < $self->{nav_pages};$ii++){
		last if($ii >= $pages);
		$pagination .= "<li>" .a({-href => $self->{script} . "?cg_page=" . (param("cg_page") + $ii) . "&cg_order=" . param("cg_order") . "&cg_side=" . param("cg_side") . "&cg_list=" . $self->{name} . $self->{transit_params}},
					 (param("cg_page") + $ii)) if((param("cg_page") + $ii) <= $pages).'</li>';
	    }
	    $pagination .= "<li>" .a({-href => $self->{script} . "?cg_page=" . (param("cg_page") +1) . "&cg_order=" . param("cg_order") . "&cg_side=" . param("cg_side") . "&cg_list=" . $self->{name} . $self->{transit_params},-alt=>"Next"},$self->{labels}{next_page}).'</li>';
	}
	
	if($self->{display_rows_total}){
	    my $rows = $self->{labels}{number_of_rows};
	    $rows =~ s/_NUMBER_/$self->{rows}/g;
	    
	    $HTML .= "    " . Tr ({},td($self->{foother}{params},
					'<div class="badge pull-left">' . $rows . '</div>' .
					'<div class="pagination pull-right"><ul>' . $pagination . '</ul></div>'
					)) . "\n";
	}
    }else{
	$self->{total_records} = $self->{rows};
		if($self->{display_rows_total}){
			my $rows = $self->{labels}{number_of_rows};
			$rows =~ s/_NUMBER_/$self->{rows}/g;
			
			$HTML .= "    " . Tr ({},td($self->{foother}{params},
						    '<span class="cg_number_rows">' . $rows . '</span>'
					      )) . "\n";
		}
    }
    return $HTML;
}
	
sub row_format {
    my $self = shift;
    my %params = @_;
    push(@{$self->{row_format}{$params{name}}},{'params' => $params{params},condition => $params{condition}});
}

sub cell_format {
    my $self = shift;
    my %params = @_;
    push(@{$self->{cell_format}{$params{name}}},{'params' => $params{params},condition => $params{condition}});
}

sub group {
    my $self = shift;
    my %params = @_;
    push(@{$self->{groups}},{'key' => $params{key},fields => $params{fields}});
    foreach my $field(@{$params{fields}}){
		push(@{$self->{group_fields_array}},$field);
		$self->{group_fields_hash}{$field} = 1;
    }

    if($self->{sql}{order_by}){
		$self->{sql}{order_by} = ($params{order_by} || $params{key}) . ", $self->{sql}{order_by}";
    }else{
		$self->{sql}{order_by} = "$params{order_by}" || $params{key};
    }
}

sub columns_width {
    my $self = shift;
    $self->{columns_width} = shift;
}

sub columns_align {
    my $self = shift;
    $self->{columns_align} = shift;
}

sub columns_headers_align {
    my $self = shift;
    $self->{columns_headers_align} = shift;
}

sub print_group_columns {
    my $self = shift;
    my @labels;
    foreach my $field(@{$self->{group_fields_array}}){
	my $col_label = $field;
	if($self->{custom_labels}->{$field}){
	    $col_label = $self->{custom_labels}->{$field};
	}else{
	    $col_label =~ s/_/ /g;
	    $col_label = ucfirst($col_label);
	}
	push(@labels,$col_label);
    }
    return "   " . Tr ($self->{columns}{params},[th($self->{group_th}{params},\@labels)]) . "\n";
}

sub print_group_item {
    my $self = shift;
    my $rec = shift;
    my @data;
    foreach my $key (@{$self->{group_fields_array}}){
	push(@data,$rec->{$key});
    }
    return "   " . Tr ($self->{columns}{params},[td($self->{group_td}{params},\@data)]) . "\n";
}

sub print_group_detail {
    my $self = shift;
    my $HTML = "";

    $self->{rows} = 0;
    my $group = undef;
    $self->get_detail_columns();
    foreach my $rec(@{$self->{rs}}) {
		#Group items
		if($group ne $rec->{$self->{groups}[0]{key}}){
			if($group ne undef){
				$HTML .= $self->print_group_item_totals($self->{groups}[0]{key},$group);
				$HTML .= "</table>\n";
				$HTML .= "    </td>\n  </tr>\n";
			}
			$group = $rec->{$self->{groups}[0]{key}};
			$HTML .= $self->print_group_item($rec);
			$HTML .= "  <tr>\n    <td colspan=" . scalar(@{$self->{group_fields_array}}) . ">\n";
			$self->{table}{class} = "cg_detail_table";
			$HTML .= start_table($self->{table}) . "\n";
			$HTML .= $self->print_detail_columns();
		}
		
		$self->{rows} ++;
		my @fields;
		my $row_cells = "";
		my $row_params = "params_b";
		my $row_html_params = 0;
		$row_params = "params_a" if (($self->{rows}/2) - int($self->{rows}/2));
		foreach my $i(0 .. (($self->{colspan})- scalar(@{$self->{group_fields_array}}))) {
			if(defined $self->{columns_align}){
				$self->{detail}{td}{params}{align} = $self->{columns_align}[$i];
			}
			if(defined $self->{cell_format}{$self->{columns}{names}[$i]}){
				#Cell Formats
				my $cell_params = $self->{detail}{td}{params};
				foreach my $cell_format(@{$self->{cell_format}{$self->{columns}{names}[$i]}}){
					my $check = 0;
					my $condition = $cell_format->{condition};
					$condition =~ s/%%/$rec->{$self->{columns}{names}[$i]}/g;
					$condition =~/([\S\s]+)\s(\S+)\s([\S\s]+)/;
					my $untained_condition = " $1 $2 $3" || "";
					eval '$check = 1 if(' . $untained_condition . ');';
					if( $check ){
						$cell_params = $cell_format->{params};
					}
				}
				$row_cells .= td($cell_params,$rec->{$self->{columns}{names}[$i]});
			}else{
				#Normal cell
				$row_cells .= td($self->{detail}{td}{params},$rec->{$self->{columns}{names}[$i]});
			}
			if(defined $self->{row_format}{$self->{columns}{names}[$i]}){
				# 		#Row Format
				foreach my $row_format(@{$self->{row_format}{$self->{columns}{names}[$i]}}){
					my $check = 0;
					my $condition = $row_format->{condition};
					$condition =~ s/%%/$rec->{$self->{columns}{names}[$i]}/g;
					$condition =~/([\S\s]+)\s(\S+)\s([\S\s]+)/;
					my $untained_condition = " $1 $2 $3" || "";
					eval '$check = 1 if(' . $untained_condition . ');';
					if( $check ){
						$row_params = $self->{columns}{names}[$i];
						$self->{detail}{Tr}{$row_params} = $row_format->{params};
						$row_html_params = 1;
					}
				}
			}
		}
		
		
		# #Links
		if($self->{link}){
			if($self->{link}{target}){
				$self->{detail}{Tr}{$row_params}{$self->{link}{event}} = "window.open('" . $self->{link}{location} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$self->{transit_params}','" . $self->{key}{target} . "','" . $self->{nw_params} . "');";
			}elsif($self->{opener}){
				my $opener_transit_params = $self->{transit_params};
				$opener_transit_params =~ s/opener=[\w]*//g;
				$self->{detail}{Tr}{$row_params}{$self->{link}{event}} = "opener.location.href='" . $self->{opener} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$opener_transit_params'; window.close();";
			}elsif($self->{link}{location}){
				$self->{detail}{Tr}{$row_params}{$self->{link}{event}} = "document.location.href='" . $self->{link}{location} . "?" . $self->{link}{key} . "=" . $rec->{$self->{link}{key}} . "$self->{transit_params}';";
			}
		}
		$HTML .= "   " . Tr ($self->{detail}{Tr}{$row_params},$row_cells) . "\n";
	}
    if($HTML){
		$HTML .= $self->print_group_item_totals($self->{groups}[0]{key},$group);
		$HTML .= "</table>\n";
		$HTML .= "    </td>\n  </tr>\n";
    }
    return $HTML;
}
	
sub print_detail_columns {
    my $self = shift;
    if (defined $self->{columns_width} or defined $self->{columns_headers_align}){
	my $HTML = "";
	my $it = 0;
	foreach my $label (@{$self->{columns}{labels}}){
	    $self->{detail_th}{params}{width} = $self->{columns_width}[$it] if(defined $self->{columns_width}[$it]);
	    $self->{detail_th}{params}{align} = $self->{columns_headers_align}[$it] if(defined $self->{columns_headers_align}[$it]);
	    $HTML .= th($self->{detail_th}{params},$label) . "\n";
	    $it++;
	}
	return "   " . Tr ($self->{columns}{params},$HTML);
    };
    return "   " . Tr ($self->{columns}{params},[th($self->{detail_th}{params},$self->{columns}{labels})]) . "\n";
}

sub get_detail_columns {
    my $self = shift;
    $self->{columns}{names} = ();
    $self->{columns}{labels} = ();
    $self->{colspan} = ($self->{sth}->{NUM_OF_FIELDS});
    foreach my $i(0 .. ($self->{colspan} - 1)) {
		defined $self->{sth}->{NAME}->[$i] or $self->{sth}->{NAME}->[$i] = "";
		if ($self->{sth}->{NAME}->[$i] and !($self->{link}{hidde_key_col} and $self->{sth}->{NAME}->[$i] eq $self->{link}{key}) and !$self->{group_fields_hash}{$self->{sth}->{NAME}->[$i]}){
			
			push(@{$self->{columns}{names}},$self->{sth}->{NAME}->[$i]);
			my $col_label = $self->{sth}->{NAME}->[$i];
			$col_label =~ s/_/ /g;
			$col_label = ucfirst($col_label);
			
			#Auto order Links
			my $side = 0;
			$side = 1 if (!param("cg_side"));
			if($self->{auto_order}){
				if(($i+1) eq param("cg_order")){
					if(param("cg_side") eq "0"){
						$col_label = a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=1&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
					}elsif(param("cg_side") eq "1"){
						$col_label = a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=0&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
					}
				}else{
					$col_label = a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=1&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$col_label);
#					$col_label .= a({href=>$self->{script} . "?cg_order=".($i+1)."&cg_side=0&cg_page=" . param("cg_page") . "&cg_list=" . $self->{name} . $self->{transit_params}},$self->{labels}{link_down});
				}
			}
			push(@{$self->{columns}{labels}},$col_label);
		}
    }
    $self->{colspan} -= 1 if($self->{link}{hidde_key_col});
}

sub total {
    my $self = shift;
    my %params = @_;
    $self->{totals}{$params{key}} = {type => $params{type},operation=>$params{operation},label=>$params{label},format=>$params{format},nearest=>$params{nearest}};
}

sub group_total {
    my $self = shift;
    my %params = @_;
    $self->{group_totals}{$params{key}} = {type => $params{type},operation=>$params{operation},label=>$params{label},format=>$params{format}};
}

sub print_totals {
    my $self = shift;
    my $HTML = "";
    my @totals;

    foreach my $i(0 .. (($self->{colspan} - 1))) {
	if(!(defined $self->{totals}{$self->{columns}{names}[$i]})){
	    push(@totals,"");
	    next;
	}
	#Operaciones
	my $total = "";
	if(defined $self->{totals}{$self->{columns}{names}[$i]}{operation}){
	    if($self->{totals}{$self->{columns}{names}[$i]}{operation} eq "SUM"){
			$total = $self->SUM($self->{columns}{names}[$i]);
	    }elsif($self->{totals}{$self->{columns}{names}[$i]}{operation} eq "AVG"){
			$total = $self->AVG($self->{columns}{names}[$i], ($self->{totals}{$self->{columns}{names}[$i]}{nearest} || ""));
	    }elsif($self->{totals}{$self->{columns}{names}[$i]}{operation} eq "COUNT"){
			$total = $self->COUNT($self->{columns}{names}[$i]);
	    }
	}

	#Formatos
	if(defined $self->{totals}{$self->{columns}{names}[$i]}{format} and $self->{totals}{$self->{columns}{names}[$i]}{format} eq "price"){
	    use Number::Format;
	    my $NF = Number::Format->new(%{$self->{Number_Format}});
	    $total = $NF->format_price($total);
	}

	if($self->{totals}{$self->{columns}{names}[$i]}{label}){
	    my $total_label = $total;
	    $total = $self->{totals}{$self->{columns}{names}[$i]}{label};
	    $total =~ s/%%/$total_label/g;
	}
	push(@totals,$total);
    }

    return "   " . Tr ($self->{totals}{Tr}{params},[td($self->{totals}{td}{params},\@totals)]) . "\n" if($totals[0]);
}

sub print_group_totals {
    my $self = shift;
    my $HTML = "";
    my @totals;

    foreach my $i(0 .. (($self->{colspan} - 1))) {
	if(!(defined $self->{totals}{$self->{columns}{names}[$i]})){
	    next;
	}
	#Operaciones
	my $total = "";
	if(defined $self->{totals}{$self->{columns}{names}[$i]}{operation}){
	    if($self->{totals}{$self->{columns}{names}[$i]}{operation} eq "SUM"){
			$total = $self->SUM($self->{columns}{names}[$i]);
	    }elsif($self->{totals}{$self->{columns}{names}[$i]}{operation} eq "AVG"){
			$total = $self->AVG($self->{columns}{names}[$i], ($self->{totals}{$self->{columns}{names}[$i]}{nearest} || ""));
	    }elsif($self->{totals}{$self->{columns}{names}[$i]}{operation} eq "COUNT"){
			$total = $self->COUNT($self->{columns}{names}[$i]);
	    }
	}

	#Formatos
	if($self->{totals}{$self->{columns}{names}[$i]}{format} eq "price"){
	    use Number::Format;
	    my $NF = Number::Format->new(%{$self->{Number_Format}});
	    $total = $NF->format_price($total);
	}

	if($self->{totals}{$self->{columns}{names}[$i]}{label}){
	    my $total_label = $total;
	    $total = $self->{totals}{$self->{columns}{names}[$i]}{label};
	    $total =~ s/%%/$total_label/g;
	}
	push(@totals,$total);
    }

    return "   " . Tr ({},td({colspan=>scalar(@{$self->{group_fields_array}})},
			     '<table width="100%">' .
			     Tr ($self->{totals}{Tr}{params},[td($self->{totals}{td}{params},\@totals)]) . "\n" .
			     '</table>'
			    )) . "\n";
}

sub print_group_item_totals {
    my $self = shift;
    my $field = shift;
    my $field_value = shift;
    my $totals = "";
    foreach my $i(0 .. (($self->{colspan})- scalar(@{$self->{group_fields_array}}))) {
#	if(!(defined $self->{group_totals}{$self->{columns}{names}[$i]})){
#	    $totals .= '<td></td>';
#	    next;
#	}
	#Operaciones
	my $total = "";
	if(defined $self->{group_totals}{$self->{columns}{names}[$i]}{operation}){
	    if($self->{group_totals}{$self->{columns}{names}[$i]}{operation} eq "SUM"){
		$total = $self->group_SUM($self->{columns}{names}[$i],$field,$field_value);
	    }elsif($self->{group_totals}{$self->{columns}{names}[$i]}{operation} eq "AVG"){
		$total = $self->group_AVG($self->{columns}{names}[$i],$field,$field_value);
	    }elsif($self->{group_totals}{$self->{columns}{names}[$i]}{operation} eq "COUNT"){
		$total = $self->group_COUNT($self->{columns}{names}[$i],$field,$field_value);
	    }
	}

	#Formatos
	if($self->{group_totals}{$self->{columns}{names}[$i]}{format} eq "price"){
	    use Number::Format;
	    my $NF = Number::Format->new(%{$self->{Number_Format}});
	    $total = $NF->format_price($total);
	}

	if($self->{group_totals}{$self->{columns}{names}[$i]}{label}){
	    my $total_label = $total;
	    $total = $self->{group_totals}{$self->{columns}{names}[$i]}{label};
	    $total =~ s/%%/$total_label/g;
	}
	if(defined $self->{columns_align}){
	    $self->{group_item_totals}{td}{params}{align} = $self->{columns_align}[$i];
	    $totals .= td($self->{group_item_totals}{td}{params},$total);
	}else{
	    $totals .= td($self->{group_item_totals}{td}{params},$total);
	}
    }
    return "   " . Tr ($self->{group_item_totals}{Tr}{params},$totals) . "\n";
}

sub SUM {
    my $self = shift;
    my $field = shift || "";
    return 0 if(!$field);
    my $total = 0;
    foreach my $rec(@{$self->{rs}}) {
		$rec->{$field} = 0 if($rec->{$field} eq "-");
		$total += $rec->{$field};
    }
    return $total;
}

sub group_SUM {
    my $self = shift;
    my $field = shift || "";
    my $filter = shift;
    my $filter_value = shift;
    return 0 if(!$field);
    my $total = 0;
    foreach my $rec(@{$self->{rs}}) {
		next if($rec->{$filter} ne $filter_value);
		$total += $rec->{$field};
    }
    return $total;
}

sub COUNT {
    my $self = shift;
    my $field = shift || "";
    return 0 if(!$field);
    return scalar( @{$self->{rs}});
}

sub group_COUNT {
    my $self = shift;
    my $field = shift || "";
    my $filter = shift;
    my $filter_value = shift;
    return 0 if(!$field);
    my $total = 0;
    foreach my $rec(@{$self->{rs}}) {
		next if($rec->{$filter} ne $filter_value);
		$total += 1;
    }
    return $total;
}

sub AVG {
    my $self = shift;
    my $field = shift || "";
	my $nearest = shift || '.01';
    return 0 if(!$field);
    my $avg = 0;
    my $it = 0;
	
    foreach my $rec(@{$self->{rs}}) {
		$it++;
		$avg += $rec->{$field};
    }

    eval {
		$avg = $avg / $it; 
    };

    if($@){
		$avg = "";
    }

    $avg = nearest($nearest,$avg);
    return $avg;
}

sub group_AVG {
    my $self = shift;
    my $field = shift || "";
    my $filter = shift;
    my $filter_value = shift;
    return 0 if(!$field);
    my $avg = 0;
    my $it = 0;

    foreach my $rec(@{$self->{rs}}) {
		next if($rec->{$filter} ne $filter_value);
		$it++;
		$avg += $rec->{$field};
    }

    eval {
		$avg = $avg / $it; 
    };

    if($@){
		$avg = "";
    }

    $avg = nearest(.01,$avg);
    return $avg;
}

sub headers_groups {
    my $self = shift;
    $self->{headers_groups} = shift;
}

sub orders {
    my $self = shift;
    $self->{orders} = shift;
    if($self->{orders}->{param("cg_order")}){
	$self->{sql}{order_by} = $self->{orders}->{param("cg_order")};
	$self->{sql}{order_by} .= " DESC  " if (param("cg_side"));
	$self->{sql}{order_by} .= " ASC  " if (!param("cg_side"));
    }
}

sub auto_order_switch {
    my $self = shift;
    $self->{auto_order_switch} = shift;
	if(int($self->{sql}{order_by}) > 0){
		if(param('cg_order') > scalar(@{$self->{auto_order_switch}})){
			param(-name=>'cg_order',-value=>'');
			$self->{sql}->{order_by} = '';
		}
	}
}

sub second_row {
    my $self = shift;
    $self->{second_row} = shift;
}

sub table_head {
  my $self = shift;
  my $HTML = shift;
  $self->{table_head} .= $HTML;
}

sub after_columns_names {
  my $self = shift;
  my $HTML = shift;
  $self->{after_columns_names} .= $HTML;
}

sub table_footer {
    my $self = shift;
    my $HTML = shift;
    $self->{table_footer} .= $HTML;
}

sub below_pagination {
    my $self = shift;
    my $HTML = shift;
    $self->{below_pagination} .= $HTML;
}

sub set_label {
    my $self = shift;
    my $field = shift;
    my $label = shift;
    $self->{custom_labels}->{$field} = $label;
}

sub hidde_column {
    my $self = shift;
    my $field = shift;
    $self->{hidde_column} = $field;
}

sub sn {
    my $self = shift;
    my $field = shift;
    my $start_on = shift;
    if(!$start_on){
	$start_on = (param('cg_page') - 1) * $self->{sql}->{limit}
    }
    $self->{sn} = {field=>$field,start_on=>$start_on};
}


=head1 SYNOPSIS

Easily create html lists whit auto order, auto pagination, grouping and conditional formats.
 
Perhaps a little code snippet.

    use Chapix::List;

    #We need a DBH Handle
    $dbh = DBI->connect(.....);

    #Create List Object
    $list = Chapix::List->new(
	dbh => $dbh,
        sql => {
            select => "foo, bar ",
            from => "table1",
            limit => "20",
            where => "some_column1=? AND some_column2=?",
            params=>["Value1","Value2"],
            order_by => "foo DESC",
       },
    );

    #Print 
    print $list->print();

=head1 FEATURES

    * Auto Order
    * Auto Pagination
    * CSS based. Contact developer for CSS examples 
    * Column totals(Only SUM, COUNT and AVG are supported)
    * Conditional formats for rows
    * Conditional Formats for cells
    * Auto detect column names
    * 2 row formats for better visualization
    * Row grouping
    * Http Link and highlight on rows based in rows keys
    * Opener action for pop up windows
    * And more

=head1 METHODS

=head2 new()

This method creates a new $list object, which you then use to generate and process your list.

    my $list = Chapix::List->new();

	The following is a description of each option, in alphabetical order:

	name => 'list_name'
            If you use a multi lists pages you need to specify a name for each list
	on_errors => 'print',
	    If you have SQL errors you can print(default), warn or die
        debug => 0 | 1, default 0
            If is set to 1 this print the query executed on SQL errors
	caption => 'list title'
	    This create a list title with the caption html tag
	auto_order => 1 | 0,   default 1
	    Enable, disable auto order mechanism on the list
	pagination => 1 | 0, default 1
	    Enable or disable auto pagination on the list
	nav_pages => $number, default 4
	    Number of pages you can see on pagination
        Number_Format => {THOUSANDS_SEP=>",",DECIMAL_POINT=>".",MON_THOUSANDS_SEP=>",","MON_DECIMAL_POINT"=>".","INT_CURR_SYMBOL"=>'$'};
            On SUM otions you can format the result to price ($1,234.00), whit this parameters THOUSANDS_SEP, DECIMAL_POINT, MON_THOUSANDS_SEP, MON_DECIMAL_POINT, INT_CURR_SYMBOL.

        table => {}
            Propiedades de la tabla, default {width => "100%",class => "cg_table",align => "center",cellpadding=>"0",cellspacing=>"0"}
        labels => {
		       page_of => 'Page _PAGE_ of _OF_',
		       no_data   => 'No records found',
		       link_up   => '&uarr;',
		       link_down => '&darr;',
		       next_page => '&raquo;',
		       previous_page => '&laquo;',
		       number_of_rows => "_NUMBER_ rows",
		      };
            This are the text printed on the list, you can traslate to other language



=head2 print()

This function renders the list into HTML, and returns a string containing the list.

    print $list->print;

=head2 group()

This method Create groups of data:

    $list->group(key=>'key_field',fields=>[qw/key_field other_field other_field/]);

=head2 group_total()

This method calculate row totals on each group:

    $list->group_total(key=>'key_field',type=>"MATH",operation=>'SUM',label=>"%% some text",format=>'price');
Operation support only SUM, AVG, and COUNT, the format parameter are optional

=head2 total()

This method calculate row totals:

    $list->total(key=>'key_field',type=>"MATH",operation=>'SUM',label=>"%% some text",format=>'price');
Operation suport only SUM, AVG, and COUNT, the format parameter are optional

=head2 row_format()

This function specify a format of row depending on their value

    $list->row_format(name=>"field_name",condition=>"'%%' eq 'urgent'",params=>{class=>"cg_row_urgent"});

%% is the cell value, on this example you need to create 2 css class cg_row_urgent and cg_row_urgent_hover 
for the hover action
	
=head2 cell_format();

This function specify a format of cell depending on their value

    $list->cell_format(name=>"field_name",condition=>"'%%' eq 'urgent'",params=>{class=>"cg_cell_urgent"});

%% is the cell value, on this example you need to create 2 css class cg_cell_urgent and cg_cell_urgent_hover 
for the hover action

=head2 columns_width()

This function specify the width of each column

    $list->columns_width(["100","200","300"]);

On this example you have a 3 columns query and 100, 200, 300 are the width of each column

=head2 columns_align()

This function specify the horizontal align of each column

    $list->columns_align(["left","center","right"]);

On this example you have a 3 columns query and left, center, right are the alignment of each column data

=head2 columns_headers_align()

This function specify the horizontal align of each column header

    $list->columns_headers_align(["left","center","right"]);

On this example you have a 3 columns query and left, center, right are the alignment of each column header data
 
=head1 Examples

This example provides an list of data with auto order, auto pagination and action on each row click

    my $list = Chapix::List->new( 
                  dbh => $dbh,
                  name => "pays_list",
                  sql => {
                      select => "p.pay_id, p.date, pr.name, " .
                          "IF(p.is_cancel,'Cancel','Active') AS 'status'",
                      from => "pays p INNER JOIN partners pr ON p.pay_id=pr.pay_id ",
                      limit => "20",
                      where => "some_column=? AND some_column=?",
                      params=>["Value1","Value2"],
                      order_by => "p.date DESC",
                     },
                  link => {
                       key => "pay_id",
                       hidde_key_col => 1,
                       location => "pays.pl",
                       transit_params => {some_param_to_be_present_everywere=>"value"},
                      },
                 );
	$list->print();


=head1 AUTHOR

David Romero Garcia, C<< <romdav at gmail.com> >>

=head1 COLABORATORS

Juan C. Sanchez-DelBarrio

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-list at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-List>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Chapix::List

You can also look for information at:

L<http://www.cgi-list.com>.
L<http://groups.google.com/group/cgilist>.

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-List>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-List>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-List>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-List>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 David Romero García, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Chapix::List
