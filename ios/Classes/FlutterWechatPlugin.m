#import "FlutterWechatPlugin.h"
#import <WechatOpenSDK/WXApi.h>
#import <WechatOpenSDK/WXApiObject.h>

// Define a block type for the cached request
typedef void(^WeChatURLHandler)(void);

@interface FlutterWechatPlugin () <WXApiDelegate, FlutterStreamHandler>
@property (nonatomic, strong) FlutterResult pendingLoginResult;
@property (nonatomic, assign) BOOL isRegistered;
@property (nonatomic, copy) WeChatURLHandler cachedURLHandler;
@property (nonatomic, strong) FlutterEventSink eventSink;
@end

@implementation FlutterWechatPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                   methodChannelWithName:@"flutter_wechat_plugin"
                                         binaryMessenger:[registrar messenger]];
    FlutterWechatPlugin* instance = [[FlutterWechatPlugin alloc] init];
    instance.isRegistered = NO;
    sharedInstance = instance; // Set static instance
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
    
    // Register event channel for response events
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                        eventChannelWithName:@"flutter_wechat_plugin/response_event"
                                              binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"registerApp" isEqualToString:call.method]) {
        [self registerApp:call result:result];
    } else if ([@"isWechatInstalled" isEqualToString:call.method]) {
        BOOL isInstalled = [WXApi isWXAppInstalled];
        result(@(isInstalled));
    } else if ([@"wechatLogin" isEqualToString:call.method]) {
        [self wechatLogin:result];
    } else if ([@"shareText" isEqualToString:call.method]) {
        [self shareText:call result:result];
    } else if ([@"shareNetworkImage" isEqualToString:call.method]) {
        [self shareNetworkImage:call result:result];
    } else if ([@"shareNetworkImageToScene" isEqualToString:call.method]) {
        [self shareNetworkImageToScene:call result:result];
    } else if ([@"shareLink" isEqualToString:call.method]) {
        [self shareLink:call result:result];
    } else if ([@"openMiniProgram" isEqualToString:call.method]) {
        [self openMiniProgram:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)registerApp:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    NSString *appId = args[@"appId"];
    NSString *universalLink = args[@"universalLink"];

    if (!appId || !universalLink) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" message:@"App ID and Universal Link are required" details:nil]);
        return;
    }

    BOOL success = [WXApi registerApp:appId universalLink:universalLink];
    self.isRegistered = success;

    if (success) {
        if (self.cachedURLHandler) {
            self.cachedURLHandler();
            self.cachedURLHandler = nil;
        }
    }
    result(@(success));
}

- (void)wechatLogin:(FlutterResult)result {
    if (!self.isRegistered) {
        result([FlutterError errorWithCode:@"WECHAT_NOT_REGISTERED" 
                                   message:@"WeChat is not registered. Call registerApp first." 
                                   details:nil]);
        return;
    }
    if (![WXApi isWXAppInstalled]) {
        result([FlutterError errorWithCode:@"WECHAT_NOT_INSTALLED" 
                                   message:@"WeChat is not installed" 
                                   details:nil]);
        return;
    }
    
    self.pendingLoginResult = result;
    
    SendAuthReq *req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo";
    req.state = @"flutter_wechat_plugin_state";
    
    [WXApi sendReq:req completion:^(BOOL success) {
        if (!success) {
            self.pendingLoginResult = nil;
            result([FlutterError errorWithCode:@"SEND_REQUEST_FAILED" 
                                       message:@"Failed to send login request" 
                                       details:nil]);
        }
    }];
}

#pragma mark - WXApiDelegate

- (void)onResp:(BaseResp *)resp {
    if ([resp isKindOfClass:[SendAuthResp class]]) {
        if (self.pendingLoginResult) {
            SendAuthResp *authResp = (SendAuthResp *)resp;
            NSMutableDictionary *response = [NSMutableDictionary dictionary];
            response[@"type"] = @"auth";
            response[@"errCode"] = @(authResp.errCode);
            if (authResp.code) response[@"code"] = authResp.code;
            if (authResp.state) response[@"state"] = authResp.state;
            if (authResp.lang) response[@"lang"] = authResp.lang;
            if (authResp.country) response[@"country"] = authResp.country;
            if (authResp.errStr) response[@"errStr"] = authResp.errStr;

            // This is the dual-callback mechanism from the Android implementation.
            // We resolve the future of the wechatLogin() call.
            self.pendingLoginResult(response);
            self.pendingLoginResult = nil;

            // We also send the event to the stream.
            [[self class] sendEventToDart:response];
        }
    } else if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        SendMessageToWXResp *messageResp = (SendMessageToWXResp *)resp;
        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        response[@"type"] = @"share";
        response[@"errCode"] = @(messageResp.errCode);
        if (messageResp.errStr) response[@"errStr"] = messageResp.errStr;
        
        // Send the event to the stream
        [[self class] sendEventToDart:response];
    } else if ([resp isKindOfClass:[WXLaunchMiniProgramResp class]]) {
        // Handle mini program response
        WXLaunchMiniProgramResp *miniProgramResp = (WXLaunchMiniProgramResp *)resp;
        NSMutableDictionary *miniProgramResult = [@{
            @"errCode": @(miniProgramResp.errCode),
            @"errStr": miniProgramResp.errStr ?: @"",
            @"type": @"miniProgram"
        } mutableCopy];
        
        if (miniProgramResp.extMsg) {
            miniProgramResult[@"extMsg"] = miniProgramResp.extMsg;
        }
        
        [[self class] sendEventToDart:miniProgramResult];
    }
}

// Static instance to access from class methods
static FlutterWechatPlugin* sharedInstance = nil;

// Helper to send events to the Dart stream
+ (void)sendEventToDart:(NSDictionary *)event {
    if (sharedInstance && sharedInstance.eventSink) {
        sharedInstance.eventSink(event);
    }
}


#pragma mark - Application Delegate Methods

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if (self.isRegistered) {
        return [WXApi handleOpenURL:url delegate:self];
    } else {
        self.cachedURLHandler = ^{
            [WXApi handleOpenURL:url delegate:self];
        };
        return NO;
    }
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    if (self.isRegistered) {
        return [WXApi handleOpenUniversalLink:userActivity delegate:self];
    } else {
        self.cachedURLHandler = ^{
            [WXApi handleOpenUniversalLink:userActivity delegate:self];
        };
        return NO;
    }
}

#pragma mark - FlutterStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    self.eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

#pragma mark - Share Methods

- (void)shareText:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (!self.isRegistered) {
        result([FlutterError errorWithCode:@"WECHAT_NOT_REGISTERED" 
                                   message:@"WeChat is not registered. Call registerApp first." 
                                   details:nil]);
        return;
    }
    
    NSString *text = call.arguments[@"text"];
    if (!text) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" 
                                   message:@"Text is required" 
                                   details:nil]);
        return;
    }
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.scene = WXSceneSession; // Default to session (friends)
    req.bText = YES;
    req.text = text;
    
    [WXApi sendReq:req completion:^(BOOL success) {
        result(@(success));
    }];
}

- (void)shareNetworkImage:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (!self.isRegistered) {
        result([FlutterError errorWithCode:@"WECHAT_NOT_REGISTERED" 
                                   message:@"WeChat is not registered. Call registerApp first." 
                                   details:nil]);
        return;
    }
    
    NSString *imageUrl = call.arguments[@"imageUrl"];
    if (!imageUrl) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" 
                                   message:@"Image URL is required" 
                                   details:nil]);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!imageData) {
                result([FlutterError errorWithCode:@"DOWNLOAD_FAILED" 
                                           message:@"Failed to download image" 
                                           details:nil]);
                return;
            }
            
            WXImageObject *imageObject = [WXImageObject object];
            imageObject.imageData = imageData;
            
            WXMediaMessage *message = [WXMediaMessage message];
            message.mediaObject = imageObject;
            
            // Create thumbnail
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                CGSize thumbnailSize = CGSizeMake(100, 100);
                UIGraphicsBeginImageContextWithOptions(thumbnailSize, NO, 0.0);
                [image drawInRect:CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height)];
                UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                if (thumbnailImage) {
                    message.thumbData = UIImageJPEGRepresentation(thumbnailImage, 0.8);
                }
            }
            
            SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
            req.scene = WXSceneSession; // Default to session (friends)
            req.message = message;
            req.bText = NO;
            
            [WXApi sendReq:req completion:^(BOOL success) {
                result(@(success));
            }];
        });
    });
}

- (void)shareNetworkImageToScene:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (!self.isRegistered) {
        result([FlutterError errorWithCode:@"WECHAT_NOT_REGISTERED" 
                                   message:@"WeChat is not registered. Call registerApp first." 
                                   details:nil]);
        return;
    }
    
    NSString *imageUrl = call.arguments[@"imageUrl"];
    NSNumber *sceneNumber = call.arguments[@"scene"];
    
    if (!imageUrl) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" 
                                   message:@"Image URL is required" 
                                   details:nil]);
        return;
    }
    
    enum WXScene scene = WXSceneSession; // Default to session
    if (sceneNumber) {
        int sceneInt = [sceneNumber intValue];
        if (sceneInt == 1) {
            scene = WXSceneTimeline; // Timeline (moments)
        } else if (sceneInt == 2) {
            scene = WXSceneFavorite; // Favorites
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!imageData) {
                result([FlutterError errorWithCode:@"DOWNLOAD_FAILED" 
                                           message:@"Failed to download image" 
                                           details:nil]);
                return;
            }
            
            WXImageObject *imageObject = [WXImageObject object];
            imageObject.imageData = imageData;
            
            WXMediaMessage *message = [WXMediaMessage message];
            message.mediaObject = imageObject;
            
            // Create thumbnail
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                CGSize thumbnailSize = CGSizeMake(100, 100);
                UIGraphicsBeginImageContextWithOptions(thumbnailSize, NO, 0.0);
                [image drawInRect:CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height)];
                UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                if (thumbnailImage) {
                    message.thumbData = UIImageJPEGRepresentation(thumbnailImage, 0.8);
                }
            }
            
            SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
            req.scene = scene;
            req.message = message;
            req.bText = NO;
            
            [WXApi sendReq:req completion:^(BOOL success) {
                result(@(success));
            }];
        });
    });
}

- (void)shareLink:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (!self.isRegistered) {
        result([FlutterError errorWithCode:@"WECHAT_NOT_REGISTERED" 
                                   message:@"WeChat is not registered. Call registerApp first." 
                                   details:nil]);
        return;
    }
    
    NSString *url = call.arguments[@"url"];
    NSString *title = call.arguments[@"title"];
    NSString *description = call.arguments[@"description"];
    
    if (!url || !title) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" 
                                   message:@"URL and title are required" 
                                   details:nil]);
        return;
    }
    
    WXWebpageObject *webpageObject = [WXWebpageObject object];
    webpageObject.webpageUrl = url;
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description ?: @"";
    message.mediaObject = webpageObject;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.scene = WXSceneSession; // Default to session (friends)
    req.message = message;
    req.bText = NO;
    
    [WXApi sendReq:req completion:^(BOOL success) {
        result(@(success));
    }];
}

- (void)openMiniProgram:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (!self.isRegistered) {
        result([FlutterError errorWithCode:@"WECHAT_NOT_REGISTERED" 
                                   message:@"WeChat is not registered. Call registerApp first." 
                                   details:nil]);
        return;
    }
    
    NSString *username = call.arguments[@"username"];
    NSString *path = call.arguments[@"path"];
    NSNumber *miniProgramTypeNumber = call.arguments[@"miniProgramType"];
    
    if (!username) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" 
                                   message:@"Username is required" 
                                   details:nil]);
        return;
    }
    
    // Convert miniProgramType from int to WXMiniProgramType
    WXMiniProgramType miniProgramType = WXMiniProgramTypeRelease; // Default
    if (miniProgramTypeNumber) {
        int typeInt = [miniProgramTypeNumber intValue];
        if (typeInt == 1) {
            miniProgramType = WXMiniProgramTypeTest;
        } else if (typeInt == 2) {
            miniProgramType = WXMiniProgramTypePreview;
        }
    }
    
    WXLaunchMiniProgramReq *launchMiniProgramReq = [WXLaunchMiniProgramReq object];
    launchMiniProgramReq.userName = username;
    launchMiniProgramReq.path = (path && ![path isEqual:[NSNull null]]) ? path : nil;
    launchMiniProgramReq.miniProgramType = miniProgramType;
    
    [WXApi sendReq:launchMiniProgramReq completion:^(BOOL success) {
        result(@(success));
    }];
}

@end
