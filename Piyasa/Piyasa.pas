program Piyasa;

{
  Piyasa 5.0
  Create Date: 23/03/2012
  Update Date: 12/10/2013
  Update Date: 21/04/2014
  Update Date: 02/03/2015
  Update Date: 26/03/2015
  Author: Nasir Senturk
  Web: http://www.shenturk.com
  E-mail: shenturk@gmail.com
}

{
  http://www.doviz.com/doviz_calc_widget/
  http://www.piyasa.com/android/android.php?doviz=USD%2CEUR&altin=GRM
  http://ws.piyasa.com/json/android/doviz_serb.json
  http://www.bigpara.com/Content/js/AltinData.asp
}

// -CirotR -gltw -Sa ile derledigimde thread icinde kirilma oluyor. Run-Time error 202

{$MODESWITCH ObjectiveC1}

uses
  CTypes, CocoaAll, MacOSAll, SysUtils, SuperObject;
  
type
  
  { NSTransparentView }
  NSTransparentView = objcclass(NSView)
  public
    procedure drawRect(rect: NSRect); override;
    function initWithFrame(frame: NSRect): id; override;
    procedure dealloc; override;
    class function defaultMenu: NSMenu; override;
  end;
  
  { NSHoverButton }
  NSHoverButton = objcclass(NSButton)
  private
    _normalImage,
    _hoverImage: NSImage;
  public
    trackingArea: NSTrackingArea;
  public
    procedure updateTrackingAreas; override;
    procedure mouseEntered(event: NSEvent); override;
    procedure mouseExited(event: NSEvent); override;
    procedure cursorUpdate(event: NSEvent); override;
    procedure setNormalImage(image: NSImage); message 'setNormalImage:';
    procedure setHoverImage(image: NSImage); message 'setHoverImage:';
  end;
  
  { NSMainWindow }
  NSMainWindow = objcclass(NSWindow)
  public
    position: NSPoint;
    threadState: BOOL;
    dragLocation: NSPoint;
    backgroundImageView: NSImageView;
    transparentView: NSTransparentView;
    captionTextField: NSTextField;
    miniaturizeButton,
    closeButton: NSHoverButton;
    eurImageView,
    usdImageView,
    goldImageView: NSImageView;
    eurBuyTextField,
    eurSellTextField: NSTextField;
    usdBuyTextField,
    usdSellTextField: NSTextField;
    goldBuyTextField,
    goldSellTextField: NSTextField;
    eurstatusTextField,
    usdstatusTextField,
    goldstatusTextField: NSTextField;
    statusTextField: NSTextField;
    contextMenu: NSMenu;
    appLogoImageView: NSImageView;
    refreshInterval: NSTimeInterval;
  public
    procedure dealloc; override;
    function canBecomeKeyWindow: BOOL; override;
    function initWindow: id; message 'initWindow';
    procedure initControls; message 'initControls';
    procedure initLoaderTimer; message 'initLoaderTimer';
    procedure initThread; message 'initThread';
    procedure initDefaults; message 'initDefaults';
    procedure doneDefaults; message 'doneDefaults';
    { Events }
    procedure mouseDown(event: NSEvent); override;
    procedure mouseDragged(event: NSEvent); override;
    procedure loaderTimer(timer: NSTimer); message 'loaderTimer:';
    procedure beginConnection(sender: id); message 'beginConnection:';
    procedure refreshTimer(timer: NSTimer); message 'refreshTimer:';
    { IBActions }
    procedure closeButtonClick(sender: id); message 'closeButtonClick:';
    procedure miniaturizeButtonClick(sender: id); message 'miniaturizeButtonClick:';
    procedure refreshMenuClick(sender: id); message 'refreshMenuClick:';
  end;
  
  { NSApplicationDelegate }
  NSApplicationDelegate = objcclass(NSObject, NSApplicationDelegateProtocol)
  private
    procedure initApplicationMenu; message 'initApplicationMenu';
    procedure initDefaults; message 'initDefaults';
    procedure doneDefaults; message 'doneDefaults';
    procedure refreshMenuClick(sender: id); message 'refreshMenuClick:';
  public
    procedure applicationWillFinishLaunching(notification: NSNotification); message 'applicationWillFinishLaunching:';
    procedure applicationWillTerminate(notification: NSNotification); message 'applicationWillTerminate:';
    function applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication): BOOL; message 'applicationShouldTerminateAfterLastWindowClosed:'; 
  end;
  
var
  pool: NSAutoreleasePool;
  application: NSApplication;
  bundle: NSBundle;
  delegate: NSApplicationDelegate;
  mainWindow: NSMainWindow;
  defaults: NSUserDefaults;
  TurkishFS,
  EnglishFS: TFormatSettings;

const
  ProjectName        = 'Piyasa';
  ProjectEnglishName = 'Piyasa';
  ProjectVersion     = '5.0';
  ProjectMutexName   = ProjectName + 'mutex';
  ProjectClassName   = ProjectName + 'class';
  ProjectWindowName  = ProjectName;
  ProjectHost        = 'www.shenturk.com';
  ProjectVersionUrl  = '/' + ProjectName + '.xml';
  ProjectConfigFile  = '/' + ProjectName + '.ini';
  ProjectTrackerID   = 'piyasatakip';
  ProjectTrackerHost = 'whos.amung.us';
  ProjectTrackerUrl  = '/swidget/' + ProjectTrackerID + '.gif';
  ProjectLinkID      = '9940';
  ProjectVersionID   = '9941';
  {$IF DEFINED(LINUX)}
  ProjectPlatform    = 'linux';
  {$ELSEIF DEFINED(DARWIN)}
  ProjectPlatform    = 'macosx';
  {$ELSE}
  ProjectPlatform    = 'windows';
  {$ENDIF}
  {$IFDEF CPU64}
  ProjectCpu         = '64';
  {$ELSE}
  ProjectCpu         = '32';
  {$ENDIF}

  
{ GetWindowTopLeftPoint }
function GetWindowTopLeftPoint(Top, Left: Integer): NSPoint;
var
  BarHeight,
  DockWidth: Integer;
begin
  BarHeight := Round(NSScreen.mainScreen.frame.size.height - NSScreen.mainScreen.visibleFrame.size.height - NSScreen.mainScreen.visibleFrame.origin.y);
  if Top < BarHeight then Top := BarHeight;
  DockWidth := Round(NSScreen.mainScreen.frame.size.width - NSScreen.mainScreen.visibleFrame.size.width);
  if Left < DockWidth then Left := DockWidth;
  Result.y := Round(NSScreen.mainScreen.frame.size.height) - Top;
  Result.x := Left;
end;

{ GetCenterScreenPoint }
function GetCenterScreenPoint(Width, Height: Integer): NSPoint;
begin
  Result.x := Round((NSScreen.mainScreen.frame.size.width - Width) / 2);
  Result.y := Round((NSScreen.mainScreen.frame.size.height - Height) / 2) + Height;
end;
  
{ NSTransparentView }
procedure NSTransparentView.drawRect(rect: NSRect);
begin
  NSColor.clearColor.set_;
  NSRectFill(self.frame);
end;

function NSTransparentView.initWithFrame(frame: NSRect): id;
begin
  Result := inherited initWithFrame(frame);
end;

procedure NSTransparentView.dealloc;
begin
  inherited dealloc;
end;

class function NSTransparentView.defaultMenu: NSMenu;
begin
  {
  contextMenu := NSMenu.alloc.initWithTitle(NSSTR('Context Menu'));
  contextMenu.insertItemWithTitle_action_keyEquivalent_atIndex(NSSTR('Beep'), objcselector('beep:'), NSSTR(''), 0);
  contextMenu.insertItemWithTitle_action_keyEquivalent_atIndex(NSSTR('Honk'), objcselector('honk:'), NSSTR(''), 1);
  }
  //NSLOG(NSSTR('NSTransparentView.defaultMenu'));
  Result := nil;
end;

{ NSHoverButton }
procedure NSHoverButton.mouseEntered(event: NSEvent);
begin
  //NSLOG(NSSTR('mouseEntered'));
  if Assigned(_hoverImage) then setImage(_hoverImage);
  {
  setImage(NSImage.alloc.initWithContentsOfFile(bundle.pathForImageResource(NSStr('close-rollover.tiff'))));
  }
end;

procedure NSHoverButton.mouseExited(event: NSEvent);
begin
  //NSLOG(NSSTR('mouseExited'));
  if Assigned(_normalImage) then setImage(_normalImage);
  {
  setImage(NSImage.alloc.initWithContentsOfFile(bundle.pathForImageResource(NSStr('close-active.tiff'))));
  }
end;

procedure NSHoverButton.updateTrackingAreas;
var
  options: NSTrackingAreaOptions;
begin
  //NSLOG(NSSTR('updateTrackingAreas'));
  inherited updateTrackingAreas;
  if Assigned(trackingArea) then
  begin
    self.removeTrackingArea(trackingArea);
    trackingArea.release;
  end;
  options := NSTrackingInVisibleRect or NSTrackingMouseEnteredAndExited or NSTrackingActiveInKeyWindow or NSTrackingCursorUpdate;
  trackingArea := NSTrackingArea.alloc.initWithRect_options_owner_userInfo(NSZeroRect, options, self, nil);
  self.addTrackingArea(trackingArea);
end;

procedure NSHoverButton.cursorUpdate(event: NSEvent);
begin
  //NSLOG(NSSTR('cursorUpdate'));
  NSCursor.pointingHandCursor.set_;
end;

procedure NSHoverButton.setNormalImage(image: NSImage);
begin
  _normalImage := image;
  setImage(image);
end;

procedure NSHoverButton.setHoverImage(image: NSImage);
begin
  _hoverImage := image;
end;
  
{ NSMainWindow }
function NSMainWindow.canBecomeKeyWindow: BOOL;
begin
  Result := True;
end;

procedure NSMainWindow.initDefaults;
begin
  TurkishFS := SysUtils.FormatSettings;
  TurkishFS.ThousandSeparator := '.';
  TurkishFS.DecimalSeparator := ',';
  EnglishFS := SysUtils.FormatSettings;
  EnglishFS.ThousandSeparator := ',';
  EnglishFS.DecimalSeparator := '.';
  position.x := defaults.floatForKey(NSSTR('left'));
  position.y := defaults.floatForKey(NSSTR('top'));
  refreshInterval := defaults.floatForKey(NSSTR('refresh'));
  if refreshInterval <= 0.0 then refreshInterval := 1.0 * 60.0 * 1.0; // 1 dakika
end;

procedure NSMainWindow.doneDefaults;
begin
  //NSLOG(NSSTR('NSMainWindow.doneDefaults'));
  defaults.setFloat_forKey(refreshInterval, NSSTR('referesh'));
  defaults.setFloat_forKey(frame.origin.y + frame.size.height, NSSTR('top'));
  defaults.setFloat_forKey(frame.origin.x, NSSTR('left'));
end;

procedure NSMainWindow.dealloc;
begin
  inherited dealloc;
end;

procedure NSMainWindow.initLoaderTimer;
begin
  Randomize();
  NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
    0.20, self, objcselector('loaderTimer:'), nil, false);
  NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
    refreshInterval, self, objcselector('refreshTimer:'), nil, true);
end;

procedure NSMainWindow.loaderTimer(timer: NSTimer);
begin
  initThread;
end;

procedure NSMainWindow.refreshTimer(timer: NSTimer);
begin
  if threadState = false then initThread;
end;

procedure NSMainWindow.initThread;
begin
  threadState := true;
  NSThread.detachNewThreadSelector_toTarget_withObject(objcselector('beginConnection:'), self, nil);
end;

procedure NSMainWindow.beginConnection(sender: id);
const
  sFindText = 'var $altinData = ';
  sEndText  = '];';
var
  url: NSURL;
  urlString, statusString: AnsiString;
  rand: Extended;
  Super: ISuperObject;
  Request: NSMutableURLRequest;
  Response: NSData;
  Content: NSString;
  Text, Key, Sell, Buy, Change, Hint: AnsiString;
  Results: TSuperArray;
  Index: Integer;
  Value: Double;
begin
  
  pool := NSAutoreleasePool.alloc.init;
  
  statusTextField.setStringValue(NSString.stringWithUTF8String('Döviz verileri alınıyor...'));

  urlString := 'http://www.bigpara.com/altin/?' + IntToStr(System.Random(MaxInt));
  //NSLOG(NSSTR(PChar(urlString)));
  url := NSURL.URLWithString(NSSTR(PChar(urlString)));
  Request := NSMutableURLRequest.requestWithURL(url);
  Response := NSURLConnection.sendSynchronousRequest_returningResponse_error(Request, nil, nil);
  Content := NSString.alloc.initWithData_encoding(Response, NSUTF8StringEncoding);
  //NSLOG(Content);

  Text := Content.UTF8String;
  Text := Trim(System.Copy(Text, Pos(sFindText, Text) + Length(sFindText), MaxInt));
  if Length(Text) > 0 then
  begin
    Text := Trim(System.Copy(Text, 1, Pos(sEndText, Text) + Length(sEndText)));
    //NSLOG(NSStr(PChar(Text)));
    if Length(Text) > 0 then
    begin
      Super := SuperObject.SO(Text);
      try
        Results := Super.AsArray;
        if Assigned(Results) then
        begin
          for Index := 0 to Results.length - 1 do
          begin
            Text := Results.O[Index].S['sembolkisa'];
            if Text = 'GLDGR' then
            begin
              Buy := Results.O[Index].S['alis'];
              Value := StrToFloatDef(Buy, 0.0, EnglishFS);
              Buy := FormatFloat('#,###0.000', Value, TurkishFS);
              goldBuyTextField.setStringValue(NSStr(PChar(Buy)));
              Sell := Results.O[Index].S['satis'];
              Value := StrToFloatDef(Sell, 0.0, EnglishFS);
              Sell := FormatFloat('#,###0.000', Value, TurkishFS);
              goldSellTextField.setStringValue(NSStr(PChar(Sell)));
              Change := Results.O[Index].S['yuzdedegisim'];
              Value := StrToFloatDef(Change, 0.0);
              if Value > 0.0 then
              begin
                with goldStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('▲'));
                  setTextColor(NSColor.greenColor);
                  Hint := 'Yükseliyor (+' + Change + ')';
                  setToolTip(NSString.stringWithUTF8String(PAnsiChar(Hint)));
                end;
              end
              else if Value < 0.0 then
              begin
                with goldStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('▼'));
                  setTextColor(NSColor.redColor);
                  Hint := 'Düşüyor (' + Change + ')';
                  setToolTip(NSString.stringWithUTF8String(PAnsiChar(Hint)));
                end;
              end
              else begin
                with goldStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('='));
                  setTextColor(NSColor.yellowColor);
                  setToolTip(NSString.stringWithUTF8String('Değişiklik Yok'));
                end;
              end;
            end
            else if Text = 'USDTRY' then
            begin
              Buy := Results.O[Index].S['alis'];
              Value := StrToFloatDef(Buy, 0.0, EnglishFS);
              Buy := FormatFloat('#,####0.0000', Value, TurkishFS);
              usdBuyTextField.setStringValue(NSStr(PChar(Buy)));
              Sell := Results.O[Index].S['satis'];
              Value := StrToFloatDef(Sell, 0.0, EnglishFS);
              Sell := FormatFloat('#,####0.0000', Value, TurkishFS);
              usdSellTextField.setStringValue(NSStr(PChar(Sell)));
              Change := Results.O[Index].S['yuzdedegisim'];
              Value := StrToFloatDef(Change, 0.0);
              if Value > 0.0 then
              begin
                with usdStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('▲'));
                  setTextColor(NSColor.greenColor);
                  Hint := 'Yükseliyor (+' + Change + ')';
                  setToolTip(NSString.stringWithUTF8String(PAnsiChar(Hint)));
                end;
              end
              else if Value < 0.0 then
              begin
                with usdStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('▼'));
                  setTextColor(NSColor.redColor);
                  Hint := 'Düşüyor (' + Change + ')';
                  setToolTip(NSString.stringWithUTF8String(PAnsiChar(Hint)));
                end;
              end
              else begin
                with usdStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('='));
                  setTextColor(NSColor.yellowColor);
                  setToolTip(NSString.stringWithUTF8String('Değişiklik Yok'));
                end;
              end;
            end
            else if Text = 'EURTRY' then
            begin
              Buy := Results.O[Index].S['alis'];
              Value := StrToFloatDef(Buy, 0.0, EnglishFS);
              Buy := FormatFloat('#,####0.0000', Value, TurkishFS);
              eurBuyTextField.setStringValue(NSStr(PChar(Buy)));
              Sell := Results.O[Index].S['satis'];
              Value := StrToFloatDef(Sell, 0.0, EnglishFS);
              Sell := FormatFloat('#,####0.0000', Value, TurkishFS);
              eurSellTextField.setStringValue(NSStr(PChar(Sell)));
              Change := Results.O[Index].S['yuzdedegisim'];
              Value := StrToFloatDef(Change, 0.0);
              if Value > 0.0 then
              begin
                with eurStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('▲'));
                  setTextColor(NSColor.greenColor);
                  Hint := 'Yükseliyor (+' + Change + ')';
                  setToolTip(NSString.stringWithUTF8String(PAnsiChar(Hint)));
                end;
              end
              else if Value < 0.0 then
              begin
                with eurStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('▼'));
                  setTextColor(NSColor.redColor);
                  Hint := 'Düşüyor (' + Change + ')';
                  setToolTip(NSString.stringWithUTF8String(PAnsiChar(Hint)));
                end;
              end
              else begin
                with eurStatusTextField do
                begin
                  setStringValue(NSString.stringWithUTF8String('='));
                  setTextColor(NSColor.yellowColor);
                  setToolTip(NSString.stringWithUTF8String('Değişiklik Yok'));
                end;
              end;
            end;
          end;
        end;
      finally
        Super := nil;
      end;
    end;
  end;

  urlString := 'http://' + ProjectTrackerHost + ProjectTrackerUrl;
  url := NSURL.URLWithString(NSSTR(PChar(urlString)));
  Request := NSMutableURLRequest.requestWithURL(url);
  Request.setValue_forHTTPHeaderField(NSStr('http://www.shenturk.com/?ref=' + ProjectPlatform + ProjectCpu),
    NSStr('Referer'));
  Response := NSURLConnection.sendSynchronousRequest_returningResponse_error(Request, nil, nil);

  statusString := 'Son Güncelleme ';
  statusString := statusString + FormatDateTime('hh:nn', SysUtils.Now); 
  statusTextField.setStringValue(NSString.stringWithUTF8String(PChar(statusString)));
  
  threadState := false;
  
  pool.release;
  
end;

procedure NSMainWindow.refreshMenuClick(sender: id);
begin
  if threadState = false then initThread;
end;

function NSMainWindow.initWindow: id;
var
  rect: NSRect;
  width, height: Integer;
  location: NSPoint;
begin
  
  initDefaults;
  
  // Menu
  contextMenu := NSMenu.alloc.initWithTitle(NSSTR('Context Menu')).autorelease;
  contextMenu.insertItemWithTitle_action_keyEquivalent_atIndex(NSString.stringWithUTF8String('Hakkında'), objcselector('orderFrontStandardAboutPanel:'), NSSTR(''), 0);
  contextMenu.addItem(NSMenuItem.separatorItem);
  contextMenu.insertItemWithTitle_action_keyEquivalent_atIndex(NSString.stringWithUTF8String('Güncelle'), objcselector('refreshMenuClick:'), NSSTR('g'), 2);
  contextMenu.addItem(NSMenuItem.separatorItem);
  contextMenu.insertItemWithTitle_action_keyEquivalent_atIndex(NSString.stringWithUTF8String('Gizle'), objcselector('hide:'), NSSTR('h'), 4);
  contextMenu.addItem(NSMenuItem.separatorItem);
  contextMenu.insertItemWithTitle_action_keyEquivalent_atIndex(NSString.stringWithUTF8String('Çıkış'), objcselector('terminate:'), NSSTR('q'), 6);
   
  width := 256; height := 180;
  location := GetCenterScreenPoint(width, height);
  if defaults.boolForKey(NSSTR('position')) then location := position;

  // Main Window
  rect := NSMakeRect(0, 0, width, height);
  Result := initWithContentRect_styleMask_backing_defer(rect, NSBorderlessWindowMask, NSBackingStoreBuffered, false);
  setFrameTopLeftPoint(location);
  setTitle(NSString.stringWithUTF8String('Piyasa'));
  setAlphaValue(1.0);
  setOpaque(false);
  {
  setLevel(kCGFloatingWindowLevelKey);
  self.center;
  }
  
  // Transparent View
  transparentView := NSTransparentView.alloc.initWithFrame(rect);
  NSView(contentView).addSubview(transparentView);
  transparentView.release;
  
  // Background Image View
  backgroundImageView := NSImageView.alloc.initWithFrame(rect);
  with backgroundImageView do
  begin
    setImageScaling(NSImageScaleProportionallyUpOrDown);
    setImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSSTR('background.png'))));
    setAlphaValue(0.85);
    setMenu(contextMenu);
    NSView(contentView).addSubview(backgroundImageView);
    release;
  end;
  
  // Applogo Image View
  rect := NSMakeRect(15, 151, 20, 20);
  appLogoImageView := NSImageView.alloc.initWithFrame(rect);
  with appLogoImageView do
  begin
    setToolTip(NSString.stringWithUTF8String('Piyasa'));
    setImageScaling(NSImageScaleProportionallyUpOrDown);
    setImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSSTR('applogo.png'))));
    setAlphaValue(1.0);
    setMenu(contextMenu);
    NSView(contentView).addSubview(appLogoImageView);
    release;
  end;
  
  // Caption Text Field
  rect := NSMakeRect(15+20, 146, 100, 30);
  captionTextField := NSTextField.alloc.initWithFrame(rect);
  with captionTextField do
  begin
    setTextColor(NSColor.whiteColor);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 18.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSString.stringWithUTF8String('Piyasa'));
    NSView(contentView).addSubview(captionTextField);
    release;
  end;
  
  // Close Button
  rect := NSMakeRect(230, 155, 14, 16);
  closeButton := NSHoverButton.alloc.initWithFrame(rect);
  with closeButton do
  begin
    setToolTip(NSString.stringWithUTF8String('Çıkış'));
    setTarget(self);
    setNormalImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSStr('close-active.tiff'))));
    setHoverImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSStr('close-rollover.tiff'))));
    {
    setAlternateImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSStr('close-rollover.tiff'))));
    }
    setBordered(False);
    setButtonType(NSMomentaryChangeButton);
    closeButton.setBezelStyle(NSRegularSquareBezelStyle);
    cell.setImageScaling(NSImageScaleProportionallyUpOrDown);
    setImagePosition(NSImageOnly);
    NSView(contentView).addSubview(closeButton);
    setAction(objcselector('closeButtonClick:'));
    release;
  end;
  
  // Miniaturize Button
  rect := NSMakeRect(210, 155, 14, 16);
  miniaturizeButton := NSHoverButton.alloc.initWithFrame(rect);
  with miniaturizeButton do
  begin
    setToolTip(NSString.stringWithUTF8String('Simge Durumuna Küçült'));
    setTarget(self);
    setNormalImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSStr('miniaturize-active.tiff'))));
    setHoverImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSStr('miniaturize-rollover.tiff'))));
    {
    setImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSStr('miniaturize-active.tiff'))));
    setAlternateImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSStr('miniaturize-rollover.tiff'))));
    }
    setBordered(False);
    setButtonType(NSMomentaryChangeButton);
    closeButton.setBezelStyle(NSRegularSquareBezelStyle);
    cell.setImageScaling(NSImageScaleProportionallyUpOrDown);
    setImagePosition(NSImageOnly);
    NSView(contentView).addSubview(miniaturizeButton);
    setAction(objcselector('miniaturizeButtonClick:'));
    release;
  end;
  
  // EUR Image View
  rect := NSMakeRect(15, 105, 32, 32);
  eurImageView := NSImageView.alloc.initWithFrame(rect);
  with eurImageView do
  begin
    setToolTip(NSString.stringWithUTF8String('Euro'));
    setImageScaling(NSImageScaleProportionallyUpOrDown);
    setImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSSTR('eur32.png'))));
    setAlphaValue(1.0);
    setMenu(contextMenu);
    NSView(contentView).addSubview(eurImageView);
    release;
  end;
  
  // EUR Buy Text Field
  rect := NSMakeRect(50, 110, 75, 25);
  eurBuyTextField := NSTextField.alloc.initWithFrame(rect);
  with eurBuyTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Euro Alış'));
    setTextColor(NSColor.whiteColor);
    setAlphaValue(0.85);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 18.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSRightTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSSTR('-.----'));
    NSView(contentView).addSubview(eurBuyTextField);
    release;
  end;
  
  // EUR Sell Text Field
  rect := NSMakeRect(135, 110, 75, 25);
  eurSellTextField := NSTextField.alloc.initWithFrame(rect);
  with eurSellTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Euro Satış'));
    setTextColor(NSColor.whiteColor);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 18.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSRightTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSSTR('-.----'));
    NSView(contentView).addSubview(eurSellTextField);
    release;
  end;
  
  // EUR status Text Field
  rect := NSMakeRect(215, 110, 25, 30);
  eurstatusTextField := NSTextField.alloc.initWithFrame(rect);
  with eurstatusTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Değişiklik Yok'));
    setTextColor(NSColor.yellowColor);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 22.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSCenterTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSString.stringWithUTF8String('='));
    NSView(contentView).addSubview(eurstatusTextField);
    release;
  end;

  // USD Image View
  rect := NSMakeRect(15, 70, 32, 32);
  usdImageView := NSImageView.alloc.initWithFrame(rect);
  with usdImageView do
  begin
    setToolTip(NSString.stringWithUTF8String('Dolar'));
    setImageScaling(NSImageScaleProportionallyUpOrDown);
    setImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSSTR('usd32.png'))));
    setAlphaValue(1.0);
    setMenu(contextMenu);
    NSView(contentView).addSubview(usdImageView);
    release;
  end;
  
  // USD Buy Text Field
  rect := NSMakeRect(50, 75, 75, 25);
  usdBuyTextField := NSTextField.alloc.initWithFrame(rect);
  with usdBuyTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Dolar Alış'));
    setTextColor(NSColor.whiteColor);
    setAlphaValue(0.85);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 18.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSRightTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSSTR('-.----'));
    NSView(contentView).addSubview(usdBuyTextField);
    release;
  end;
  
  // USD Sell Text Field
  rect := NSMakeRect(135, 75, 75, 25);
  usdSellTextField := NSTextField.alloc.initWithFrame(rect);
  with usdSellTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Dolar Satış'));
    setTextColor(NSColor.whiteColor);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 18.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSRightTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSSTR('-.----'));
    NSView(contentView).addSubview(usdSellTextField);
    release;
  end;
  
  // USD status Text Field
  rect := NSMakeRect(215, 75, 25, 30);
  usdstatusTextField := NSTextField.alloc.initWithFrame(rect);
  with usdstatusTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Değişiklik Yok'));
    setTextColor(NSColor.yellowColor);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 22.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSCenterTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSString.stringWithUTF8String('='));
    NSView(contentView).addSubview(usdstatusTextField);
    release;
  end;

  // Gold Image View
  rect := NSMakeRect(15, 35, 32, 32);
  goldImageView := NSImageView.alloc.initWithFrame(rect);
  with goldImageView do
  begin
    setToolTip(NSString.stringWithUTF8String('Altın'));
    setImageScaling(NSImageScaleProportionallyUpOrDown);
    setImage(NSImage.alloc.initWithContentsOfFile(
      bundle.pathForImageResource(NSSTR('gold32.png'))));
    setAlphaValue(1.0);
    setMenu(contextMenu);
    NSView(contentView).addSubview(goldImageView);
    release;
  end;
  
  // Gold Buy Text Field
  rect := NSMakeRect(50, 40, 75, 25);
  goldBuyTextField := NSTextField.alloc.initWithFrame(rect);
  with goldBuyTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Altın Alış'));
    setTextColor(NSColor.whiteColor);
    setAlphaValue(0.85);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 18.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSRightTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSSTR('-.----'));
    NSView(contentView).addSubview(goldBuyTextField);
    release;
  end;
  
  // Gold Sell Text Field
  rect := NSMakeRect(135, 40, 75, 25);
  goldSellTextField := NSTextField.alloc.initWithFrame(rect);
  with goldSellTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Altın Satış'));
    setTextColor(NSColor.whiteColor);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 18.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSRightTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSSTR('-.----'));
    NSView(contentView).addSubview(goldSellTextField);
    release;
  end;
  
  // Gold status Text Field
  rect := NSMakeRect(215, 40, 25, 30);
  goldstatusTextField := NSTextField.alloc.initWithFrame(rect);
  with goldstatusTextField do
  begin
    setToolTip(NSString.stringWithUTF8String('Değişiklik Yok'));
    setTextColor(NSColor.yellowColor);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 22.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSCenterTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSString.stringWithUTF8String('='));
    NSView(contentView).addSubview(goldstatusTextField);
    release;
  end;

  // Status Text Field
  rect := NSMakeRect(40, 12, 200, 15);
  statusTextField := NSTextField.alloc.initWithFrame(rect);
  with statusTextField do
  begin
    setTextColor(NSColor.whiteColor);
    setAlphaValue(0.85);
    setFont(NSFont.fontWithName_size(NSStr('Menlo'), 10.0));
    //cell.setBackgroundStyle(NSBackgroundStyleLowered);
    cell.setAlignment(NSRightTextAlignment);
    setBezeled(False);
    setEditable(False);
    setSelectable(False);
    setDrawsBackground(False);
    setMenu(contextMenu);
    setStringValue(NSString.stringWithUTF8String('Bağlanılıyor...'));
    NSView(contentView).addSubview(statusTextField);
    release;
  end;
  
  initControls;
  initLoaderTimer;
  
end;

procedure NSMainWindow.initControls;
begin

end;

procedure NSMainWindow.mouseDown(event: NSEvent);
begin
  dragLocation := event.locationInWindow;
  inherited mouseDown(event);
end;

procedure NSMainWindow.mouseDragged(event: NSEvent);
var
  currentLocation: NSPoint;
  windowFrame: NSRect;
  newOrigin: NSPoint;
  visibleFrame: NSRect;
begin
  visibleFrame := NSScreen.mainScreen.visibleFrame;
  windowFrame := self.frame;
  newOrigin := windowFrame.origin;
  currentLocation := event.locationInWindow;
  newOrigin.x := newOrigin.x + (currentLocation.x - dragLocation.x);
  newOrigin.y := newOrigin.y + (currentLocation.y - dragLocation.y);
  if (newOrigin.y + windowFrame.size.height) > (visibleFrame.origin.y + visibleFrame.size.height) then
    newOrigin.y := visibleFrame.origin.y + (visibleFrame.size.height - windowFrame.size.height);
  self.setFrameOrigin(newOrigin);
end;

procedure NSMainWindow.closeButtonClick(sender: id);
begin
  //self.close;
  application.terminate(nil);
end;

procedure NSMainWindow.miniaturizeButtonClick(sender: id);
begin
  self.miniaturize(self);
end;

{ NSApplicationDelegate }
procedure NSApplicationDelegate.refreshMenuClick(sender: id);
begin
  mainWindow.refreshMenuClick(sender);
end;

procedure NSApplicationDelegate.applicationWillFinishLaunching(notification: NSNotification);
begin
  initDefaults;
  initApplicationMenu;
  mainWindow := NSMainWindow.alloc.initWindow;
  mainWindow.makeKeyAndOrderFront(nil);
end;

procedure NSApplicationDelegate.applicationWillTerminate(notification: NSNotification);
begin
  doneDefaults;
  mainWindow.release;
end;

function NSApplicationDelegate.applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication): BOOL;
begin
  Result := True;
end;

procedure NSApplicationDelegate.initDefaults;
begin
  
end;

procedure NSApplicationDelegate.doneDefaults;
begin
  defaults.setBool_forKey(true, NSSTR('position'));
  mainWindow.doneDefaults;
  defaults.synchronize;
end;

procedure NSApplicationDelegate.initApplicationMenu;
var
  barMenu, applicationMenu: NSMenu;
  aboutMenuItem,
  refreshMenuItem,
  hideMenuItem,
  hideOthersMenuItem,
  showAllMenuItem,
  quitMenuItem: NSMenuItem;
  //applicationName: NSString;
begin
  //applicationName := bundle.objectForInfoDictionaryKey(NSSTR('CFBundleName'));
  barMenu := NSMenu.alloc.initWithTitle(NSSTR(''));
  application.setMainMenu(barMenu);
  applicationMenu := NSMenu.alloc.initwithTitle(NSSTR(''));
  applicationMenu.setAutoEnablesItems(False);
  
  aboutMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSString.stringWithUTF8String('Hakkında'),
    objcselector('orderFrontStandardAboutPanel:'), NSSTR(''));
  applicationMenu.addItem(aboutMenuItem);
  
  applicationMenu.addItem(NSMenuItem.separatorItem);
  
  refreshMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSString.stringWithUTF8String('Güncelle'),
    objcselector('refreshMenuClick:'), NSSTR('g'));
  applicationMenu.addItem(refreshMenuItem);
  
  applicationMenu.addItem(NSMenuItem.separatorItem);
  
  hideMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSString.stringWithUTF8String('Gizle'),
    objcselector('hide:'), NSSTR('h'));
  applicationMenu.addItem(hideMenuItem);
  
  hideOthersMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSString.stringWithUTF8String('Diğerlerini Gizle'),
    objcselector('hideOtherApplications:'), NSSTR('h'));
  hideOthersMenuItem.setKeyEquivalentModifierMask(NSCommandKeyMask or NSAlternateKeyMask);
  applicationMenu.addItem(hideOthersMenuItem);
  
  showAllMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSString.stringWithUTF8String('Tümünü Göster'),
    objcselector('unhideAllApplications:'), NSSTR(''));
  applicationMenu.addItem(showAllMenuItem);
  
  applicationMenu.addItem(NSMenuItem.separatorItem);
  
  quitMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSString.stringWithUTF8String('Çıkış'),
    objcselector('terminate:'), NSSTR('q'));
  applicationMenu.addItem(quitMenuItem);
  
  barMenu.addItemWithTitle_action_keyEquivalent(NSSTR(''), nil, NSSTR('')).setSubmenu(applicationMenu);
  application.tryToPerform_with(objcselector('setAppleMenu:'), applicationMenu);
  quitMenuItem.release;
  showAllMenuItem.release;
  hideOthersMenuItem.release;
  hideMenuItem.release;
  refreshMenuItem.release;
  aboutMenuItem.release;
  applicationMenu.release;
  barMenu.release;
end;

begin
  pool := NSAutoreleasePool.alloc.init;
  application := NSApplication.sharedApplication;
  bundle := NSBundle.mainBundle;
  defaults := NSUserDefaults.standardUserDefaults;
  delegate := NSApplicationDelegate.alloc.init;
  application.setDelegate(delegate);
  application.run;
  delegate.release;
  pool.release;
end.

