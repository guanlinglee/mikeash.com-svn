//
//  DiagonalSlider.m
//  DiagonalSlider
//
//  Created by Michael Ash on 4/21/10.
//  Copyright 2010 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "DiagonalSlider.h"


@implementation DiagonalSlider

const CGFloat kInsetX = 12;
const CGFloat kInsetY = 12;
const CGFloat kSliderWidth = 6;
const CGFloat kKnobRadius = 10;

- (NSPoint)_point1
{
    return NSMakePoint(kInsetX, kInsetY);
}

- (NSPoint)_point2
{
    NSRect bounds = [self bounds];
    return NSMakePoint(NSMaxX(bounds) - kInsetX, NSMaxY(bounds) - kInsetY);
}

- (NSPoint)_knobCenter
{
    NSPoint p1 = [self _point1];
    NSPoint p2 = [self _point2];
    
    return NSMakePoint(p1.x * (1.0 - _value) + p2.x * _value, p1.y * (1.0 - _value) + p2.y * _value);
}

- (NSBezierPath *)_knobPath
{
    NSRect knobR = { [self _knobCenter], NSZeroSize };
    return [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(knobR, kKnobRadius, kKnobRadius)];
}

- (void)drawRect: (NSRect)r
{
    NSBezierPath *slider = [NSBezierPath bezierPath];
    [slider moveToPoint: [self _point1]];
    [slider lineToPoint: [self _point2]];
    [slider setLineWidth: kSliderWidth];
    
    [[NSColor blueColor] setStroke];
    [slider stroke];
    
    [[NSColor redColor] setFill];
    [[self _knobPath] fill];
}

static NSPoint sub(NSPoint p1, NSPoint p2)
{
    return NSMakePoint(p1.x - p2.x, p1.y - p2.y);
}

static CGFloat dot(NSPoint p1, NSPoint p2)
{
    return p1.x * p2.x + p1.y * p2.y;
}

static CGFloat len(NSPoint p)
{
    return sqrt(p.x * p.x + p.y * p.y);
}

- (double)_valueForPoint: (NSPoint)p
{
    // vector from slider start to point
    NSPoint delta = sub(p, [self _point1]);
    
    // vector of slider
    NSPoint slider = sub([self _point2], [self _point1]);
    
    // project delta onto slider
    CGFloat projection = dot(delta, slider) / len(slider);
    
    // value is projection length divided by slider length
    return projection / len(slider);
}

- (BOOL)_sliderContainsPoint: (NSPoint)p
{
    // vector from slider start to point
    NSPoint delta = sub(p, [self _point1]);
    
    // vector of slider
    NSPoint slider = sub([self _point2], [self _point1]);
    
    // vector of perpendicular to slider
    NSPoint sliderPerp = { -slider.y, slider.x };
    
    // project delta onto perpendicular
    CGFloat projection = dot(delta, sliderPerp) / len(sliderPerp);
    
    // distance to slider is absolute value of projection
    // see if that's within the slider width
    return fabs(projection) <= kSliderWidth;
}

- (void)_trackMouseWithStartPoint: (NSPoint)p
{
    // compute the value offset: this makes the pointer stay on the
    // same piece of the knob when dragging
    double valueOffset = [self _valueForPoint: p] - _value;
    
    // track!
    NSEvent *event = nil;
    while([event type] != NSLeftMouseUp)
    {
        event = [[self window] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask];
        
        NSPoint p = [self convertPoint: [event locationInWindow] fromView: nil];
        double value = [self _valueForPoint: p];
        [self setValue: value - valueOffset];
        [self sendAction: [self action] to: [self target]];
    }
}

- (void)mouseDown: (NSEvent *)event
{
    NSPoint p = [self convertPoint: [event locationInWindow] fromView: nil];
    
    if([[self _knobPath] containsPoint: p])
    {
        [self _trackMouseWithStartPoint: p];
    }
    else if([self _sliderContainsPoint: p])
    {
        [self setValue: [self _valueForPoint: p]];
        [self _trackMouseWithStartPoint: p];
    }
}

- (void)setValue: (double)value
{
    // clamp to [0, 1]
    value = MAX(value, 0);
    value = MIN(value, 1);
    
    _value = value;
    [self setNeedsDisplay: YES];
}

- (double)value
{
    return _value;
}

@end
