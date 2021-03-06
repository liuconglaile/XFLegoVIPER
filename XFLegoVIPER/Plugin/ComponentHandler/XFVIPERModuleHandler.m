//
//  XFVIPERModuleHandler.m
//  XFLegoVIPER
//
//  Created by Yizzuide on 2017/1/23.
//  Copyright © 2017年 yizzuide. All rights reserved.
//

#import "XFVIPERModuleHandler.h"
#import "XFRoutingFactory.h"
#import "XFRouting.h"
#import "XFRoutingLinkManager.h"
#import "NSObject+XFLegoInvokeMethod.h"
#import "XFVIPERModuleReflect.h"
#import "XFModuleReflect.h"

#define IS_Module(component) [component respondsToSelector:@selector(routing)]
#define Routing ((XFRouting *)[component routing])

@implementation XFVIPERModuleHandler

+ (BOOL)matchComponent:(id)component
{
    if ([component isKindOfClass:[NSString class]]) {
        return [XFModuleReflect verifyModule:component stuffixName:@"Routing"];
    }
    return IS_Module(component);
}

+ (BOOL)matchUInterface:(UIViewController *)uInterface
{
    return [uInterface valueForKeyPath:@"eventHandler"];
}

+ (id<XFComponentRoutable>)createComponentFromName:(NSString *)componentName
{
    XFRouting *routing = [XFRoutingFactory createRouingFromModuleName:componentName];
    return routing.uiOperator;
}

+ (NSString *)componentNameFromComponent:(id<XFComponentRoutable>)component
{
    return [XFVIPERModuleReflect moduleNameForModuleLayerObject:component];
}

+ (UIViewController *)uInterfaceForComponent:(__kindof id<XFComponentRoutable>)component
{
    XFRouting *routing = [component valueForKeyPath:@"routing"];
    return routing.realUInterface;
}

+ (id<XFComponentRoutable>)componentForUInterface:(UIViewController *)uInterface
{
    return [uInterface valueForKeyPath:@"eventHandler"];
}

+ (id<XFComponentRoutable>)component:(__kindof id<XFComponentRoutable>)component createNextComponentFromName:(NSString *)componentName {
    // 初始化一个Routing
    XFRouting *nextRouting = [XFRoutingFactory createRoutingFastFromModuleName:componentName];
    NSAssert(nextRouting, @"模块创建失败！请检测模块名是否正确！(注意：使用帕斯卡命名法<首字母大写>）");
    // 上一个是VIPER模块组件
    if ([self matchComponent:component]) {
        // 如果下一个路由有事件处理层
        if (nextRouting.uiOperator) {
            // 绑定模块关系
            [self _flowToNextRouting:nextRouting withComponent:component];
        }
        // 跟踪当前要跳转的路由,用于对共享的路由URL匹配
        [XFRoutingLinkManager setCurrentActionRounting:Routing];
    }
    return nextRouting.uiOperator;
}

+ (void)willRemoveComponent:(__kindof id<XFComponentRoutable>)component
{
}

+ (void)willReleaseComponent:(__kindof id<XFComponentRoutable>)component
{
    // 释放路由
    [Routing invokeMethod:@"xfLego_releaseRouting:" param:Routing];
}


#pragma mark - 私有方法
// 绑定模块组件关系链
+ (void)_flowToNextRouting:(XFRouting *)nextRouting withComponent:(__kindof id<XFComponentRoutable>)component
{
    [Routing setValue:nextRouting forKey:@"nextRouting"];
    [nextRouting setValue:Routing forKey:@"previousRouting"];
}
@end
