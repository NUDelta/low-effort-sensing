//
//  BackgroundTaskManager.h
//  CrowdFound
//
//  Created by Yongsung on 9/8/15.
//  Copyright (c) 2015 YK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BackgroundTaskManager : NSObject

+(instancetype)sharedBackgroundTaskManager;

-(UIBackgroundTaskIdentifier)beginNewBackgroundTask;
-(void)endAllBackgroundTasks;

@end
