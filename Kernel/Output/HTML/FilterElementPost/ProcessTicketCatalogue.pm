# --
# Copyright (C) 2024 mo-azfar, https://github.com/mo-azfar/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::FilterElementPost::ProcessTicketCatalogue;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::ProcessManagement::DB::Process',
    'Kernel::System::Web::Request',
);

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');

    my $Action = $ParamObject->GetParam( Param => 'Action' );

    return 1 if !$Action;
    return 1 if !$Param{Templates}->{$Action};

    my $HttpType        = $ConfigObject->Get('HttpType');
    my $FQDN            = $ConfigObject->Get('FQDN');
    my $ScriptAlias     = $ConfigObject->Get('ScriptAlias');
    my $ProcessEntityID = $ParamObject->GetParam( Param => 'ProcessEntityID' );

    my $URL;
    if ( $Param{TemplateFile} eq 'AgentTicketProcess' )
    {
        $URL = $HttpType . '://' . $FQDN . '/' . $ScriptAlias . 'index.pl?Action=' . $Action;
    }
    elsif ( $Param{TemplateFile} eq 'CustomerTicketProcess' )
    {
        $URL = $HttpType . '://' . $FQDN . '/' . $ScriptAlias . 'customer.pl?Action=' . $Action;
    }

    #get value from process dropdown element
    my @OptionValues = ${ $Param{Data} } =~ /<select[^>]*id="ProcessEntityID"[^>]*>(.*?)<\/select>/s;
    my @SelectValues = $OptionValues[0]  =~ /<option value="([^"]+)".*>/g;

    my $CSS = qq~<style type="text/css">
    .row-process {
        margin: 0 -0.313rem;
        display: flex;
        justify-content: center;
        flex-wrap: wrap;
        border-bottom: 0.1rem double #e8e8e8;
        margin-bottom: 0.3rem;
    }

    /* Clear floats after the columns */
    .row-process:after {
        content: "";
        display: table;
        clear: both;
    }

    .WidgetSimpleCatalogue {
        cursor: pointer;
        border-color: #f92;
    }

    /* hover */
    .WidgetSimpleCatalogue:hover {
        background: #f92;
    }

    /* Content text color */
    .WidgetSimpleCatalogue .Content p {
        color: #251c17;
    }

    /* Float 4 columns side by side */
    .column-process {
        float: left;
        width: 25%;
        padding: 0 0.625rem;
        padding-bottom: 1.2rem;
    }

    \@media screen and (max-width: 600px) {
        .column-process {
            width: 100%;
            display: block;
            margin-bottom: 0.1rem;
        }
    </style>
    ~;

    my $Card = qq~ <div class="row-process"> ~;
    my $JS;
    my $n = 0;

    for my $ProcessEntityID (@SelectValues)
    {
        $n++;

        my $Process = $ProcessObject->ProcessGet(
            EntityID => $ProcessEntityID,
            UserID   => 1,
        );

        $Card .= qq~
        <div class="column-process">
            <a href='$URL;ProcessEntityID=$Process->{EntityID}' title="$Process->{Name}">
            <div class="WidgetSimple WidgetSimpleCatalogue">
                <div class="Header">
                    <h2><i class="fa fa-superpowers" aria-hidden="true"></i> $n. $Process->{Name}</h2>
                </div>
                <div class="Content">
                <p>$Process->{Config}->{Description}</p>
                </div>
            </div>
            </a>
        </div>~

            #possible values:
            #$Process->{Name}
            #$Process->{ID}
            #$Process->{Config}->{Description}
            #$Process->{EntityID}
    }
    $Card .= qq~ </div> ~;

    my $SearchField1 = quotemeta "<label class=\"Mandatory\" for=\"ProcessEntityID\">";
    my $ReturnField1 = qq~ $CSS $Card <label class="Mandatory" for="ProcessEntityID">
    ~;

    #search and replace
    ${ $Param{Data} } =~ s{$SearchField1}{$ReturnField1};

    if ($ProcessEntityID)
    {
        my $JS = qq~
                    \$(document).ready(function() {
                        \$('#ProcessEntityID').val('$ProcessEntityID').trigger('change');
                    });
                ~;

        $LayoutObject->AddJSOnDocumentComplete(
            Code => $JS,
        );
    }

    return 1;
}

1;
