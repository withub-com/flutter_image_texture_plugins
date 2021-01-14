package com.plugin.flutterimagetexture.flutterimagetexture;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.util.Base64;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

public class FlutterImageTexture {
    Context context;
    String url;
    String fallback;
    float width;
    float height;
    TextureRegistry.SurfaceTextureEntry mEntry;
    Surface surface;
    MethodChannel.Result result;
//    Bitmap bitmap;
    public FlutterImageTexture(Context context, String url, float width, float height, String fallback, TextureRegistry.SurfaceTextureEntry entry, MethodChannel.Result result) {
        this.context = context;
        this.url = url;
        this.fallback = fallback;
        this.width = width;
        this.height = height;
        this.mEntry = entry;
        this.surface = new Surface(entry.surfaceTexture());
        this.result = result;
        loadImage(context,url,width,height,fallback);
    }

    private void draw(Bitmap bitmap){
        if(surface!=null&&surface.isValid()){
            mEntry.surfaceTexture().setDefaultBufferSize(dip2px(context,width),dip2px(context,height));
            Canvas canvas = surface.lockCanvas(null);
            canvas.drawBitmap(bitmap,0,0,new Paint());
            surface.unlockCanvasAndPost(canvas);
            Log.d("FlutterImageTexture","entry_id========="+mEntry.id());
            result.success(mEntry.id());
        }
    }
    public void dispose(){
        surface.release();
        surface = null;
        mEntry.release();
        mEntry = null;
        result = null;
        context = null;
//        if(bitmap != null && !bitmap.isRecycled()){
//            bitmap.recycle();
//            bitmap = null;
//        }
    }

    private void loadImage(final Context context, String url, final float width, final float height, final String fallback) {
        Glide.with(context).asBitmap().load(url).override(dip2px(context,width),dip2px(context,height)).into(new CustomTarget<Bitmap>() {
            @Override
            public void onLoadFailed(@Nullable Drawable errorDrawable) {
                //super.onLoadFailed(errorDrawable);
                //加载失败后，重新下载
                Glide.with(context).asBitmap().load(fallback).override(dip2px(context,width),dip2px(context,height)).into(new CustomTarget<Bitmap>() {
                    @Override
                    public void onLoadFailed(@Nullable Drawable errorDrawable) {
                        //如果任然失败，则返回默认的；
                        String code = "iVBORw0KGgoAAAANSUhEUgAAAMgAAADICAIAAAAiOjnJAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyNpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTQ4IDc5LjE2NDAzNiwgMjAxOS8wOC8xMy0wMTowNjo1NyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIxLjAgKFdpbmRvd3MpIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkQ5MDY3NkNFQkFFNTExRUE5QkE0ODg0NkNCNEI1MUUzIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkQ5MDY3NkNGQkFFNTExRUE5QkE0ODg0NkNCNEI1MUUzIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6RDkwNjc2Q0NCQUU1MTFFQTlCQTQ4ODQ2Q0I0QjUxRTMiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6RDkwNjc2Q0RCQUU1MTFFQTlCQTQ4ODQ2Q0I0QjUxRTMiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz6wPYyVAAAIzUlEQVR42uyd25La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";
                        Bitmap bitmap = null;
                        try {
                            byte[] bitmapByte = Base64.decode(code, Base64.DEFAULT);
                            bitmap = BitmapFactory.decodeByteArray(bitmapByte, 0, bitmapByte.length);
                            draw(bitmap);
                        } catch (Exception e) {
                            super.onLoadFailed(errorDrawable);
                        }
                    }
        
                    @Override
                    public void onResourceReady(@NonNull Bitmap b, @Nullable Transition<? super Bitmap> transition) {
                        draw(b);
                    }
        
                    @Override
                    public void onLoadCleared(@Nullable Drawable placeholder) {
        
                    }
                });
            }

            @Override
            public void onResourceReady(@NonNull Bitmap b, @Nullable Transition<? super Bitmap> transition) {
                draw(b);
            }

            @Override
            public void onLoadCleared(@Nullable Drawable placeholder) {

            }
        });
    }

    public static int dip2px(Context context, float dpValue) {
        float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dpValue * scale + 0.5f);
    }
}