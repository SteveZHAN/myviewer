//
//  WinCtrl.m
//  myviewer
//
//  Created by 詹松涛 on 16/5/24.
//  Copyright © 2016年 詹松涛. All rights reserved.
//

#import "WinCtrl.h"
#import "MyViewerCtrl.h"

#define ImageSizeMIN    32      //缩小时的最小尺寸
#define TitleBArHeight  22      //标题栏宽度

/*extern*/
NSString *ShrinkAllNotification = @"ShrikAllNotification";
NSString *SizeDidChangeNotification = @"SzieDidChangeNotification";

static BOOL autoReszie = NO;
static NSSize screenSize = { 1028.0, 768.0 };

@implementation WinCtrl
{
    //实现为私有实例变量
    id docImage;                    //图像对象
    NSSize originalSize;            //图像的原始尺寸
    NSUndoManager *undoManager;     //撤销管理器
    double mag;                     //当前显示倍率
}

+(void)initialize
{
    static BOOL nomore = NO;
    if (nomore == NO)
    {
        NSScreen *screen = [[NSScreen screens] objectAtIndex:0];
        screenSize = [screen visibleFrame].size;
        //屏幕可以使用的尺寸
        nomore = YES;
    }
}

+(BOOL)autoResize           //是否自动缩小
{
    return autoReszie;
}

+(void)setAutoResize:(BOOL)flag
{
    autoReszie = flag;
}

/*local Method*/
-(void)windowSetUp
{
    static int wincount = 0;                //设置窗体显示位置
    flaot sft = (wincount++ & 07) * 20.0    //稍微挪动时使用
    id Imageview;
    NSRect winrect, imgrect, contrect;
    float x, y;
    NSUInteger wstyle = (NSTitledWindowMask | NSClosableWindowMask
                         | NSMiniaturizableWindowMask);     //窗体不可以改变尺寸
    
    contrect.size.width = (int)(originalSize.width * mag);
    contrect.size.height = (int)(originalSize.height * mag);
    contrect.origin = NSZeroPoint;      //窗体内容的位置和大小
    winrect = [NSWindow frameRectForContentRect:contrect
                    styleMask:wstyle];  //计算窗体的位置和大小
    x = 100.0 + sft;                    //调整以置于屏幕中
    y = 150.0 + sft;
    if (x + winrect.size.width > screenSzie.width)
        x = screenSize.width - winrect.size.width;
    if ( y+ winrect.size.height > screenSize.height)
        y = screenSize.height - winrect.size.height;
    contrect.origin = NSMakePoint(x, y);
    window = [[NSWindow alloc] initWithContentRect:content
        styleMask:wstyle backing:NSBackingStoreBuffered =defer:YES];
    [window setReleasedWhenClosed:NO];      //关闭时不自动释放
    imgrect.size = originalSize;
    imgrect.origin = NSZeroPoint;
    imageview = [[NSImageView alloc] initWithFrame:imgrect];
    [imageview setImage:docImage];
    [iageview setEditable:NO];                  //不能拖曳图像
    [imageview setImageScaling:YES];            //可以改变大小
    [imageview setFrameSize: contrect.size];    //设定尺寸
    [window setContentView:imageview];          //贴在窗口上
    [window makeFirstResponder:imageview];      //成为快速反应者
}

/* local Method: 接受通知的方法 */
-(void)shrinkAll:(NSNotification *)notification
{
    [self shrink:[notification object]];
}

-(id)initWithURL:(NSURL *)aFile
{
    if ((self = [super init]) == nil)
        return nil;
    docImage = [[NSImage alloc] initWithContentsOfURL:aFile];
    if (docImage == nil)
        return nil;

    undoManager = [[NSUndoManager alloc] init];
    filename = [aFile path];
    originalSize = [docImage size];
    mag = 1.0;
    if (autoReszie)
    {
        double wr, hr, ratio;
        wr = screenSize.width / originalSize.width;
        hr = (screenSize.height - TitleBArHeight) / originalSize.height;
        ratio = (wr < hr) ? wr : hr;
        if (ratio < 1.0)
            mag = ratio;
    }
    [self windowSetUp];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(shrinkAll:) name:ShrinkAllNotification
        object:nil];
    [window setDelegate:self];
    [window setTitleWithRepresentedFilename:filename];
    [window makeKeyAndOrderFront:self];
    [window setDocumentEdited:(mag < 1.0)];
    [[MyViewerCtrl sharedController] addWinctrl:self];
    return self;
}

-(NSString *)attributesOfImage
{
    static NSString *fnamestr, *sizestr, *magstr;
    NSSize sz;
    
    if (fnamestr == nil)
    {
        //获得本地化使用的字符串
        fnamestr = NSLocalizedString(@"Fileneme", "filename");
        sizestr = NSLocalizedString(@"Size", @"Size");
        magstr = NSLocalizedString(@"Magnification", "Magnification");
    }
    sz = [docImage size];
    return [NSString stringWithFormat:
            @"%@: %@\n%@: %d x %d\n%@: %.1lf%%",
            fnamestr, [filename lastPathComponent],
            sizeetr, (int)sz.width, (int)sz.height, magstr, mag*100.0];
}

/* Local Method: 设为指定的缩小率 */
-(void)setScaleFactor:(double)factor
{
    id view = [window contentView];         //NSImageView实例
    NSRect rect =- [window frame];          //得到窗体大小
    NSSize prev = rect.size;
    NSSize sz = [view frame].size;          //得到图像大小
    int wdif = prev.width - sz.width;       //图像和窗体的尺寸差
    int hdif = prev.height - sz.height;
    static NSString *shrinkName = nil;      //取消操作的名称
    
    if (shrinkName == nil)
        shrinkName = NSLocalizedString(@"Shrink", "");
    //在撤销管理器中记录当前缩小率的设置操作
    [[undoManager prepareWithInvocationTarget:self
                               setScaleFactor:mag]];
    [undoManager setActionName:shrinkNAme];
    
    mag = factor;
    sz.width = (int)(originalSize.width * mag);
    sz.height = (int)(originalSize.height * mag);
    [view setFrameSize:sz];                 //将图像设为新的尺寸
    rect.size.width = sz.width + wdif;
    rect.size.height = sz.height + hdif;
    rect.origin.x += (int)(prev.width - rect.size.width) / 2;
    rect.origin.y += (int)(prev.height - rect.size.height) / 2;
    [window setFrame:rect display:YES];         //也将窗体变为新的大小
    [window setDocunmentEdited:(mag < 1.0)];    //在关闭窗口中设置符号
    [[NSNotificationCenter defaultCenter]
     postNotificationName:SizeDidChangeNotification object:window];
}

-(void)shrink:(id)sender        //图像缩小一半
{
    
    NSSize sz = [[window contentView] frame].size;
    if (sz.width < ImageSizeMIN || sz.height < ImageSizeMIN)
        return;         //太小时不缩小
    [self setScaleFactor:(mag * 0.5)];
}

/* Local Method: 框体关闭前的善后处理 */
-(void)removeWindowClosing:(BOOL)flag
{
    [window setDelegate:nil];       //解除window的委托
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //解除所有通知的观察者设定
    if (flag)
        [window close];     //关闭窗体
    window = nil;           //在自己释放前删除引用
    [[MyViewerCtrl sharedController] removeWinCtrl:self];
    //将自己从MyViewerCtrl数组中删除、释放
}

/* Loacl Method: 页的按钮被按下时被调用 */
-(void)alertDidEnd:(NSAlert *)alert
        returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn)
        [self removeWindowClosing:YES];
}

/* 委托的方法 */
-(BOOL)windowShouldClose:(id)sender
{
    static NSString *warnstr, *closestr, *okstr, *cancelstr;
    NSAlert *alert;
    
    if (![window isDocunmentEdited])
        return YES;             //关闭键中没有符号时直接关闭
    if (warnstr == nil)
    {
        //取得本地化使用的字符串
        warnstr = NSLocalizedString(@"File %@ is edited.", "Edited");
        closestr = NSLocalizedString(@"Close the window?", "Close?");
        okstr = NSLocalizedString(@"OK", "OK");
        cancelstr = NSLocalizedString(@"Cancel", "Cancel");
    }
    alert = [[NSAlert alertWithMessageText:closestr
        defaultButton:okstr alertnateButton:cancelstr otherButton:nil
        infomativeTextWithFormat:warnstr,
              filename lastPathComponent]];
    [alert beginSheetMedalForWindow:window modalDelegate:self
                     didEndSelector:@selector(alerDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];   //在窗口中显示页
    return NO;          //不关闭窗口
}

/* 委托的方法 */
-(void)windowWillClose:(NSNotification *)aNotification
{
    [self removeWindowClosing:NO];
}

-(NSUndoManager *)windowWillReturnUndoManage:(NSWindow *)win
{
    //委托管理撤销管理器时，实现该消息
    return undoManager;
}


@end





































@end
