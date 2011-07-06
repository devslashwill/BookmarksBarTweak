#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SA_ActionSheet.h"

#define CANCEL_STRING NSLocalizedStringFromTableInBundle(@"Cancel (action sheet)", @"Localizable", [NSBundle bundleWithPath:@"/Applications/MobileSafari.app"], @"")
#define OPEN_IN_STRING NSLocalizedStringFromTableInBundle(@"Open in %@", @"Localizable", [NSBundle bundleWithPath:@"/Applications/MobileSafari.app"], @"")
#define NEW_PAGE_STRING NSLocalizedStringFromTableInBundle(@"New Page", @"Localizable", [NSBundle bundleWithPath:@"/Applications/MobileSafari.app"], @"")
#define OINP_STRING [NSString stringWithFormat:OPEN_IN_STRING, NEW_PAGE_STRING]
#define OPEN_STRING NSLocalizedStringFromTableInBundle(@"Open Link", @"Localizable", [NSBundle bundleWithPath:@"/System/Library/Frameworks/UIKit.framework"], @"")
#define COPY_STRING NSLocalizedStringFromTableInBundle(@"Copy", @"Localizable", [NSBundle bundleWithPath:@"/System/Library/Frameworks/UIKit.framework"], @"")

@interface WebBookmark : NSObject
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *title;
@end

@interface BookmarksBarView : UIView
- (void)_buttonTapped:(id)button;
@end

@interface BookmarksBarLabelButton : UIButton
- (WebBookmark *)bookmark;
@end

@interface BrowserController : NSObject
+ (id)sharedBrowserController;
- (void)loadURLInNewWindow:(NSURL *)url animated:(BOOL)animated;
- (void)loadURL:(NSURL *)url userDriven:(BOOL)userDriven;
- (id)currentPopoverController;
- (id)addressView;
@end

@interface BookmarksTableViewController : UITableViewController
- (id)bookmarksNavigationController;
- (WebBookmark *)_bookmarkAtIndexPath:(NSIndexPath *)indexPath;
@end

%class BrowserController;

BOOL isShowingActionSheet = NO;

%hook BookmarksBarView

- (void)_reloadBookmarkLabels
{
    %orig;
    
    NSMutableArray *labels = MSHookIvar<NSMutableArray *>(self, "_bookmarkBarLabels");
    for (BookmarksBarLabelButton *bookmarkButton in labels)
    {
        if (![[bookmarkButton gestureRecognizers] count])
        {
            UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(bookmarkButtonHeld:)];
            [bookmarkButton addGestureRecognizer:holdGesture];
            [holdGesture release];
        }
    }
}

- (void)_createAllLabelButtons
{
    %orig;
    
    NSMutableArray *labels = MSHookIvar<NSMutableArray *>(self, "_bookmarkBarLabels");
    for (BookmarksBarLabelButton *bookmarkButton in labels)
    {
        UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(bookmarkButtonHeld:)];
        [bookmarkButton addGestureRecognizer:holdGesture];
        [holdGesture release];
    }
}

%new(v@:) - (void)bookmarkButtonHeld:(UILongPressGestureRecognizer *)sender
{
    if (!isShowingActionSheet)
    {
        isShowingActionSheet = YES;
        
        BookmarksBarLabelButton *button = (BookmarksBarLabelButton *)sender.view;
        
        SA_ActionSheet *sheet = [[SA_ActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:OPEN_STRING, OINP_STRING, COPY_STRING, nil];
        
        [sheet showFromRect:button.frame inView:self animated:YES buttonBlock:^(int buttonIndex){
            switch (buttonIndex)
            {
                case 0:
                {
                    [self _buttonTapped:button];
                    break;
                }
                case 1:
                {
                    NSURL *url = [NSURL URLWithString:button.bookmark.address];
                    [[$BrowserController sharedBrowserController] loadURLInNewWindow:url animated:YES];
                    break;
                }
                case 2:
                {
                    [[UIPasteboard generalPasteboard] setString:button.bookmark.address];
                    break;
                }
            }
            
            isShowingActionSheet = NO;
        }];
        
        [sheet release];
    }
}

%end

%hook BookmarksTableViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Very ugly way of checking if we have been shown from the bookmarks bar chevron
    if ([self bookmarksNavigationController] == MSHookIvar<id>(MSHookIvar<id>([[$BrowserController sharedBrowserController] addressView], "_bookmarksBarView"), "_bookmarksNavigationController"))
    {
        UITableViewCell *cell = %orig;
        
        UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(overflowBookmarkHeld:)];
        [cell addGestureRecognizer:holdGesture];
        [holdGesture release];
        
        cell.tag = indexPath.row;
        
        return cell;
    }
    
    return %orig;
}

%new(v@:) - (void)overflowBookmarkHeld:(UILongPressGestureRecognizer *)sender
{
    if (!isShowingActionSheet)
    {
        isShowingActionSheet = YES;
        
        WebBookmark *bookmark = [self _bookmarkAtIndexPath:[NSIndexPath indexPathForRow:sender.view.tag inSection:0]];
        
        SA_ActionSheet *sheet = [[SA_ActionSheet alloc] initWithTitle:bookmark.title delegate:nil cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_STRING, OINP_STRING, COPY_STRING, nil];
        [sheet showInView:[self view] buttonBlock:^(int buttonIndex){
            switch (buttonIndex)
            {
                case 0:
                {
                    NSURL *url = [NSURL URLWithString:bookmark.address];
                    [[$BrowserController sharedBrowserController] loadURL:url userDriven:YES];
                    break;
                }
                case 1:
                {
                    NSURL *url = [NSURL URLWithString:bookmark.address];
                    [[$BrowserController sharedBrowserController] loadURLInNewWindow:url animated:YES];
                    break;
                }
                case 2:
                {
                    [[UIPasteboard generalPasteboard] setString:bookmark.address];
                    break;
                }
            }
            
            if (buttonIndex != 3)
                [[[$BrowserController sharedBrowserController] currentPopoverController] dismissPopoverAnimated:YES];
            
            isShowingActionSheet = NO;
        }];
        [sheet release];
    }
}

%end
