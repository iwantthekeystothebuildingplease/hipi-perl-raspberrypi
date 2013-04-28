#########################################################################################
# Package       HiPi::Apps::Control::Panel::Pad
# Description:  Base for GPIO Pad panels
# Created       Wed Feb 27 23:09:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Panel::Pad;

#########################################################################################

use strict;
use warnings;
use Wx qw( :panel :id :sizer :misc :window :textctrl :font );
use parent qw( HiPi::Apps::Control::Panel::Base );
use Wx::Event qw( EVT_PAINT EVT_COMMAND );
use HiPi::Apps::Control::Data::PadPin;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( pad detail vdata2) );

our $ID_HIPI_EVT_PIN_CLICKED = Wx::NewEventType();
our $ID_HIPI_EVT_PROPERTY_CHANGED = Wx::NewEventType();

sub new {
    my ($class, $parent, $vdata, $padname) = @_;
    my $self = $class->SUPER::new($parent);
    $self->SetValidationData($vdata);
    {
        my $gpiopin1 = $vdata->get_gpio_pinnumber(1);
        my $newdata = HiPi::Apps::Control::Data::PadPin->new(1, $gpiopin1, 1);
        $self->vdata2( $newdata );
    }
    
    #---------------------------------------------
    # Controls
    #---------------------------------------------
    
    my $pad  = HiPi::Apps::Control::Panel::Pad::MC->new($self, $vdata);
    my $detail = HiPi::Apps::Control::Panel::Pad::PinDetail->new($self, $self->vdata2);

    $self->pad($pad);
    $self->detail($detail);
    
    #---------------------------------------------
    # Events
    #---------------------------------------------
    
    EVT_COMMAND($self, $pad, $ID_HIPI_EVT_PIN_CLICKED, sub { shift->_on_evt_pin_clicked( @_ ); });
    EVT_COMMAND($self, $detail, $ID_HIPI_EVT_PROPERTY_CHANGED, sub { shift->_on_evt_property_changed( @_ ); });
    
    #---------------------------------------------
    # Layout
    #---------------------------------------------
    
    my $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $sizer->Add($pad, 0, wxALL|wxEXPAND, 0);
    $sizer->Add($detail, 1, wxALL|wxEXPAND, 0);
    $self->SetSizer( $sizer );
    
    return $self;
}

sub InitValidatedPanel {
    my $self = shift;
    if(my $vdata = $self->GetValidationData) {
        $vdata->load_data;
    }
    if(my $vdata = $self->vdata2) {
        $vdata->load_data;
    }
    $self->TransferDataToWindow;
}

sub WriteValidatedPanel {
    my $self = shift;
    my $rval = 0;
    if($self->Validate && $self->TransferDataFromWindow ) {
        if( my $vdata = $self->GetValidationData ) {
            $rval = $vdata->flush_if_dirty;
            return 0 if !$rval;
        } else {
            $rval = 1; # default if we have no vdata
        }
        if( my $vdata = $self->vdata2 ) {
            $rval = $vdata->flush_if_dirty;
        } else {
            $rval = 1; # default if we have no vdata
        }
    }
    return $rval;
}

sub RefreshValidatedPanel {
    my ($self) = @_;
    $self->WriteValidatedPanel;
    $self->InitValidatedPanel;
}

sub _on_evt_pin_clicked {
    my($self, $event) = @_;
    $self->select_pin( $event->GetInt )
}

sub _on_evt_property_changed {
    my($self, $event) = @_;
    $self->RefreshValidatedPanel;
}

sub select_pin {
    my($self, $pinid) = @_;
    my $busy = Wx::BusyCursor->new;
    my $pdata = $self->pad->pins->[$pinid];
    $self->pad->selectedpin($pinid);
    $self->detail->set_selected_pin($pdata->{padnum}, $pdata->{gpionum});
    $self->pad->Refresh;
}

#########################################################################################

package HiPi::Apps::Control::Panel::Pad::MC;

#########################################################################################
use strict;
use warnings;
use Wx qw( :misc :id :colour :font :brush :pen :sizer :panel :window);
use base qw( Wx::Window HiPi::Class );
use Wx::Event qw( EVT_PAINT EVT_SIZE EVT_MOTION EVT_LEAVE_WINDOW EVT_LEFT_DOWN);

__PACKAGE__->create_accessors( qw( padname pins pincount pindata margintop
                              marginleft pinheight bodyheight bodywidth
                              pinindent labelwidth labelmargin overlay
                              selectedpin ) );

our %_defaults = (
    margintop   => 30,
    marginleft  => 100,
    pinheight   => 16,
    bodywidth   => 50,
    labelwidth  => 80,
    labelmargin => 10,
);

sub new {
    my($class, $parent, $vdata) = @_;
    my $width = ( $_defaults{marginleft} * 2 ) + $_defaults{bodywidth};
    my $self = $class->SUPER::new($parent, wxID_ANY, wxDefaultPosition, [ $width, -1 ], wxBORDER_NONE );
    $self->SetValidator(HiPi::Apps::Control::Panel::Pad::MC::Validator->new($vdata, 'pins'));
    
    EVT_PAINT( $self, sub { shift->_evt_on_paint( @_ ); } );
    EVT_SIZE( $self, sub { shift->_evt_on_size( @_ ); } );
    EVT_MOTION( $self, sub { shift->_evt_on_mouse_move( @_ ); } );
    EVT_LEAVE_WINDOW( $self, sub { shift->_evt_on_mouse_leave( @_ ); } );
    EVT_LEFT_DOWN( $self, sub { shift->_evt_on_left_down( @_ ); } );
    
    my $mfont = Wx::Font->new(10, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0);
    $self->SetFont( $mfont );
    
    $self->margintop($_defaults{margintop});
    $self->marginleft($_defaults{marginleft});
    $self->pinheight($_defaults{pinheight});
    $self->bodywidth($_defaults{bodywidth});
    $self->pinindent(int($_defaults{bodywidth} / 3));
    $self->labelwidth($_defaults{labelwidth});
    $self->labelmargin($_defaults{labelmargin});
    
    $self->overlay(Wx::Overlay->new);
        
    return $self;
}

sub set_pins {
    my($self, $pins) = @_;
    $self->pincount(scalar @$pins);
    $self->pins($pins);
    my $slots = int($self->pincount / 2) + ($self->pincount % 2); 
    $self->bodyheight( $slots * $self->pinheight );
    
    my @pindata;
    
    my $selectedpin = $self->selectedpin || 0;
    
    my $slotcount = 0;
    for ( my $i = 0; $i < @$pins; $i++ ) {
        my $isleftpin = ( $i % 2 ) ? 0 : 1;
        my $ycoord = ($self->pinheight / 2) + $self->margintop + ( $slotcount * $self->pinheight );
        my $xcoord = ( $isleftpin ) ? $self->marginleft + $self->pinindent : $self->marginleft + ( $self->bodywidth - $self->pinindent );
                
        my %data = (
            bodypin => [ $xcoord, $ycoord ],
        );
        
        if( $isleftpin ) {
            #$data{extpin}    = [ $xcoord - 25, $ycoord ];
            $data{textrect}  = Wx::Rect->new(
                $self->marginleft - ( $self->labelmargin + $self->labelwidth ),
                $ycoord - ($self->pinheight / 2),
                $self->labelwidth,
                $self->pinheight
            );
            $data{textalign} = wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL;
            $data{focusrect}  = Wx::Rect->new(
                $self->marginleft - ( $self->labelmargin + $self->labelwidth ),
                $ycoord - ($self->pinheight / 2),
                $self->labelwidth + $self->labelmargin + ($self->bodywidth / 2),
                $self->pinheight
            );
        } else {
            #$data{extpin}    = [ $xcoord + 25, $ycoord ];
            $data{textrect}  = Wx::Rect->new(
                $self->marginleft + $self->bodywidth + $self->labelmargin,
                $ycoord - ($self->pinheight / 2),
                $self->labelwidth,
                $self->pinheight
            );
            $data{textalign} = wxALIGN_LEFT|wxALIGN_CENTER_VERTICAL;
            $data{focusrect}  = Wx::Rect->new(
                $self->marginleft + ($self->bodywidth / 2),
                $ycoord - ($self->pinheight / 2),
                $self->labelwidth + $self->labelmargin + ($self->bodywidth / 2),
                $self->pinheight
            );
        }
        
        if( $i && ($i % 2)) {
            $slotcount ++;
        }
        push @pindata, \%data;
    }
    
    $self->pindata( \@pindata );
    
    my $newevent = Wx::CommandEvent->new(
        $HiPi::Apps::Control::Panel::Pad::ID_HIPI_EVT_PIN_CLICKED,
        $self->GetId
        );
    $newevent->SetInt($selectedpin);
    $self->GetEventHandler->AddPendingEvent($newevent);
}

sub _evt_on_size {
    my( $self, $event ) = @_;
    $event->Skip(1);
    $self->Refresh;
}

sub _evt_on_mouse_leave {
    my( $self, $event ) = @_;
    $event->Skip(1);
    my $dc = Wx::ClientDC->new( $self );
    my $overlaydc = Wx::DCOverlay->new($self->overlay, $dc);
    $overlaydc->Clear;
}

sub _evt_on_mouse_move {
    my( $self, $event ) = @_;
    $event->Skip(1);
    my $dc = Wx::ClientDC->new( $self );
    my $overlaydc = Wx::DCOverlay->new($self->overlay, $dc);
    $overlaydc->Clear;
    
    my $pos = $event->GetPosition;
    
    for my $pin ( @{ $self->pindata } ) {
        if( $pin->{focusrect}->Contains( $pos ) ) {
            my $pen   = Wx::Pen->new( wxRED, 2, wxSOLID );
            my $brush = wxTRANSPARENT_BRUSH;
            $dc->SetPen( $pen );
            $dc->SetBrush ( $brush );
            $dc->DrawRectangle($pin->{focusrect}->x, $pin->{focusrect}->y, $pin->{focusrect}->GetWidth, $pin->{focusrect}->GetHeight);
            last;
        }
    }
}

sub _evt_on_left_down {
    my( $self, $event ) = @_;
    $event->Skip(1);
    
    my $pos = $event->GetPosition;
    my $pidata = $self->pindata;
    for( my $i = 0; $i < @$pidata; $i++) {
        if( $pidata->[$i]->{focusrect}->Contains( $pos ) ) {
            my $newevent = Wx::CommandEvent->new(
                $HiPi::Apps::Control::Panel::Pad::ID_HIPI_EVT_PIN_CLICKED,
                $self->GetId
                );
            $newevent->SetInt($i);
            $self->GetEventHandler->AddPendingEvent($newevent);
            last;
        }
    }
}

sub _evt_on_paint {
    my( $self, $event ) = @_;
    
    my $dc = Wx::AutoBufferedPaintDC->new($self);
    
    # Clear Background
    {
        my $bbrush = Wx::Brush->new(Wx::Colour->new(20,100,0), wxSOLID);
        $dc->SetBackground( $bbrush );
        $dc->SetBrush( $bbrush );
        $dc->Clear;
    }
    
    return unless $self->pins;
    
    $self->_draw_body($dc);
    $self->_draw_pins($dc);
    $self->_draw_selected_pin($dc);
    $self->overlay->Reset;
}

sub _draw_body {
    my($self, $dc) = @_;
    
    my $bheight = $self->bodyheight;
    my $bwidth = $self->bodywidth;
    
    $dc->SetBrush( Wx::Brush->new(Wx::Colour->new(127,127,127), wxSOLID) );
    $dc->SetPen( Wx::Pen->new(Wx::Colour->new(80,80,80),1,wxSOLID) );
    
    $dc->DrawRectangle($self->marginleft, $self->margintop, $bwidth, $bheight);
    
    $dc->SetTextForeground(wxWHITE);
    {
        my($w, $h, $d, $e) = $dc->GetTextExtent($self->padname);
        #my $coordy = $self->margintop + ( $bheight + $w ) / 2;
        #my $coordx = $self->marginleft + ( $bwidth / 2 ) - ( $h / 2 );
        #$dc->DrawRotatedText($self->padname, $coordx, $coordy, 90);
        my $coordx = $self->marginleft + ( $bwidth / 2 ) - ( $w / 2 );
        my $coordy = 10;
        $dc->DrawText($self->padname, $coordx, $coordy);
    }
}

sub _draw_pins {
    my($self, $dc) = @_;
    
    my $pins = $self->pins;
    my $pindata = $self->pindata;
    
    my $pinradius = ( $self->pinheight / 2 ) - 3;
    
    $dc->SetTextForeground(wxWHITE);
    for (my $i = 0; $i < @$pins; $i++) {
        $dc->DrawLabel($pins->[$i]->{label}, $pindata->[$i]->{textrect}, $pindata->[$i]->{textalign});
        $dc->SetPen(wxBLACK_PEN);
        $dc->SetBrush(Wx::Brush->new(Wx::Colour->new(@{$pins->[$i]->{colouter}}), wxSOLID));
        $dc->DrawCircle($pindata->[$i]->{bodypin}->[0], $pindata->[$i]->{bodypin}->[1], $pinradius );
        $dc->SetBrush(Wx::Brush->new(Wx::Colour->new(@{$pins->[$i]->{colinner}}), wxSOLID));
        $dc->DrawCircle($pindata->[$i]->{bodypin}->[0], $pindata->[$i]->{bodypin}->[1], $pinradius - 3 );
    }
}

sub _draw_selected_pin {
    my($self, $dc) = @_;
    my $pen   = Wx::Pen->new( wxGREEN, 2, wxSOLID );
    my $brush = wxTRANSPARENT_BRUSH;
    $dc->SetPen( $pen );
    $dc->SetBrush ( $brush );
    my $pinindex = $self->selectedpin || 0;
    my $pin = $self->pindata->[$pinindex];
    $dc->DrawRectangle($pin->{focusrect}->x, $pin->{focusrect}->y, $pin->{focusrect}->GetWidth, $pin->{focusrect}->GetHeight);
}


#########################################################################################

package HiPi::Apps::Control::Panel::Pad::PinDetail;

#########################################################################################
use strict;
use warnings;
use Wx::PropertyGrid;
use base qw( Wx::PropertyGrid HiPi::Class HiPi::Wx::Common );
use Wx qw( :id :misc :propgrid wxTheApp );
use HiPi::Constant qw( :raspberry );
use Wx::Event qw( EVT_PG_CHANGED );
use Try::Tiny;
use Carp;

__PACKAGE__->create_accessors( qw( pindata ) );

sub new {
    my($class, $parent, $vdata) = @_;
    my $self = $class->SUPER::new($parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxPG_DEFAULT_STYLE);
    $self->SetValidator(HiPi::Apps::Control::Panel::Pad::PinDetail::Validator->new($vdata, 'pindata'));
    #-------------------------------------------------
    # Controls
    #-------------------------------------------------
    $self->Append( Wx::PropertyCategory->new('Selected Pin Detail') );
    $self->Append( Wx::StringProperty->new('Current Pin Mode Name ', 'MODE', 'INPUT') );
    $self->SetPropertyReadOnly ( 'MODE' , 1);
    $self->Append( Wx::StringProperty->new('RPi Pin Number', 'RPI', '3') );
    $self->SetPropertyReadOnly ( 'RPI' , 1);
    $self->Append( Wx::StringProperty->new('GPIO Pin Number', 'GPIO', '15') );
    $self->SetPropertyReadOnly ( 'GPIO' , 1);  
    
    $self->Append( Wx::EnumProperty->new('Direction', 'DIRECTION',
        [ 'Output', 'Input', ],
        [ 1, 0,], 0));
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'Pin Set High', 'HIGH', 1 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    
    $self->Append( Wx::FlagsProperty->new('Interrupts', 'INTERRUPTS',
		[ 'Falling',    'Rising',     'High',       'Low',     'Async Falling', 'Async Rising', ],
		[ RPI_INT_FALL, RPI_INT_RISE, RPI_INT_HIGH, RPI_INT_LOW, RPI_INT_AFALL, RPI_INT_ARISE ] , RPI_INT_RISE|RPI_INT_HIGH ) );
    

    $self->SetPropertyReadOnly ( 'INTERRUPTS' , 1, 0);
	
    $self->SetPropertyAttribute( 'INTERRUPTS' , wxPG_BOOL_USE_CHECKBOX, 1 , wxPG_RECURSE);
    
    $self->Append( Wx::EnumProperty->new('Apply PUD Resistor', 'PUD',
        [ '-- PUD Settings are write only --', 'Remove Resistors','Pull Down', 'Pull Up' ],
        [ RPI_PUD_NULL, RPI_PUD_OFF, RPI_PUD_DOWN, RPI_PUD_UP ], RPI_PUD_NULL));
    
    $self->Append( Wx::PropertyCategory->new('Peripherals') );
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'SPI 0', 'SPI0', 0 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'I2C 1', 'I2C1', 0 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'UART 0', 'UART0', 0 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'PWM 0', 'PWM0', 0 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'I2C 0', 'I2C0', 0 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'CTS RTS 0', 'CTS0', 0 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'UART 1', 'UART1', 0 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    {
        my $prop = $self->Append( Wx::BoolProperty->new( 'CTS RTS 1', 'CTS1', 0 ) );
	$prop->SetAttribute( wxPG_BOOL_USE_CHECKBOX, 1 );
    }
    
    #-----------------------------------------
    # Events
    #-----------------------------------------
    
    EVT_PG_CHANGED($self,  $self, sub { shift->OnPropertyGridChange( @_ ); } );
       
    return $self;
}

sub set_selected_pin {
    my($self, $rpinum, $gpionum) = @_;
    $self->GetValidator->vdata->set_new_pin( $rpinum, $gpionum );
    $self->GetValidator->RefreshSource;
}

sub OnPropertyGridChange {
    my( $self, $event) = @_;
    $event->Skip(1);
    
    my $property = $event->GetProperty();
    my $name     = $property->GetName();
    my $value    = $property->GetPlValue();
    
    # get the old value
    
    my %namemap = (
        SPI0        => 'SPI0',
        I2C0        => 'I2C0',
        I2C1        => 'I2C1',
        UART0       => 'UART0',
        UART1       => 'UART1',
        CTS0        => 'CTS0',
        CTS1        => 'CTS1',
        PWM0        => 'PWM0',
        INTERRUPTS  => 'interrupts',
        HIGH        => 'value',
        DIRECTION   => 'fsel',
        PUD         => 'PUD',
    );
    
    my $oldvalue;
    if( exists($namemap{$name}) ) {
        $oldvalue = $self->GetValidator->vdata->get_value( 'pindata' )->{$namemap{$name}} ;
    } else {
        Wx::LogError(qq(unknown property type $name));
        return;
    }
    
    my $docommand = 1;
    
    # put a guard around HIGH/LOW interrupt settings
    
    my $applypud  = 0;
    
    if($name eq 'INTERRUPTS') {
        # cannot HIGH & LOW
        if(($value & RPI_INT_HIGH) && ( $value & RPI_INT_LOW )) {
            Wx::LogError('You cannot apply both HIGH and LOW event detection. Select one or the other.');
            $docommand = 0;
        }
        if($docommand && ($value & RPI_INT_HIGH)) {
            my $ques = 'Setting a HIGH event detection will normally hang your ';
            $ques   .= 'Pi unless you also set a Pull Down Resistor on the pin. ';
            $ques   .= 'Do you want to proceed setting a Pull Down Resistor first?';
            $docommand = $self->WaitForQuestion($ques);
            $applypud = 1 if $docommand;
        } elsif($docommand && ($value & RPI_INT_LOW)) {
            my $ques = 'Setting a LOW event detection will normally hang your ';
            $ques   .= 'Pi unless you also set a Pull Up Resistor on the pin. ';
            $ques   .= 'Do you want to proceed setting a Pull Up Resistor first?';
            $docommand = $self->WaitForQuestion($ques);
            $applypud = 2 if $docommand;
        }
    }
    
    # guard against removing / resetting resistors when HIGH/LOW interrupts are set
    if($name eq 'PUD') {
        try {
            my $intrpts = wxTheApp->devmem->gpio_get_eds($self->pindata->{gpionum});
            if(($intrpts & RPI_INT_HIGH) || ( $intrpts & RPI_INT_LOW )) {
                $docommand = 0;
                Wx::LogError('Pin %s currently has HIGH or LOW event detection enabled. Remove this before setting PUD resistors.', $self->pindata->{gpionum});
            }
        } catch {
            $docommand = 0;
            Wx::LogError($_);
            Wx::LogError('Failed to set resistors for pin %s.', $self->pindata->{gpionum});
        };
    }
    
    if($docommand) {
        try {
            require HiPi::Apps::Control::Command::GPIO;
            my $handler = HiPi::Apps::Control::Command::GPIO->new;
            # Set PUD first if necessary
            $handler->property_change('PUD', $applypud, $self->pindata->{gpionum}, undef) if $applypud;
            $handler->property_change($name, $value, $self->pindata->{gpionum}, $oldvalue);
        } catch {
            Wx::LogError($_);
            Wx::LogError('Failed to change properties for %s.', $name);
        };
    }
    
    my $newevent = Wx::CommandEvent->new(
        $HiPi::Apps::Control::Panel::Pad::ID_HIPI_EVT_PROPERTY_CHANGED,
        $self->GetId
        );
    
    $newevent->SetInt($self->pindata->{padnum} -1);
    $self->GetEventHandler->AddPendingEvent($newevent);
}


#########################################################################################

package HiPi::Apps::Control::Panel::Pad::MC::Validator;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub GetWindowValue {
    my $self = shift;
    $self->GetWindow->pins;
}

sub SetWindowValue {
    my ($self, $data) = @_;
    $self->GetWindow->padname($self->vdata->get_value('padname'));
    $self->GetWindow->set_pins($data);
}

#########################################################################################

package HiPi::Apps::Control::Panel::Pad::PinDetail::Validator;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub GetWindowValue {
    my $self = shift;
    return $self->GetWindow->pindata;
}

sub SetWindowValue {
    my ($self, $data) = @_;
    
    my $pg = $self->GetWindow;
    $pg->pindata($data);
    
    # Peripherals
    
    for my $key ( qw( SPI0 I2C0 I2C1 UART0 UART1 CTS0 CTS1 PWM0 )) {
        $pg->SetPropertyValueAsBool( $key, $data->{$key} );
    }
    
    # PinInfo
    $pg->SetPropertyValueAsInt('PUD', -1);
    
    if( $data->{powerpin} ) {
        $pg->SetPropertyValue('RPI', $data->{padnum});
        $pg->SetPropertyValue('MODE', $data->{label});
        $pg->HideProperty('GPIO', 1);
        $pg->HideProperty('HIGH', 1);
        $pg->HideProperty('INTERRUPTS', 1);
        $pg->HideProperty('DIRECTION', 1);
        $pg->HideProperty('PUD', 1);
    } else {
        $pg->HideProperty('GPIO', 0);
        
        $pg->SetPropertyValue('RPI', $data->{padnum});
        $pg->SetPropertyValue('GPIO', $data->{gpionum});
        $pg->SetPropertyValue('MODE', $data->{label});
        $pg->SetPropertyValueAsInt('HIGH', $data->{value});
        $pg->SetPropertyValueAsInt('INTERRUPTS', $data->{interrupts});
        
        if( $data->{function} eq 'INPUT') {
            $pg->HideProperty('HIGH', 0);
            $pg->SetPropertyReadOnly( 'HIGH', 1);
            
            $pg->HideProperty('DIRECTION', 0);
            $pg->SetPropertyValueAsInt('DIRECTION', $data->{fsel});
            $pg->HideProperty('INTERRUPTS', 0);
            $pg->HideProperty('PUD', 0);
            
        } elsif(  $data->{function} eq 'OUTPUT') {
            $pg->HideProperty('HIGH', 0);
            $pg->SetPropertyReadOnly( 'HIGH', 0);
            
            $pg->HideProperty('DIRECTION', 0);
            $pg->SetPropertyValueAsInt('DIRECTION', $data->{fsel}); 
            $pg->HideProperty('INTERRUPTS', 1);
            $pg->HideProperty('PUD', 1);
            
        } else {
            $pg->HideProperty('HIGH', 1);
            $pg->HideProperty('INTERRUPTS', 1);
            $pg->HideProperty('DIRECTION', 1);
            $pg->HideProperty('PUD', 1);
        }
    }
}

1;
