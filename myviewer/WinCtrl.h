//
//  WinCtrl.h
//  myviewer
//
//  Created by 詹松涛 on 16/5/24.
//  Copyright © 2016年 詹松涛. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WinCtrl : NSObject <NSWindowDelegate>
{
    NSString *filename;         //文件路径名
    NSWindow *window;           //窗口
}
+(void)initialize;
+(BOOL)autoResize;
+(void)setAutoResize:(BOOL)flag;
-(id)initWithURL:(NSURL *)aFile;
-(NSString *)attributesOfImage;
-(void)shrink:(id)sender;

@end
