/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

#import <AppKit/NSViewController.h>

@class DVTExtension, DVTStackBacktrace, NSString;

@interface DVTViewController : NSViewController
{
	DVTExtension *_representedExtension;
	BOOL _isViewLoaded;
	BOOL _didCallViewWillUninstall;
	void *_keepSelfAliveUntilCancellationRef;
}

+ (id)defaultViewNibBundle;
+ (id)defaultViewNibName;
+ (void)initialize;
@property(retain, nonatomic) DVTExtension *representedExtension; // @synthesize representedExtension=_representedExtension;
@property BOOL isViewLoaded; // @synthesize isViewLoaded=_isViewLoaded;
- (void)primitiveInvalidate;
- (void)invalidate;
- (BOOL)commitEditingForAction:(int)arg1 errors:(id)arg2;
- (void)_willUninstallContentView:(id)arg1;
- (void)_didInstallContentView:(id)arg1;
- (void)viewWillUninstall;
- (void)viewDidInstall;
- (void)loadView;
- (void)setView:(id)arg1;
- (void)separateKeyViewLoops;
- (BOOL)delegateFirstResponder;
- (id)supplementalMainViewController;
- (id)description;
- (BOOL)becomeFirstResponder;
- (id)view;
- (id)initWithCoder:(id)arg1;
- (id)initWithNibName:(id)arg1 bundle:(id)arg2;
- (id)initUsingDefaultNib;
- (void)dvtViewController_commonInit;
@property(readonly) BOOL canBecomeMainViewController;

// Remaining properties
@property(retain) DVTStackBacktrace *creationBacktrace;
@property(readonly) DVTStackBacktrace *invalidationBacktrace;
@property(readonly, nonatomic, getter=isValid) BOOL valid;

@end
