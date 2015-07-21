/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

#import "DVTViewController.h"

@class DVTStateToken, IDESelection, IDEWorkspace, IDEWorkspaceDocument, IDEWorkspaceTabController;

@interface IDEViewController : DVTViewController
{
	IDEWorkspaceTabController *_workspaceTabController;
	id _outputSelection;
	id _contextMenuSelection;
	DVTStateToken *_stateToken;
}

+ (void)configureStateSavingObjectPersistenceByName:(id)arg1;
+ (long long)version;
@property(retain, nonatomic) IDEWorkspaceTabController *workspaceTabController; // @synthesize workspaceTabController=_workspaceTabController;
@property(copy) IDESelection *contextMenuSelection; // @synthesize contextMenuSelection=_contextMenuSelection;
@property(copy) IDESelection *outputSelection; // @synthesize outputSelection=_outputSelection;
- (void)setStateToken:(id)arg1;
- (BOOL)_knowsAboutInstalledState;
- (void)revertState;
- (void)commitState;
- (void)commitStateToDictionary:(id)arg1;
- (void)revertStateWithDictionary:(id)arg1;
- (void)primitiveInvalidate;
@property(readonly) BOOL automaticallyInvalidatesChildViewControllers;
- (void)_invalidateSubViewControllersForView:(id)arg1;
- (id)supplementalTargetForAction:(SEL)arg1 sender:(id)arg2;
@property(readonly) IDEWorkspace *workspace;
@property(readonly) IDEWorkspaceDocument *workspaceDocument;
- (id)workspaceDocumentProvider;
- (id)initWithNibName:(id)arg1 bundle:(id)arg2;

@end
