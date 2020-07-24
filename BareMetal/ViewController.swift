//
//  ViewController.swift
//  BareMetal
//
//  Created by Max Harris on 6/26/20.
//  Copyright © 2020 Max Harris. All rights reserved.
//

import Metal
import QuartzCore
import simd // vector_float2, vector_float4
import UIKit

struct CubicBezierParameters {
    static let coordinateRange: Float = 1.0

    var a: vector_float2 = vector_float2()
    var b: vector_float2 = vector_float2()
    var p1: vector_float2 = vector_float2()
    var p2: vector_float2 = vector_float2()

    var lineWidth: Float = 0.050

    var color: vector_float4 = vector_float4()
    var timestamp: Int64 = 0
    var elementsPerInstance: Int = 128

    init(start: vector_float2, end: vector_float2, control1: vector_float2, control2: vector_float2, itemColor: vector_float4, ts: Int64) {
        a = start
        b = end
        p1 = control1
        p2 = control2
        color = itemColor
        timestamp = ts
    }
}

struct QuadraticBezierParameters {
    static let coordinateRange: Float = 1.0

    var a: vector_float2 = vector_float2()
    var b: vector_float2 = vector_float2()
    var p: vector_float2 = vector_float2()

    var lineWidth: Float = 0.050

    var color: vector_float4 = vector_float4()
    var timestamp: Int64 = 0

    var elementsPerInstance: Int = 128

    init(start: vector_float2, end: vector_float2, control: vector_float2, itemColor: vector_float4, ts: Int64) {
        a = start
        b = end
        p = control
        color = itemColor
        timestamp = ts
    }
}

public extension Float {
    static func r(n: Float, tol: Float) -> Float {
        let low = n - tol
        let high = n + tol
        return tol == 0 || low > high ? n : Float.random(in: low ..< high)
    }
}

extension Date {
    func toMilliseconds() -> Int64 {
        Int64(timeIntervalSince1970 * 1000)
    }
}

class ViewController: UIViewController {
    var device: MTLDevice!
    var metalLayer: CAMetalLayer
    var vertexBuffer: MTLBuffer!
    var quadraticBezierBuffer: MTLBuffer!
    var cubicBezierBuffer: MTLBuffer!
    var vertexColorBuffer: MTLBuffer!
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    var timer: CADisplayLink!
    var shapeIndex: [Int] = []

    var vertexCount: Int = 0

    required init?(coder aDecoder: NSCoder) {
        metalLayer = CAMetalLayer()

        super.init(coder: aDecoder)
    }

    @objc override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        device = MTLCreateSystemDefaultDevice()

        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)

        guard let defaultLibrary = device.makeDefaultLibrary() else { return }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "basic_vertex")
        pipelineStateDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "basic_fragment")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            try renderPipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Failed to create pipeline state, error \(error)")
        }

        commandQueue = device.makeCommandQueue() // this is expensive to create, so we save a reference to it

        timer = CADisplayLink(target: self, selector: #selector(ViewController.gameloop))
        timer.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }

    func addCubicBezier(
        start: [Float], c1: [Float], c2: [Float], end: [Float], options: BezierTesselationOptions, vertexData: inout [Float]
    ) {
        let cubicBezier = CubicBezierTesselator(start: start, c1: c1, c2: c2, end: end, existingPoints: [], options: options)
        let cubicBezierTriangles = cubicBezier.dumpTriangleStrip()

        shapeIndex.append(cubicBezierTriangles.count / 3)
        vertexData.append(contentsOf: cubicBezierTriangles)
    }

    func generateVerts() {
        let bezierOptions = BezierTesselationOptions(
            curveAngleToleranceEpsilon: 0.3, mAngleTolerance: 0.2, mCuspLimit: 0.0, thickness: 0.05, miterLimit: 1.0, scale: 300
        )

        var vertexData: [Float] = []
        shapeIndex.removeAll() // clear this or else render() will loop infinitely

        addCubicBezier(start: [-1.0, -1.0], c1: [1.0, 2.0], c2: [1.0, -2.0], end: [-1.0, 1.0], options: bezierOptions, vertexData: &vertexData)
        addCubicBezier(start: [1.0, 1.0], c1: [-1.0, 1.0], c2: [-1.0, -1.0], end: [1.0, -1.0], options: bezierOptions, vertexData: &vertexData)
        addCubicBezier(start: [-0.5, 0.5], c1: [1.0, 1.0], c2: [-1.0, -1.0], end: [0.5, -0.5], options: bezierOptions, vertexData: &vertexData)
        addCubicBezier(start: [-0.25, 0.35], c1: [0.1, 0.9], c2: [-0.1, 1.0], end: [0.25, 0.5], options: bezierOptions, vertexData: &vertexData)

        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: dataSize,
                                         options: .storageModeShared)
    }

    func render() {
        guard let drawable: CAMetalDrawable = metalLayer.nextDrawable() else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 255.0 / 255.0, green: 16.0 / 255.0, blue: 22.0 / 255.0, alpha: 1.0)

        generateVerts()

        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        var currentVertexPosition = 0
        for si in shapeIndex {
            renderCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: currentVertexPosition, vertexCount: si)
            currentVertexPosition += si
        }

        renderCommandEncoder.endEncoding()
        commandBuffer.present(drawable)
        // NB: you can pass in a time to present the finished image:
        // present(drawable: drawable, atTime presentationTime: CFTimeInterval)
        commandBuffer.commit()
    }

    @objc func gameloop() {
        autoreleasepool {
            self.render()
        }
    }
}
