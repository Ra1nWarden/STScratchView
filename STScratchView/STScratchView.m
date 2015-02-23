//
//  STScratchView.m
//  STScratchView
//
//  Created by Sebastien Thiebaud on 12/17/12.
//  Copyright (c) 2012 Sebastien Thiebaud. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "STScratchView.h"

@interface STScratchView()

- (void)initScratch;
- (void)refreshAutomaticScratch:(NSTimer *)timer;

@end

@implementation STScratchView
{
    CGPoint _previousTouchLocation;
    CGPoint _currentTouchLocation;
    
    CGImageRef _hideImage;
    CGImageRef _scratchImage;
    
	CGContextRef _contextMask;
    
    UIView *_refMovementView;

    size_t _width;
    size_t _height;
    int _pointsFilled;
    bool *_matrix;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setOpaque:NO];
        
        _sizeBrush = 10.0;
    }
    return self;
}

#pragma mark -
#pragma mark CoreGraphics methods

// Will be called every touch and at the first init
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    UIImage *imageToDraw = [UIImage imageWithCGImage:_scratchImage];
    [imageToDraw drawInRect:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
    
}

// Method to change the view which will be scratched
- (void)setHideView:(UIView *)hideView
{
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();

    float scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(hideView.bounds.size, NO, 0);
    [hideView.layer renderInContext:UIGraphicsGetCurrentContext()];
    hideView.layer.contentsScale = scale;
    _hideImage = UIGraphicsGetImageFromCurrentImageContext().CGImage;
    UIGraphicsEndImageContext();
    
    size_t imageWidth = CGImageGetWidth(_hideImage);
    size_t imageHeight = CGImageGetHeight(_hideImage);
    
    CFMutableDataRef pixels = CFDataCreateMutable(NULL, imageWidth * imageHeight);
    _contextMask = CGBitmapContextCreate(CFDataGetMutableBytePtr(pixels), imageWidth, imageHeight , 8, imageWidth, colorspace, kCGImageAlphaNone);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(pixels);
    CFRelease(pixels);
    
    CGContextSetFillColorWithColor(_contextMask, [UIColor blackColor].CGColor);
    CGContextFillRect(_contextMask, CGRectMake(0, 0, self.frame.size.width * scale, self.frame.size.height * scale));

    
    CGContextSetStrokeColorWithColor(_contextMask, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(_contextMask, _sizeBrush);
    CGContextSetLineCap(_contextMask, kCGLineCapRound);
    
    CGImageRef mask = CGImageMaskCreate(imageWidth, imageHeight, 8, 8, imageWidth, dataProvider, nil, NO);
    _scratchImage = CGImageCreateWithMask(_hideImage, mask);
    CGDataProviderRelease(dataProvider);
    
    CGImageRelease(mask);
    CGColorSpaceRelease(colorspace);

    _width = imageWidth / _sizeBrush;
    _height = imageHeight / _sizeBrush;
    _matrix = (bool *) malloc(_width * _height);
    bool *tmp = _matrix;
    for(size_t i = 0; i < _width * _height; i++) {
        *tmp = false; 
        tmp++;
    }
    _pointsFilled = 0;
}

- (void)scratchTheViewFrom:(CGPoint)startPoint to:(CGPoint)endPoint
{
    float scale = [UIScreen mainScreen].scale;

    CGContextMoveToPoint(_contextMask, startPoint.x * scale, (self.frame.size.height - startPoint.y) * scale);
	CGContextAddLineToPoint(_contextMask, endPoint.x * scale, (self.frame.size.height - endPoint.y) * scale);
	CGContextStrokePath(_contextMask);
    
    size_t startx = MAX(MIN(startPoint.x, self.frame.size.width), 0) / self.frame.size.width * _width;
    size_t starty = MAX(MIN(startPoint.y, self.frame.size.height), 0) / self.frame.size.height * _height;
    size_t endx = MAX(MIN(endPoint.x, self.frame.size.width), 0) / self.frame.size.width * _width;
    size_t endy = MAX(MIN(endPoint.y, self.frame.size.height), 0) / self.frame.size.height * _height;
    
    CGFloat dx = (startx > endx ? -1.0 * (startx - endx) : 1.0 * (endx - startx)) / 700.0;
    CGFloat dy = (starty > endy ? -1.0 * (starty - endy) : 1.0 * (endy - starty)) / 700.0;
    
    bool changed = false;
    
    for(int i = 0; i <= 700; i++) {
        size_t newx = dx * i + startx;
        size_t newy = dy * i + starty;
        if(!_matrix[newy * _width + newx]) {
            _matrix[newy * _width + newx] = true;
            _pointsFilled++;
            changed = true;
        }
    }
    if(changed) {
        [_delegate STScratchView:self didChangeProgress:((CGFloat)_pointsFilled) / ((CGFloat) (_width * _height))];
    }
    
	[self setNeedsDisplay];
    
}

#pragma mark -
#pragma mark Touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [[event touchesForView:self] anyObject];
    _currentTouchLocation = [touch locationInView:self];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [[event touchesForView:self] anyObject];
   
    if (!CGPointEqualToPoint(_previousTouchLocation, CGPointZero))
    {
        _currentTouchLocation = [touch locationInView:self];
    }
    
    _previousTouchLocation = [touch previousLocationInView:self];
   
    [self scratchTheViewFrom:_previousTouchLocation to:_currentTouchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [[event touchesForView:self] anyObject];

    if (!CGPointEqualToPoint(_previousTouchLocation, CGPointZero))
    {
        _previousTouchLocation = [touch previousLocationInView:self];
        [self scratchTheViewFrom:_previousTouchLocation to:_currentTouchLocation];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
}

- (void)initScratch
{
    _currentTouchLocation = CGPointZero;
    _previousTouchLocation = CGPointZero;
}

#pragma mark -
#pragma mark Automatic scratch

- (void)setAutomaticScratchCurve:(UIBezierPath *)curvePath duration:(float)duration
{
    [_refMovementView removeFromSuperview];
    _refMovementView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 5.0, 5.0)];
    _refMovementView.alpha = 0.0;
    [self addSubview:_refMovementView];

    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.duration = duration;
    pathAnimation.path = curvePath.CGPath;
    pathAnimation.calculationMode = kCAAnimationLinear;
    pathAnimation.removedOnCompletion = YES;
    pathAnimation.autoreverses = NO;
    pathAnimation.fillMode = kCAFillModeForwards;
    [_refMovementView.layer addAnimation:pathAnimation forKey:@"movingAnimation"];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(refreshAutomaticScratch:) userInfo:nil repeats:YES];
}

- (void)refreshAutomaticScratch:(NSTimer *)timer
{    
    if (_refMovementView.layer.animationKeys.count == 0)
    {
        return;
    }
    
    CALayer *presentationLayer = _refMovementView.layer.presentationLayer;
    _currentTouchLocation = presentationLayer.position;
    
    if (CGPointEqualToPoint(_currentTouchLocation, _previousTouchLocation))
    {
        [timer invalidate];
    }
    
    [self scratchTheViewFrom:_previousTouchLocation to:_currentTouchLocation];
    _previousTouchLocation = _currentTouchLocation;
}

@end
