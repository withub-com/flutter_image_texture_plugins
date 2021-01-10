//
//  DuiaflutterextexturePresenter.m
//  Pods
//
//  Created by xhw on 2020/5/15.
//

#import "DuiaflutterextexturePresenter.h"
#import <Foundation/Foundation.h>
//#import <OpenGLES/EAGL.h>
//#import <OpenGLES/ES2/gl.h>
//#import <OpenGLES/ES2/glext.h>
//#import <CoreVideo/CVPixelBuffer.h>
#import <UIKit/UIKit.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import <SDWebImage/SDWebImageManager.h>
#import "FlutterimagetexturePlugin.h"


static uint32_t bitmapInfoWithPixelFormatType(OSType inputPixelFormat, bool hasAlpha){
    
    if (inputPixelFormat == kCVPixelFormatType_32BGRA) {
        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
        if (!hasAlpha) {
            bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
        }
        return bitmapInfo;
    }else if (inputPixelFormat == kCVPixelFormatType_32ARGB) {
        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
        return bitmapInfo;
    }else{
        NSLog(@"不支持此格式");
        return 0;
    }
}

// alpha的判断
BOOL CGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}
@interface DuiaflutterextexturePresenter()
@property (nonatomic) CVPixelBufferRef target;

@property (nonatomic,assign) CGSize size;
@property (nonatomic,assign) CGSize imageSize;//图片实际大小 px
@property(nonatomic,assign)Boolean useExSize;//是否使用外部设置的大小

@property(nonatomic,assign)Boolean iscopy;

//gif
@property (nonatomic, assign) Boolean asGif;//是否是gif
//下方是展示gif图相关的
@property (nonatomic, strong) CADisplayLink * displayLink;
@property (nonatomic, strong) NSMutableArray<NSDictionary*> *images;
@property (nonatomic, assign) int now_index;//当前展示的第几帧
@property (nonatomic, assign) CGFloat can_show_duration;//下一帧要展示的时间差


@end



@implementation DuiaflutterextexturePresenter


- (instancetype)initWithImageStr:(NSString*)imageStr size:(CGSize)size asGif:(Boolean)asGif fallback:(NSString*)fallback{
    self = [super init];
    if (self){
        self.size = size;
        self.asGif = asGif;
        self.useExSize = YES;//默认使用外部传入的大小
        
        //全部都从网络加载
        [self loadImageWithStrFromWeb:imageStr fallback:fallback];
        // if ([imageStr hasPrefix:@"http://"]||[imageStr hasPrefix:@"https://"]) {
        //     [self loadImageWithStrFromWeb:imageStr];
        // } else {
        //     [self loadImageWithStrForLocal:imageStr];
        // }
    }
    return self;
}

-(void)dealloc{
    
}
- (CVPixelBufferRef)copyPixelBuffer {
    //copyPixelBuffer方法执行后 释放纹理id的时候会自动释放_target
    //如果没有走copyPixelBuffer方法时 则需要手动释放_target
    _iscopy = YES;
    //    CVPixelBufferRetain(_target);//运行发现 这里不用加;
    return _target;
}

-(void)dispose{
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
    if (!_iscopy) {
        CVPixelBufferRelease(_target);
    }
}

// 此方法能还原真实的图片
- (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img size:(CGSize)size {
    if (!img) {
        return nil;
    }
    CGImageRef image = [img CGImage];
    
    //    CGSize size = CGSizeMake(5000, 5000);
//    CGFloat frameWidth = CGImageGetWidth(image);
//    CGFloat frameHeight = CGImageGetHeight(image);
    CGFloat frameWidth = size.width;
    CGFloat frameHeight = size.height;
    
    //兼容外部 不传大小
    if (frameWidth<=0 || frameHeight<=0) {
        if (img!=nil) {
            frameWidth = CGImageGetWidth(image);
            frameHeight = CGImageGetHeight(image);
        }else{
            frameWidth  = 1;
            frameHeight  = 1;
        }
    }else if (!self.useExSize && img!=nil) {//使用图片大小
        frameWidth = CGImageGetWidth(image);
        frameHeight = CGImageGetHeight(image);
    }
    
    
    BOOL hasAlpha = CGImageRefContainsAlpha(image);
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             empty, kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    
    //    NSDictionary *options = @{
    //        (NSString *)kCVPixelBufferCGImageCompatibilityKey:@YES,
    //        (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey:@YES,
    //        (NSString *)kCVPixelBufferIOSurfacePropertiesKey:[NSDictionary dictionary]
    //    };
    
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef) options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint32_t bitmapInfo = bitmapInfoWithPixelFormatType(kCVPixelFormatType_32BGRA, (bool)hasAlpha);
    CGContextRef context = CGBitmapContextCreate(pxdata, frameWidth, frameHeight, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, bitmapInfo);
    //    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, frameWidth, frameHeight), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}



#pragma mark - image
-(void)loadImageWithStrForLocal:(NSString*)imageStr{
    if (self.asGif) {
        self.images = [NSMutableArray array];
        [self sd_GIFImagesWithLocalNamed:imageStr];
    } else {
        UIImage *iamge = [UIImage imageNamed:imageStr];
        self.target = [self CVPixelBufferRefFromUiImage:iamge size:self.size];
    }
}
-(void)loadImageWithStrFromWeb:(NSString*)imageStr fallback:(NSString*)fallback{
    __weak typeof(DuiaflutterextexturePresenter*) weakSelf = self;

    // [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imageStr] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        
    //     if (weakSelf.asGif) {
    //         for (UIImage * uiImage in image.images) {
    //             NSDictionary *dic = @{
    //                 @"duration":@(image.duration*1.0/image.images.count),
    //                 @"image":uiImage
    //             };
    //             [weakSelf.images addObject:dic];
    //         }
    //         [weakSelf startGifDisplay];
    //     } else {
    //         weakSelf.target = [weakSelf CVPixelBufferRefFromUiImage:image size:weakSelf.size];
    //         if (weakSelf.updateBlock) {
    //             weakSelf.updateBlock();
    //         }
    //     }
    // }];
    //按给定的URL下载图片，如果没有在缓存则下载图片，否则返回缓存中的版本。
    [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:imageStr] options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if(image)
        {
            if (weakSelf.asGif) {
                for (UIImage * uiImage in image.images) {
                    NSDictionary *dic = @{
                        @"duration":@(image.duration*1.0/image.images.count),
                        @"image":uiImage
                    };
                    [weakSelf.images addObject:dic];
                }
                [weakSelf startGifDisplay];
            } else {
                weakSelf.target = [weakSelf CVPixelBufferRefFromUiImage:image size:weakSelf.size];
                if (weakSelf.updateBlock) {
                    weakSelf.updateBlock();
                }
            }
        }
        else{
            //如果正常的图下载错误，就下载fallback指定的图片；
            [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:fallback] options:0 progress:nil completed:^(UIImage * _Nullable fallbackImg, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                if(fallbackImg){
                    weakSelf.target = [weakSelf CVPixelBufferRefFromUiImage:fallbackImg size:weakSelf.size];
                    if (weakSelf.updateBlock) {
                        weakSelf.updateBlock();
                    }
                }
                else{
                    //如果下载图片错误，则返回默认的占位图
                    NSString *encodedImageStr = @"iVBORw0KGgoAAAANSUhEUgAAAMgAAADICAIAAAAiOjnJAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyNpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTQ4IDc5LjE2NDAzNiwgMjAxOS8wOC8xMy0wMTowNjo1NyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIxLjAgKFdpbmRvd3MpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkQ5MDY3NkNFQkFFNTExRUE5QkE0ODg0NkNCNEI1MUUzIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkQ5MDY3NkNGQkFFNTExRUE5QkE0ODg0NkNCNEI1MUUzIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6RDkwNjc2Q0NCQUU1MTFFQTlCQTQ4ODQ2Q0I0QjUxRTMiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6RDkwNjc2Q0RCQUU1MTFFQTlCQTQ4ODQ2Q0I0QjUxRTMiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz6wPYyVAAAIzUlEQVR42uyd25La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";
                    NSData *decodedImageData = [[NSData alloc] initWithBase64EncodedString:encodedImageStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage *img = [UIImage imageWithData:decodedImageData];
                    weakSelf.target = [weakSelf CVPixelBufferRefFromUiImage:img size:weakSelf.size];
                    if (weakSelf.updateBlock) {
                        weakSelf.updateBlock();
                    }
                }
            }];
        }
    }];
}


-(void)updategif:(CADisplayLink*)displayLink{
    //    NSLog(@"123--->%f",displayLink.duration);
    if (self.images.count==0) {
        self.displayLink.paused = YES;
        [self.displayLink invalidate];
        self.displayLink = nil;
        return;
    }
    self.can_show_duration -=displayLink.duration;
    if (self.can_show_duration<=0) {
        NSDictionary*dic = [self.images objectAtIndex:self.now_index];
        
        if (_target &&!_iscopy) {
            CVPixelBufferRelease(_target);
        }
        self.target = [self CVPixelBufferRefFromUiImage:[dic objectForKey:@"image"] size:self.size];
        _iscopy = NO;
        self.updateBlock();
        
        self.now_index += 1;
        if (self.now_index>=self.images.count) {
            self.now_index = 0;
            //            self.displayLink.paused = YES;
            //            [self.displayLink invalidate];
            //            self.displayLink = nil;
        }
        self.can_show_duration = ((NSNumber*)[dic objectForKey:@"duration"]).floatValue;
    }
    
    
}
- (void)startGifDisplay {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updategif:)];
    //    self.displayLink.paused = YES;
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)sd_GifImagesWithLocalData:(NSData *)data {
    if (!data) {
        return;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {
        //        CVPixelBufferRef targets[count];
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!image) {
                continue;
            }
            
            UIImage *uiImage = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            
            NSDictionary *dic = @{
                @"duration":@([self sd_frameDurationAtIndex:i source:source]),
                @"image":uiImage
            };
            [_images addObject:dic];
            
            CGImageRelease(image);
        }
        
    }
    
    CFRelease(source);
    [self startGifDisplay];
}

- (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

- (void)sd_GIFImagesWithLocalNamed:(NSString *)name {
    if ([name hasSuffix:@".gif"]) {
        name = [name  stringByReplacingCharactersInRange:NSMakeRange(name.length-4, 4) withString:@""];
    }
    CGFloat scale = [UIScreen mainScreen].scale;
    
    if (scale > 1.0f) {
        NSData *data = nil;
        if (scale>2.0f) {
            NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@3x"] ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:retinaPath];
        }
        if (!data){
            NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:retinaPath];
        }
        
        if (!data) {
            NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:path];
        }
        
        if (data) {
            [self sd_GifImagesWithLocalData:data];
        }
        
    }
    else {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        
        if (data) {
            [self sd_GifImagesWithLocalData:data];
        }
        
    }
}
@end
