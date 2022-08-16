package com.hanjukukobo.walking_analysis

import android.graphics.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.pow
import kotlin.math.roundToInt

class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "walking_analysis/ml"
        private const val METHOD_CREATE = "create"
        private const val METHOD_PROCESS = "process"
        private const val METHOD_CLOSE = "close"
    }
    
    private lateinit var channel: MethodChannel
    private var moveNet: MoveNet? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 通信チャンネルを作成
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        // 呼ばれた時の処理
        channel.setMethodCallHandler {methodCall, result ->
            when(methodCall.method) {
                METHOD_CREATE -> {
                    val model = methodCall.arguments
                    moveNet = MoveNet.create(this, model as Int)
                }
                METHOD_PROCESS -> {
                    val byteArray = methodCall.arguments as ByteArray
                    val map = processImage(byteArray)
                    result.success(map)
                }
                METHOD_CLOSE -> {
                    moveNet?.close()
                    result.success(null)
                }
            }
        }
    }

    private fun processImage(bytes: ByteArray): HashMap<String, Any> {
        // 画像と変数の初期化
        val bitmap: Bitmap? = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)

        val persons = mutableListOf<Person>()
        val angleList = mutableListOf<Int>()
        val keyPoints = mutableListOf<MutableList<Float>>()

        if (bitmap != null) {
            // TensorFlowLiteで推論
            moveNet!!.estimatePoses(bitmap).let {
                // personの配列を取得
                persons.addAll(it)

                // 関節角度を求める際に必要なKeyPointを取得
                val person = persons[0]
                val leftHip = person.keyPoints[BodyPart.LEFT_HIP.position]
                val leftKnee = person.keyPoints[BodyPart.LEFT_KNEE.position]
                val leftAnkle = person.keyPoints[BodyPart.LEFT_ANKLE.position]
                val rightHip = person.keyPoints[BodyPart.RIGHT_HIP.position]
                val rightKnee = person.keyPoints[BodyPart.RIGHT_KNEE.position]
                val rightAnkle = person.keyPoints[BodyPart.RIGHT_ANKLE.position]

                // 関節角度を取得しReturnする配列に格納
                val leftKneeAngle = getArticularAngle(leftHip, leftKnee, leftAnkle)
                val rightKneeAngle = getArticularAngle(rightHip, rightKnee, rightAnkle)
                angleList.add(leftKneeAngle)
                angleList.add(rightKneeAngle)

                // すべてのKeyPointを取得
                person.keyPoints.forEach { keyPoint ->
                    keyPoints.add(mutableListOf(keyPoint.coordinate.x, keyPoint.coordinate.y))
                }
            }

            // Map形式でFlutterにReturn
            return hashMapOf(
                "angleList" to angleList,
                "keyPoint" to keyPoints
            )
        } else {
            // うまくBitmapが処理できなかった場合はからMapでReturn
            return hashMapOf()
        }
    }

    /// 姿勢推定の結果から関節角度を計算する
    private fun getArticularAngle (
            firstLandmark: KeyPoint,
            middleLandmark: KeyPoint,
            lastLandmark: KeyPoint) : Int {

        // 辺の長さを計算
        val firstToMid = (
                (firstLandmark.coordinate.x - middleLandmark.coordinate.x).toDouble().pow(2.0)
                        + (firstLandmark.coordinate.y - middleLandmark.coordinate.y).toDouble().pow(2.0)
                ).pow(0.5)

        val lastToMid = (
                (lastLandmark.coordinate.x - middleLandmark.coordinate.x).toDouble().pow(2.0)
                    + (lastLandmark.coordinate.y - middleLandmark.coordinate.y).toDouble().pow(2.0)
                ).pow(0.5)

        val firstToLast = (
                (firstLandmark.coordinate.x - lastLandmark.coordinate.x).toDouble().pow(2.0)
                    + (firstLandmark.coordinate.y - lastLandmark.coordinate.y).toDouble().pow(2.0)
                ).pow(0.5)

        // 第二余弦定理でcosΘを計算
        val angle = (firstToMid.pow(2.0) + lastToMid.pow(2.0) - firstToLast.pow(2.0)) / (2 * firstToMid * lastToMid)

        // Θを取得
        val angleRad = kotlin.math.acos(angle)

        // ラジアンから度に変換
        var result = angleRad * 180 / kotlin.math.PI

        // 180度以上になったら計算順が逆だったことになるので反転させる
        if (result > 180) { result = (360.0 - result) }

        // 小数点四捨五入
        return result.roundToInt()
    }
}