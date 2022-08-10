import UIKit
import Flutter


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
  var moveNet: MoveNet!
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: "walking_analysis/ml", binaryMessenger: controller as! FlutterBinaryMessenger)
      
    methodChannel.setMethodCallHandler({(call: FlutterMethodCall, result: FlutterResult) -> Void in
        switch call.method {
            case "create":
              let model: Int = (call.arguments as! NSNumber).intValue
              self.moveNet = MoveNet(index: model)
            case "process":
              let byteArray = call.arguments as! FlutterStandardTypedData
              let map = self.processImage(byteArray: byteArray)
              result(map)
        default: break
        }
    })
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    func processImage(byteArray: FlutterStandardTypedData) -> NSDictionary {
        // 画像変換処理
        let uiImage = UIImage(data: byteArray.data)!
        let cvPixelBuffer = uiImage.toCVPixelBuffer()
        let size: CGSize = CGSize(width: uiImage.size.width, height: uiImage.size.height)
        let persons = moveNet.estimatePoses(pixelBuffer: cvPixelBuffer!, sourceSize: size)
        var angleList: [Int] = []
        var keyPoints: [[Double]] = []

        // 関節角度を取得
        if persons != nil {
            let person = persons![0]
            
            // 全てのkeyPointを取得
            for keyPoint in person.keyPoints {
                let row = [Double(keyPoint.coordinate.x), Double(keyPoint.coordinate.y)]
                keyPoints.append(row)
            }
            
            let lefthip = person.keyPoints[BodyPart.LEFT_HIP.rawValue]
            let leftKnee = person.keyPoints[BodyPart.LEFT_KNEE.rawValue]
            let leftAnkle = person.keyPoints[BodyPart.LEFT_ANKLE.rawValue]
            let rightHip = person.keyPoints[BodyPart.RIGHT_HIP.rawValue]
            let rightKnee = person.keyPoints[BodyPart.RIGHT_KNEE.rawValue]
            let rightAnkle = person.keyPoints[BodyPart.RIGHT_ANKLE.rawValue]
            
            let leftKneeAngle = getArticularAngle(firstLandmark: lefthip, middleLandmark: leftKnee, lastLandmark: leftAnkle)
            let rightKneeAngle = getArticularAngle(firstLandmark: rightHip, middleLandmark: rightKnee, lastLandmark: rightAnkle)
            
            angleList.append(leftKneeAngle)
            angleList.append(rightKneeAngle)
        }
        
        /*
         let outputImage = visualize(persons: persons!, uiImage: uiImage, size: size)
         let data: Data = outputImage.pngData()!
         let outputByteArray = FlutterStandardTypedData(bytes: data)
         */
        
        // 辞書を初期化
        let dictionary: NSDictionary = [
            "angleList": angleList,
            "keyPoint": keyPoints,
        ]
        
        return dictionary
    }
    
    func visualize(persons: [Person], uiImage: UIImage, size: CGSize) -> UIImage {
        let inputImage: CGImage = uiImage.cgImage!
        
        let imageWidth: CGFloat = size.width
        let imageHeight: CGFloat = size.height
        
        let cgContext = CGContext(
            data: nil,
            width: Int(imageWidth),
            height: Int(imageHeight),
            bitsPerComponent: 8,
            bytesPerRow: 4 * Int(imageWidth),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        cgContext!.draw(inputImage, in: CGRect(origin: .zero, size: size))
        
        let outputImage = Visualizationutils.shared.drawBodyKeyPoints(
            cgContext: cgContext!, inputImage: inputImage, persons: persons)!
        
        let screenWidth: Int
        let screenHeight: Int
        
        if imageHeight > imageWidth {
            let ratio = imageHeight / imageWidth
            screenWidth = Int(imageWidth)
            screenHeight = Int(imageWidth * ratio)
        } else {
            let ratio = imageWidth / imageHeight
            screenHeight = Int(imageHeight)
            screenWidth = Int(imageHeight * ratio)
        }
        
        let resultImage = outputImage.resize(width: screenWidth, height: screenHeight)
        
        return UIImage(cgImage: resultImage!, scale: 0, orientation: uiImage.imageOrientation)
    }
    
    func getArticularAngle(firstLandmark: KeyPoint, middleLandmark: KeyPoint, lastLandmark: KeyPoint) -> Int {
        let firstToMid = pow(
            pow(Double(firstLandmark.coordinate.x - middleLandmark.coordinate.x), 2)
            + pow(Double(firstLandmark.coordinate.y - middleLandmark.coordinate.y), 2)
            , 0.5)
        
        let lastToMid = pow(
            pow(Double(lastLandmark.coordinate.x - middleLandmark.coordinate.x), 2)
            + pow(Double(lastLandmark.coordinate.y - middleLandmark.coordinate.y), 2)
            , 0.5)
        
        let firstToLast = pow(
            pow(Double(firstLandmark.coordinate.x - lastLandmark.coordinate.x), 2)
            + pow(Double(firstLandmark.coordinate.y - lastLandmark.coordinate.y), 2)
            , 0.5
        )
        
        let angle = (pow(firstToMid, 2) + pow(lastToMid, 2) - pow(firstToLast, 2)) / (2 * firstToMid * lastToMid)
        
        let angleRad = acos(angle)
        
        var degree = angleRad * 180 / Double.pi
        
        if degree > 180 {
            degree = 360.0 - degree
        }
        
        return Int(degree.rounded(.toNearestOrAwayFromZero))
    }
}

// 拡張（Convert UIImage to CVPixelBuffer）
extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)

            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            return pixelBuffer
        }

        return nil
    }
}

extension CGImage {
    func resize(width: Int, height: Int) -> CGImage? {
        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel
        
        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: self.bitsPerComponent,
            bytesPerRow: destBytesPerRow,
            space: colorSpace, bitmapInfo: self.alphaInfo.rawValue)
        else { return nil }
        
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
}

extension Data {
    var encodedHexadecimals: [UInt8]? {
        let responseValues = self.withUnsafeBytes({ (pointer: UnsafeRawBufferPointer) -> [UInt8] in
            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!
            return [UInt8](UnsafeBufferPointer(start: unsafePointer, count: self.count))
        })
        return responseValues
    }
}
