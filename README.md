## LHScore
这是一个生成APP评分弹框的

## 配置
1.添加LHScore到你的项目中
2.如果你的项目不是ARC, `LHScore.m`需要添加`-fobjc-arc`
3.添加`CFNetwork`, `SystemConfiguration`, and `StoreKit frameworks`到你的项目中

## 开发阶段
设置 `[LHScore setDebug:YES]`将确保每一次的应用程序被显示的评级要求

## 使用
确保你设置`[LHScore setDebug:NO]`确保该应用程序在应用程序启动时不显示,  也要确保这些组件中的每一个都设置在`application:didFinishLaunchingWithOptions:`这个方法

 这个例子说明，该评级申请仅显示当应用程序已经第二次打开App时，一打开就弹出,此后统计app每打开第n*10次

```objc
[XSScore setAppId:@"xxxxxxxxx"];
[XSScore setUsesUntilPrompt:2];
[XSScore setCountBeforeReminding:10];
[XSScore appLaunched];
```