//
//  MyViewerCtrl.h
//  myviewer
//
//  Created by 詹松涛 on 16/5/22.
//  Copyright © 2016年 詹松涛. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyViewerCtrl : NSObject <NSApplicationDelegate>

+(id)sharedController;                  //返回共享实例
-(void)setupMainMenu;                   //准备菜单
-(void)openFile:(id)sender;             //打开文件
-(void)addWinctrl:(id)obj;              //添加WinCtrl类实例
-(void)removeWinCtrl:(id)obj;           //删除WinCtrl类实例
-(void)activateInspector:(id)sender;    //打开简介
-(void)toggleAutoResize:(id)sender;     //切换是否自动缩小

@end
