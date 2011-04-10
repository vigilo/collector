################################################################################
## $Id$
##
## base.pm : PERL function package, Customizable functions for the Collector
##           Nagios Plugin
##
## Copyright (C) 2006-2011 CS-SI
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
################################################################################

package Functions;
use strict;
use warnings;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA=qw(Exporter);
@EXPORT= qw( %Functions %Primitive );
$VERSION = 1.0;

# Hashmap of generic multipurpose routines
our %Primitive = (
"date2Time" => sub {
    # converts a sysuptime string into a number of seconds
    my $date = shift;

    if ($date =~ /^(\d+) days?, (\d+):(\d+):(\d+)\.(\d+)/)
    {
        return (((((($1 * 24) + $2) * 60) + $3) * 60) + $4);
    }
    if ($date =~ /^(\d+) hours?, (\d+):(\d+)\.(\d+)/)
    {
        return (((($1 * 60) + $2) * 60) + $3);
    }
    if ($date =~ /^(\d+) minutes?, (\d+)\.(\d+)/)
    {
        return (($1 * 60) + $2) ;
    }
    if ($date =~ /^(\d+)\.(\d+) seconds?/)
    {
        return ($1);
    }
    return 0;
},
"checkOIDVal" => sub {
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
"lookup" => sub {
    # looks for a given pattern in an OID subtree
    # which is supposed to be one-level deep
    # pattern can be a portion of a regexp
    # returns the index of the OID first matching the pattern
    my ($response,$where,$key)=@_;
    foreach my $OID (keys %{$response})
    {
        if ($OID =~ /^$where\./)
        {
            if ($response->{$OID} =~ /^${key}\000?$/)
            {
                $OID =~ /\.(\d+)$/; # Got it
                return $1;
            }
        }
    }
    return -1;
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
"lookupText" => sub {
    # looks for the index betwen an an OID subtree
    # and the numeric representation of the text
    # returns this index
    my ($response,$where,$text)=@_;
    my $numeric = "";
    foreach my $char (split(//,$text))
    {
        $numeric = "$numeric.".ord($char);
    }
    foreach my $OID (keys %{$response})
    {
        if ($OID =~ /^$where\.(\d+$numeric)/)
        {
            return $1;
        }
    }
    return -1;
},
"resultMap" => sub {
    # maps the result given an array of hashmaps describing a regex and a state and message to produce
    # fallback is returned is no match occured
    my ($val,$valFilters,$fallbackState,$fallbackMessage)=@_;
    foreach my $i (@$valFilters)
    {
        if ($val =~ /$$i{"pattern"}/)
        {
            return ($$i{"state"},$$i{"message"});
        }
    }
    return ($fallbackState,$fallbackMessage);
},
"genericHW" => sub {
    my ($response,$descrOID,$stateOID,$okValue,$caption,$debug)=@_;
    my $state="OK";
    my @msg;
    my $nbItems=0;
    foreach my $OID (keys %{$response})
    {
        if ($OID =~ /^$stateOID\.(\d+)/) {
            my $index = $1;
            $nbItems++;
            if ($response->{$OID} =~ /^${okValue}\000?$/) {
                print "ignoring \"".$response->{"$descrOID.$index"}."\" $caption that seems OK\n" if ($debug);
                next;
            }
            push @msg,$response->{"$descrOID.$index"};
            $state="CRITICAL";
        }
    }
    return ("UNKNOWN","UNKNOWN: no $caption found.") if ($nbItems == 0);
    return ("OK","OK: $nbItems $caption(s) OK") if ($state eq "OK");
    return ("CRITICAL","CRITICAL: Failed $caption(s): ".join(',',@msg));
},
"genericIfOperStatus"        => sub {
    my ($interfaceName, $ifAdminStatus, $ifOperStatus, $ifAlias, $ifIndex, $adminWarn, $dormantWarn, $Primitive, $debug)=@_;

    my ($state, $answer);
    my $alias = '';
    if ($Primitive->{"checkOIDVal"}->($ifAlias) && $ifAlias ne '')
    {
        $alias = "($ifAlias)";
    }
    else
    {
        $alias = "(index $ifIndex)";
    }

    $answer = "Interface $interfaceName $alias";
    # if AdminStatus is down - some one made a consious effort to change config
    if ( not ($ifAdminStatus == 1) )
    {
        $answer .= " is administratively down.";
        if ( not defined $adminWarn or $adminWarn eq "w" )
        {
            $state = 'WARNING';
        }
        elsif ( $adminWarn eq "i" )
        {
            $state = 'OK';
        }
        elsif ( $adminWarn eq "c" )
        {
            $state = 'CRITICAL';
        }
        else
        { # If wrong value for authProto, say warning
            $state = 'WARNING';
        }
    } 
    ## Check operational status
    elsif ( $ifOperStatus == 2 )
    {
            $state = 'CRITICAL';
            $answer .= " is down.";
    }
    elsif ( $ifOperStatus == 5 )
    {
        $answer .= " is dormant.";
        if (defined $dormantWarn )
        {
            if ($dormantWarn eq "w")
            {
                $state = 'WARNING';
            }
            elsif($dormantWarn eq "c")
            {
                $state = 'CRITICAL';
            }
            elsif($dormantWarn eq "i")
            {
                $state = 'OK';
            }
        }
        else
        {
            # dormant interface  - but warning/critical/ignore not requested
            $state = 'CRITICAL';
        }
    }
    elsif( $ifOperStatus == 6 )
    {
        $state = 'CRITICAL';
        $answer .= " notPresent - possible hotswap in progress.";
    }
    elsif ( $ifOperStatus == 7 )
    {
        $state = 'CRITICAL';
        $answer .= " down due to lower layer being down.";
    }
    elsif ( $ifOperStatus == 3 || $ifOperStatus == 4  )
    {
        $state = 'CRITICAL';
        $answer .= " down (testing/unknown).";
    }
    else
    {
            $state = 'OK';
            $answer .= " is up.";
    }

    return ($state, "$state: $answer");
},
);

# Initialize sup and metro functions
our %Functions = ();

1;
