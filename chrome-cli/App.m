//
//  App.m
//  chrome-cli
//
//  Created by Petter Rasmussen on 08/02/14.
//  Copyright (c) 2014 Petter Rasmussen. All rights reserved.
//

#import "App.h"
#import "chrome.h"


static NSInteger const kMaxLaunchTimeInSeconds = 15;
static NSString * const kVersion = @"1.9.1";
static NSString * const kJsPrintSource = @"(function() { return document.getElementsByTagName('html')[0].outerHTML })();";



@implementation App {
    NSString *bundleIdentifier;
    OutputFormat outputFormat;
    NSMutableArray *windows;
    NSMutableArray *tabsToWindow;
    chromeWindow* activeWindow;
    chromeTab* activeTab;
}

- (NSString*) genKeyWithPoint: (chromeWindow*) p {
  return [NSString stringWithFormat:@"%p", p];
}

- (id)initWithBundleIdentifier:(NSString *)bundleIdentifier outputFormat:(OutputFormat)outputFormat {
    self = [super init];
    self->bundleIdentifier = bundleIdentifier;
    self->outputFormat = outputFormat;
    self->windows = [NSMutableArray array];
    self->tabsToWindow = [NSMutableArray array];

    // extract window and tab object
    for (chromeWindow *window in self.chrome.windows) {
      if (self->activeWindow == nil) {
        self->activeWindow = window;
      }
      NSMutableArray *tabs = [NSMutableArray array];
      for (chromeTab *tab in window.tabs) {
        [tabs addObject: tab];
      }
      [self->tabsToWindow addObject: tabs];
      [self->windows addObject: window];
    }

    if (self->windows.count > 0) {
        int activeTabIdx = [self activeWindow].activeTabIndex;
        self->activeTab = [[self->tabsToWindow objectAtIndex:0] objectAtIndex: activeTabIdx-1];
    }
    return self;
}


- (chromeApplication *)chrome {
    chromeApplication *chrome = [SBApplication applicationWithBundleIdentifier:self->bundleIdentifier];

    if ([chrome isRunning]) {
        return chrome;
    }

    if (self->outputFormat == kOutputFormatText) {
        printf("Waiting for chrome to start...\n");
    }
    [chrome activate];
    NSDate *start = [NSDate date];

    // Wait until chrome has one or more windows or give up if MaxLaunchTime is reached
    while ([[NSDate date] timeIntervalSinceDate:start] < kMaxLaunchTimeInSeconds) {
        // Sleep for 100ms
        usleep(100000);

        if ([chrome.windows count] > 0) {
            return chrome;
        }
    }

    if (self->outputFormat == kOutputFormatText) {
        printf("Chrome did not start for %ld seconds\n", kMaxLaunchTimeInSeconds);
    }
    exit(1);
}


- (void)listWindows:(Arguments *)args {
    if (self->outputFormat == kOutputFormatJSON) {
        NSMutableArray *windowInfos = [[NSMutableArray alloc] init];
        int winIdx = 0;
        for (chromeWindow *window in self.chrome.windows) {
            NSDictionary *windowInfo = @{
                @"id" : @(winIdx),
                @"name" : window.name,
            };
            [windowInfos addObject:windowInfo];
            ++winIdx;
        }

        NSDictionary *output = @{
            @"windows" : windowInfos,
        };
        [self printJSON:output];
    } else {
        int winIdx = 0;
        for (chromeWindow *window in self.chrome.windows) {
            printf("[%ld] %s\n", (long)winIdx, window.name.UTF8String);
            ++winIdx;
        }
    }

}

- (void)listTabs:(Arguments *)args {
    int count = 1;
    if (self->outputFormat == kOutputFormatJSON) {
        NSMutableArray *tabInfos = [[NSMutableArray alloc] init];

        int winIdx = 0;
        for (chromeWindow *window in self.chrome.windows) {
            int tabIdx = 0;
            for (chromeTab *tab in window.tabs) {
                NSDictionary *tabInfo = @{
                    @"windowId" : @(winIdx),
                    @"windowName" : window.name,
                    @"index" : @(count),
                    @"id" : @(tabIdx),
                    @"title" : tab.title,
                    @"url" : tab.URL,
                };
                [tabInfos addObject:tabInfo];
                ++tabIdx;
                ++count;
            }
            ++winIdx;
        }

        NSDictionary *output = @{
            @"tabs" : tabInfos,
        };
        [self printJSON:output];
    } else {
        int winIdx = 0;
        for (chromeWindow *window in self.chrome.windows) {
            int tabIdx = 0;
            for (chromeTab *tab in window.tabs) {
                printf("[%d:%d] %s\n", winIdx, tabIdx, tab.title.UTF8String);
                ++tabIdx;
            }
            ++winIdx;
        }
    }
}

- (void)listTabsLinks:(Arguments *)args {
    if (self->outputFormat == kOutputFormatJSON) {
        NSMutableArray *tabInfos = [[NSMutableArray alloc] init];

        int winIdx = 0;
        for (chromeWindow *window in self.chrome.windows) {
            int tabIdx = 0;
            for (chromeTab *tab in window.tabs) {
                NSDictionary *tabInfo = @{
                    @"windowId" : @(winIdx),
                    @"windowName" : window.name,
                    @"id" : @(tabIdx),
                    @"title" : tab.title,
                    @"url" : tab.URL,
                };
                [tabInfos addObject:tabInfo];
                ++tabIdx;
            }
            ++winIdx;
        }

        NSDictionary *output = @{
            @"tabs" : tabInfos,
        };
        [self printJSON:output];
    } else {
        int winIdx = 0;
        for (chromeWindow *window in self.chrome.windows) {
            int tabIdx = 0;
            for (chromeTab *tab in window.tabs) {
                if (self.chrome.windows.count > 1) {
                    printf("[%d:%d] %s\n", winIdx, tabIdx, tab.URL.UTF8String);
                } else {
                    printf("[%d] %s\n", tabIdx, tab.URL.UTF8String);
                }
                ++tabIdx;
            }
            ++winIdx;
        }
    }
}

- (void)listTabsWithLink:(Arguments *)args {
    if (self->outputFormat == kOutputFormatJSON) {
        NSMutableArray *tabInfos = [[NSMutableArray alloc] init];
        int winIdx = 0;
        for(chromeWindow *window in self.chrome.windows) {
            int tabIdx = 0;
            for (chromeTab *tab in window.tabs) {
                NSDictionary *tabInfo = @{
                    @"windowId": @(winIdx),
                    @"windowName": window.name,
                    @"id": @(tabIdx),
                    @"title": tab.title,
                    @"url": tab.URL,
                };
                [tabInfos addObject:tabInfo];
                ++tabIdx;
            }
            ++winIdx;
        }
        NSDictionary *output = @{
            @"tabs": tabInfos,
        };
        [self printJSON:output];
    } else {
        int winIdx = 0;
        for (chromeWindow *window in self.chrome.windows) {
            int tabIdx = 0;
            for (chromeTab *tab in window.tabs) {
                if (self.chrome.windows.count > 1) {
                    printf("[%d:%d] title: %s, url: %s\n", winIdx, tabIdx, tab.title.UTF8String, tab.URL.UTF8String);
                } else {
                    printf("[%dß] title: %s, url: %s\n", tabIdx, tab.title.UTF8String, tab.URL.UTF8String);
                }
                ++tabIdx;
            }
            ++winIdx;
        }
    }
}

- (void)listTabsInWindow:(Arguments *)args {
    NSInteger windowId = [args asInteger:@"id"];
    chromeWindow *window = [self findWindow:windowId];

    if (!window) {
        return;
    }

    if (self->outputFormat == kOutputFormatJSON) {
        NSMutableArray *tabInfos = [[NSMutableArray alloc] init];

        int tabIdx = 0;
        for (chromeTab *tab in window.tabs) {
            NSDictionary *tabInfo = @{
                @"windowId" : @(windowId),
                @"windowName" : window.name,
                @"id" : @(tabIdx),
                @"title" : tab.title,
                @"url" : tab.URL,
            };
            [tabInfos addObject:tabInfo];
            ++tabIdx;
        }

        NSDictionary *output = @{
            @"tabs" : tabInfos,
        };
        [self printJSON:output];
    } else {
        int tabIdx = 0;
        for (chromeTab *tab in window.tabs) {
            printf("[%d] %s\n", tabIdx, tab.title.UTF8String);
            ++tabIdx;
        }
    }
}

- (void)listTabsLinksInWindow:(Arguments *)args {
    NSInteger windowId = [args asInteger:@"id"];
    chromeWindow *window = [self findWindow:windowId];

    if (!window) {
        return;
    }

    if (self->outputFormat == kOutputFormatJSON) {
        NSMutableArray *tabInfos = [[NSMutableArray alloc] init];
        int tabIdx = 0;
        for (chromeTab *tab in window.tabs) {
            NSDictionary *tabInfo = @{
                @"windowId" : @(windowId),
                @"windowName" : window.name,
                @"id" : @(tabIdx),
                @"title" : tab.title,
                @"url" : tab.URL,
            };
            [tabInfos addObject:tabInfo];
            ++tabIdx;
        }

        NSDictionary *output = @{
            @"tabs" : tabInfos,
        };
        [self printJSON:output];
    } else {
        int tabIdx = 0;
        for (chromeTab *tab in window.tabs) {
            printf("[%d] %s\n", tabIdx, tab.URL.UTF8String);
            ++tabIdx;
        }
    }
}

- (void)printActiveTabInfo:(Arguments *)args {
    chromeTab *tab = [self activeTab];
    [self printInfo:tab];
}

- (void)printTabInfo:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];
    chromeTab *tab = [self findTab:tabId];
    [self printInfo:tab];
}

- (void)openUrlInNewTab:(Arguments *)args {
    NSString *url = [args asString:@"url"];

    chromeTab *tab = [[[self.chrome classForScriptingClass:@"tab"] alloc] init];
    chromeWindow *window = [self activeWindow];
    [window.tabs addObject:tab];
    tab.URL = url;

    [self printInfo:tab];
}

- (void)openUrlInNewWindow:(Arguments *)args {
    NSString *url = [args asString:@"url"];

    chromeWindow *window = [[[self.chrome classForScriptingClass:@"window"] alloc] init];
    [self.chrome.windows addObject:window];

    chromeTab *tab = [window.tabs firstObject];
    tab.URL = url;

    [self printInfo:tab];
}

- (void)openUrlInNewIncognitoWindow:(Arguments *)args {
    NSString *url = [args asString:@"url"];

    chromeWindow *window = [[[self.chrome classForScriptingClass:@"window"] alloc] initWithProperties:@{@"mode": @"incognito"}];
    [self.chrome.windows addObject:window];

    chromeTab *tab = [window.tabs firstObject];
    tab.URL = url;

    [self printInfo:tab];
}

- (void)openUrlInTab:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];
    NSString *url = [args asString:@"url"];

    chromeTab *tab = [self findTab:tabId];

    if (tab) {
        tab.URL = url;
    }
}

- (void)openUrlInWindow:(Arguments *)args {
    NSInteger windowId = [args asInteger:@"id"];
    NSString *url = [args asString:@"url"];

    chromeTab *tab = [[[self.chrome classForScriptingClass:@"tab"] alloc] init];
    chromeWindow *window = [self findWindow:windowId];

    if (!window) {
        return;
    }

    [window.tabs addObject:tab];
    tab.URL = url;

    [self printInfo:tab];
}

- (void)reloadActiveTab:(Arguments *)args {
    chromeTab *tab = [self activeTab];

    if (tab) {
        [tab reload];
    }
}

- (void)reloadTab:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];
    chromeTab *tab = [self findTab:tabId];

    if (tab) {
        [tab reload];
    }
}

- (void)closeActiveTab:(Arguments *)args {
    chromeTab *tab = [self activeTab];

    if (tab) {
        [tab close];
    }
}

- (void)closeTab:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];
    chromeTab *tab = [self findTab:tabId];

    if (tab) {
        [tab close];
    }
}

- (void)closeActiveWindow:(Arguments *)args {
    chromeWindow *window = [self activeWindow];

    if (window) {
        [window close];
    }
}

- (void)closeWindow:(Arguments *)args {
    NSInteger windowId = [args asInteger:@"id"];
    chromeWindow *window = [self findWindow:windowId];

    if (window) {
        [window close];
    }
}


- (void)goBackActiveTab:(Arguments *)args {
    chromeTab *tab = [self activeTab];

    if (tab) {
        [tab goBack];
    }
}

- (void)goBackInTab:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];
    chromeTab *tab = [self findTab:tabId];

    if (tab) {
        [tab goBack];
    }
}

- (void)goForwardActiveTab:(Arguments *)args {
    chromeTab *tab = [self activeTab];

    if (tab) {
        [tab goForward];
    }
}

- (void)goForwardInTab:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];
    chromeTab *tab = [self findTab:tabId];

    if (tab) {
        [tab goForward];
    }
}

- (void)activateTab:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];
    chromeWindow *window = [self activeWindow];
    int curIdx = 0;
    for (chromeTab *tab in window.tabs) {
        if (curIdx == tabId) {
          [self setTabActivateToIndex: curIdx inWindow: window];
          return;
        }
        ++curIdx;
    }
}

- (void)printActiveWindowSize:(Arguments *)args {
    chromeWindow *window = [self activeWindow];
    CGSize size = window.bounds.size;

    if (self->outputFormat == kOutputFormatJSON) {
        NSDictionary *output = @{
            @"width" : @(size.width),
            @"height" : @(size.height),
        };
        [self printJSON:output];
    } else {
        printf("width: %f, height: %f\n", size.width, size.height);
    }

}

- (void)printWindowSize:(Arguments *)args {
    NSInteger windowId = [args asInteger:@"id"];
    chromeWindow *window = [self findWindow:windowId];
    CGSize size = window.bounds.size;
    if (self->outputFormat == kOutputFormatJSON) {
        NSDictionary *output = @{
            @"width" : @(size.width),
            @"height" : @(size.height),
        };
        [self printJSON:output];
    } else {
        printf("width: %f, height: %f\n", size.width, size.height);
    }
}

- (void)setActiveWindowSize:(Arguments *)args {
    float width = [args asFloat:@"width"];
    float height = [args asFloat:@"height"];

    chromeWindow *window = [self activeWindow];
    CGPoint origin = window.bounds.origin;
    window.bounds = NSMakeRect(origin.x, origin.y, width, height);
}

- (void)setWindowSize:(Arguments *)args {
    NSInteger windowId = [args asInteger:@"id"];
    float width = [args asFloat:@"width"];
    float height = [args asFloat:@"height"];

    chromeWindow *window = [self findWindow:windowId];
    CGPoint origin = window.bounds.origin;
    window.bounds = NSMakeRect(origin.x, origin.y, width, height);
}

- (void)printActiveWindowPosition:(Arguments *)args {
    chromeWindow *window = [self activeWindow];
    CGPoint origin = window.bounds.origin;

    if (self->outputFormat == kOutputFormatJSON) {
        NSDictionary *output = @{
            @"x" : @(origin.x),
            @"y" : @(origin.y),
        };
        [self printJSON:output];
    } else {
        printf("x: %f, y: %f\n", origin.x, origin.y);
    }
}

- (void)printWindowPosition:(Arguments *)args {
    NSInteger windowId = [args asInteger:@"id"];
    chromeWindow *window = [self findWindow:windowId];
    CGPoint origin = window.bounds.origin;

    if (self->outputFormat == kOutputFormatJSON) {
        NSDictionary *output = @{
            @"x" : @(origin.x),
            @"y" : @(origin.y),
        };
        [self printJSON:output];
    } else {
        printf("x: %f, y: %f\n", origin.x, origin.y);
    }
}

- (void)setActiveWindowPosition:(Arguments *)args {
    float x = [args asFloat:@"x"];
    float y = [args asFloat:@"y"];

    chromeWindow *window = [self activeWindow];
    CGSize size = window.bounds.size;
    window.bounds = NSMakeRect(x, y, size.width, size.height);
}

- (void)setWindowPosition:(Arguments *)args {
    NSInteger windowId = [args asInteger:@"id"];
    float x = [args asFloat:@"x"];
    float y = [args asFloat:@"y"];

    chromeWindow *window = [self findWindow:windowId];
    CGSize size = window.bounds.size;
    window.bounds = NSMakeRect(x, y, size.width, size.height);
}

- (void)executeJavascriptInActiveTab:(Arguments *)args {
    NSString *js = [args asString:@"javascript"];

    chromeTab *tab = [self activeTab];
    if (!tab) {
        return;
    }

    id data = [tab executeJavascript:js];

    if (self->outputFormat == kOutputFormatJSON) {
        NSString *jsOutput = [[NSString alloc] init];
        if (data) {
            jsOutput = (NSString *)data;
        }
        NSDictionary *output = @{
            @"output" : jsOutput,
        };
        [self printJSON:output];
    } else {
        if (!data) {
            return;
        }
        printf("%s\n", [(NSString *)data UTF8String]);
    }
}

- (void)executeJavascriptInTab:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];
    NSString *js = [args asString:@"javascript"];

    chromeTab *tab = [self findTab:tabId];
    if (!tab) {
        return;
    }

    id data = [tab executeJavascript:js];

    if (self->outputFormat == kOutputFormatJSON) {
        NSString *jsOutput = [[NSString alloc] init];
        if (data) {
            jsOutput = (NSString *)data;
        }
        NSDictionary *output = @{
            @"output" : jsOutput,
        };
        [self printJSON:output];
    } else {
        if (!data) {
            return;
        }
        printf("%s\n", [(NSString *)data UTF8String]);
    }
}

- (void)printSourceFromActiveTab:(Arguments *)args {
    chromeTab *tab = [self activeTab];
    if (!tab) {
        return;
    }

    id data = [tab executeJavascript:kJsPrintSource];

    if (self->outputFormat == kOutputFormatJSON) {
        NSString *jsOutput = [[NSString alloc] init];
        if (data) {
            jsOutput = (NSString *)data;
        }
        NSDictionary *output = @{
            @"source" : jsOutput,
        };
        [self printJSON:output];
    } else {
        if (!data) {
            return;
        }
        printf("%s\n", [(NSString *)data UTF8String]);
    }
}

- (void)printSourceFromTab:(Arguments *)args {
    NSInteger tabId = [args asInteger:@"id"];

    chromeTab *tab = [self findTab:tabId];
    if (!tab) {
        return;
    }

    id data = [tab executeJavascript:kJsPrintSource];

    if (self->outputFormat == kOutputFormatJSON) {
        NSString *jsOutput = [[NSString alloc] init];
        if (data) {
            jsOutput = (NSString *)data;
        }
        NSDictionary *output = @{
            @"source" : jsOutput,
        };
        [self printJSON:output];
    } else {
        if (!data) {
            return;
        }
        printf("%s\n", [(NSString *)data UTF8String]);
    }
}

- (void)printChromeVersion:(Arguments *)args {
    if (self->outputFormat == kOutputFormatJSON) {
        NSDictionary *output = @{
            @"version" : self.chrome.version,
        };
        [self printJSON:output];
    } else {
        printf("%s\n", self.chrome.version.UTF8String);
    }
}


- (void)printVersion:(Arguments *)args {

    if (self->outputFormat == kOutputFormatJSON) {
        NSDictionary *output = @{
            @"version" : kVersion,
        };
        [self printJSON:output];
    } else {
        printf("%s\n", kVersion.UTF8String);
    }
}


#pragma mark Helper functions

- (chromeWindow *)activeWindow {
    if (self->activeWindow == nil) {
        chromeWindow* window = [[[self.chrome classForScriptingClass:@"window"] alloc] init];
        [self.chrome.windows addObject:window];
        [self->windows addObject:window];
        self->activeWindow = window;
    }

    return self->activeWindow;
}

- (chromeWindow *)findWindow:(NSInteger)windowId {
    int curIdx = 0;
    for (chromeWindow *window in self.chrome.windows) {
        if (curIdx == windowId) {
            return window;
        }
        ++curIdx;
    }

    return nil;
}

- (chromeTab *)activeTab {
    return self->activeTab;
    // int activeTabIdx = [self activeWindow].activeTabIndex;
    // chromeWindow* window = [self activeWindow];
    // int curIdx = 1;
    // for (chromeTab *t in window.tabs) {
    //     if (curIdx == activeTabIdx) {
    //         return t;
    //     }
    //     ++curIdx;
    // }
    // return [self activeWindow].activeTab;
}

- (void)setTabActive:(chromeTab *)tab inWindow:(chromeWindow *)window {
    NSInteger index = [self findTabIndex:tab inWindow:window];
    window.activeTabIndex = index;
}

- (void)setTabActivateToIndex:(NSInteger)index inWindow:(chromeWindow *)window {
    window.activeTabIndex = index;
}

- (chromeTab *)findTab:(NSInteger)tabId {
    chromeWindow *window = [self activeWindow];
    int curIdx = 0;
    for (chromeTab *t in window.tabs) {
        if (curIdx == tabId){
            return t;
        }
        ++curIdx;
    }

    return nil;
}

- (chromeWindow *)findWindowWithTab:(chromeTab *)tab {
    int idx = 0;
    for (NSArray* tabs in self->tabsToWindow) {
      for (chromeTab *t in tabs) {
            if (t == tab) {
                return self->windows[idx];
            }
        }
        ++idx;
    }

    return nil;
}

- (NSInteger)findTabIndex:(chromeTab *)tab inWindow:(chromeWindow *)window {
    // Tab index starts at 1
    for (NSArray* tabs in tabsToWindow) {
        int i = 0;
        for (chromeTab *t in tabs) {
            if (t == tab) {
                return i;
            }
            i++;
        }
    }

    return NSNotFound;
}

- (NSInteger)findWindowIndex:(chromeWindow *)window {
    int i = 0;

    for (chromeWindow* win in self->windows) {
      if (win == window) {
        return i;
      }
      ++i;
    }
    return NSNotFound;
}



- (void)printInfo:(chromeTab *)tab {
    if (!tab) {
        return;
    }

    chromeWindow *window = [self findWindowWithTab:tab];
    NSInteger winIdx = [self findWindowIndex:window];
    NSInteger tabIdx = [self findTabIndex:tab inWindow:window];

    if (self->outputFormat == kOutputFormatJSON) {
        NSDictionary *output = @{
            @"id" : @(tabIdx),
            @"windowId" : @(winIdx),
            @"title" : tab.title,
            @"url" : tab.URL,
            @"loading" : @(tab.loading),
        };
        [self printJSON:output];
    } else {
        printf("Id: %ld\n", (long)tabIdx);
        printf("Window id: %ld\n", (long)winIdx);
        printf("Title: %s\n", tab.title.UTF8String);
        printf("Url: %s\n", tab.URL.UTF8String);
        printf("Loading: %s\n", tab.loading ? "Yes" : "No");
    }
}

- (void)printJSON:(NSDictionary *)output {
    NSJSONWritingOptions options = [self jsonWritingOptions];
    NSData *data = [NSJSONSerialization dataWithJSONObject:output options:options error: nil];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    printf("%s\n", [string UTF8String]);
}

- (NSJSONWritingOptions)jsonWritingOptions {
    if (@available(macOS 10.15, *)) {
        return NSJSONWritingPrettyPrinted | NSJSONWritingWithoutEscapingSlashes | NSJSONWritingSortedKeys;
    } else if (@available(macOS 10.13, *)) {
        return NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys;
    }
    return NSJSONWritingPrettyPrinted;
}

@end
