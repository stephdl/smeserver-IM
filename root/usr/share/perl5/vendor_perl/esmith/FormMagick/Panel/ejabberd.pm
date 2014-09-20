#!/usr/bin/perl -w 

package esmith::FormMagick::Panel::ejabberd;

use strict;

use esmith::FormMagick;
use esmith::ConfigDB;
use esmith::AccountsDB;
use esmith::cgi;
use File::Basename;
use Exporter;
use Carp;

our @ISA = qw(esmith::FormMagick Exporter);

our @EXPORT = qw(

  show_initial
  get_ejabberd_access
  get_exception_list
  get_cgi_param
  print_gateways
);

our $db = esmith::ConfigDB->open() || die "Couldn't open config db";
our $ejdb = esmith::ConfigDB->open('im') ||
            esmith::ConfigDB->create('im');
our $adb = esmith::AccountsDB->open_ro() || die "Couldn't open AccountsDB";

our @transports = qw/Msn/;

our $VERSION = sprintf '%d.%03d', q$Revision: 2.00 $ =~ /: (\d+).(\d+)/;


=pod 

=head1 NAME

esmith::FormMagick::Panels::ejabberd - useful panel functions

=head1 SYNOPSIS

    use esmith::FormMagick::Panels::ejabberd;

    my $panel = esmith::FormMagick::Panel::ejabberd->new();
    $panel->display();

=head1 DESCRIPTION

=cut


=head2 new();

Exactly as for esmith::FormMagick

=begin testing

$ENV{ESMITH_DOMAINS_DB} = "10e-smith-base/domains.conf";
$ENV{ESMITH_CONFIG_DB} = "10e-smith-base/configuration.conf";

use_ok('esmith::FormMagick::Panel::ejabberd');
use vars qw($panel);
ok($panel = esmith::FormMagick::Panel::ejabberd->new(), "Create panel object");
isa_ok($panel, 'esmith::FormMagick::Panel::ejabberd');

=end testing

=cut

sub new {
    shift;
    my $self = esmith::FormMagick->new();
    $self->{calling_package} = (caller)[0];
    bless $self;
    return $self;
}


=head1 ACCESSORS

=head2 get_cgi_param FM FIELD

Returns the named CGI parameter as a string

=cut

sub get_cgi_param {
    my $fm    = shift;
    my $param = shift;

    return ( $fm->{'cgi'}->param($param) );
}


=head2 get_prop ITEM PROP

A simple accessor for esmith::ConfigDB::Record::prop

=cut

sub get_prop {
  my ($self, $item, $prop) = @_;
  warn "You must specify a record key"    unless $item;
  warn "You must specify a property name" unless $prop;
  my $record = $db->get($item) or warn "Couldn't get record for $item";
  return $record ? $record->prop($prop) : undef;
}

=head2 get_value ITEM

A simple accessor for esmith::ConfigDB::Record::value

=cut

sub get_value {
  my $self = shift;
  my $item = shift;
  return ($db->get($item)->value());
}

=head2 get_ejabberd_access

Returns "public", "private" or "off" depending on the 'access' and 'status' properties
of the "ejabberd" config file variable

=cut

sub get_ejabberd_access {

  my ($self) = @_;
  my $status = get_prop($self,'ejabberd','status');
  if ( (defined $status) && ($status eq 'enabled')) {
    my $access = get_prop($self,'ejabberd','access');
    return $access ? $access : 'off';
  }
  else {
    return('off');
  }
}

=head2 get_exception_list

return the list of already defined exceptions

=cut

sub get_exception_list
{   
    my ($self) = @_;
    my $q = $self->{cgi};

    my $rec = $ejdb->get('exception') ||
              $ejdb->new_record('exception', {type=>'list'});
    my %rules = $rec->props;
    my @exceptions = ();
    while (my ($parameter,$value) = each(%rules)) {
        next if ($parameter eq "type");

        if ($value eq "User") {
            $parameter =~ s/\\\\40/%/;
            push (@exceptions,$parameter);
        }
    }
    return join("\n", @exceptions);
}

=head1 ACTION


=head2 change_settings

If everything has been validated, properly, go ahead and set the new settings

=cut


sub change_settings {
    my ($self) = @_;

    my %conf;

    my $q = $self->{'cgi'};

    # Don't process the form unless we clicked the Save button. The event is
    # called even if we chose the Remove link or the Add link.
    return unless($q->param('Next') eq $self->localise('SAVE'));

    my $access = $q->param ('access') || 'off';
    my $webadmin = $q->param('webadmin') || 'disabled';
    my @gateways = $q->param('transports') || ();
    my $roster = $q->param('shared_roster') || 'disabled';
    my $filter = $q->param('default_filter') || 'allow';
    my $log = $q->param('log') || 'none';
    my $exceptions = ($q->param('exception_list') || '');
    my @exceptions = split(/[\n\r]/, $exceptions);

    #------------------------------------------------------------
    # Looks good; go ahead and change the access.
    #------------------------------------------------------------

    my $rec = $db->get('ejabberd');
    if($rec)
    {
    	if ($access eq "off")
    	{
	    $rec->set_prop('status','disabled');
    	}
    	else
      	{
	    $rec->set_prop('status','enabled');
	    $rec->set_prop('access', $access);
      	}
    }

    $rec->set_prop('FilterDefault', $filter);
    $rec->set_prop('AllowedGroups', join(',',$q->param('allowedGroups')));
    $rec->set_prop('SharedRoster', $roster);

    $rec = $db->get('spectrum');

    if ($rec){
        foreach my $proto (@transports){
            if (grep ($proto, @gateways)){
                $rec->set_prop("$proto",'enabled');
            }
            else{
                $rec->set_prop("$proto",'disabled');
            }
        }
    }

    $rec = $ejdb->get('exception');

    my %list = $rec->props;
    while (my ($parameter,$value) = each(%list)) {
        if ($parameter eq "type") {next;}

        if ($value eq "User") {
            $ejdb->get_prop_and_delete('exception', "$parameter");
        }
    }

    foreach (@exceptions){
        $rec->set_prop($_, 'User');
    }

    $self->cgi->param(-name=>'wherenext', -value=>'First');

    unless ( system( "/sbin/e-smith/signal-event", "ejabberd-update" ) == 0 )
    {
        $self->error('ERROR_UPDATING');
        return undef;
    }

    $self->success('SUCCESS');
}

=head2 print_gateways

This method print status of the available gateways

=cut

sub print_gateways
{
    my ($self) = @_;
    my $q = $self->{cgi};

    my $spectrum = $db->get('spectrum') || return undef;

    print "<tr><td class=\"sme-noborders-label\">",
        $self->localise('LABEL_GATEWAYS'),
        "</td><td>\n";

    print $q->start_table({-class => "sme-border"}),"\n";
    print $q->Tr(
            esmith::cgi::genSmallCell($q, $self->localise('PROTOCOL'),"header"),
            esmith::cgi::genSmallCell($q, $self->localise('STATUS'),"header"),
        );

    foreach my $proto (@transports){
        my $status = $spectrum->prop($proto) || 'disabled';
        my $checked = ($status eq 'enabled') ? 'checked' : '';
        print $q->Tr(
                esmith::cgi::genSmallCell($q, $proto,"normal"),
                $q->td(
                    "<input type=\"checkbox\""
                    . " name=\"transports\""
                    . " $checked value=\"$self->localise($proto)\">"
                )
            );
    }
    print "</table></td></tr>\n";

    return undef;
}

=head2 print_allowed_groups

This method print a matrix of allowed groups

=cut
sub print_allowed_groups(){
    my ($self) = @_;
    my $q = $self->{cgi};

    my @allowedGroups = split(/[,;]/, (get_prop($self, 'ejabberd', 'AllowedGroups')));

    if (my @groups = $adb->groups()) {

        print "<tr><td class=\"sme-noborders-label\">",
        $self->localise('ALLOWED_GROUPS'),
        "</td><td>\n";

        print $q->start_table({-class => "sme-border"}),"\n";
        print $q->Tr(
            esmith::cgi::genSmallCell($q, $self->localise('ALLOWED_OR_NOT'),"header"),
            esmith::cgi::genSmallCell($q, $self->localise('GROUP'),"header"),
            esmith::cgi::genSmallCell($q, $self->localise('DESCRIPTION'),"header")
        );

        foreach my $g (@groups) {
            my $groupname = $g->key();
            my $checked;
            if (grep { $groupname eq $_ } @allowedGroups) {
                $checked = 'checked';
            } else {
                $checked = '';
            }

            print $q->Tr(
                $q->td(
                    "<input type=\"checkbox\""
                    . " name=\"allowedGroups\""
                    . " $checked value=\"$groupname\">"
                ),
                esmith::cgi::genSmallCell($q, $groupname,"normal"),
                esmith::cgi::genSmallCell( $q, $adb->get($groupname)->prop("Description"),"normal")
            );
        }

        print "</table></td></tr>\n";

    }

    return undef;

}

1;
