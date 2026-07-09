-------------------------------------
Translated Report (Full Report Below)
-------------------------------------

Process:               MacScreen [26347]
Path:                  /Users/USER/Desktop/*/MacScreen.app/Contents/MacOS/MacScreen
Identifier:            local.macos.macscreen
Version:               0.1.0 (1)
Code Type:             ARM-64 (Native)
Parent Process:        launchd [1]
User ID:               502

Date/Time:             2026-07-09 11:19:35.3032 +0800
OS Version:            macOS 15.3.1 (24D70)
Report Version:        12
Anonymous UUID:        05078A0B-672D-E3BF-8EEF-9915C36184C1

Sleep/Wake UUID:       3B169AE7-9379-469E-8F15-F6CC4482E3D2

Time Awake Since Boot: 1500000 seconds
Time Since Wake:       4933 seconds

System Integrity Protection: enabled

Crashed Thread:        0  Dispatch queue: com.apple.main-thread

Exception Type:        EXC_BAD_ACCESS (SIGSEGV)
Exception Codes:       KERN_INVALID_ADDRESS at 0x0000000000000020
Exception Codes:       0x0000000000000001, 0x0000000000000020

Termination Reason:    Namespace SIGNAL, Code 11 Segmentation fault: 11
Terminating Process:   exc handler [26347]

VM Region Info: 0x20 is not in any region.  Bytes before following region: 4363747296
      REGION TYPE                    START - END         [ VSIZE] PRT/MAX SHRMOD  REGION DETAIL
      UNUSED SPACE AT START
--->  
      __TEXT                      104198000-1041cc000    [  208K] r-x/r-x SM=COW  /Users/USER/Desktop/*/MacScreen.app/Contents/MacOS/MacScreen

Thread 0 Crashed::  Dispatch queue: com.apple.main-thread
0   libobjc.A.dylib               	       0x196780280 objc_release + 16
1   libobjc.A.dylib               	       0x196787d94 AutoreleasePoolPage::releaseUntil(objc_object**) + 204
2   libobjc.A.dylib               	       0x196784138 objc_autoreleasePoolPop + 260
3   CoreFoundation                	       0x196bf70e8 _CFAutoreleasePoolPop + 32
4   Foundation                    	       0x197dde404 -[NSAutoreleasePool drain] + 136
5   AppKit                        	       0x19a7a18a4 -[NSApplication run] + 528
6   AppKit                        	       0x19a778068 NSApplicationMain + 888
7   SwiftUI                       	       0x1c58d670c specialized runApp(_:) + 160
8   SwiftUI                       	       0x1c5d4c9a0 runApp<A>(_:) + 140
9   SwiftUI                       	       0x1c60c8e68 static App.main() + 224
10  MacScreen                     	       0x1041b1514 static MacScreenApp.$main() + 40
11  MacScreen                     	       0x1041b16e8 main + 12
12  dyld                          	       0x1967d0274 start + 2840

Thread 1:
0   libsystem_pthread.dylib       	       0x196b4b0e8 start_wqthread + 0

Thread 2::  Dispatch queue: com.apple.coremedia.videolayer.notificationqueue
0   libsystem_kernel.dylib        	       0x196b11bbc __psynch_mutexwait + 8
1   libsystem_pthread.dylib       	       0x196b4d3f8 _pthread_mutex_firstfit_lock_wait + 84
2   libsystem_pthread.dylib       	       0x196b4adbc _pthread_mutex_firstfit_lock_slow + 220
3   MediaToolbox                  	       0x1a70e3d7c 0x1a6ee4000 + 2096508
4   CoreFoundation                	       0x196c2d3ac __CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ + 208
5   CoreFoundation                	       0x196cbe20c ___CFXRegistrationPost_block_invoke + 88
6   CoreFoundation                	       0x196cbe154 _CFXRegistrationPost + 436
7   CoreFoundation                	       0x196bfbfac _CFXNotificationPost + 732
8   CoreFoundation                	       0x196c2d44c CFNotificationCenterPostNotificationWithOptions + 136
9   CoreMedia                     	       0x1a1caa4a8 CMNotificationCenterPostNotification + 128
10  libdispatch.dylib             	       0x19699b854 _dispatch_call_block_and_release + 32
11  libdispatch.dylib             	       0x19699d5b4 _dispatch_client_callout + 20
12  libdispatch.dylib             	       0x1969a4bd8 _dispatch_lane_serial_drain + 768
13  libdispatch.dylib             	       0x1969a5730 _dispatch_lane_invoke + 380
14  libdispatch.dylib             	       0x1969b09a0 _dispatch_root_queue_drain_deferred_wlh + 288
15  libdispatch.dylib             	       0x1969b01ec _dispatch_workloop_worker_thread + 540
16  libsystem_pthread.dylib       	       0x196b4c3d8 _pthread_wqthread + 288
17  libsystem_pthread.dylib       	       0x196b4b0f0 start_wqthread + 8

Thread 3:
0   libsystem_pthread.dylib       	       0x196b4b0e8 start_wqthread + 0

Thread 4:: com.apple.NSEventThread
0   libsystem_kernel.dylib        	       0x196b0ef54 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	       0x196b21604 mach_msg2_internal + 80
2   libsystem_kernel.dylib        	       0x196b17af8 mach_msg_overwrite + 480
3   libsystem_kernel.dylib        	       0x196b0f29c mach_msg + 24
4   CoreFoundation                	       0x196c38a4c __CFRunLoopServiceMachPort + 160
5   CoreFoundation                	       0x196c372ac __CFRunLoopRun + 1212
6   CoreFoundation                	       0x196c36734 CFRunLoopRunSpecific + 588
7   AppKit                        	       0x19a8d3278 _NSEventThread + 148
8   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
9   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 5:
0   libsystem_pthread.dylib       	       0x196b4b0e8 start_wqthread + 0

Thread 6:
0   libsystem_pthread.dylib       	       0x196b4b0e8 start_wqthread + 0

Thread 7:: caulk.messenger.shared:17
0   libsystem_kernel.dylib        	       0x196b0eed0 semaphore_wait_trap + 8
1   caulk                         	       0x1a1c7bff4 caulk::semaphore::timed_wait(double) + 220
2   caulk                         	       0x1a1c7bea0 caulk::concurrent::details::worker_thread::run() + 36
3   caulk                         	       0x1a1c7bb74 void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*) + 96
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 8:: caulk.messenger.shared:high
0   libsystem_kernel.dylib        	       0x196b0eed0 semaphore_wait_trap + 8
1   caulk                         	       0x1a1c7bff4 caulk::semaphore::timed_wait(double) + 220
2   caulk                         	       0x1a1c7bea0 caulk::concurrent::details::worker_thread::run() + 36
3   caulk                         	       0x1a1c7bb74 void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*) + 96
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 9:: com.apple.coremedia.imagequeue.coreanimation.common
0   libsystem_kernel.dylib        	       0x196b126ec __psynch_cvwait + 8
1   libsystem_pthread.dylib       	       0x196b50894 _pthread_cond_wait + 1204
2   CoreMedia                     	       0x1a1cc23f4 WaitOnConditionTimed + 76
3   CoreMedia                     	       0x1a1cad6e4 FigSemaphoreWaitRelative + 172
4   MediaToolbox                  	       0x1a736f028 0x1a6ee4000 + 4763688
5   CoreMedia                     	       0x1a1cc2008 figThreadMain + 224
6   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
7   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 10:: com.apple.coremedia.videomediaconverter
0   libsystem_kernel.dylib        	       0x196b126ec __psynch_cvwait + 8
1   libsystem_pthread.dylib       	       0x196b50894 _pthread_cond_wait + 1204
2   CoreMedia                     	       0x1a1cc23f4 WaitOnConditionTimed + 76
3   CoreMedia                     	       0x1a1cad6e4 FigSemaphoreWaitRelative + 172
4   VideoToolbox                  	       0x1a694c31c 0x1a6718000 + 2310940
5   VideoToolbox                  	       0x1a673ea80 0x1a6718000 + 158336
6   VideoToolbox                  	       0x1a673be00 0x1a6718000 + 146944
7   MediaToolbox                  	       0x1a6fed108 0x1a6ee4000 + 1085704
8   MediaToolbox                  	       0x1a7365544 0x1a6ee4000 + 4724036
9   CoreMedia                     	       0x1a1cc2008 figThreadMain + 224
10  libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
11  libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 11:: com.apple.coremedia.rootQueue.fP-48.mP-47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 12:: com.apple.coremedia.rootQueue.fP-48.mP-47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 13:: com.apple.coremedia.sharedRootQueue.47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 14:: com.apple.coremedia.sharedRootQueue.47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 15:: com.apple.coremedia.rootQueue.fP-45.mP-47 Dispatch queue: */QZ
0   libsystem_kernel.dylib        	       0x196b11bbc __psynch_mutexwait + 8
1   libsystem_pthread.dylib       	       0x196b4d3f8 _pthread_mutex_firstfit_lock_wait + 84
2   libsystem_pthread.dylib       	       0x196b4adbc _pthread_mutex_firstfit_lock_slow + 220
3   MediaToolbox                  	       0x1a6efa918 VMC2WaitUntilCompletelyStopped + 96
4   MediaToolbox                  	       0x1a6efa350 VMC2Invalidate + 60
5   MediaToolbox                  	       0x1a71a5a60 0x1a6ee4000 + 2890336
6   MediaToolbox                  	       0x1a70c1564 0x1a6ee4000 + 1955172
7   MediaToolbox                  	       0x1a70dd8e0 0x1a6ee4000 + 2070752
8   MediaToolbox                  	       0x1a70edbc4 0x1a6ee4000 + 2137028
9   MediaToolbox                  	       0x1a75a7ff4 0x1a6ee4000 + 7094260
10  MediaToolbox                  	       0x1a72d87dc 0x1a6ee4000 + 4147164
11  MediaToolbox                  	       0x1a720cbd0 0x1a6ee4000 + 3312592
12  MediaToolbox                  	       0x1a709f880 0x1a6ee4000 + 1816704
13  MediaToolbox                  	       0x1a70a5e98 0x1a6ee4000 + 1842840
14  libdispatch.dylib             	       0x19699d5b4 _dispatch_client_callout + 20
15  libdispatch.dylib             	       0x1969a4bd8 _dispatch_lane_serial_drain + 768
16  libdispatch.dylib             	       0x1969a5764 _dispatch_lane_invoke + 432
17  libdispatch.dylib             	       0x1969af4cc _dispatch_root_queue_drain + 392
18  libdispatch.dylib             	       0x1969af260 _dispatch_worker_thread + 260
19  libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
20  libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 16:: com.apple.coremedia.rootQueue.fP-47.mP-47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 17:: com.apple.coremedia.rootQueue.fP-47.mP-47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 18:: com.apple.coremedia.sharedRootQueue.47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 19:: com.apple.coremedia.sharedRootQueue.47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 20:: com.apple.coremedia.sharedRootQueue.48
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 21:: com.apple.coremedia.sharedRootQueue.49
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8

Thread 22:: com.apple.coremedia.rootQueue.fP-45.mP-47
0   libsystem_kernel.dylib        	       0x196b0eee8 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19699dbcc _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x19699e1cc _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1969af2a0 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x196b502e4 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x196b4b0fc thread_start + 8


Thread 0 crashed with ARM Thread State (64-bit):
    x0: 0x00000001387d49f0   x1: 0x0000000139c0ee50   x2: 0x0000000000000000   x3: 0x0000000000000001
    x4: 0x0000000139c0e2c0   x5: 0x0000000000000001   x6: 0x0000000000000002   x7: 0x00000000000009f0
    x8: 0x0000000000000000   x9: 0x0000000000000000  x10: 0x0000000000179f41  x11: 0x00000000000c97e0
   x12: 0x0000000139c03f28  x13: 0x0000000000000000  x14: 0x0000000139c00000  x15: 0x0000000090a54d34
   x16: 0x0000000000000000  x17: 0x0000000139c0ee50  x18: 0x0000000000000000  x19: 0x000000013a009000
   x20: 0x000000013a0090e8  x21: 0x00000001387d49f0  x22: 0x00000002004c0920  x23: 0x00000000a1a1a1a1
   x24: 0x0f00ffffffffffff  x25: 0xa3a3a3a3a3a3a3a3  x26: 0x0000000000000001  x27: 0x00000001fa467000
   x28: 0x00000001fe1b2000   fp: 0x000000016bc66d80   lr: 0x0000000196787d94
    sp: 0x000000016bc66d40   pc: 0x0000000196780280 cpsr: 0x00001000
   far: 0x0000000000000020  esr: 0x92000006 (Data Abort) byte read Translation fault

Binary Images:
       0x104198000 -        0x1041cbfff local.macos.macscreen (0.1.0) <9696f259-a540-3d37-a013-3aba57479aaa> /Users/USER/Desktop/*/MacScreen.app/Contents/MacOS/MacScreen
       0x104638000 -        0x104643fff libobjc-trampolines.dylib (*) <3d687e9b-e092-3632-bc1d-74b19d492de0> /usr/lib/libobjc-trampolines.dylib
       0x117000000 -        0x1176a3fff com.apple.AGXMetalG13X (324.6) <d03677d4-c896-3fd7-88c0-abed05133e06> /System/Library/Extensions/AGXMetalG13X.bundle/Contents/MacOS/AGXMetalG13X
       0x12f000000 -        0x12f8effff com.apple.audio.codecs.Components (7.0) <383b5b29-4e54-35da-a59f-a19118dfbf03> /System/Library/Components/AudioCodecs.component/Contents/MacOS/AudioCodecs
       0x12ffb4000 -        0x12ffd3fff com.apple.security.csparser (3.0) <fb85321b-0fa8-3ace-941c-abef6c37ff36> /System/Library/Frameworks/Security.framework/Versions/A/PlugIns/csparser.bundle/Contents/MacOS/csparser
       0x196778000 -        0x1967c9ca3 libobjc.A.dylib (*) <b2882096-462b-3878-be2a-410f7b1a27fd> /usr/lib/libobjc.A.dylib
       0x196bbb000 -        0x1970affff com.apple.CoreFoundation (6.9) <190e6a36-fcaa-3ea3-94bb-7009c44653da> /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation
       0x197dad000 -        0x198bf4fff com.apple.Foundation (6.9) <16d282d0-8b48-3e76-8036-fcb45dece518> /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation
       0x19a773000 -        0x19bbaffff com.apple.AppKit (6.9) <b88a44c1-d617-33dc-90ed-b6ab417c428e> /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
       0x1c588b000 -        0x1c7034fff com.apple.SwiftUI (6.3.5.1) <680539f6-0829-3a16-9151-d8345b0936d4> /System/Library/Frameworks/SwiftUI.framework/Versions/A/SwiftUI
       0x1967ca000 -        0x19684bf3f dyld (*) <398a133c-9bcb-317f-a064-a40d3cea3c0f> /usr/lib/dyld
               0x0 - 0xffffffffffffffff ??? (*) <00000000-0000-0000-0000-000000000000> ???
       0x196b49000 -        0x196b55fff libsystem_pthread.dylib (*) <642faf7a-874e-37e6-8aba-2b0cc09a3025> /usr/lib/system/libsystem_pthread.dylib
       0x196b0e000 -        0x196b48ff7 libsystem_kernel.dylib (*) <eee9d0d3-dffc-37cb-9ced-b27cd0286d8c> /usr/lib/system/libsystem_kernel.dylib
       0x1a6ee4000 -        0x1a7880fff com.apple.MediaToolbox (1.0) <1005d5b1-a18a-3133-94c7-fa613857f0ae> /System/Library/Frameworks/MediaToolbox.framework/Versions/A/MediaToolbox
       0x1a1ca2000 -        0x1a1e0cfff com.apple.CoreMedia (1.0) <3b231b1b-4beb-3f2b-819a-06d087c30c75> /System/Library/Frameworks/CoreMedia.framework/Versions/A/CoreMedia
       0x196999000 -        0x1969dffff libdispatch.dylib (*) <5576e4fd-aad2-3608-8c8f-4eec421236f9> /usr/lib/system/libdispatch.dylib
       0x1a1c7a000 -        0x1a1ca1fff com.apple.audio.caulk (1.0) <a307ba82-97de-37d1-99b7-bf68ac23c35c> /System/Library/PrivateFrameworks/caulk.framework/Versions/A/caulk
       0x1a6718000 -        0x1a6b95fff com.apple.VideoToolbox (1.0) <e592940b-133b-3bff-b7c8-afede3f3e78f> /System/Library/Frameworks/VideoToolbox.framework/Versions/A/VideoToolbox

External Modification Summary:
  Calls made by other processes targeting this process:
    task_for_pid: 0
    thread_create: 0
    thread_set_state: 0
  Calls made by this process:
    task_for_pid: 0
    thread_create: 0
    thread_set_state: 0
  Calls made by all processes on this machine:
    task_for_pid: 0
    thread_create: 0
    thread_set_state: 0

VM Region Summary:
ReadOnly portion of Libraries: Total=1.6G resident=0K(0%) swapped_out_or_unallocated=1.6G(100%)
Writable regions: Total=1.5G written=707K(0%) resident=707K(0%) swapped_out=0K(0%) unallocated=1.5G(100%)

                                VIRTUAL   REGION 
REGION TYPE                        SIZE    COUNT (non-coalesced) 
===========                     =======  ======= 
Accelerate framework               128K        1 
Activity Tracing                   256K        1 
AttributeGraph Data               1024K        1 
CG image                            96K        5 
ColorSync                          624K       31 
CoreAnimation                     1280K       80 
CoreGraphics                        32K        2 
CoreMedia memory pool             2208K        2 
CoreUI image data                  960K       14 
Dispatch continuations            80.0M        1 
Foundation                          16K        1 
Image IO                          2448K       16 
Kernel Alloc Once                   32K        1 
MALLOC                             1.4G       83 
MALLOC guard page                  384K       24 
STACK GUARD                       56.4M       23 
Stack                             19.7M       23 
VM_ALLOCATE                        304K       16 
__AUTH                            5127K      659 
__AUTH_CONST                      69.7M      900 
__CTF                               824        1 
__DATA                            24.2M      884 
__DATA_CONST                      23.8M      912 
__DATA_DIRTY                      2751K      337 
__FONT_DATA                        2352        1 
__INFO_FILTER                         8        1 
__LINKEDIT                       609.4M        6 
__OBJC_RW                         2374K        1 
__TEXT                             1.0G      932 
__TPRO_CONST                       272K        2 
mapped file                      262.2M       47 
owned unmapped memory             2496K        1 
page table in kernel               707K        1 
shared memory                      896K       15 
===========                     =======  ======= 
TOTAL                              3.5G     5025 



-----------
Full Report
-----------

{"app_name":"MacScreen","timestamp":"2026-07-09 11:19:39.00 +0800","app_version":"0.1.0","slice_uuid":"9696f259-a540-3d37-a013-3aba57479aaa","build_version":"1","platform":1,"bundleID":"local.macos.macscreen","share_with_app_devs":0,"is_first_party":0,"bug_type":"309","os_version":"macOS 15.3.1 (24D70)","roots_installed":0,"name":"MacScreen","incident_id":"27CB6E17-4B24-44BE-902B-249A64D87DD0"}
{
  "uptime" : 1500000,
  "procRole" : "Foreground",
  "version" : 2,
  "userID" : 502,
  "deployVersion" : 210,
  "modelCode" : "MacBookPro18,1",
  "coalitionID" : 241079,
  "osVersion" : {
    "train" : "macOS 15.3.1",
    "build" : "24D70",
    "releaseType" : "User"
  },
  "captureTime" : "2026-07-09 11:19:35.3032 +0800",
  "codeSigningMonitor" : 1,
  "incident" : "27CB6E17-4B24-44BE-902B-249A64D87DD0",
  "pid" : 26347,
  "translated" : false,
  "cpuType" : "ARM-64",
  "roots_installed" : 0,
  "bug_type" : "309",
  "procLaunch" : "2026-07-09 11:18:49.1415 +0800",
  "procStartAbsTime" : 38038723055315,
  "procExitAbsTime" : 38039830314341,
  "procName" : "MacScreen",
  "procPath" : "\/Users\/USER\/Desktop\/*\/MacScreen.app\/Contents\/MacOS\/MacScreen",
  "bundleInfo" : {"CFBundleShortVersionString":"0.1.0","CFBundleVersion":"1","CFBundleIdentifier":"local.macos.macscreen"},
  "storeInfo" : {"deviceIdentifierForVendor":"BDAEC9E2-2CD0-56EC-86C4-179BE8663E91","thirdParty":true},
  "parentProc" : "launchd",
  "parentPid" : 1,
  "coalitionName" : "local.macos.macscreen",
  "crashReporterKey" : "05078A0B-672D-E3BF-8EEF-9915C36184C1",
  "codeSigningID" : "MacScreen",
  "codeSigningTeamID" : "",
  "codeSigningFlags" : 570556929,
  "codeSigningValidationCategory" : 10,
  "codeSigningTrustLevel" : 4294967295,
  "instructionByteStream" : {"beforePC":"gf7\/VMADX9bAA1\/W4SU6sCEcIpFlBQAUAAAA6m3\/\/1QQAED5Aq59kg==","atPC":"URBA+TEDEDYwBAA2Ef5305H+\/7Q\/BgDxYAIAVBEg4NIRAhHL4QMQqg=="},
  "bootSessionUUID" : "BFAE7CD9-AE8A-4D35-95EB-34D88EDFBBFE",
  "wakeTime" : 4933,
  "sleepWakeUUID" : "3B169AE7-9379-469E-8F15-F6CC4482E3D2",
  "sip" : "enabled",
  "vmRegionInfo" : "0x20 is not in any region.  Bytes before following region: 4363747296\n      REGION TYPE                    START - END         [ VSIZE] PRT\/MAX SHRMOD  REGION DETAIL\n      UNUSED SPACE AT START\n--->  \n      __TEXT                      104198000-1041cc000    [  208K] r-x\/r-x SM=COW  \/Users\/USER\/Desktop\/*\/MacScreen.app\/Contents\/MacOS\/MacScreen",
  "exception" : {"codes":"0x0000000000000001, 0x0000000000000020","rawCodes":[1,32],"type":"EXC_BAD_ACCESS","signal":"SIGSEGV","subtype":"KERN_INVALID_ADDRESS at 0x0000000000000020"},
  "termination" : {"flags":0,"code":11,"namespace":"SIGNAL","indicator":"Segmentation fault: 11","byProc":"exc handler","byPid":26347},
  "vmregioninfo" : "0x20 is not in any region.  Bytes before following region: 4363747296\n      REGION TYPE                    START - END         [ VSIZE] PRT\/MAX SHRMOD  REGION DETAIL\n      UNUSED SPACE AT START\n--->  \n      __TEXT                      104198000-1041cc000    [  208K] r-x\/r-x SM=COW  \/Users\/USER\/Desktop\/*\/MacScreen.app\/Contents\/MacOS\/MacScreen",
  "extMods" : {"caller":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"system":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"targeted":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"warnings":0},
  "faultingThread" : 0,
  "threads" : [{"triggered":true,"id":104163358,"threadState":{"x":[{"value":5242702320},{"value":5263912528},{"value":0},{"value":1},{"value":5263909568},{"value":1},{"value":2},{"value":2544},{"value":0},{"value":0},{"value":1548097},{"value":825312},{"value":5263867688},{"value":0},{"value":5263851520},{"value":2426752308},{"value":0},{"value":5263912528},{"value":0},{"value":5268082688},{"value":5268082920},{"value":5242702320},{"value":8594917664,"symbolLocation":224,"symbol":"_main_thread"},{"value":2711724449},{"value":1081145385545629695},{"value":11791448172606497699},{"value":1},{"value":8493887488},{"value":8558157824,"symbolLocation":1712,"symbol":"_controlBitfieldLock"}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6819446164},"cpsr":{"value":4096},"fp":{"value":6103133568},"sp":{"value":6103133504},"esr":{"value":2449473542,"description":"(Data Abort) byte read Translation fault"},"pc":{"value":6819414656,"matchesCrashFrame":1},"far":{"value":32}},"queue":"com.apple.main-thread","frames":[{"imageOffset":33408,"symbol":"objc_release","symbolLocation":16,"imageIndex":5},{"imageOffset":64916,"symbol":"AutoreleasePoolPage::releaseUntil(objc_object**)","symbolLocation":204,"imageIndex":5},{"imageOffset":49464,"symbol":"objc_autoreleasePoolPop","symbolLocation":260,"imageIndex":5},{"imageOffset":245992,"symbol":"_CFAutoreleasePoolPop","symbolLocation":32,"imageIndex":6},{"imageOffset":201732,"symbol":"-[NSAutoreleasePool drain]","symbolLocation":136,"imageIndex":7},{"imageOffset":190628,"symbol":"-[NSApplication run]","symbolLocation":528,"imageIndex":8},{"imageOffset":20584,"symbol":"NSApplicationMain","symbolLocation":888,"imageIndex":8},{"imageOffset":309004,"symbol":"specialized runApp(_:)","symbolLocation":160,"imageIndex":9},{"imageOffset":4987296,"symbol":"runApp<A>(_:)","symbolLocation":140,"imageIndex":9},{"imageOffset":8642152,"symbol":"static App.main()","symbolLocation":224,"imageIndex":9},{"imageOffset":103700,"symbol":"static MacScreenApp.$main()","symbolLocation":40,"imageIndex":0},{"imageOffset":104168,"symbol":"main","symbolLocation":12,"imageIndex":0},{"imageOffset":25204,"symbol":"start","symbolLocation":2840,"imageIndex":10}]},{"id":104163384,"frames":[{"imageOffset":8424,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":12}],"threadState":{"x":[{"value":6104264704},{"value":10243},{"value":6103728128},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6104264704},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823391464},"far":{"value":0}}},{"id":104163385,"threadState":{"x":[{"value":4},{"value":0},{"value":1280},{"value":104165171},{"value":73896},{"value":529412},{"value":6104833332},{"value":6104833320},{"value":5264951831},{"value":5264951824},{"value":5264951816},{"value":104163385},{"value":5497558140162},{"value":5497558140418},{"value":104165171},{"value":8595014928,"symbolLocation":0,"symbol":"OBJC_CLASS_$___CFNotification"},{"value":301},{"value":8735695496},{"value":0},{"value":5264951792},{"value":5497558140418},{"value":1280},{"value":5264951816},{"value":104163385},{"value":5264951824},{"value":5241848856},{"value":0},{"value":3156800962915},{"value":6104833432}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6823400440},"cpsr":{"value":1610616832},"fp":{"value":6104833168},"sp":{"value":6104833120},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823156668},"far":{"value":0}},"queue":"com.apple.coremedia.videolayer.notificationqueue","frames":[{"imageOffset":15292,"symbol":"__psynch_mutexwait","symbolLocation":8,"imageIndex":13},{"imageOffset":17400,"symbol":"_pthread_mutex_firstfit_lock_wait","symbolLocation":84,"imageIndex":12},{"imageOffset":7612,"symbol":"_pthread_mutex_firstfit_lock_slow","symbolLocation":220,"imageIndex":12},{"imageOffset":2096508,"imageIndex":14},{"imageOffset":467884,"symbol":"__CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__","symbolLocation":208,"imageIndex":6},{"imageOffset":1061388,"symbol":"___CFXRegistrationPost_block_invoke","symbolLocation":88,"imageIndex":6},{"imageOffset":1061204,"symbol":"_CFXRegistrationPost","symbolLocation":436,"imageIndex":6},{"imageOffset":266156,"symbol":"_CFXNotificationPost","symbolLocation":732,"imageIndex":6},{"imageOffset":468044,"symbol":"CFNotificationCenterPostNotificationWithOptions","symbolLocation":136,"imageIndex":6},{"imageOffset":33960,"symbol":"CMNotificationCenterPostNotification","symbolLocation":128,"imageIndex":15},{"imageOffset":10324,"symbol":"_dispatch_call_block_and_release","symbolLocation":32,"imageIndex":16},{"imageOffset":17844,"symbol":"_dispatch_client_callout","symbolLocation":20,"imageIndex":16},{"imageOffset":48088,"symbol":"_dispatch_lane_serial_drain","symbolLocation":768,"imageIndex":16},{"imageOffset":50992,"symbol":"_dispatch_lane_invoke","symbolLocation":380,"imageIndex":16},{"imageOffset":96672,"symbol":"_dispatch_root_queue_drain_deferred_wlh","symbolLocation":288,"imageIndex":16},{"imageOffset":94700,"symbol":"_dispatch_workloop_worker_thread","symbolLocation":540,"imageIndex":16},{"imageOffset":13272,"symbol":"_pthread_wqthread","symbolLocation":288,"imageIndex":12},{"imageOffset":8432,"symbol":"start_wqthread","symbolLocation":8,"imageIndex":12}]},{"id":104163420,"frames":[{"imageOffset":8424,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":12}],"threadState":{"x":[{"value":6105411584},{"value":48903},{"value":6104875008},{"value":0},{"value":409602},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6105411584},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823391464},"far":{"value":0}}},{"id":104163421,"name":"com.apple.NSEventThread","threadState":{"x":[{"value":268451845},{"value":21592279046},{"value":8589934592},{"value":166056320565248},{"value":0},{"value":166056320565248},{"value":2},{"value":4294967295},{"value":18446744073709550527},{"value":2},{"value":0},{"value":0},{"value":0},{"value":38663},{"value":0},{"value":0},{"value":18446744073709551569},{"value":8735677944},{"value":0},{"value":4294967295},{"value":2},{"value":166056320565248},{"value":0},{"value":166056320565248},{"value":6105981032},{"value":8589934592},{"value":21592279046},{"value":21592279046},{"value":4412409862}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6823220740},"cpsr":{"value":4096},"fp":{"value":6105980880},"sp":{"value":6105980800},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145300},"far":{"value":0}},"frames":[{"imageOffset":3924,"symbol":"mach_msg2_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":79364,"symbol":"mach_msg2_internal","symbolLocation":80,"imageIndex":13},{"imageOffset":39672,"symbol":"mach_msg_overwrite","symbolLocation":480,"imageIndex":13},{"imageOffset":4764,"symbol":"mach_msg","symbolLocation":24,"imageIndex":13},{"imageOffset":514636,"symbol":"__CFRunLoopServiceMachPort","symbolLocation":160,"imageIndex":6},{"imageOffset":508588,"symbol":"__CFRunLoopRun","symbolLocation":1212,"imageIndex":6},{"imageOffset":505652,"symbol":"CFRunLoopRunSpecific","symbolLocation":588,"imageIndex":6},{"imageOffset":1442424,"symbol":"_NSEventThread","symbolLocation":148,"imageIndex":8},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104163603,"frames":[{"imageOffset":8424,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":12}],"threadState":{"x":[{"value":6108278784},{"value":53255},{"value":6107742208},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6108278784},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823391464},"far":{"value":0}}},{"id":104163604,"frames":[{"imageOffset":8424,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":12}],"threadState":{"x":[{"value":6108852224},{"value":0},{"value":6108315648},{"value":0},{"value":278532},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6108852224},"esr":{"value":0,"description":" Address size fault"},"pc":{"value":6823391464},"far":{"value":0}}},{"id":104163605,"name":"caulk.messenger.shared:17","threadState":{"x":[{"value":14},{"value":5263900442},{"value":0},{"value":6109425770},{"value":5263900416},{"value":25},{"value":0},{"value":0},{"value":0},{"value":4294967295},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":18446744073709551580},{"value":8735684328},{"value":0},{"value":5263959952},{"value":5263959952},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":7009189876},"cpsr":{"value":2147487744},"fp":{"value":6109425536},"sp":{"value":6109425504},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145168},"far":{"value":0}},"frames":[{"imageOffset":3792,"symbol":"semaphore_wait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":8180,"symbol":"caulk::semaphore::timed_wait(double)","symbolLocation":220,"imageIndex":17},{"imageOffset":7840,"symbol":"caulk::concurrent::details::worker_thread::run()","symbolLocation":36,"imageIndex":17},{"imageOffset":7028,"symbol":"void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*)","symbolLocation":96,"imageIndex":17},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104163606,"name":"caulk.messenger.shared:high","threadState":{"x":[{"value":14},{"value":5263923516},{"value":0},{"value":6109999212},{"value":5263923488},{"value":27},{"value":0},{"value":0},{"value":0},{"value":4294967295},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":18446744073709551580},{"value":8735684328},{"value":0},{"value":5263923312},{"value":5263923312},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":7009189876},"cpsr":{"value":2147487744},"fp":{"value":6109998976},"sp":{"value":6109998944},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145168},"far":{"value":0}},"frames":[{"imageOffset":3792,"symbol":"semaphore_wait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":8180,"symbol":"caulk::semaphore::timed_wait(double)","symbolLocation":220,"imageIndex":17},{"imageOffset":7840,"symbol":"caulk::concurrent::details::worker_thread::run()","symbolLocation":36,"imageIndex":17},{"imageOffset":7028,"symbol":"void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*)","symbolLocation":96,"imageIndex":17},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104163664,"name":"com.apple.coremedia.imagequeue.coreanimation.common","threadState":{"x":[{"value":260},{"value":0},{"value":352256},{"value":0},{"value":0},{"value":65704},{"value":0},{"value":16665666},{"value":6116879672},{"value":0},{"value":0},{"value":2},{"value":2},{"value":0},{"value":0},{"value":0},{"value":305},{"value":8735695480},{"value":0},{"value":4696896832},{"value":5259815256},{"value":6116880608},{"value":16665666},{"value":0},{"value":352256},{"value":561409},{"value":561664},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6823413908},"cpsr":{"value":1610616832},"fp":{"value":6116879792},"sp":{"value":6116879648},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823159532},"far":{"value":0}},"frames":[{"imageOffset":18156,"symbol":"__psynch_cvwait","symbolLocation":8,"imageIndex":13},{"imageOffset":30868,"symbol":"_pthread_cond_wait","symbolLocation":1204,"imageIndex":12},{"imageOffset":132084,"symbol":"WaitOnConditionTimed","symbolLocation":76,"imageIndex":15},{"imageOffset":46820,"symbol":"FigSemaphoreWaitRelative","symbolLocation":172,"imageIndex":15},{"imageOffset":4763688,"imageIndex":14},{"imageOffset":131080,"symbol":"figThreadMain","symbolLocation":224,"imageIndex":15},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104163665,"name":"com.apple.coremedia.videomediaconverter","threadState":{"x":[{"value":260},{"value":0},{"value":590848},{"value":0},{"value":0},{"value":65704},{"value":0},{"value":999999000},{"value":6117451800},{"value":0},{"value":15616},{"value":67070209309954},{"value":67070209309954},{"value":15616},{"value":0},{"value":67070209309952},{"value":305},{"value":8735695480},{"value":0},{"value":4697036992},{"value":4697036904},{"value":6117454048},{"value":999999000},{"value":0},{"value":590848},{"value":590849},{"value":591104},{"value":4294954504},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6823413908},"cpsr":{"value":1610616832},"fp":{"value":6117451920},"sp":{"value":6117451776},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823159532},"far":{"value":0}},"frames":[{"imageOffset":18156,"symbol":"__psynch_cvwait","symbolLocation":8,"imageIndex":13},{"imageOffset":30868,"symbol":"_pthread_cond_wait","symbolLocation":1204,"imageIndex":12},{"imageOffset":132084,"symbol":"WaitOnConditionTimed","symbolLocation":76,"imageIndex":15},{"imageOffset":46820,"symbol":"FigSemaphoreWaitRelative","symbolLocation":172,"imageIndex":15},{"imageOffset":2310940,"imageIndex":18},{"imageOffset":158336,"imageIndex":18},{"imageOffset":146944,"imageIndex":18},{"imageOffset":1085704,"imageIndex":14},{"imageOffset":4724036,"imageIndex":14},{"imageOffset":131080,"symbol":"figThreadMain","symbolLocation":224,"imageIndex":15},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104163711,"name":"com.apple.coremedia.rootQueue.fP-48.mP-47","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":4982102272},{"value":2},{"value":2},{"value":1027},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":4981800748},{"value":1},{"value":4981784576},{"value":1320198},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950235458},{"value":4982041200},{"value":1000000000},{"value":6171996384},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6171995968},"sp":{"value":6171995936},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104163712,"name":"com.apple.coremedia.rootQueue.fP-48.mP-47","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":1},{"value":0},{"value":0},{"value":1027},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":4982089624},{"value":5260880000},{"value":8594931080,"symbolLocation":0,"symbol":"OBJC_CLASS_$_OS_voucher"},{"value":8594931080,"symbolLocation":0,"symbol":"OBJC_CLASS_$_OS_voucher"},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039942870999},{"value":4982041200},{"value":1000000000},{"value":6172569824},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6172569408},"sp":{"value":6172569376},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104164626,"name":"com.apple.coremedia.sharedRootQueue.47","threadState":{"x":[{"value":14},{"value":5},{"value":0},{"value":68719460488},{"value":8594929712,"symbolLocation":48,"symbol":"_OS_dispatch_queue_serial_vtable"},{"value":0},{"value":0},{"value":1027},{"value":0},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":4697041256},{"value":65519},{"value":9005137670438912},{"value":9005137670438912},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950236001},{"value":5263437664},{"value":1000000000},{"value":6106558688},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6106558272},"sp":{"value":6106558240},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104165167,"name":"com.apple.coremedia.sharedRootQueue.47","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":172674865170947},{"value":0},{"value":2},{"value":0},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":4696786808},{"value":0},{"value":2199023259648},{"value":144115188344294016},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950219533},{"value":5263437664},{"value":1000000000},{"value":6103691488},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6103691072},"sp":{"value":6103691040},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"threadState":{"x":[{"value":4},{"value":0},{"value":0},{"value":104163665},{"value":8352},{"value":4},{"value":2},{"value":0},{"value":4982042423},{"value":4982042416},{"value":4982042408},{"value":104165171},{"value":2},{"value":258},{"value":4981784576},{"value":2251227135},{"value":301},{"value":8735695496},{"value":0},{"value":4982042384},{"value":258},{"value":0},{"value":4982042408},{"value":104165171},{"value":4982042416},{"value":4982041696},{"value":0},{"value":6107130400},{"value":6107129936}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6823400440},"cpsr":{"value":1610616832},"fp":{"value":6107129472},"sp":{"value":6107129424},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823156668},"far":{"value":0}},"id":104165171,"name":"com.apple.coremedia.rootQueue.fP-45.mP-47","queue":"*\/QZ","frames":[{"imageOffset":15292,"symbol":"__psynch_mutexwait","symbolLocation":8,"imageIndex":13},{"imageOffset":17400,"symbol":"_pthread_mutex_firstfit_lock_wait","symbolLocation":84,"imageIndex":12},{"imageOffset":7612,"symbol":"_pthread_mutex_firstfit_lock_slow","symbolLocation":220,"imageIndex":12},{"imageOffset":92440,"symbol":"VMC2WaitUntilCompletelyStopped","symbolLocation":96,"imageIndex":14},{"imageOffset":90960,"symbol":"VMC2Invalidate","symbolLocation":60,"imageIndex":14},{"imageOffset":2890336,"imageIndex":14},{"imageOffset":1955172,"imageIndex":14},{"imageOffset":2070752,"imageIndex":14},{"imageOffset":2137028,"imageIndex":14},{"imageOffset":7094260,"imageIndex":14},{"imageOffset":4147164,"imageIndex":14},{"imageOffset":3312592,"imageIndex":14},{"imageOffset":1816704,"imageIndex":14},{"imageOffset":1842840,"imageIndex":14},{"imageOffset":17844,"symbol":"_dispatch_client_callout","symbolLocation":20,"imageIndex":16},{"imageOffset":48088,"symbol":"_dispatch_lane_serial_drain","symbolLocation":768,"imageIndex":16},{"imageOffset":51044,"symbol":"_dispatch_lane_invoke","symbolLocation":432,"imageIndex":16},{"imageOffset":91340,"symbol":"_dispatch_root_queue_drain","symbolLocation":392,"imageIndex":16},{"imageOffset":90720,"symbol":"_dispatch_worker_thread","symbolLocation":260,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104165172,"name":"com.apple.coremedia.rootQueue.fP-47.mP-47","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":4966374976},{"value":4},{"value":2},{"value":1027},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":4697362216},{"value":3},{"value":4966055936},{"value":269484032},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950237259},{"value":5260529872},{"value":1000000000},{"value":6107705568},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6107705152},"sp":{"value":6107705120},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104165173,"name":"com.apple.coremedia.rootQueue.fP-47.mP-47","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":5263537200},{"value":7},{"value":2},{"value":0},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":4697002136},{"value":6},{"value":5262802944},{"value":139010440},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950236707},{"value":5260529872},{"value":1000000000},{"value":6110572768},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6110572352},"sp":{"value":6110572320},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104165174,"name":"com.apple.coremedia.sharedRootQueue.47","threadState":{"x":[{"value":14},{"value":4294966759129088004},{"value":999999875},{"value":68719460488},{"value":15534896709632},{"value":389274360872960},{"value":44},{"value":0},{"value":999999875},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":0},{"value":0},{"value":0},{"value":0},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950219483},{"value":5263437664},{"value":1000000000},{"value":6111719648},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6111719232},"sp":{"value":6111719200},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104165175,"name":"com.apple.coremedia.sharedRootQueue.47","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":5263013680},{"value":4},{"value":2},{"value":1027},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":5263687704},{"value":3},{"value":5262802944},{"value":1359513665},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950277771},{"value":5263437664},{"value":1000000000},{"value":6111146208},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6111145792},"sp":{"value":6111145760},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104165176,"name":"com.apple.coremedia.sharedRootQueue.48","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":8594929704,"symbolLocation":40,"symbol":"_OS_dispatch_queue_serial_vtable"},{"value":3},{"value":0},{"value":0},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":4696812696},{"value":274877906945},{"value":9005618706776065},{"value":9005618706776065},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950276315},{"value":4966332960},{"value":1000000000},{"value":6112293088},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6112292672},"sp":{"value":6112292640},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104165177,"name":"com.apple.coremedia.sharedRootQueue.49","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":5263987520},{"value":1},{"value":2},{"value":6112862536},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":4697476664},{"value":2},{"value":5263851520},{"value":1280926720},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950277042},{"value":5242355984},{"value":1000000000},{"value":6112866528},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6112866112},"sp":{"value":6112866080},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]},{"id":104165178,"name":"com.apple.coremedia.rootQueue.fP-45.mP-47","threadState":{"x":[{"value":14},{"value":4294967115611373572},{"value":999999958},{"value":68719460488},{"value":5266153120},{"value":2},{"value":2},{"value":7102689428},{"value":999999958},{"value":12297829382473034411},{"value":13835058055282163714},{"value":80000000},{"value":5266089176},{"value":1},{"value":5265948672},{"value":52},{"value":18446744073709551578},{"value":8735697560},{"value":0},{"value":38039950281819},{"value":5261942432},{"value":1000000000},{"value":6113439968},{"value":0},{"value":0},{"value":18446744071427850239},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6821632972},"cpsr":{"value":2147487744},"fp":{"value":6113439552},"sp":{"value":6113439520},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6823145192},"far":{"value":0}},"frames":[{"imageOffset":3816,"symbol":"semaphore_timedwait_trap","symbolLocation":8,"imageIndex":13},{"imageOffset":19404,"symbol":"_dispatch_sema4_timedwait","symbolLocation":64,"imageIndex":16},{"imageOffset":20940,"symbol":"_dispatch_semaphore_wait_slow","symbolLocation":76,"imageIndex":16},{"imageOffset":90784,"symbol":"_dispatch_worker_thread","symbolLocation":324,"imageIndex":16},{"imageOffset":29412,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":12},{"imageOffset":8444,"symbol":"thread_start","symbolLocation":8,"imageIndex":12}]}],
  "usedImages" : [
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4363747328,
    "CFBundleShortVersionString" : "0.1.0",
    "CFBundleIdentifier" : "local.macos.macscreen",
    "size" : 212992,
    "uuid" : "9696f259-a540-3d37-a013-3aba57479aaa",
    "path" : "\/Users\/USER\/Desktop\/*\/MacScreen.app\/Contents\/MacOS\/MacScreen",
    "name" : "MacScreen",
    "CFBundleVersion" : "1"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 4368596992,
    "size" : 49152,
    "uuid" : "3d687e9b-e092-3632-bc1d-74b19d492de0",
    "path" : "\/usr\/lib\/libobjc-trampolines.dylib",
    "name" : "libobjc-trampolines.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 4680843264,
    "CFBundleShortVersionString" : "324.6",
    "CFBundleIdentifier" : "com.apple.AGXMetalG13X",
    "size" : 6963200,
    "uuid" : "d03677d4-c896-3fd7-88c0-abed05133e06",
    "path" : "\/System\/Library\/Extensions\/AGXMetalG13X.bundle\/Contents\/MacOS\/AGXMetalG13X",
    "name" : "AGXMetalG13X",
    "CFBundleVersion" : "324.6"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 5083496448,
    "CFBundleShortVersionString" : "7.0",
    "CFBundleIdentifier" : "com.apple.audio.codecs.Components",
    "size" : 9371648,
    "uuid" : "383b5b29-4e54-35da-a59f-a19118dfbf03",
    "path" : "\/System\/Library\/Components\/AudioCodecs.component\/Contents\/MacOS\/AudioCodecs",
    "name" : "AudioCodecs",
    "CFBundleVersion" : "7.0"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 5099962368,
    "CFBundleShortVersionString" : "3.0",
    "CFBundleIdentifier" : "com.apple.security.csparser",
    "size" : 131072,
    "uuid" : "fb85321b-0fa8-3ace-941c-abef6c37ff36",
    "path" : "\/System\/Library\/Frameworks\/Security.framework\/Versions\/A\/PlugIns\/csparser.bundle\/Contents\/MacOS\/csparser",
    "name" : "csparser",
    "CFBundleVersion" : "61439.81.1"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6819381248,
    "size" : 335012,
    "uuid" : "b2882096-462b-3878-be2a-410f7b1a27fd",
    "path" : "\/usr\/lib\/libobjc.A.dylib",
    "name" : "libobjc.A.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6823849984,
    "CFBundleShortVersionString" : "6.9",
    "CFBundleIdentifier" : "com.apple.CoreFoundation",
    "size" : 5197824,
    "uuid" : "190e6a36-fcaa-3ea3-94bb-7009c44653da",
    "path" : "\/System\/Library\/Frameworks\/CoreFoundation.framework\/Versions\/A\/CoreFoundation",
    "name" : "CoreFoundation",
    "CFBundleVersion" : "3302.1.400"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6842667008,
    "CFBundleShortVersionString" : "6.9",
    "CFBundleIdentifier" : "com.apple.Foundation",
    "size" : 14974976,
    "uuid" : "16d282d0-8b48-3e76-8036-fcb45dece518",
    "path" : "\/System\/Library\/Frameworks\/Foundation.framework\/Versions\/C\/Foundation",
    "name" : "Foundation",
    "CFBundleVersion" : "3302.1.400"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6886469632,
    "CFBundleShortVersionString" : "6.9",
    "CFBundleIdentifier" : "com.apple.AppKit",
    "size" : 21221376,
    "uuid" : "b88a44c1-d617-33dc-90ed-b6ab417c428e",
    "path" : "\/System\/Library\/Frameworks\/AppKit.framework\/Versions\/C\/AppKit",
    "name" : "AppKit",
    "CFBundleVersion" : "2575.40.6"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7609036800,
    "CFBundleShortVersionString" : "6.3.5.1",
    "CFBundleIdentifier" : "com.apple.SwiftUI",
    "size" : 24813568,
    "uuid" : "680539f6-0829-3a16-9151-d8345b0936d4",
    "path" : "\/System\/Library\/Frameworks\/SwiftUI.framework\/Versions\/A\/SwiftUI",
    "name" : "SwiftUI",
    "CFBundleVersion" : "6.3.5.1"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6819717120,
    "size" : 532288,
    "uuid" : "398a133c-9bcb-317f-a064-a40d3cea3c0f",
    "path" : "\/usr\/lib\/dyld",
    "name" : "dyld"
  },
  {
    "size" : 0,
    "source" : "A",
    "base" : 0,
    "uuid" : "00000000-0000-0000-0000-000000000000"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6823383040,
    "size" : 53248,
    "uuid" : "642faf7a-874e-37e6-8aba-2b0cc09a3025",
    "path" : "\/usr\/lib\/system\/libsystem_pthread.dylib",
    "name" : "libsystem_pthread.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6823141376,
    "size" : 241656,
    "uuid" : "eee9d0d3-dffc-37cb-9ced-b27cd0286d8c",
    "path" : "\/usr\/lib\/system\/libsystem_kernel.dylib",
    "name" : "libsystem_kernel.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7095599104,
    "CFBundleShortVersionString" : "1.0",
    "CFBundleIdentifier" : "com.apple.MediaToolbox",
    "size" : 10080256,
    "uuid" : "1005d5b1-a18a-3133-94c7-fa613857f0ae",
    "path" : "\/System\/Library\/Frameworks\/MediaToolbox.framework\/Versions\/A\/MediaToolbox",
    "name" : "MediaToolbox",
    "CFBundleVersion" : "3200.5.1"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7009345536,
    "CFBundleShortVersionString" : "1.0",
    "CFBundleIdentifier" : "com.apple.CoreMedia",
    "size" : 1486848,
    "uuid" : "3b231b1b-4beb-3f2b-819a-06d087c30c75",
    "path" : "\/System\/Library\/Frameworks\/CoreMedia.framework\/Versions\/A\/CoreMedia",
    "name" : "CoreMedia",
    "CFBundleVersion" : "3200.5.1"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6821613568,
    "size" : 290816,
    "uuid" : "5576e4fd-aad2-3608-8c8f-4eec421236f9",
    "path" : "\/usr\/lib\/system\/libdispatch.dylib",
    "name" : "libdispatch.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7009181696,
    "CFBundleShortVersionString" : "1.0",
    "CFBundleIdentifier" : "com.apple.audio.caulk",
    "size" : 163840,
    "uuid" : "a307ba82-97de-37d1-99b7-bf68ac23c35c",
    "path" : "\/System\/Library\/PrivateFrameworks\/caulk.framework\/Versions\/A\/caulk",
    "name" : "caulk"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 7087423488,
    "CFBundleShortVersionString" : "1.0",
    "CFBundleIdentifier" : "com.apple.VideoToolbox",
    "size" : 4710400,
    "uuid" : "e592940b-133b-3bff-b7c8-afede3f3e78f",
    "path" : "\/System\/Library\/Frameworks\/VideoToolbox.framework\/Versions\/A\/VideoToolbox",
    "name" : "VideoToolbox",
    "CFBundleVersion" : "3200.5.1"
  }
],
  "sharedCache" : {
  "base" : 6818906112,
  "size" : 4865835008,
  "uuid" : "d272b91e-f9f0-3854-b5b9-508b21c25dcc"
},
  "vmSummary" : "ReadOnly portion of Libraries: Total=1.6G resident=0K(0%) swapped_out_or_unallocated=1.6G(100%)\nWritable regions: Total=1.5G written=707K(0%) resident=707K(0%) swapped_out=0K(0%) unallocated=1.5G(100%)\n\n                                VIRTUAL   REGION \nREGION TYPE                        SIZE    COUNT (non-coalesced) \n===========                     =======  ======= \nAccelerate framework               128K        1 \nActivity Tracing                   256K        1 \nAttributeGraph Data               1024K        1 \nCG image                            96K        5 \nColorSync                          624K       31 \nCoreAnimation                     1280K       80 \nCoreGraphics                        32K        2 \nCoreMedia memory pool             2208K        2 \nCoreUI image data                  960K       14 \nDispatch continuations            80.0M        1 \nFoundation                          16K        1 \nImage IO                          2448K       16 \nKernel Alloc Once                   32K        1 \nMALLOC                             1.4G       83 \nMALLOC guard page                  384K       24 \nSTACK GUARD                       56.4M       23 \nStack                             19.7M       23 \nVM_ALLOCATE                        304K       16 \n__AUTH                            5127K      659 \n__AUTH_CONST                      69.7M      900 \n__CTF                               824        1 \n__DATA                            24.2M      884 \n__DATA_CONST                      23.8M      912 \n__DATA_DIRTY                      2751K      337 \n__FONT_DATA                        2352        1 \n__INFO_FILTER                         8        1 \n__LINKEDIT                       609.4M        6 \n__OBJC_RW                         2374K        1 \n__TEXT                             1.0G      932 \n__TPRO_CONST                       272K        2 \nmapped file                      262.2M       47 \nowned unmapped memory             2496K        1 \npage table in kernel               707K        1 \nshared memory                      896K       15 \n===========                     =======  ======= \nTOTAL                              3.5G     5025 \n",
  "legacyInfo" : {
  "threadTriggered" : {
    "queue" : "com.apple.main-thread"
  }
},
  "logWritingSignature" : "32e576d2eda5625443fbee18ef21611051b44616",
  "trialInfo" : {
  "rollouts" : [
    {
      "rolloutId" : "67d07cd6a7affa169ae21f45",
      "factorPackIds" : {

      },
      "deploymentId" : 240000002
    },
    {
      "rolloutId" : "661464ecda55e5192b100804",
      "factorPackIds" : {

      },
      "deploymentId" : 240000005
    }
  ],
  "experiments" : [

  ]
}
}

Model: MacBookPro18,1, BootROM 11881.101.1, proc 10:8:2 processors, 16 GB, SMC 
Graphics: Apple M1 Pro, Apple M1 Pro, Built-In
Display: DELL U2419H, 1920 x 1080 (1080p FHD - Full High Definition), Main, MirrorOn, Online
Display: Color LCD, 3456 x 2234 Retina, MirrorOn, Online
Memory Module: LPDDR5, Samsung
AirPort: spairport_wireless_card_type_wifi (0x14E4, 0x4387), wl0: Oct 31 2024 06:06:06 version 20.10.1135.4.8.7.191 FWID 01-e648b845
IO80211_driverkit-1345.10 "IO80211_driverkit-1345.10" Dec 14 2024 17:47:07
AirPort: 
Bluetooth: Version (null), 0 services, 0 devices, 0 incoming serial ports
Network Service: AX88179B, Ethernet, en7
Network Service: Wi-Fi, AirPort, en0
USB Device: USB31Bus
USB Device: USB31Bus
USB Device: USB3.1 Hub
USB Device: AX88179B
USB Device: USB2.1 Hub
USB Device: USB31Bus
Thunderbolt Bus: MacBook Pro, Apple Inc.
Thunderbolt Bus: MacBook Pro, Apple Inc.
Thunderbolt Bus: MacBook Pro, Apple Inc.
