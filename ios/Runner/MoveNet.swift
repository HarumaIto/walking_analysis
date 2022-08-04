//
//  MoveNet.swift
//  Runner
//
//  Created by hanzyuku on 2022/07/30.
//

import TensorFlowLite
import Foundation
import Accelerate

struct Person {
    var id: Int = -1
    let keyPoints: [KeyPoint]
    let boundingBox: CGRect? = nil
    let score: Float
}

enum BodyPart: Int, CaseIterable {
    case NOSE = 0
    case LEFT_EYE = 1
    case RIGHT_EYE = 2
    case LEFT_EAR = 3
    case RIGHT_EAR = 4
    case LEFT_SHOULDER = 5
    case RIGHT_SHOULDER = 6
    case LEFT_ELBOW = 7
    case RIGHT_ELBOW = 8
    case LEFT_WRIST = 9
    case RIGHT_WRIST = 10
    case LEFT_HIP = 11
    case RIGHT_HIP = 12
    case LEFT_KNEE = 13
    case RIGHT_KNEE = 14
    case LEFT_ANKLE = 15
    case RIGHT_ANKLE = 16
}

struct KeyPoint {
    let bodyPart: BodyPart
    var coordinate: CGPoint
    let score: Float
}

class MoveNet {
    init() {}
    
    let THUNDER_FILE: String = "movenet_thunder"
    let LIGHTNING_FILE: String = "movenet_lightning"
    
    let BATCH_SIZE: Float = 1
    let INPUT_CHANNELS: Float = 3
    
    var inputWidth: Float = 256
    var inputHeight: Float = 256
    
    var interpreter: Interpreter!
    
    init(index: Int) {
        // モデルパスの生成
        var modelName: String
        if index == 0 {
            modelName = THUNDER_FILE
            inputWidth = 256
            inputHeight = 256
        } else {
            modelName = LIGHTNING_FILE
            inputWidth = 192
            inputHeight = 192
        }
        let modelPath = Bundle.main.path(
            forResource: modelName,
            ofType: "tflite"
        )!
        // インタプリタオプションの生成
        var options = Interpreter.Options()
        options.threadCount = 1
        // インタプリタの生成
        do {
            interpreter = try Interpreter(modelPath: modelPath, options: options)
            try interpreter.allocateTensors()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func estimatePoses(pixelBuffer: CVPixelBuffer, sourceSize: CGSize) -> [Person]? {
        // 画像のクロップとスケーリング
        let scaledSize = CGSize(width: Int(inputWidth), height: Int(inputHeight))
        guard let cropPixelBuffer = pixelBuffer.centerThumbnail(offsize: scaledSize)
            else { return nil }
        
        let outputTnesor: Tensor
        do {
            // RGBデータの生成
            let inputTensor = try interpreter.input(at: 0)
            let rgbData = buffer2rgbData(
                cropPixelBuffer,
                byteCount: Int(BATCH_SIZE * inputWidth * inputHeight * INPUT_CHANNELS),
                isModelQuantized: inputTensor.dataType == .uInt8)
            
            // 推論の実行
            try interpreter.copy(rgbData!, toInputAt: 0)
            try interpreter.invoke()
            outputTnesor = try interpreter.output(at: 0)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        let output: [Float] = [Float32](unsafeData: outputTnesor.data) ?? []
        let numKeyPoints = output.count / 3
        let widthRaito = Float(sourceSize.width) / inputWidth
        let heightRatio = Float(sourceSize.height) / inputHeight
        
        var positions: [Float] = []
        var keyPoints: [KeyPoint] = []
        var totalScore: Float = 0.0
        
        for idx in 0..<numKeyPoints {
            let x = output[idx * 3 + 1] * inputWidth * widthRaito
            let y = output[idx * 3 + 0] * inputHeight * heightRatio
            
            positions.append(x)
            positions.append(y)
            let score = output[idx * 3 + 2]
            keyPoints.append(
                KeyPoint(
                    bodyPart: BodyPart(rawValue: idx)!,
                    coordinate: CGPoint(x: Double(x), y: Double(y)),
                    score: score
                )
            )
            totalScore += score
        }
        
        return [Person(keyPoints: keyPoints, score: totalScore / Float(numKeyPoints))]
    }
    
    // PixelBuffer→rgbData
    private func buffer2rgbData(_ buffer: CVPixelBuffer,
        byteCount: Int, isModelQuantized: Bool) -> Data? {
        //PixelBuffer→bufferData
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let mutableRawPointer = CVPixelBufferGetBaseAddress(buffer) else {
            return nil
        }
        let count = CVPixelBufferGetDataSize(buffer)
        let bufferData = Data(bytesNoCopy: mutableRawPointer,
            count: count, deallocator: .none)
        
        //bufferData→rgbBytes
        var rgbBytes = [UInt8](repeating: 0, count: byteCount)
        var index = 0
        for component in bufferData.enumerated() {
            let offset = component.offset
            let isAlphaComponent = (offset % 4) == 3
            guard !isAlphaComponent else {continue}
            rgbBytes[index] = component.element
            index += 1
        }

        //rgbBytes→rgbData
        if isModelQuantized {return Data(rgbBytes)}
        return Data(copyingBufferOf: rgbBytes.map{Float($0)/255.0})
    }
}

extension CVPixelBuffer {
    func centerThumbnail(offsize size: CGSize ) -> CVPixelBuffer? {
        let imageWidth = CVPixelBufferGetWidth(self)
        let imageHeight = CVPixelBufferGetHeight(self)
        let pixelBufferType = CVPixelBufferGetPixelFormatType(self)
        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
        let imageChannels = 4
        let thumbnailSize = min(imageWidth, imageHeight)
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        var originX = 0
        var originY = 0
        if imageWidth > imageHeight {
            originX = (imageWidth - imageHeight) / 2
        }
        else {
            originY = (imageHeight - imageWidth) / 2
        }
        
        //PixelBufferで最大の正方形をみつける
        guard let inputBaseAddress = CVPixelBufferGetBaseAddress(self)?.advanced(
            by: originY * inputImageRowBytes + originX * imageChannels) else {
          return nil
        }
        
        //入力画像から画像バッファを取得
        var inputVImageBuffer = vImage_Buffer(
            data: inputBaseAddress, height: UInt(thumbnailSize), width: UInt(thumbnailSize),
            rowBytes: inputImageRowBytes)
        let thumbnailRowBytes = Int(size.width) * imageChannels
        guard  let thumbnailBytes = malloc(Int(size.height) * thumbnailRowBytes) else {
          return nil
        }
        
        //サムネイル画像にvImageバッファを割り当て
        var thumbnailVImageBuffer = vImage_Buffer(data: thumbnailBytes,
            height: UInt(size.height), width: UInt(size.width), rowBytes: thumbnailRowBytes)
        
        //入力画像バッファでスケール操作を実行し、サムネイル画像バッファに保存
        let scaleError = vImageScale_ARGB8888(&inputVImageBuffer, &thumbnailVImageBuffer, nil, vImage_Flags(0))
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        guard scaleError == kvImageNoError else {
            return nil
        }
        let releaseCallBack: CVPixelBufferReleaseBytesCallback = {mutablePointer, pointer in
            if let pointer = pointer {
                free(UnsafeMutableRawPointer(mutating: pointer))
            }
        }
        
        //サムネイルのvImageバッファをCVPixelBufferに変換
        var thumbnailPixelBuffer: CVPixelBuffer?
        let conversionStatus = CVPixelBufferCreateWithBytes(
            nil, Int(size.width), Int(size.height), pixelBufferType, thumbnailBytes,
            thumbnailRowBytes, releaseCallBack, nil, nil, &thumbnailPixelBuffer)
        guard conversionStatus == kCVReturnSuccess else {
            free(thumbnailBytes)
            return nil
        }
        return thumbnailPixelBuffer
    }
}

extension Data {
   //float配列→byte配列(長さ4倍)
   init<T>(copyingBufferOf array: [T]) {
       self = array.withUnsafeBufferPointer(Data.init)
   }
}

extension Array {
   //byte配列→float配列（長さ1/4倍）
   init?(unsafeData: Data) {
       guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
       #if swift(>=5.0)
       self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
       #else
       self = unsafeData.withUnsafeBytes {
           .init(UnsafeBufferPointer<Element>(
               start: $0,
               count: unsafeData.count / MemoryLayout<Element>.stride
           ))
       }
       #endif  // swift(>=5.0)
   }
}
