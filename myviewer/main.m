//
//  main.m
//  myviewer
//
//  Created by 詹松涛 on 16/5/22.
//  Copyright © 2016年 詹松涛. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyViewerCtrl.h"

int main(int argc, const char *argv[])
{
    @autoreleasepool
    {
        MyViewerCtrl *controller = [MyViewerCtrl shardController];
        NSApplication *app = [NSApplication shardApplication];
        [app setDelegate:controller];
        [app run];
    }
    return 0;
}