//
//  Toolbar.swift
//  BareMetal
//
//  Created by Max Harris on 8/13/20.
//  Copyright © 2020 Max Harris. All rights reserved.
//

import SwiftUI

struct VerticalSlider: View {
    @Binding var value: Float
    var sliderHeight: CGFloat

    var body: some View {
        Slider(
            value: $value,
            in: 1.0 ... 10.0,
            step: 0.5
        )
        .frame(width: sliderHeight, height: 30)
        .rotationEffect(.degrees(-90.0), anchor: .center)
        .frame(width: 30, height: sliderHeight)
    }
}

struct ToolbarItems: View {
    @ObservedObject var delegate: ContentViewDelegate

    var body: some View {
        HStack(spacing: 10) {
            Button("Clear") {
                self.delegate.clear = true
            }
            Button("Undo") {}
            Button("Redo") {}

            self.delegate.mode == "pan" ? Button("Draw") {
                self.delegate.mode = "draw"
            } : Button("Pan") {
                self.delegate.mode = "pan"
            }

            self.delegate.recording ? Button("Stop Recording") {
                self.delegate.recording = false
            } : Button("Record") {
                self.delegate.recording = true
            }
            self.delegate.playing ? Button("Stop Playing") {
                self.delegate.playing = false
            } : Button("Play") {
                self.delegate.playing = true
            }

            VerticalSlider(value: $delegate.strokeWidth, sliderHeight: 80)

            ColorPickerPopover(selectedColor: $delegate.selectedColor, uiRects: $delegate.uiRects)
            // SoundControl(audioRecorder: AudioRecorder()).background(Color.clear)
        }
    }
}

struct Toolbar: View {
    @ObservedObject var delegate: ContentViewDelegate

    init(delegate: ContentViewDelegate) {
        self.delegate = delegate
    }

    @State private var currentPosition: CGSize = .zero
    @State private var newPosition: CGSize = .zero
    @State private var tapped = false
    @State private var hovered = true

    var body: some View {
        let circleDragGesture = DragGesture(minimumDistance: 0.0, coordinateSpace: CoordinateSpace.global)
            .onChanged { value in
                self.currentPosition = CGSize(
                    width: value.translation.width + self.newPosition.width,
                    height: value.translation.height + self.newPosition.height
                )
                self.tapped = true
            }
            .onEnded { value in
                self.currentPosition = CGSize(
                    width: value.translation.width + self.newPosition.width,
                    height: value.translation.height + self.newPosition.height
                )
                print(self.newPosition.width)
                self.newPosition = self.currentPosition
                self.tapped = false
            }

        let scale: CGFloat = 1.0 // tapped ? 1.3 : 1.0

//        return !hovered ? Circle()
//                    .frame(width: 60.0 * scale, height: 60.0 * scale)
//                    .foregroundColor(Color.white)
//                    .shadow(color: Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 1.0), radius: 10)
//                    .background(GeometryGetter(rects: $delegate.uiRects, key: "tool"))
//                    .offset(x: self.currentPosition.width, y: self.currentPosition.height)
//                    .onTapGesture {
//                        self.tapped.toggle()
//                    }
//                    .gesture(circleDragGesture)

        return AnyView(
            ZStack {
                Rectangle()
                    .frame(width: 420 * scale, height: 100 * scale)
                    .foregroundColor(Color.white)
                    .background(GeometryGetter(rects: $delegate.uiRects, key: "tool"))
                    .shadow(color: Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 1.0), radius: 10)
                    .drawingGroup()
                    .gesture(circleDragGesture)
                ToolbarItems(delegate: self.delegate)
            }.offset(x: self.currentPosition.width, y: self.currentPosition.height)
        )
    }
}
