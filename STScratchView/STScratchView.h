//
//  STScratchView.h
//  STScratchView
//
//  Created by Sebastien Thiebaud on 12/17/12.
//  Copyright (c) 2012 Sebastien Thiebaud. All rights reserved.
//

@class STScratchView;

@protocol STScratchViewDelegate

- (void)STScratchView:(STScratchView*)scratchView didChangeProgress:(CGFloat)progress;

@end

@interface STScratchView : UIView

@property (nonatomic, assign) float sizeBrush;
@property (nonatomic, strong) UIView *hideView;
@property (nonatomic, weak) id<STScratchViewDelegate> delegate;

- (void)setHideView:(UIView *)hideView;
- (void)setAutomaticScratchCurve:(UIBezierPath *)curvePath duration:(float)duration;

@end
