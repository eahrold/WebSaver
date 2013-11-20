//
//  WebSaverView.m
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

// Cheesy Debugging toggle
//#define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
# define DLog(...) /* */

# define ALog(...)
//#define ALog(...) NSLog(@"%@",[NSString stringWithFormat:__VA_ARGS__])

#import "WebSaverView.h"
#import "NSDictionary+NSData.h"

static NSString * const WebSaverScreenSaver = @"org.brock-family.WebSaver";
static NSString * upArrow, *downArrow, *leftArrow, *rightArrow;


@implementation WebSaverView

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame
{
}

- (void)webView:(WebView *)sender serverRedirectedForDataSource:(WebFrame *)frame
{
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
}



- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    ALog(@"init");
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
	    lastLoad = [[NSDate alloc] init];
		sms_type = detect_sms();
		if (sms_type) {
			unichar ua = NSUpArrowFunctionKey;
			unichar da = NSDownArrowFunctionKey;
			unichar la = NSLeftArrowFunctionKey;
			unichar ra = NSRightArrowFunctionKey;
			upArrow    = [[NSString alloc] initWithCharacters:&ua length:1];
			downArrow  = [[NSString alloc] initWithCharacters:&da length:1];
			leftArrow  = [[NSString alloc] initWithCharacters:&la length:1];
			rightArrow = [[NSString alloc] initWithCharacters:&ra length:1];	
		}

		ScreenSaverDefaults *defaults;
		defaults = [ScreenSaverDefaults defaultsForModuleWithName:WebSaverScreenSaver];
        [defaults registerDefaults:@{@"keyURL":@"http://google.com",
                                     @"EnableReload":@"NO",
                                     @"ReloadTime":@"60",
                                     @"EnableSMS":@"NO",
                                     @"EnableMultiMonitor":@"NO",
                                     @"wscrollURL":@"",
                                     @"wscrollEnabled":@"NO"}];
        
         
        
        
		[self setAnimationTimeInterval:0.5];
		
		saverURLString = [defaults stringForKey:@"keyURL"];
		DLog(@"URL: %@", saverURLString);
		
        wscrollEnabledBool = [defaults boolForKey:@"wscrollEnabled"];
        DLog(@"wscrollEnabled: %d", wscrollEnabledBool);

        wscrollURLString = [defaults stringForKey:@"wscrollURL"];
        DLog(@"wscrollURLString: %@", saverURLString);
        
		enableReloadBool = [defaults boolForKey:@"EnableReload"];
		DLog(@"Will Reload: %d", enableReloadBool);
		
		reloadTimeFloat = [defaults floatForKey:@"ReloadTime"];
		DLog(@"Reload Time: %d", reloadTimeFloat);

		enableSMSBool = [defaults boolForKey:@"EnableSMS"];
		DLog(@"Will use SMS: %d", enableSMSBool);
        
		enableMultiMonitorBool = [defaults boolForKey:@"EnableMultiMonitor"];
		DLog(@"Will use MultiMonitor: %d", enableMultiMonitorBool);
        
		webView = [[WebView alloc] initWithFrame:frame];
		[webView setDrawsBackground:NO];
        [webView setCustomUserAgent:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8) AppleWebKit/536.25 (KHTML, like Gecko) Version/6.0 Safari/536.25"];

		if (isPreview) {
			[self scaleUnitSquareToSize:NSMakeSize( 0.25, 0.25 )];
		}

		[webView setFrameLoadDelegate:self];
		
		[self addSubview:webView];
	}

    return self;
}

- (void)setFrame:(NSRect)frameRect
{
	DLog(@"NSView:setFrame");
	[super setFrame:frameRect];
	[webView setFrame:frameRect];	
	[webView setFrameSize:[webView convertSize:frameRect.size fromView:nil]];
}


- (void)startAnimation
{
    if(wscrollURLString){
        webPageList = [self getListFromServer:wscrollURLString];
    }
    
    currentURLString = [[ScreenSaverDefaults defaultsForModuleWithName:WebSaverScreenSaver] stringForKey:@"keyURL"];

    if([currentURLString isEqualToString:@""]){
        currentURLString = @"http://google.com/";
    }
    
    ALog(@"start Animation with %@ %@",wscrollURLString,webPageList);
    
    NSScreen *screen;
    int srand_time = 15;

	DLog(@"webView:startAnimation");
    [super startAnimation];

    
	// Calibrate 'natural' positon with 20 readings
	if (enableSMSBool && sms_type) {
		int loop;	
		for(loop = 0; loop < 20; loop++) {
			int x, y, z;
			if (read_sms_scaled(sms_type, &x, &y, &z)) {
				avgx = avgx + x;
				avgy = avgy + y;
				avgz = avgz + z;
			}
		}
		avgx = avgx / 20;
		avgy = avgy / 20;
		avgz = avgz / 20; 
		DLog(@"SMS Average - x = %d, y = %d, z = %d", avgx, avgy, avgz);
	}

    if (enableMultiMonitorBool) {
        screen = [ [webView window] screen ];
        DLog(@"Screen %@", [screen description]);
        currentURLString = [NSString stringWithFormat: @"%@?x=%.0f&y=%.0f&w=%.0f&h=%.0f&screen=%i&srand=%i", currentURLString,
               [screen frame].origin.x,   [screen frame].origin.y,
               [screen frame].size.width, [screen frame].size.height,
               (int)[[NSScreen screens] indexOfObject: screen],
               ((int)time(0)+(srand_time/2)/srand_time) ];
    }
    
	// Reload the page and reset load time
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString:currentURLString]]];
	lastLoad = [[NSDate alloc] init];
	ALog(@"reloaded %@",[lastLoad description]);

}

- (void)stopAnimation
{
	DLog(@"webView:stopAnimation");
	
	// Reload the page and reset load time 
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:"]]];
	lastLoad = [[NSDate alloc] init];
	DLog(@"reloaded %@",[lastLoad description]);

    [super stopAnimation];
}


- (void)doKeyUp:(NSTimer*)theTimer {
	//DebugLog(@"doKeyUp");
	[[NSApplication sharedApplication] sendEvent:[NSEvent keyEventWithType:NSKeyUp 
		location:      NSMakePoint(1,1)
		modifierFlags: 0
		timestamp:     [[NSDate date] timeIntervalSinceReferenceDate]
		windowNumber:  [[self window] windowNumber] 
		context:       [NSGraphicsContext currentContext] 
		characters:    [theTimer userInfo]
		charactersIgnoringModifiers:[theTimer userInfo]
		isARepeat:     NO 
		keyCode:       0]];
}


- (void)doKeyDown:(NSTimer*)theTimer {
	//DebugLog(@"doKeyDown");
	[[NSApplication sharedApplication] sendEvent:[NSEvent keyEventWithType:NSKeyDown 
		location:      NSMakePoint(1,1)
		modifierFlags: 0
		timestamp:     [[NSDate date] timeIntervalSinceReferenceDate]
		windowNumber:  [[self window] windowNumber] 
		context:       [NSGraphicsContext currentContext] 
		characters:    [theTimer userInfo]
		charactersIgnoringModifiers:[theTimer userInfo]
		isARepeat:     NO 
		keyCode:      0]];
}

#pragma mark - Scroll / Reload
- (void)animateOneFrame
{
    
    if(!webPageList.count){
        webPageList = [[ScreenSaverDefaults defaultsForModuleWithName:WebSaverScreenSaver] objectForKey:@"webPageList"];
    }

	if (enableReloadBool || wscrollEnabled) {
		if (reloadTimeFloat + [lastLoad timeIntervalSinceNow] < 0) {
            
            if(count == webPageList.count || !count)count = 0;
            currentURLString = webPageList[count];
            count++;
            
			[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString:currentURLString]]];
			lastLoad = [[NSDate alloc] init];
		}
	}
		
	if (enableSMSBool && sms_type) {
		int x,y,z;
		if (read_sms_scaled(sms_type, &x, &y, &z)) {
			//DebugLog(@"average - x = %d, y = %d, z = %d     Current Reading:  x = %d, y = %d, z = %d", avgx, avgy, avgz, x, y, z);
	
			int cx = avgx - x;
			int cy = avgy - y;
		
			if (abs(cx) > abs(cy)) {
				if(cx > 30) {
					DLog(@"SMS Send Right Cursor");
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0 target:self selector:@selector(doKeyDown:) userInfo:rightArrow repeats:NO];
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).05 target:self selector:@selector(doKeyUp:) userInfo:rightArrow repeats:NO];
				} else if(cx < -30) {
					DLog(@"SMS Send Left Cursor");
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0 target:self selector:@selector(doKeyDown:) userInfo:leftArrow repeats:NO];
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).05 target:self selector:@selector(doKeyUp:) userInfo:leftArrow repeats:NO];
				}
			} else {
				if(cy > 30) {
					DLog(@"SMS Send Up Cursor");
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0 target:self selector:@selector(doKeyDown:) userInfo:upArrow repeats:NO];
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).05 target:self selector:@selector(doKeyUp:) userInfo:upArrow repeats:NO];
				} else if(cy < -30) {
					DLog(@"SMS Send Down Cursor");
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0 target:self selector:@selector(doKeyDown:) userInfo:downArrow repeats:NO];
					[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).5 target:self selector:@selector(doKeyUp:) userInfo:downArrow repeats:NO];
				}	
			}
		}
	}
}

#pragma mark - Config Sheet
- (NSWindow*)configureSheet
{
	DLog(@"webView:configureSheet");

	
	if (!configSheet) {
		if (![NSBundle loadNibNamed:@"ConfigureSheet" owner:self]) {
			ALog( @"Failed to load configure sheet." );
			NSBeep(); 
		}
	}

	NSDictionary *infoDictionary;
	infoDictionary = [[NSBundle bundleForClass:[self class]] infoDictionary];
	NSString *versionString;
	versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    NSString* defURL = [[ScreenSaverDefaults defaultsForModuleWithName:WebSaverScreenSaver] objectForKey:@"keyURL"];
    
    if([defURL isEqualToString:@""] || !defURL){
        defURL = @"http://google.com";
    }
    
    [wscrollURL setStringValue:wscrollURLString];
    [wscrollEnabled setState:wscrollEnabledBool];
    [saverURL setStringValue:defURL];
	[versionLabel setStringValue:versionString];
	[enableReload setState:enableReloadBool];
	[reloadTime selectItemWithTag:reloadTimeFloat];
	[enableSMS setState:enableSMSBool];
	[enableMultiMonitor setState:enableMultiMonitorBool];
	[reloadTime setEnabled:[enableReload state]];
	[enableSMS setEnabled:sms_type ? true : false];

	return configSheet;
}


- (IBAction)okClick:(id)sender{
	DLog(@"IBAction:okClick");

	// Check what the user set
	saverURLString          = saverURL.stringValue;
	wscrollURLString        = wscrollURL.stringValue;
    enableReloadBool        = enableReload.state;
	enableSMSBool           = enableSMS.state;
	enableMultiMonitorBool  = enableMultiMonitor.state;
    wscrollEnabledBool      = wscrollEnabled.state;
    reloadTimeFloat         = reloadTime.selectedItem.tag;

    if(wscrollEnabledBool){
        webPageList = [self getListFromServer:wscrollURL.stringValue];
	}
    
    // Save the Settings
	ScreenSaverDefaults *defaults;
	defaults = [ScreenSaverDefaults defaultsForModuleWithName:WebSaverScreenSaver];
	[defaults setObject:saverURLString       forKey:@"keyURL"];
    [defaults setObject:wscrollURLString     forKey:@"wscrollURL"];
    [defaults setBool:wscrollEnabledBool     forKey:@"wscrollEnabled"];
	[defaults setBool:enableReloadBool       forKey:@"EnableReload"];
	[defaults setFloat:reloadTimeFloat       forKey:@"ReloadTime"];
	[defaults setBool:enableSMSBool          forKey:@"EnableSMS"];
	[defaults setBool:enableMultiMonitorBool forKey:@"EnableMultiMonitor"];
    [defaults setObject:webPageList          forKey:@"webPageList"];
    [defaults synchronize];
	
	// Reload the page and reset load time 
	
    if(wscrollEnabled.state && webPageList.count){
        currentURLString = webPageList[0];
    }else{
        currentURLString = saverURL.stringValue;
    }
    
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:currentURLString]]];
	
    lastLoad = [[NSDate alloc] init];
	
    DLog(@"reloaded %@",[lastLoad description]);
    
	// Close the window
	[[NSApplication sharedApplication] endSheet:configSheet];
}

- (IBAction)cancelClick:(id)sender
{
	DLog(@"IBAction:cancelClick");
	[[NSApplication sharedApplication] endSheet:configSheet];
}

- (IBAction)enableClick:(id)sender
{
	DLog(@"IBAction:enableClick");
	[reloadTime setEnabled:[enableReload state]];
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

#pragma mark - Get Wscroll List
-(NSArray*)getListFromServer:(NSString*)urlString{
    
    NSData* data;
    NSError* error;
    NSURL* url = [NSURL URLWithString:urlString];
    
    NSHTTPURLResponse* response = nil;
    
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // set as GET request
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 3.0;
    
    // set header fields
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // Create url connection and fire request
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    return [NSDictionary dictionaryFromData:data][@"webpages"];
}


@end
