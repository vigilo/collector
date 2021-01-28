################################################################################
## $Id$
##
## metro.pm : PERL function package, Customizable metrology functions for the
##            Collector Nagios Plugin
##
## Copyright (C) 2006-2021 CS GROUP - France
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

package Functions;
use strict;
use warnings;
require Exporter;
use Math::RPN;
use vars qw(@ISA @EXPORT $VERSION);
@ISA=qw(Exporter);
@EXPORT= qw( %Functions );
$VERSION = 1.0;

our %Functions;

$Functions{m_table} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name     = $parameters->[0];
    my $OID      = (split('/',$variables->[0]))[1];
    my $descrOID = (split('/',$variables->[1]))[1];

    # Get the index
    my $index = $Primitive->{"lookup"}->($response,$descrOID,$name);
    return ("UNKNOWN","U") if ($index == -1);
    return ("UNKNOWN","U") unless exists($response->{"$OID.$index"});
    my $value = $response->{"$OID.$index"};
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($value);
    return ('OK', $value);
};
$Functions{m_table_add} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name     = $parameters->[0];
    my $OID      = (split('/',$variables->[0]))[1];
    my $descrOID = (split('/',$variables->[1]))[1];

    # Get the indexes
    my @indexes = $Primitive->{"lookupMultiple"}->($response,$descrOID,$name);
    return ("UNKNOWN","U") if ($#indexes == -1);
    my $total = 0;
    my $value;
    foreach my $index (@indexes)
    {
        return ("UNKNOWN","U") unless exists($response->{"$OID.$index"});
        $value = $response->{"$OID.$index"};
        return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($value);
        $total += $value;
    }
    return ('OK', $total);
};
$Functions{m_average} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID = (split('/',$variables->[0]))[1];

    # Get the index
    my @indexes = $Primitive->{"lookupMultipleIndex"}->($response,$OID);
    return ("UNKNOWN","U") if ($#indexes == -1);
    my $total = 0;
    my $nb_value = 0;
    my $value;
    foreach my $index (@indexes){
        return ("UNKNOWN","U") unless exists($response->{"$OID.$index"});
        $value = $response->{"$OID.$index"};
        return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($value);
        $total += $value;
        $nb_value += 1;
    }
    return ("UNKNOWN","U") if ($nb_value == 0);
    $total = $total / $nb_value;
    return ('OK', $total);
};
$Functions{m_table_average} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name     = $parameters->[0];
    my $OID      = (split('/',$variables->[0]))[1];
    my $descrOID = (split('/',$variables->[1]))[1];

    # Get the indexes
    my @indexes = $Primitive->{"lookupMultiple"}->($response,$descrOID,$name);
    return ("UNKNOWN","U") if ($#indexes == -1);
    my $total = 0;
    my $nb_value = 0;
    my $value;
    foreach my $index (@indexes){
        return ("UNKNOWN","U") unless exists($response->{"$OID.$index"});
        $value = $response->{"$OID.$index"};
        return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($value);
        $total += $value;
        $nb_value += 1;
    }
    return ("UNKNOWN","U") if ($nb_value == 0);
    $total = $total / $nb_value;
    return ('OK', $total);
};
$Functions{m_table_mult} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name     = $parameters->[0];
    my $val1OID  = (split('/',$variables->[0]))[1];
    my $val2OID  = (split('/',$variables->[1]))[1];
    my $descrOID = (split('/',$variables->[2]))[1];

    # Get the indexes
    my @indexes = $Primitive->{"lookupMultiple"}->($response,$descrOID,$name);
    return ("UNKNOWN","U") if ($#indexes == -1);
    my $total = 0;
    my $val1;
    my $val2;
    foreach my $index (@indexes)
    {
        return ("UNKNOWN","U") unless exists($response->{"$val1OID.$index"});
        return ("UNKNOWN","U") unless exists($response->{"$val2OID.$index"});
        $val1 = $response->{"$val1OID.$index"};
        $val2 = $response->{"$val2OID.$index"};
        return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($val1);
        return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($val2);
        $total += $val1 * $val2;
    }
    return ('OK', $total);
};
$Functions{percentage} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID = (split('/',$variables->[0]))[1];
    return ("UNKNOWN","U") unless exists($response->{$OID});
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($response->{$OID});
    return ('OK',$response->{$OID}/100);
};
$Functions{perthousand} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID = (split('/',$variables->[0]))[1];
    return ("UNKNOWN","U") unless exists($response->{$OID});
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($response->{$OID});
    return ('OK',$response->{$OID}/10.0);
};
$Functions{percentage2values} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID1 = (split('/',$variables->[0]))[1];
    my $OID2 = (split('/',$variables->[1]))[1];
    return ("UNKNOWN","U") unless exists($response->{$OID1});
    return ("UNKNOWN","U") unless exists($response->{$OID2});
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($response->{$OID1});
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($response->{$OID2});
    return ('OK',$response->{$OID1}/$response->{$OID2}*100);
};
$Functions{directValue} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID = (split('/',$variables->[0]))[1];
    return ("UNKNOWN","U") unless exists($response->{$OID});
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($response->{$OID});
    return ('OK',$response->{$OID});
};
$Functions{m_mult} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID1 = (split('/',$variables->[0]))[1];
    my $OID2 = (split('/',$variables->[1]))[1];

    return ("UNKNOWN","U") unless exists($response->{$OID1});
    return ("UNKNOWN","U") unless exists($response->{$OID2});
    my $val1 = $response->{$OID1};
    my $val2 = $response->{$OID2};

    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($val1);
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($val2);
    return ("OK",$val1*$val2);
};
$Functions{m_sysUpTime} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $sysUpTimeOID = (split('/',$variables->[0]))[1];
    my $timestamp    = 0;

    return ("UNKNOWN","U") unless exists($response->{$sysUpTimeOID});
    my $sysUpTime    = $response->{$sysUpTimeOID};
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($sysUpTime);

    if ($timestamp = $Primitive->{"date2Time"}->($sysUpTime))
    {
        return ('OK',"$timestamp");
    }
    return ('UNKNOWN', "U");
};
$Functions{m_walk_grep_count} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $pattern = $parameters->[0];
    my $walk    = (split('/',$variables->[0]))[1];

    my $value = 0;
    my $matches = 0;
    # Get the ifIndex
    foreach my $OID (keys %{$response})
    {
        if ($OID =~ /^$walk\./)
        {
            $matches++;
            if ($response->{$OID} =~ /^$pattern\000?$/)
            {
                $value++;
            }
        }
    }
    return ("UNKNOWN", "U") if ($matches == 0);
    return ("OK", $value);
};
$Functions{m_rpn} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my @formula = @$parameters;
    # remplacement des OIDs par leur valeur dans la formule
    foreach my $cmpid (0 .. $#formula)
    {
        my $component = $formula[$cmpid];
        if (substr($component, 0, 1) eq ".")
        { # commence par un "." -> c'est un OID
            return ("UNKNOWN","U") unless exists($response->{$component});
            return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($response->{$component});
            $formula[$cmpid] = $response->{$component};
        }
    }
    # calcul
    return ('OK', rpn(@formula));
};
$Functions{m_valueAndPercentageToValue} = sub {
    # permet de calculer une valeur brute à partir d'une valeur brute et d'un pourcentage de cette valeur
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OIDval = (split('/',$variables->[0]))[1];
    my $OIDper = (split('/',$variables->[1]))[1];
    return ("UNKNOWN","U") unless exists($response->{$OIDval});
    return ("UNKNOWN","U") unless exists($response->{$OIDper});
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($response->{$OIDval});
    return ("UNKNOWN","U") unless $Primitive->{"checkOIDVal"}->($response->{$OIDper});
    return ('OK',$response->{$OIDval}*$response->{$OIDper}/100);
};


1;
