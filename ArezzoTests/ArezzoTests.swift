//
//  ArezzoTests.swift
//  ArezzoTests
//
//  Created by Max Harris on 10/10/20.
//  Copyright © 2020 Max Harris. All rights reserved.
//

import XCTest

class ArezzoTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // PenDown(type: "PenDown", color: [0.0, 0.0, 0.0, 0.0], lineWidth: 5.0, timestamp: 1602408785964, id: 0)
    // Point(type: "Point", point: [513.87476, 343.04993], timestamp: 1602408785976, id: 1)
    // Point(type: "Point", point: [517.7709, 343.04993], timestamp: 1602408786160, id: 2)
    // Point(type: "Point", point: [522.0779, 342.015], timestamp: 1602408786177, id: 3)
    // Point(type: "Point", point: [526.7654, 341.54828], timestamp: 1602408786193, id: 4)
    // Point(type: "Point", point: [531.5544, 341.54828], timestamp: 1602408787213, id: 5)
    // Point(type: "Point", point: [556.4631, 342.81653], timestamp: 1602408787221, id: 6)
    // PenUp(type: "PenUp", timestamp: 1602408787221, id: 7)

    func testShape() throws {
        let f = Shape(type: DrawOperationType.line)
        let color: [Float] = [1.0, 0.0, 0.0, 1.0]
        let lineWidth: Float = 5
        f.addShapePoint(point: [513.87476, 343.04993], timestamp: 1_602_408_785_976, color: color, lineWidth: lineWidth)
        f.addShapePoint(point: [517.7709, 343.04993], timestamp: 1_602_408_786_160, color: color, lineWidth: lineWidth)
        f.addShapePoint(point: [522.0779, 342.015], timestamp: 1_602_408_786_177, color: color, lineWidth: lineWidth)
        f.addShapePoint(point: [526.7654, 341.54828], timestamp: 1_602_408_786_193, color: color, lineWidth: lineWidth)
        f.addShapePoint(point: [531.5544, 341.54828], timestamp: 1_602_408_787_213, color: color, lineWidth: lineWidth)
        f.addShapePoint(point: [556.4631, 342.81653], timestamp: 1_602_408_787_221, color: color, lineWidth: lineWidth)

        XCTAssert(f.getIndex(timestamp: 1_602_408_787_221) == 10)
        XCTAssert(f.getIndex(timestamp: -1) == -2)
        XCTAssert(f.getIndex(timestamp: 1_602_408_786_194) == 6)
    }

    func testCircle() {
        let capResolutionOdd = 7
        let capVerticesOdd: [Float] = circleGeometry(edges: capResolutionOdd)
        let capIndicesOdd: [UInt32] = shapeIndices(edges: capResolutionOdd)

        XCTAssertEqual(capVerticesOdd, [0.5, 0.0, 0.31174493, 0.39091572, -0.111260414, 0.48746398, -0.45048442, 0.21694191, -0.45048448, -0.21694177, -0.111260734, -0.4874639, 0.31174484, -0.3909158])
        XCTAssertEqual(capIndicesOdd, [6, 0, 5, 1, 4, 2, 3])

        let capResolutionEven = 8
        let capVerticesEven: [Float] = circleGeometry(edges: capResolutionEven)
        let capIndicesEven: [UInt32] = shapeIndices(edges: capResolutionEven)

        XCTAssertEqual(capVerticesEven, [0.5, 0.0, 0.3535534, 0.35355338, 3.774895e-08, 0.5, -0.35355338, 0.35355338, -0.5, 7.54979e-08, -0.3535535, -0.3535533, 5.9624403e-09, -0.5, 0.35355332, -0.35355344])
        XCTAssertEqual(capIndicesEven, [7, 0, 6, 1, 5, 2, 4, 3])
    }

    func testCollector() {
        let recording = Recording()
        let renderer = Renderer(frame: CGRect(x: 0, y: 0, width: 100, height: 100), scale: 2.0)

        XCTAssertEqual(recording.opList.count, 0)

        recording.beginProvisionalOps()
        recording.addOpToShapeList(op: AudioClip(timestamp: CFAbsoluteTimeGetCurrent(), audioSamples: []), renderer: renderer)
        recording.addOpToShapeList(op: PenDown(color: [1.0, 0.0, 1.0, 1.0], lineWidth: DEFAULT_LINE_WIDTH, timestamp: CFAbsoluteTimeGetCurrent(), mode: .draw), renderer: renderer)
        recording.addOpToShapeList(op: Point(point: [800, 100], timestamp: CFAbsoluteTimeGetCurrent()), renderer: renderer)
        recording.addOpToShapeList(op: PenUp(timestamp: CFAbsoluteTimeGetCurrent()), renderer: renderer)
        recording.addOpToShapeList(op: PenDown(color: [0.0, 0.0, 0.0, 0.0], lineWidth: DEFAULT_LINE_WIDTH, timestamp: CFAbsoluteTimeGetCurrent(), mode: .pan), renderer: renderer)
        recording.addOpToShapeList(op: Pan(point: [100, 400], timestamp: CFAbsoluteTimeGetCurrent()), renderer: renderer)
        recording.addOpToShapeList(op: PenUp(timestamp: CFAbsoluteTimeGetCurrent()), renderer: renderer)

        XCTAssertEqual(recording.opList[0].type, .audioClip)
        XCTAssertEqual(recording.opList[1].type, .penDown)
        XCTAssertEqual(recording.opList[2].type, .point)
        XCTAssertEqual(recording.opList[3].type, .penUp)
        XCTAssertEqual(recording.opList[4].type, .penDown)
        XCTAssertEqual(recording.opList[5].type, .pan)
        XCTAssertEqual(recording.opList[6].type, .penUp)

        recording.cancelProvisionalOps()

        // ensure that provisional ops are destroyed when cancelled
        XCTAssertEqual(recording.opList.count, 0)
        XCTAssertEqual(recording.shapeList.count, 0)
        XCTAssertEqual(recording.timestamps.count, 0)

        recording.beginProvisionalOps()
        recording.addOpToShapeList(op: PenDown(color: [1.0, 0.0, 1.0, 1.0], lineWidth: DEFAULT_LINE_WIDTH, timestamp: CFAbsoluteTimeGetCurrent(), mode: .draw), renderer: renderer)
        recording.addOpToShapeList(op: Point(point: [310, 645], timestamp: CFAbsoluteTimeGetCurrent()), renderer: renderer)
        recording.addOpToShapeList(op: Point(point: [284.791, 429.16245], timestamp: CFAbsoluteTimeGetCurrent()), renderer: renderer)
        recording.addOpToShapeList(op: Point(point: [800, 100], timestamp: CFAbsoluteTimeGetCurrent()), renderer: renderer)
        recording.addOpToShapeList(op: PenUp(timestamp: CFAbsoluteTimeGetCurrent()), renderer: renderer)

        recording.commitProvisionalOps()
        recording.cancelProvisionalOps()

        // ensure that commited ops are retained post-cancellation
        XCTAssertEqual(recording.opList.count, 5)
        XCTAssertEqual(recording.shapeList.count, 1)
        XCTAssertEqual(recording.timestamps.count, 5)

        XCTAssertEqual(recording.opList[0].type, .penDown)
        XCTAssertEqual(recording.opList[1].type, .point)
        XCTAssertEqual(recording.opList[2].type, .point)
        XCTAssertEqual(recording.opList[3].type, .point)
        XCTAssertEqual(recording.opList[4].type, .penUp)
    }
}
