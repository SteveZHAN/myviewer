//
//  MyViewerCtrl.m
//  myviewer
//
//  Created by 詹松涛 on 16/5/22.
//  Copyright © 2016年 詹松涛. All rights reserved.
//

#import "MyViewerCtrl.h"
#import "WinCtrl.h"
#import "MyInspector.h"

static NSString *AutoResizeKey = @"AutoResize";
//将是否自动缩小写入用户默认时的键
static id shardCntr = nil;         //保存唯一一个共享实例


@implementation MyViewerCtrl
{   //因为是依赖实现的实例变量，所以设为私有
    __weak id autoResizeItem;       //指向自动缩小的菜单项
    NSMutableArray *ctrlPool;       //保存WinCtrl的实例
}

+(id)sharedController
{   //单体模式
    if (shardCntr == nil)
    {
        shardCntr = [[[self class] alloc] init];
    }
    return shardCntr;
}

//Local Method：构建菜单的本地方法
-(NSMenu *)makeSubMenu:(NSArray *)itemsArray
                 title:(NSString *)title note:(NSMutableDirection *)iddic
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
    for (NSDictionary *dic in itemsArray)
    {
        NSMenuItem *item;
        NSString *itemtitle = [dic objectForKey:@"title"];
        if (itemtitle == nil)
        {   //menu separator
            [menu addItem:[NSMenuItem separatorItem]];
            continue;
        }
        NSArray *sub = [dic objectForKey:@"submenu"];
        if (sub != nil)
        {
            NSMenu *submenu;
            item = [menu addItemWithTitle:itemtitle
                                   action:(SEL)0 keyEquivalent:@""];
            submenu = [self makeSubMenu:sub title:itemtitle note:iddic];
            [item setSubmenu: submenu];
        }
        else
        {
            NSString *key = [dic objectForKey:@"key"];
            NSString *targetstr = [dic objectForKey:@"target"];
            SEL sel = NSSelectorFromString([dic objectForKey:@"selector"]);
            item = [menu addItemWithTitle:itemtitle
                                   action:sel keyEquivalent:(key ? key: @"")];
            [item setTarget: (targetstr ? self : nil)];
        }
        if (iddic !=nil)
        {
            NSString *idkey = [dic objectForKey:@"id"];
            if (ifkey != nil)
            {
                [iddic setObject:item forkey:idkey];
            }
        }
    }
    return menu;
}

/*在本地化的资源Menu.plist内用属性列表格式书写菜单内容。
 该方法会读入该信息，然后构建菜单
 电磁菜单时的消息接收者中，“打开文件”“简介”“自动缩小”
 三个被设置为self，其他被设置为快速反应 */
-(void) setupMainMenu
{
    NSBundle *bundle = [NSbundle mainBundle];
    NSString *path = [bundle pathForResource:@"Menu" ofType:@"plist"];
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:path];
    NSMutableDictionary *iddic = [NSMutableDictionary dictionary];
    NSMenu *menu = [self makeSubMenu:[dic objectForKey:@"submenu"]
                               title:[dic objectForKey:@"title"] note:iddic];
    [NSApp setMainMenu: menu];
    [NSApp setWindowMenu: [[iddic objectForKey:@"window"] submenu]];
    autoResizeItem = [iddic objectForKey:@"autoResize"];
}

-(void)openFile:(id)sender
{   //显示打开面板
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setAllowedFileTypes:[NSImage imageFileTypes]];
    [oPanel beginWithCompletionHandler: ^(NSInteger result)
     {
         if (result == NSFileHandlingPanelOKbutton)
         {
             for (NSURL *aFile in [oPanel URLs])
                 (void)[[WinCtrl alloc] initWithURL:aFile];
         }
     }];
}

//添加WinCtrl实例
-(void)addWinctrl:(id)obj
{
    [ctrlPool addObject:obj];
}

//删除WinCtrl实例
-(void)removeWinCtrl:(id)obj
{
    [ctrlPool removeObject:obj];
}


-(void)activateInspector:(id)sender         //显示简介
{
    static Class inspectorClass = Nil;      //指向加载的类
    NSBundle *bundle;
    NSString *path;
    
    if (inspectorClass == Nil)
    {
        //尚未被加载时
        path = [[NSBundle mainBundle]
                pathForResource:@"insperctor" ofType:@"bundle"];
        //从主束内获得可加载束
        if ((bundle = [NSBundle bundleForClass:path]) == nil)
            return; //ERROR!
        inspectorClass = [bundle classNamed:@"MyInspector"];
    }
    [[inspectorClass sharedInstance] activate];
}

-(void)toggleAutoResize:(id)sender          //切换菜单的复选项
{
    BOOL newState = ([sender state] != NSOnState);      //否定现在的状态
    //由WinCtrl类来管理是否自动缩小
    [WinCtrl setAutoResize: newState];
    [sender setState:(newState ? NSOnState : NSOffState)];
    //写入用户默认
    [[NSUserDefaults standardUserDefaults]
     setBool:newState forKey:AutoResizeKey];
}

//应用启动后NSApplication发送的委托消息
-(void)applicationWillfinishLaunching:(NSNotification *)aNotification
{
    BOOl flag;
    [self setupMainMenu];       //生成并设定主菜单
    ctrlPool = [NSMutableArray array];      //预留空数组
    //从用户默认中读取自动缩小的设定值，并在WinCtrl类和菜单中的设定
    flag = [[NSUserDefaults standardUserDefaults]
                            boolForKey:AutoResizeKey];
    [WinCtrl setAutoResize: flag];
    [autoResizeItem setState:(flag ? NAOnState : NSOffState)];
}

//应用终止时NSApplicationd发送的委托消息
-(void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[NSUersDefaults standardUserDefaults] synchronize];
}


@end
