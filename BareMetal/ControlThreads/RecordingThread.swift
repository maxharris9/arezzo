//
//  RecordingThread.swift
//  BareMetal
//
//  Created by Max Harris on 11/30/20.
//  Copyright © 2020 Max Harris. All rights reserved.
//

import AudioToolbox
import Foundation

extension ViewController {
    @objc func recording(thread _: Thread) {
        print("self.recordingThread.isCancelled:", self.recordingThread.isCancelled)

        var recordingState: RecordingState = RecordingState()
        var queue: AudioQueueRef?

        check(AudioQueueNewInput(&audioFormat, inputCallback, &recordingState, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue, 0, &queue))

        var buffers: [AudioQueueBufferRef?] = Array<AudioQueueBufferRef?>.init(repeating: nil, count: BUFFER_COUNT)

        print("Recording\n")
        recordingState.running = true

        for i in 0 ..< BUFFER_COUNT {
            check(AudioQueueAllocateBuffer(queue!, UInt32(bufferByteSize), &buffers[i]))
            var bs = AudioTimeStamp()
            inputCallback(inUserData: &recordingState, inQueue: queue!, inBuffer: buffers[i]!, inStartTime: &bs, inNumPackets: 0, inPacketDesc: nil)

            if !recordingState.running {
                break
            }
        }

        check(AudioQueueStart(queue!, nil))

        repeat {
            print("self.recordingThread.isCancelled:", self.recordingThread.isCancelled)
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, BUFFER_DURATION, false)
        } while !self.recordingThread.isCancelled

        self.recordingState.running = false
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, BUFFER_DURATION * Double(BUFFER_COUNT + 1), false)

        check(AudioQueueStop(queue!, true))
        check(AudioQueueDispose(queue!, true))
    }
}
