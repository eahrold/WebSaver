//
//  WebSaverView.h
//
//    WebSaver - A web screen-saver for MacOS-X
//    Copyright (C) 2008 Gavin Brock http://brock-family.org/gavin
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <ScreenSaver/ScreenSaver.h>
#import <WebKit/WebKit.h>
#include "unimotion.h"



@interface WebSaverView : ScreenSaverView 
{
    WebView *webView;
	NSDate *lastLoad;
    NSArray *webPageList;
    NSInteger count;
	
	// Motion Sensor Related
	int sms_type, avgx, avgy, avgz;

	IBOutlet NSPanel* configSheet;
	IBOutlet NSTextField* versionLabel;

    NSString* currentURLString;
    
	IBOutlet NSTextField *saverURL;
	NSString *saverURLString;

    IBOutlet NSTextField *wscrollURL;
	NSString *wscrollURLString;
    
    IBOutlet NSButton* wscrollEnabled;
    BOOL wscrollEnabledBool;
    
	IBOutlet NSButton* enableReload;
	BOOL enableReloadBool;

	IBOutlet NSPopUpButton *reloadTime;
	int reloadTimeFloat;
	
	IBOutlet NSButton* enableSMS;
	BOOL enableSMSBool;

    IBOutlet NSButton* enableMultiMonitor;
	BOOL enableMultiMonitorBool;

}
@end

        
@interface WebView (WebKitStuffThatShouldBeAPI)
    - (void)setDrawsBackground:(BOOL)drawsBackground;
@end