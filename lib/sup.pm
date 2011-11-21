################################################################################
## $Id$
##
## sup.pm : PERL function package, Customizable supervision functions for the
##          Collector Nagios Plugin
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
use Math::RPN;
use vars qw(@ISA @EXPORT $VERSION);
@ISA=qw(Exporter);
@EXPORT= qw( %Functions );
$VERSION = 1.0;

our %Functions;

$Functions{thresholds_OID_simple} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID        = (split('/',$variables->[0]))[1];
    my $warnThresh = $parameters->[0];
    my $critThresh = $parameters->[1];
    my $caption    = $parameters->[2] || "%s";
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $OID") unless exists($response->{$OID});

    my $value      = $response->{$OID};
    return ("UNKNOWN","UNKNOWN: OID $OID not found") unless $Primitive->{"checkOIDVal"}->($value);
    return $Primitive->{"thresholdIt"}->($value,$warnThresh,$critThresh,$caption, $Primitive);
};
$Functions{thresholds_OID_plus_max} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID        = (split('/',$variables->[0]))[1];
    my $maxOID     = (split('/',$variables->[1]))[1];
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $OID") unless exists($response->{$OID});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $maxOID") unless exists($response->{$maxOID});

    my $value      = $response->{$OID};
    my $maxValue   = $response->{$maxOID};
    my $warnThresh = $parameters->[0];
    my $critThresh = $parameters->[1];
    my $caption    = $parameters->[2] || "usage: %2.2f%%";

    return ("UNKNOWN","UNKNOWN: OID $OID not found") unless $Primitive->{"checkOIDVal"}->($value);
    return ("UNKNOWN","UNKNOWN: OID $maxOID not found") unless $Primitive->{"checkOIDVal"}->($maxValue);
    return $Primitive->{"thresholdIt"}->($value*100.0/$maxValue,$warnThresh,$critThresh,$caption,$Primitive);
};
$Functions{thresholds_mult} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID1       = (split('/',$variables->[0]))[1];
    my $OID2       = (split('/',$variables->[1]))[1];
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $OID1") unless exists($response->{$OID1});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $OID2") unless exists($response->{$OID2});

    my $val1       = $response->{$OID1};
    my $val2       = $response->{$OID2};
    my $warnThresh = $parameters->[0];
    my $critThresh = $parameters->[1];
    my $caption    = $parameters->[2] || "%s";

    return ("UNKNOWN","UNKNOWN: OID $OID1 not found") unless $Primitive->{"checkOIDVal"}->($val1);
    return ("UNKNOWN","UNKNOWN: OID $OID2 not found") unless $Primitive->{"checkOIDVal"}->($val2);
    return $Primitive->{"thresholdIt"}->($val1*$val2,$warnThresh,$critThresh,$caption,$Primitive);
};
$Functions{simple_factor} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $OID        = (split('/',$variables->[0]))[1];
    my $warnThresh = $parameters->[0];
    my $critThresh = $parameters->[1];
    my $factor     = $parameters->[2];
    my $caption    = $parameters->[3] || "%s";

    my $value      = $response->{$OID};
    return ("UNKNOWN","UNKNOWN: OID $OID not found") unless $Primitive->{"checkOIDVal"}->($value);
    # Verifions qu'on a bien un nombre
    return ("UNKNOWN","UNKNOWN: $value") unless $value =~ /^-?(\d+\.?\d*|\.\d+)$/;
    return $Primitive->{"thresholdIt"}->($value*$factor,$warnThresh,$critThresh,$caption, $Primitive);
};
$Functions{table} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name       = $parameters->[0];
    my $warnThresh = $parameters->[1];
    my $critThresh = $parameters->[2];
    my $caption    = $parameters->[3] || "%s";
    my $OID        = (split('/',$variables->[0]))[1];
    my $descrOID   = (split('/',$variables->[1]))[1];

    # Get the index
    my $index = $Primitive->{"lookup"}->($response,$descrOID,$name);
    return ("UNKNOWN","UNKNOWN: $name not found in $descrOID") if ($index == -1);
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $OID.$index") unless exists($response->{"$OID.$index"});
    my $value=$response->{"$OID.$index"};
    return ("UNKNOWN","UNKNOWN: OID $OID.$index not found") unless $Primitive->{"checkOIDVal"}->($value);
    return $Primitive->{"thresholdIt"}->($value, $warnThresh, $critThresh, $caption, $Primitive);
};
$Functions{table_factor} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name       = $parameters->[0];
    my $warnThresh = $parameters->[1];
    my $critThresh = $parameters->[2];
    my $factor     = $parameters->[3];
    my $caption    = $parameters->[4] || "%s";
    my $OID        = (split('/',$variables->[0]))[1];
    my $descrOID   = (split('/',$variables->[1]))[1];

    # Get the index
    my $index = $Primitive->{"lookup"}->($response,$descrOID,$name);
    return ("UNKNOWN","UNKNOWN: $name not found in $descrOID") if ($index == -1);
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $OID.$index") unless exists($response->{"$OID.$index"});
    my $value=$response->{"$OID.$index"};
    return ("UNKNOWN","UNKNOWN: OID $OID.$index not found") unless $Primitive->{"checkOIDVal"}->($value);
    return $Primitive->{"thresholdIt"}->($value * $factor, $warnThresh, $critThresh, $caption, $Primitive);
};
$Functions{table_mult} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name       = $parameters->[0];
    my $warnThresh = $parameters->[1];
    my $critThresh = $parameters->[2];
    my $caption    = $parameters->[3] || "%s";
    my $val1OID    = (split('/',$variables->[0]))[1];
    my $val2OID    = (split('/',$variables->[1]))[1];
    my $descrOID   = (split('/',$variables->[2]))[1];

    # Get the index
    my $index = $Primitive->{"lookup"}->($response,$descrOID,$name);
    return ("UNKNOWN","UNKNOWN: $name not found in $descrOID") if ($index == -1);
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $val1OID.$index") unless exists($response->{"$val1OID.$index"});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $val2OID.$index") unless exists($response->{"$val2OID.$index"});
    my $val1=$response->{"$val1OID.$index"};
    my $val2=$response->{"$val2OID.$index"};
    return ("UNKNOWN","UNKNOWN: OID $val1OID.$index not found") unless $Primitive->{"checkOIDVal"}->($val1);
    return ("UNKNOWN","UNKNOWN: OID $val2OID.$index not found") unless $Primitive->{"checkOIDVal"}->($val2);
    return $Primitive->{"thresholdIt"}->($val1*$val2, $warnThresh, $critThresh, $caption, $Primitive);
};
$Functions{table_used_free} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name       = $parameters->[0];
    my $warnThresh = $parameters->[1];
    my $critThresh = $parameters->[2];
    my $caption    = $parameters->[3] || "%f%%";
    my $usedOID    = (split('/',$variables->[0]))[1];
    my $freeOID    = (split('/',$variables->[1]))[1];
    my $descrOID   = (split('/',$variables->[2]))[1];

    # Get the index
    my $index = $Primitive->{"lookup"}->($response,$descrOID,$name);
    return ("UNKNOWN","UNKNOWN: $name not found in $descrOID") if ($index == -1);
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $usedOID.$index") unless exists($response->{"$usedOID.$index"});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $freeOID.$index") unless exists($response->{"$freeOID.$index"});
    my $used=$response->{"$usedOID.$index"};
    my $free=$response->{"$freeOID.$index"};
    return ("UNKNOWN","UNKNOWN: OID $usedOID.$index not found") unless $Primitive->{"checkOIDVal"}->($used);
    return ("UNKNOWN","UNKNOWN: OID $freeOID.$index not found") unless $Primitive->{"checkOIDVal"}->($free);
    return $Primitive->{"thresholdIt"}->(($used*100.0)/($free+$used), $warnThresh, $critThresh, $caption, $Primitive);
};
$Functions{table_total_free} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name         = $parameters->[0];
    my $warnThresh   = $parameters->[1];
    my $critThresh   = $parameters->[2];
    my $caption      = $parameters->[3] || "%f%%";
    my $totalOID     = (split('/',$variables->[0]))[1];
    my $freeOID = (split('/',$variables->[1]))[1];

    # Get the index
    my $total=$response->{"$totalOID"};
    my $free=$response->{"$freeOID"};
    return ("UNKNOWN","UNKNOWN: OID $totalOID not found") unless $Primitive->{"checkOIDVal"}->($total);
    return ("UNKNOWN","UNKNOWN: OID $freeOID not found") unless $Primitive->{"checkOIDVal"}->($free);
    return $Primitive->{"thresholdIt"}->(($free*100.0)/($total), $warnThresh, $critThresh, $caption, $Primitive);
};
$Functions{table_mult_factor} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name       = $parameters->[0];
    my $warnThresh = $parameters->[1];
    my $critThresh = $parameters->[2];
    my $factor     = $parameters->[3];
    my $caption    = $parameters->[4] || "%s";
    my $val1OID    = (split('/',$variables->[0]))[1];
    my $val2OID    = (split('/',$variables->[1]))[1];
    my $descrOID   = (split('/',$variables->[2]))[1];

    # Get the index
    my $index = $Primitive->{"lookup"}->($response,$descrOID,$name);
    return ("UNKNOWN","UNKNOWN: $name not found in $descrOID") if ($index == -1);
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $val1OID.$index") unless exists($response->{"$val1OID.$index"});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $val2OID.$index") unless exists($response->{"$val2OID.$index"});
    my $val1=$response->{"$val1OID.$index"};
    my $val2=$response->{"$val2OID.$index"};
    return ("UNKNOWN","UNKNOWN: OID $val1OID.$index not found") unless $Primitive->{"checkOIDVal"}->($val1);
    return ("UNKNOWN","UNKNOWN: OID $val2OID.$index not found") unless $Primitive->{"checkOIDVal"}->($val2);
    return $Primitive->{"thresholdIt"}->($val1 * $val2 * $factor, $warnThresh, $critThresh, $caption, $Primitive);
};
$Functions{sysUpTime} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $criticalTime = $parameters->[0] || 400;
    my $warnTime     = $parameters->[1] || 900;
    my $sysUpTimeOID = (split('/',$variables->[0]))[1];
    my $timestamp    = 0;

    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $sysUpTimeOID") unless exists($response->{$sysUpTimeOID});
    my $sysUpTime    = $response->{$sysUpTimeOID};

    return ("UNKNOWN","UNKNOWN: OID $sysUpTimeOID not found") unless $Primitive->{"checkOIDVal"}->($sysUpTime);
    if ($timestamp = $Primitive->{"date2Time"}->($sysUpTime))
    {
        return $Primitive->{"thresholdIt"}->($timestamp,"\@$warnTime","\@$criticalTime","sysUpTime is $sysUpTime (%d s)",$Primitive);
    }
    return ('UNKNOWN', "UNKNOWN: unable to understand sysUpTime $sysUpTime");
};
$Functions{ifOperStatus} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $interface     = $parameters->[0];
    my $interfaceName = $parameters->[1];
    my $adminWarn     = $parameters->[2] || 'w';
    my $dormantWarn   = $parameters->[3] || 'c';
    my $ifDescrOID    = (split('/',$variables->[0]))[1];
    my $ifAdminStatusOID = (split('/',$variables->[1]))[1];
    my $ifOperStatusOID  = (split('/',$variables->[2]))[1];
    my $ifAliasOID    = (split('/',$variables->[3]))[1];

    my ($state, $answer);
    my $ifIndex = $Primitive->{"lookup"}->($response,$ifDescrOID,$interface);
    return ("UNKNOWN","Interface name ($interface) not found in ifDescr") if ($ifIndex == -1);

    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $ifAdminStatusOID.$ifIndex")
        unless exists($response->{"$ifAdminStatusOID.$ifIndex"});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $ifOperStatusOID.$ifIndex")
        unless exists($response->{"$ifOperStatusOID.$ifIndex"});
    my $ifAdminStatus = $response->{"$ifAdminStatusOID.$ifIndex"};
    my $ifOperStatus  = $response->{"$ifOperStatusOID.$ifIndex"};
    my $ifAlias       = $response->{"$ifAliasOID.$ifIndex"};
    return ("UNKNOWN","UNKNOWN: OID $ifAdminStatusOID.$ifIndex not found") unless $Primitive->{"checkOIDVal"}->($ifAdminStatus);
    return ("UNKNOWN","UNKNOWN: OID $ifOperStatusOID.$ifIndex not found")  unless $Primitive->{"checkOIDVal"}->($ifOperStatus);
    return $Primitive->{"genericIfOperStatus"}->($interfaceName, $ifAdminStatus, $ifOperStatus, $ifAlias, $ifIndex, $adminWarn, $dormantWarn, $Primitive, $debug);
};
$Functions{staticIfOperStatus} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $ifIndex       = $parameters->[0];
    my $interfaceName = $parameters->[1];
    my $adminWarn     = $parameters->[2] || 'w';
    my $dormantWarn   = $parameters->[3] || 'c';
    my $ifDescrOID    = (split('/',$variables->[0]))[1];
    my $ifAdminStatusOID = (split('/',$variables->[1]))[1];
    my $ifOperStatusOID  = (split('/',$variables->[2]))[1];
    my $ifAliasOID    = (split('/',$variables->[3]))[1];

    my ($state, $answer);

    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $ifAdminStatusOID.$ifIndex")
        unless exists($response->{"$ifAdminStatusOID.$ifIndex"});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $ifOperStatusOID.$ifIndex")
        unless exists($response->{"$ifOperStatusOID.$ifIndex"});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $ifDescrOID.$ifIndex")
        unless exists($response->{"$ifDescrOID.$ifIndex"});
    my $ifAdminStatus = $response->{"$ifAdminStatusOID.$ifIndex"};
    my $ifOperStatus  = $response->{"$ifOperStatusOID.$ifIndex"};
    my $ifAlias       = $response->{"$ifAliasOID.$ifIndex"};
    my $ifDescr       = $response->{"$ifDescrOID.$ifIndex"};
    return ("UNKNOWN","UNKNOWN: OID $ifAdminStatusOID.$ifIndex not found") unless $Primitive->{"checkOIDVal"}->($ifAdminStatus);
    return ("UNKNOWN","UNKNOWN: OID $ifOperStatusOID.$ifIndex not found")  unless $Primitive->{"checkOIDVal"}->($ifOperStatus);
    if ($Primitive->{"checkOIDVal"}->($ifDescrOID))
    {
        $interfaceName = "$ifDescr $interfaceName";
    }
    return $Primitive->{"genericIfOperStatus"}->($interfaceName, $ifAdminStatus, $ifOperStatus, $ifAlias, $ifIndex, $adminWarn, $dormantWarn, $Primitive, $debug);
};
$Functions{storage} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $partition         = $parameters->[0];
    my $warnThresh        = $parameters->[1];
    my $critThresh        = $parameters->[2];
    my $percent           = $parameters->[3];
    my $hrStorageDescrOID = (split('/',$variables->[0]))[1];
    my $hrStorageAllocationUnitsOID = (split('/',$variables->[1]))[1];
    my $hrStorageSizeOID  = (split('/',$variables->[2]))[1];
    my $hrStorageUsedOID  = (split('/',$variables->[3]))[1];

    my $hrIndex = $Primitive->{"lookup"}->($response,$hrStorageDescrOID,$partition);
    return ("UNKNOWN","Partition name ($partition) not found in hrStorageDescr") if ($hrIndex == -1);

    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $$hrStorageAllocationUnitsOID.$hrIndex")
        unless exists($response->{"$hrStorageAllocationUnitsOID.$hrIndex"});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $hrStorageSizeOID.$hrIndex")
        unless exists($response->{"$hrStorageSizeOID.$hrIndex"});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $hrStorageUsedOID.$hrIndex")
        unless exists($response->{"$hrStorageUsedOID.$hrIndex"});
    my $hrAU = $response->{"$hrStorageAllocationUnitsOID.$hrIndex"};
    my $hrS  = $response->{"$hrStorageSizeOID.$hrIndex"};
    my $hrU  = $response->{"$hrStorageUsedOID.$hrIndex"};
    return ("UNKNOWN","UNKNOWN: OID $hrStorageAllocationUnitsOID.$hrIndex not found") unless $Primitive->{"checkOIDVal"}->($hrAU);
    return ("UNKNOWN","UNKNOWN: OID $hrStorageUsedOID.$hrIndex not found") unless $Primitive->{"checkOIDVal"}->($hrU);
    return ("UNKNOWN","UNKNOWN: OID $hrStorageSizeOID.$hrIndex not found") unless $Primitive->{"checkOIDVal"}->($hrS);
    my $usedBytes = $hrU*$hrAU;
    my $maxBytes = $hrS*$hrAU;
    return ("UNKNOWN","UNKNOWN: 0 byte Allocation units for storage $partition") if $maxBytes == 0;
    if ($percent)
    {
        my $usagePercentage = $usedBytes*100.0/$maxBytes;
        return $Primitive->{"thresholdIt"}->($usagePercentage,$warnThresh,$critThresh,"Usage: ".sprintf("%.2f",$usedBytes/1024/1024)." MB (%2.2f%%)", $Primitive);
    }
    else
    {
        my $freeBytes = $maxBytes - $usedBytes;
        my $freePercentage = $freeBytes*100.0/$maxBytes;
        $freePercentage = sprintf("%2.2f%%%%",$freePercentage);
        return $Primitive->{"thresholdIt"}->($freeBytes,"@".($warnThresh*1024*1024),"@".($critThresh*1024*1024),"Usage: %d Bytes free ($freePercentage)", $Primitive);
    }
};
$Functions{walk_grep_count} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $pattern    = $parameters->[0];
    my $warnThresh = $parameters->[1];
    my $critThresh = $parameters->[2];
    my $caption    = $parameters->[3] || "%d occurences";
    my $walk       = (split('/',$variables->[0]))[1];

    my $value=0;
    # Get the ifIndex
    foreach my $OID (keys %{$response})
    {
        if ($OID =~ /^$walk\./)
        {
            if ($response->{$OID} =~ /^$pattern\000?$/)
            {
                $value++;
            }
        }
    }
    return $Primitive->{"thresholdIt"}->($value,$warnThresh,$critThresh,$caption,$Primitive);
};
$Functions{statusWithMessage} = sub {
    # NETWORK-APPLIANCE-MIB::miscGlobalStatus.0 = INTEGER: ok(3)
    # NETWORK-APPLIANCE-MIB::miscGlobalStatusMessage.0 = STRING: "The system's global status is normal. "
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;
    my $okValue    = $parameters->[0];
    my $warnValue  = $parameters->[1];
    my $valueOID   = (split('/',$variables->[0]))[1];
    my $msgOID     = (split('/',$variables->[1]))[1];

    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $valueOID") unless exists($response->{$valueOID});
    return ("UNKNOWN", "UNKNOWN: unable to collect value for OID $msgOID") unless exists($response->{$msgOID});
    my $stateValue = $response->{$valueOID};
    my $msgValue   = $response->{$msgOID};
    return ("UNKNOWN","UNKNOWN: OID $valueOID not found") unless $Primitive->{"checkOIDVal"}->($stateValue);
    return ("UNKNOWN","UNKNOWN: OID $msgOID not found") unless $Primitive->{"checkOIDVal"}->($msgValue);
    # TODO: use thresholdIt
    return ("OK","OK: $msgValue") if $stateValue == $okValue;
    return ("WARNING","WARNING: $msgValue") if $stateValue == $warnValue;
    return ("CRITICAL","CRITICAL: $msgValue");
};
$Functions{sup_rpn} = sub {
    my ($parameters, $variables, $response, $debug, $Primitive)=@_;

    my $name       = $parameters->[0];
    my $warnThresh = $parameters->[1];
    my $critThresh = $parameters->[2];
    my $caption    = $parameters->[3];

    my @formula = @$parameters;
    @formula = @formula[4..$#formula];
    # remplacement des OIDs par leur valeur dans la formule
    foreach my $cmpid (0 .. $#formula)
    {
        my $component = $formula[$cmpid];
        if (substr($component, 0, 1) eq ".")
        { # commence par un "." -> c'est un OID
            return ("UNKNOWN","UNKNOWN: $name cannot be computed (can't find $component)") unless exists($response->{$component});
            return ("UNKNOWN","UNKNOWN: $name cannot be computed (wrong value for $component)") unless $Primitive->{"checkOIDVal"}->($response->{$component});
            $formula[$cmpid] = $response->{$component};
        }
    }
    # calcul
    my $result = rpn(@formula);
    return $Primitive->{"thresholdIt"}->($result, $warnThresh, $critThresh, $caption, $Primitive);
};


1;
