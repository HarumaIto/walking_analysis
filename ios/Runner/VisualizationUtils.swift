//
//  Visualization.swift
//  Runner
//
//  Created by hanzyuku on 2022/08/02.
//

import Foundation

// シングルトンクラスとして実装
final public class Visualizationutils {
    private init() {}
    public static let shared = Visualizationutils()
    
    private let CIRCLE_RADIUS = 6
    private let LINE_WIDTH = 4
    
    private let bodyJoints = [
        (BodyPart.NOSE, BodyPart.LEFT_EYE),
        (BodyPart.NOSE, BodyPart.RIGHT_EYE),
        (BodyPart.LEFT_EYE, BodyPart.LEFT_EAR),
        (BodyPart.RIGHT_EYE, BodyPart.RIGHT_EAR),
        (BodyPart.NOSE, BodyPart.LEFT_SHOULDER),
        (BodyPart.NOSE, BodyPart.RIGHT_SHOULDER),
        (BodyPart.LEFT_SHOULDER, BodyPart.LEFT_ELBOW),
        (BodyPart.LEFT_ELBOW, BodyPart.LEFT_WRIST),
        (BodyPart.RIGHT_SHOULDER, BodyPart.RIGHT_ELBOW),
        (BodyPart.RIGHT_ELBOW, BodyPart.RIGHT_WRIST),
        (BodyPart.LEFT_SHOULDER, BodyPart.RIGHT_SHOULDER),
        (BodyPart.LEFT_SHOULDER, BodyPart.LEFT_HIP),
        (BodyPart.RIGHT_SHOULDER, BodyPart.RIGHT_HIP),
        (BodyPart.LEFT_HIP, BodyPart.RIGHT_HIP),
        (BodyPart.LEFT_HIP, BodyPart.LEFT_KNEE),
        (BodyPart.LEFT_KNEE, BodyPart.LEFT_ANKLE),
        (BodyPart.RIGHT_HIP, BodyPart.RIGHT_KNEE),
        (BodyPart.RIGHT_KNEE, BodyPart.RIGHT_ANKLE)
    ]
    
    func drawBodyKeyPoints(cgContext: CGContext, inputImage: CGImage, persons: [Person]) -> CGImage? {
        // 線を描画するためのセットアップ
        cgContext.setLineWidth(CGFloat(LINE_WIDTH))
        cgContext.setStrokeColor(UIColor.red.cgColor)
        
        // 丸を描画するためのセットアップ
        cgContext.setFillColor(UIColor.red.cgColor)
        
        persons.forEach {
            let person = $0
            
            bodyJoints.forEach {
                let pointA = person.keyPoints[$0.0.rawValue].coordinate
                let pointB = person.keyPoints[$0.1.rawValue].coordinate
                cgContext.move(to: CGPoint(x: pointA.x, y: pointA.y))
                cgContext.addLine(to: CGPoint(x: pointB.x, y: pointB.y))
            }
            
            person.keyPoints.forEach {
                let rectangle = CGRect(
                    origin: $0.coordinate,
                    size: CGSize(width: CIRCLE_RADIUS, height: CIRCLE_RADIUS))
                cgContext.addEllipse(in: rectangle)
            }
        }
        
        guard let image = cgContext.makeImage() else { return nil }
        return image
    }
}
