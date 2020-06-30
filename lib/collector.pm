# vim: set fileencoding=utf-8 sw=4 ts=4 et :
################################################################################
## $Id$
##
## Collector :  Nagios script which collects informations from hosts
#               in one pass
## Copyright (C) 2005-2020 CS GROUP - France
##
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License
## as published by the Free Software Foundation; either version 2
## of the License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
################################################################################

=head1 Collector

=head2 Overview

This is a library intended to monitor hosts using SNMP.

Configuration files are of two kinds:

=over 2

=item Host configuration: gives a list of what to collect, what function to apply
to what data, what threshold to set, what Nagios passive services and RRD
to route results to

=item Function library: describes the logical processing of the results by
implementing several functions (that are referenced into the Host configuration
files.

=back

=head2 Host Configuration file example

  # This is an Host configuration file extract

  use strict;
  use warnings;
  package host;
  our %Host = (
      sup => {services => { },},
      IPAddress     => "127.0.0.1",
      hostname      => "localhost",
      snmp          => { port => 161, snmpOIDsPerPDU => 10, version => 2, communityString => 'public'},
      metro         => { DS => [ ] }
  );

  push @{$Host{metro}{DS}},{output => "root_partition", reRouteFor => undef, function => "m_table_mult", parameters => ['/'] , variables =>  ['WALK/.1.3.6.1.2.1.25.2.3.1.4', 'WALK/.1.3.6.1.2.1.25.2.3.1.6', 'WALK/.1.3.6.1.2.1.25.2.3.1.3']}; # / part
  p

  $Host{sup}{services}{"1 min Load"}={reRouteFor => undef, function => "simple_factor", parameters => [10, 20, 0.01, 'Load : %2.2f'] , variables => ['GET/.1.3.6.1.4.1.2021.10.1.5.1'] };


=head2 Functions file example

  # This is a Functions configuration extract

  package Functions;
  use strict;
  use warnings;
  use Data::Dumper;
  require Exporter;
  use vars qw(@ISA @EXPORT $VERSION);
  @ISA=qw(Exporter);
  @EXPORT= qw( %Functions %Primitive );
  $VERSION = 1.0;

  # These primitive are shared code that might be used by several
  # Functions

  our %Primitive = (
  "checkOIDVal"   => sub {
      # checks whether the value returned by an SNMP GET or WALKS seems correct
      my $val = shift;
      return 0 unless defined $val;
      return ($val =~ /noSuch(Object|Instance)|endOfMibView|NULL/ ? 0 : 1)
  },
  "isOutOfBounds" => sub {
      # checks if a value fits is out the "Nagios standard Threshold range"
      # see http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT
      my ($value,$st)=@_;
      my $inside=( ($st =~ /^@/) ? 1 : 0 );
      $st =~ s/^@//;
      $st=":" if ($st eq "");
      if ( $st =~ /:/)
      { # two limits have been given
          my ($low,$upp)=split(/:/,$st);
          return $inside if (! $low && ! $upp);
          return ($inside ? $value <= $upp : $value > $upp) ? 1 : 0 if ($low =~ /^~?$/);
          return ($inside ? $value >= $low : $value < $low) ? 1 : 0 if($upp eq "" );
          return -1 if($low>$upp);
          return( $inside ? ($value >= $low && $value <= $upp) : ($value > $upp || $value < $low) ) ? 1 : 0;
      }
      return ($value >= 0 && $value <= $st) ? 1 : 0 if $inside;
      return ($value < 0 || $value > $st) ? 1 : 0;
  },
  "thresholdIt" => sub {
      # checks the correctness of the given value, with the warn and crit thresholds
      # see http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT for thresholds syntax
      my ($value,$warnThresh,$critThresh,$caption,$Primitive)=@_;
      $caption=$caption || "%s";
      return("CRITICAL", sprintf("CRITICAL: $caption", $value))   if ($Primitive->{"isOutOfBounds"}->($value, $critThresh));
      return("WARNING",  sprintf("WARNING: $caption",   $value))  if ($Primitive->{"isOutOfBounds"}->($value, $warnThresh));
      return('OK',       sprintf("OK: $caption",       $value));
  },
  "lookupMultiple" => sub {
      # looks for a given pattern in an OID subtree
      # which is supposed to be one-level deep
      # pattern can be a portion of a regexp
      # returns the list of indexes matching
      my ($response,$where,$key)=@_;
      my @indexes;
      foreach my $OID (keys %{$response})
      {
          if ($OID =~ /^$where\./)
          {
              if ($response->{$OID} =~ /^${key}\000?$/)
              {
                  $OID =~ /\.(\d+)$/; # Got it
                  push @indexes,$1;
              }
          }
      }
      return @indexes;
  },
  );

  # This is the main hashmap that will be exported and used by Collector.
  our %Functions = (
  "simple_factor" => sub {
      my ($parameters, $variables, $response, $debug, $Primitive)=@_;

      my $OID         = (split('/',$variables->[0]))[1];
      my $warnThresh  = $parameters->[0];
      my $critThresh  = $parameters->[1];
      my $factor      = $parameters->[2];
      my $caption     = $parameters->[3] || "%s";

      my $value       = $response->{$OID};
      return ("UNKNOWN","UNKNOWN: OID $OID not found") unless $Primitive->{"checkOIDVal"}->($value);
      return $Primitive->{"thresholdIt"}->($value*$factor,$warnThresh,$critThresh,$caption, $Primitive);
  },
  "m_table_mult"      => sub {
      my ($parameters, $variables, $response, $debug, $Primitive)=@_;

      my $name    = $parameters->[0];
      my $val1OID     = (split('/',$variables->[0]))[1];
      my $val2OID     = (split('/',$variables->[1]))[1];
      my $descrOID    = (split('/',$variables->[2]))[1];

      # Get the indexes
      my @indexes = $Primitive->{"lookupMultiple"}->($response,$descrOID,$name);
      return ("UNKNOWN","U") if ($#indexes == -1);
      my $total=0;
      my $val1;
      my $val2;
      foreach my $index (@indexes)
      {
          $val1=$response->{"$val1OID.$index"};
          $val2=$response->{"$val2OID.$index"};
          return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($val1);
          return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($val2);
          $total += $val1 * $val2;
      }
      return ('OK', $total);
  }
  );
  1;

=cut

package collector;

use POSIX;
use strict;
use Nagios::Plugin qw(%ERRORS);
use Net::SNMP;
use Data::Dumper;

sub print_help();
sub usage();
sub supServicesHashRef;
sub snmpWalk($);
sub getOIDValues;
sub verifySNMPIdent;
sub check_conf;
sub load_libs($);
sub collect_host($);

require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA=qw(Exporter);
@EXPORT= qw( check_conf load_libs collect_host );
$VERSION = 1.0;

our ($lib, $path, $timeout, $nagios_cmd_file, $connector_socket, $tmppath);
our $debug = 0;
my $hostname;

my $state = "UNKNOWN";
my $answer = "";

my %snmpOIDs4Get;
my %snmpOIDs4Walk;
my @snmpOIDs4Get;
my @snmpOIDs4Walk;
my @snmpoids;
# Net::SNMP message size. Default is 1472, but it does not cope with big
# tables. We set it higher. References:
# http://search.cpan.org/~dtown/Net-SNMP-5.2.0/lib/Net/SNMP.pm
# http://nagios.manubulon.com/faq.html#FAQ9
# http://www.cpanforum.com/posts/848
my $maxmsgsize = 2000;
my ($session, $error, $response);

### subroutines


=head2 getAllOIDs

=head3 OverView

Builds up a list of all SNMP OIDs that will need to be gathered, either
by SNMP GETs or WALKs.

Uses the @snmpOIDs4Get and @snmpOIDs4Walk arrays to write the final lists

=head3 Arguments

None

=head3 Returns

None

=cut

sub getAllOIDs
{
    # get OIDs from services' sup
    foreach my $v_service (values %{&supServicesHashRef}) {
        for (my $i=0; $i <= $#{$v_service->{'variables'}}; $i++) {
            if ($v_service->{'variables'}->[$i] =~ /^(GET|WALK)\/((\.\d+)+)$/) {
                $snmpOIDs4Get{$2}++ if ($1 eq 'GET');
                $snmpOIDs4Walk{$2}++ if ($1 eq 'WALK') ;
            }
        }
    }
    # get OIDs from DS' metro
    my $hashRefTmp;
    for (my $i=0; $i <= $#{&metroDSArrayRef}; $i++) {
        $hashRefTmp = &metroDSArrayRef()->[$i]->{'variables'};
        for (my $j=0; $j<=$#{$hashRefTmp}; $j++) {
            if ($hashRefTmp->[$j] =~ /^(GET|WALK)\/((\.\d+)+)$/) {
                $snmpOIDs4Get{$2}++ if ($1 eq 'GET');
                $snmpOIDs4Walk{$2}++ if ($1 eq 'WALK') ;
            }
        }
    }
    # We put all oids in a HashMap before, because we want have only once each OID
    @snmpOIDs4Get = keys %snmpOIDs4Get;
    @snmpOIDs4Walk = keys %snmpOIDs4Walk;
}

=head2 verifySNMPIdent

=head3 Overview

Opens an SNMP session using the good protocol and credentials

Uses the $Host:Host hashref to know what kind of SNMP to use.

Stores the open session into $session global variable

=head3 Arguments

None

=head3 Returns

A list with ($state, $message).

=cut

sub verifySNMPIdent
{
    my %param = ('hostname', $host::Host{'IPAddress'},
                 'port'    , $host::Host{'snmp'}->{'port'},
                 'version' , $host::Host{'snmp'}->{'version'},
                 'domain',   'udp',
    );
    if ($host::Host{'snmp'}->{'version'} == 3) {
        # Must define a security level even though the default is noAuthNoPriv
        # v3 requires a security username
        if (defined $host::Host{'snmp'}->{'seclevel'}
            && defined $host::Host{'snmp'}->{'secname'}) {

            # Must define a security level even though the default is noAuthNoPriv
            unless ($host::Host{'snmp'}->{'seclevel'} =~ /^(noAuthNoPriv|authNoPriv|authPriv)$/ ) {
                return ("UNKNOWN", "Invalid value for 'seclevel': " . ($host::Host{'snmp'}->{'seclevel'}));
            }

            # Authentication wanted (MD5- or SHA1-based)
            if ($host::Host{'snmp'}->{'seclevel'} =~ /(authNoPriv|authPriv)/ ) {
                if (! defined $host::Host{'snmp'}->{'authproto'}) {
                    $host::Host{'snmp'}->{'authproto'} = "MD5";
                }else{
                    unless ($host::Host{'snmp'}->{'authproto'} =~ /(MD5|SHA)/i ) {
                        return ("UNKNOWN", "Invalid value for 'authproto': " . ($host::Host{'snmp'}->{'authproto'}));
                    }
                }

                if ( !defined $host::Host{'snmp'}->{'authpass'}) {
                    return ("UNKNOWN", "Missing value for 'authpass'");
                }else{
                    if ($host::Host{'snmp'}->{'authpass'} =~ /^0x/ ) {
                        $param{'authkey'} = $host::Host{'snmp'}->{'authpass'};
                    }else{
                        $param{'authpassword'} = $host::Host{'snmp'}->{'authpass'};
                    }
                }

            }

            # Privacy wanted (using DES or AES encryption)
            if ($host::Host{'snmp'}->{'seclevel'} eq  'authPriv' ) {
                if (! defined $host::Host{'snmp'}->{'privproto'}) {
                    $host::Host{'snmp'}->{'privproto'} = "DES";
                }else{
                    unless ($host::Host{'snmp'}->{'privproto'} =~ /(DES|AES|3DES)/i ) {
                        return ("UNKNOWN", "Invalid value for 'privproto': " . ($host::Host{'snmp'}->{'privproto'}));
                    }
                }

                if (! defined $host::Host{'snmp'}->{'privpass'}) {
                    return ("UNKNOWN", "Missing value for 'privpass'");
                }else{
                    if ($host::Host{'snmp'}->{'privpass'} =~ /^0x/){
                        $param{'privkey'} = $host::Host{'snmp'}->{'privpass'};
                    }else{
                        $param{'privpassword'} = $host::Host{'snmp'}->{'privpass'};
                    }
                }
            }

        } else {
            return ("UNKNOWN", "Missing value for 'seclevel' or 'secname'");
        }
    } # end snmpv3

    if ( $host::Host{'snmp'}->{'version'} =~ /[12]/ ) {
        $param{'community'} = $host::Host{'snmp'}->{'communityString'};
        $param{'maxmsgsize'} = $maxmsgsize;
    }elsif ( $host::Host{'snmp'}->{'version'} == 3 ) {
        $param{'username'} = $host::Host{'snmp'}->{'secname'};
        # Note: dans le cas
        # $host::Host{'snmp'}->{'seclevel'} eq 'noAuthNoPriv'
        # il n'y a rien de plus a configurer.
        if ( $host::Host{'snmp'}->{'seclevel'} eq 'authNoPriv' ) {
            $param{'authprotocol'} = $host::Host{'snmp'}->{'authproto'};
        }elsif ($host::Host{'snmp'}->{'seclevel'} eq 'authPriv' ) {
            $param{'authprotocol'} = $host::Host{'snmp'}->{'authproto'};
            $param{'privprotocol'} = $host::Host{'snmp'}->{'privproto'};
        }
    }else{
        return ("UNKNOWN", "UNKNOWN: No support for SNMP v".$host::Host{'snmp'}->{'version'}." yet");
    }

    if (defined($host::Host{'snmp'}->{'transport'})) {
        $param{'domain'} = $host::Host{'snmp'}->{'transport'};
    }

    # Cas des adresses IPv6.
    if ( $host::Host{'IPAddress'} =~ /:/ ) {
        $param{'domain'} .= '6';
    }

    ($session, $error) = Net::SNMP->session(%param);
    if (!defined($session)) {
        $state='UNKNOWN';
        $answer=$error;
        return ($state, "$state: $answer");
    }

    return ('OK', 'OK');
}

=head2 getOIDValues

=head3 OverView

Perform all SNMP gets and walk

Uses the $Host:Host global variable to use the SNMP version as defined into
the configuration file.

Uses @snmpOIDs4Get as a list of items to retrieve by using SNMP get/bulkget.

Uses @snmpOIDs4Walk as a list of items to retrieve by SNMP walking the MIB.

Uses $response to write results into.

=head3 Arguments

None

=head3 Returns

Returns a list with ($state, $message).

=cut

sub getOIDValues
{
    ## Get OIDs for SNMPGet
    my $responseGetOIDs = {};
    if (@snmpOIDs4Get) {
        my $OIDsPerPDU = &snmpOIDsPerPDU;
        my @snmpOIDs4GetTMP;
        my $responseGetOIDsTMP;
        my %args  = () ;
        if($host::Host{'snmp'}->{'version'} == 3 and defined ($host::Host{'snmp'}->{'context'})) {
            $args{'contextname'} = $host::Host{'snmp'}->{'context'};
        }
        my $length = $#snmpOIDs4Get + 1;
        for (my $i=0; $i < $length ; ) {
            @snmpOIDs4GetTMP = ();
            if ($debug) {
                print "DEBUG GET TABLE : i = $i et msgPerPDU = "
                      .$OIDsPerPDU."; ALL Get : $length\n" if ($debug);
            }

            @snmpOIDs4GetTMP = splice(@snmpOIDs4Get, 0, $OIDsPerPDU) ;
            $i += $OIDsPerPDU ;
            $args{'varbindlist'} = \@snmpOIDs4GetTMP ;

            print Dumper(\@snmpOIDs4GetTMP) if ($debug);

            if (!defined($responseGetOIDsTMP = $session->get_request(%args))) {
                    $answer=$session->error;
                    return ("CRITICAL", "CRITICAL: SNMP error: $answer");
            }
            if ($responseGetOIDs) {
                %$responseGetOIDs = (%$responseGetOIDs, %$responseGetOIDsTMP) if ($responseGetOIDsTMP);
            } else {
                %$responseGetOIDs = %$responseGetOIDsTMP;
            }
        }
    }

    my $responseWalkOIDs = {};
    if (@snmpOIDs4Walk) {
        # Get OIDs from SNMPWalk
        $responseWalkOIDs = &snmpWalk(\@snmpOIDs4Walk);
    }
    # Merge hashes
    if (%{$responseWalkOIDs}) {
        if (%{$responseGetOIDs}) {
            %{$response} = (%{$responseGetOIDs}, %{$responseWalkOIDs});
        } else {
            %{$response} = %{$responseWalkOIDs};
        }
    } elsif (%{$responseGetOIDs}) {
        %{$response} = %{$responseGetOIDs};
    } else {
        return ('UNKNOWN', 'No OID to collect');
    }
    return ('OK', 'OK');
}

=head2 snmpWalk($)

=head3 OverView

Perform an SNMP Walk.

Uses the $Host:Host global variable to use the SNMP version as defined into
the configuration file.

=head3 Arguments

=over 2

=item $1: $OIDs, reference to an array of OIDs to walk through.

=back

=head3 Returns

A hashmap of the gathered (OID, value) items.

=cut

sub snmpWalk($)
{

    my $OIDs = shift;
    my %args = ();
    my %returnTmp;
    my $OIDsPerPDU = &snmpOIDsPerPDU;
    my $oid;
    my $length = $#{$OIDs} + 1 ;
    if ($host::Host{'snmp'}->{'version'} == 1) {
        for (my $i=0; $i < $length; $i++) {
            $oid = $OIDs->[$i];
            $args{'varbindlist'} = [$oid];
            while (defined($session->get_next_request(%args))) {
                my $res = ($session->var_bind_names())[0];
                if (!Net::SNMP::oid_base_match($oid, $res)) { last; }
                $returnTmp{$res} = $session->var_bind_list()->{$res};
                $args{'varbindlist'}  = [$res];
            }
        }
    }
    else{
        if($host::Host{'snmp'}->{'version'} == 3 and defined ($host::Host{'snmp'}->{'context'})) {
            $args{'contextname'} = $host::Host{'snmp'}->{'context'};
        }
        $args{'maxrepetitions'} = $OIDsPerPDU;
        for (my $i=0; $i < $length; $i++) {
            $oid = $OIDs->[$i];
            $args{'varbindlist'} = [$oid];
            outer: while (defined($session->get_bulk_request(%args))) {
                my @oids = Net::SNMP::oid_lex_sort(keys(%{$session->var_bind_list()}));
                foreach (@oids) {
                    if (!Net::SNMP::oid_base_match($oid, $_)) { last outer; }
                    $returnTmp{$_} = $session->var_bind_list()->{$_};
                    # Make sure we have not hit the end of the MIB
                    if ($session->var_bind_list()->{$_} eq 'endOfMibView') { last outer; }
                }
                # Get the last OBJECT IDENTIFIER in the returned list
                $args{'varbindlist'} = [pop(@oids)];
            }
        }
    }
    return \%returnTmp;
}

=head2 send2Metro

=head3 Overview

Walk throught the defined Data Sources (DSs), apply the metrology functions
to the received SNMP responses from host, compute the final values and sends
the results to the bus.

Uses the $Hosts::Host hashmap, the Function::Function hashmap to
get the parameters to send to the functions and the functions references
themself, as they are dynamically defined by configuration

=head3 Arguments

None

=head3 Returns

A list with ($state, $message).

=cut

sub send2Metro
{
    # TODO: optimisation si le serveur de metro est local (connector-metro a modifier aussi)
    use IO::Socket::UNIX;

    my $now = time();
    my ($dish,$msg_tmp);
    my $DSList = &metroDSArrayRef;
    my $sock;
    my $hostname;
    my $dsname;
    my $message;
    if (! ($sock = IO::Socket::UNIX->new( Type => IO::Socket::SOCK_STREAM, Peer => $connector_socket))){
        return ("CRITICAL", "CRITICAL: problem opening an UNIX socket in send2Metro");
    }
    my $length = $#{$DSList} + 1;
    for (my $i=0; $i < $length; $i++) {
        ($dish,$msg_tmp) =
            $Functions::Functions{$DSList->[$i]->{'function'}}->($DSList->[$i]->{'parameters'}
                    , $DSList->[$i]->{'variables'}
                    , $response, $debug, \%Functions::Primitive
                    );
        $dsname = $DSList->[$i]->{'datasource'};
        if (!defined $msg_tmp || $msg_tmp eq 'U') {
            print "send2Metro: $dsname is unknown, not sending\n" if ($debug);
            next;
        }
        if ($DSList->[$i]->{'reRouteFor'}) {
            $hostname = $DSList->[$i]->{'reRouteFor'}->{'hostname'};
        }
        else {
            $hostname = $host::Host{'hostname'};
        }
        $message = "perf|$now|$hostname|$dsname|$msg_tmp\n";
        $sock->send($message);
        print "send2Metro: $message" if ($debug);
    }
    $sock->close();
    return ("OK", "OK");
}

=head2 send2Sup

=head3 Overview

Walk through the defined passive services, apply the supervision functions
to the received SNMP responses from host, compute the final Nagios-like states
(OK, WARNING, CRITICAL, UNKNOWN…) and returns the hasmap with the values
Uses then send2NagiosCmd or send2Nsca to forward the result to the right daemon.

Uses the $Hosts::Host hashmap, the Function::Function hashmap to
get the parameters to send to the functions and the functions references
themself, as they are dynamically defined by configuration

=head3 Arguments

None

=head3 Returns

A list with ($state, $message).

=cut

sub send2Sup($)
{
    use IO::Socket::INET;
    use Net::Domain qw(hostname hostfqdn hostdomain);

    my $remote;
    my $service;
    my $now = time;
    my $result;
    my @results_local = ();
    my @results_remote = ();

    # Loops over all monitoring services to get the service's state and its output (answer)
    foreach my $k_service (keys %{&supServicesHashRef()}) {
        # If the function to handle the test is not defined,
        # don't crash but:
        #  - fill the plugin output with this particular error;
        #  - fill the Collector ouput (if possible).
        if ( ! defined $Functions::Functions{&supServicesHashRef()->{$k_service}->{'function'}}) {
            if ($state eq "OK") {
                $state = 'UNKNOWN';
                $answer = "UNKNOWN: in test \"$k_service\", " .
                          "perl function \"" .
                          &supServicesHashRef()->{$k_service}->{'function'} .
                          "\" not found\n";
            }
            $result = {
                return_code => $ERRORS{'UNKNOWN'},
                plugin_output => "UNKNOWN: in test \"$k_service\", " .
                                 "perl function \"" .
                                 &supServicesHashRef()->{$k_service}->{'function'} .
                                 "\" not found\n",
            };
        } else {
            my ($state, $answer) =
                $Functions::Functions{
                    &supServicesHashRef()->{$k_service}->{'function'}
                }->(&supServicesHashRef()->{$k_service}->{'parameters'}
                ,&supServicesHashRef()->{$k_service}->{'variables'}
                ,$response,$debug,\%Functions::Primitive);
            $result = {
                return_code => $ERRORS{$state},
                plugin_output => $answer,
                };
        }
        if (&supServicesHashRef()->{$k_service}->{'reRouteFor'}) {
            $result->{host_name} = &supServicesHashRef()->{$k_service}->{'reRouteFor'}->{'host'};
            $result->{svc_description} = &supServicesHashRef()->{$k_service}->{'reRouteFor'}->{'service'};
            my $vserver = &supServicesHashRef()->{$k_service}->{'reRouteFor'}->{'vserver'};
            if ($debug) {
                print "hostname(): ";
                STDOUT->flush();
            }
            my $local_hostname = hostname();
            print "$local_hostname\n" if ($debug);
            if ($debug) {
                print "hostfqdn(): ";
                STDOUT->flush();
            }
            my $local_fqdn = hostfqdn();
            print "$local_fqdn\n" if ($debug);
            if ($vserver eq $local_hostname || $vserver eq $local_fqdn || $vserver eq "localhost") {
                push (@results_local, $result);
            } else {
                push (@results_remote, $result);
            }
        }
        else {
            $result->{host_name} = $host::Host{'hostname'};
            $result->{svc_description} = $k_service;
            push (@results_local, $result);
        }
    }
    &send2NagiosCmd(@results_local);
    return &send2RemoteNagios(@results_remote);
}

sub send2NagiosCmd($)
{
    use Nagios::Cmd;
    use File::Temp qw/ tempfile /;

    my @results = @_;

    my $now = time;
    my $message;
    my $nagios_cmd = Nagios::Cmd->new($nagios_cmd_file);
    #$Nagios::Cmd::debug = 1;
    #my $nagios_cmd = Nagios::Cmd->new_anyfile("/tmp/test_file.txt");

    (my $tmpfh, my $tmpfn) = tempfile($tmppath."/Collector-$hostname-XXXXXXXXXX", UNLINK => 0);
    foreach my $result (@results) {
        $message = "[$now] PROCESS_SERVICE_CHECK_RESULT;".$result->{host_name}
                  .";".$result->{svc_description}.";".$result->{return_code}
                  .";".$result->{plugin_output}."\n";
        print $tmpfh $message;
    }
    close($tmpfh);

    $nagios_cmd->nagios_cmd("[$now] PROCESS_FILE;".$tmpfn.";1");

    print "send2NagiosCmd: $tmpfn\n" if ($debug);
    return (0);
}

sub send2RemoteNagios($)
{
    use IO::Socket::UNIX;

    my @results = @_;

    my $now = time;
    my $sock;
    my $message;

    # If no message needs to be sent to a remote Nagios server,
    # don't even try to open the connector's UNIX socket.
    if (not scalar @results) {
        return ("OK", "OK");
    }

    if (! ($sock = IO::Socket::UNIX->new( Type => IO::Socket::SOCK_STREAM, Peer => $connector_socket ))) {
        return ("CRITICAL", "CRITICAL: problem opening the UNIX socket in send2RemoteNagios");
    }
    foreach my $result (@results) {
        $message = "nagios|$now|PROCESS_SERVICE_CHECK_RESULT|"
                  .$result->{host_name}.";".$result->{svc_description}.";"
                  .$result->{return_code}.";".$result->{plugin_output}."\n";
        $sock->send($message);
        print "send2RemoteNagios : $message" if ($debug);
    }
    $sock->close();
    return ("OK", "OK");
}



=head2 supServicesHashRef

=head3 Overview

Simple wrapper to help access a global variable

=head3 Arguments

None

=head3 Returns

The reference to the array of all sevices that are to handle (passively) for this host.

=cut

sub supServicesHashRef
{
    return $host::Host{'sup'}->{'services'};
}

=head2 supServicesHashRef

=head3 Overview

Simple wrapper to help access a global variable

=head3 Arguments

None

=head3 Returns

The reference to the array of all DS that are to handle for this host.

=cut

sub metroDSArrayRef
{
    return $host::Host{'metro'}->{'DS'};
}


=head2 supServicesHashRef

=head3 Overview

Simple wrapper to help access a global variable

=head3 Arguments

None

=head3 Returns

The number of OID that are to send in the same Protocol Data Unit

=cut

sub snmpOIDsPerPDU
{
    return $host::Host{'snmp'}->{'snmpOIDsPerPDU'};
}

sub check_conf()
{
    if (!defined $tmppath) {
        $tmppath = "/tmp";
    }

    if (! $path) {
        print "Provide a pathname for the configuration files directory\n";
        exit $ERRORS{'UNKNOWN'};
    } elsif (! -x $path) {
        print "Provide an existing conf path: $path\n";
        exit $ERRORS{'UNKNOWN'};
    }
}

sub load_libs($)
{
    $debug = shift;
    srand();

    # Load the core libraries
    require "$lib/base.pm";
    require "$lib/sup.pm";
    require "$lib/metro.pm";

    # Load the extensions
    if (-d "$lib/ext") {
        opendir(LIBDIR, "$lib/ext") or die "can't opendir $lib/ext: $!";
        my $file;
        while (defined($file = readdir(LIBDIR))) {
            if ($file =~ /\.pm$/) {
                #print "Loading $lib/ext/$file...\n";
                require "$lib/ext/$file";
            }
        }
        closedir(LIBDIR);
    }
}

sub collect_host($)
{
    $hostname = shift;

    # Read the host configuration file
    eval {do "$path/$hostname.pm";} ||
        return ("CRITICAL", "'$path/$hostname.pm' isn't present");
    #print Dumper(\%host::Host);

    if ((defined $host::Host{'timeout'}) && ($host::Host{'timeout'} > 0)){
        $timeout = $host::Host{'timeout'};
    }else{
        $timeout = 15;
    }

    # Just in case of problems, let's not hang Nagios
    $SIG{'ALRM'} = sub {
         return ("CRITICAL", "CRITICAL: No response (timeout)");
    };

    alarm($timeout);

    #Get all SNMP OIDs for this host
    &getAllOIDs();

    ($state, $answer) = &verifySNMPIdent;
    if ($state ne "OK") {
        return ($state, $answer);
    }

    ($state, $answer) = &getOIDValues;
    if ($state ne "OK") {
        $session->close();
        return ($state, $answer);
    }

    print Dumper($response) if ($debug);

    ($state, $answer) = &send2Sup;
    $session->close();
    if ($state ne "OK") {
        return ($state, $answer);
    }

    ($state, $answer) = &send2Metro;
    if ($state ne "OK") {
        return ($state, $answer);
    }

    return ("OK", "OK: Collector OK");
}

1;
