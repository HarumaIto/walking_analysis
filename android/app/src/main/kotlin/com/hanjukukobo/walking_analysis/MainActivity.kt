package com.hanjukukobo.walking_analysis

import android.graphics.*
import androidx.core.graphics.createBitmap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.lang.Math.*
import kotlin.math.roundToInt

class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.hanjukukobo.walking_analysis/ml"
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
        val bitmap: Bitmap? = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)

        val persons = mutableListOf<Person>()
        val angleList = mutableListOf<Int>()

        if (bitmap != null) {
            moveNet!!.estimatePoses(bitmap).let {
                persons.addAll(it)

                val person = persons[0]
                val leftHip = person.keyPoints[BodyPart.LEFT_HIP.position]
                val leftKnee = person.keyPoints[BodyPart.LEFT_KNEE.position]
                val leftAnkle = person.keyPoints[BodyPart.LEFT_ANKLE.position]
                val rightHip = person.keyPoints[BodyPart.RIGHT_HIP.position]
                val rightKnee = person.keyPoints[BodyPart.RIGHT_KNEE.position]
                val rightAnkle = person.keyPoints[BodyPart.RIGHT_ANKLE.position]

                val leftKneeAngle = getArticularAngle(leftHip, leftKnee, leftAnkle)
                val rightKneeAngle = getArticularAngle(rightHip, rightKnee, rightAnkle)

                angleList.add(leftKneeAngle)
                angleList.add(rightKneeAngle)
            }


            val outputBitmap = visualize(persons, bitmap)

            val baos = ByteArrayOutputStream()
            outputBitmap.compress(Bitmap.CompressFormat.PNG, 100, baos)
            val outputBytes: ByteArray = baos.toByteArray()

            return hashMapOf(
                "angleList" to angleList,
                "image" to outputBytes
            )
        } else {
            return hashMapOf()
        }
    }

    private fun visualize(persons: List<Person>, bitmap: Bitmap) : Bitmap {
        /** Threshold for confidence score. */
        val minConfidence = .2f

        val resultBitmap: Bitmap =
                Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)

        val outputBitmap = VisualizationUtils.drawBodyKeyPoints(
                bitmap,
                persons.filter { it.score > minConfidence }
        )

        val canvas = Canvas(resultBitmap)

        val screenWidth: Int
        val screenHeight: Int
        val left: Int
        val top: Int

        if (canvas.height > canvas.width) {
            val ratio = outputBitmap.height.toFloat() / outputBitmap.width
            screenWidth = canvas.width
            left = 0
            screenHeight = (canvas.width * ratio).toInt()
            top = (canvas.height - screenHeight) / 2
        } else {
            val ratio = outputBitmap.width.toFloat() / outputBitmap.height
            screenHeight = canvas.height
            top = 0
            screenWidth = (canvas.height * ratio).toInt()
            left = (canvas.width - screenWidth) / 2
        }
        val right: Int = left + screenWidth
        val bottom: Int = top + screenHeight

        canvas.drawBitmap(
                outputBitmap, Rect(0, 0, outputBitmap.width, outputBitmap.height),
                Rect(left, top, right, bottom), null)

        return resultBitmap
    }

    /// 姿勢推定の結果から関節角度を計算する
    private fun getArticularAngle (
            firstLandmark: KeyPoint,
            middleLandmark: KeyPoint,
            lastLandmark: KeyPoint) : Int {

        // 辺の長さを計算
        val firstToMid = pow(
                pow((firstLandmark.coordinate.x - middleLandmark.coordinate.x).toDouble(), 2.0)
                        + pow((firstLandmark.coordinate.y - middleLandmark.coordinate.y).toDouble(), 2.0), 0.5)

        val lastToMid = pow(
                pow((lastLandmark.coordinate.x - middleLandmark.coordinate.x).toDouble(), 2.0)
                        + pow((lastLandmark.coordinate.y - middleLandmark.coordinate.y).toDouble(), 2.0), 0.5)

        val firstToLast = pow(
                pow((firstLandmark.coordinate.x - lastLandmark.coordinate.x).toDouble(), 2.0)
                        + pow((firstLandmark.coordinate.y - lastLandmark.coordinate.y).toDouble(), 2.0), 0.5)

        // 第二余弦定理でcosΘを計算
        val angle = (pow(firstToMid, 2.0) + pow(lastToMid, 2.0) - pow(firstToLast, 2.0)) / (2 * firstToMid * lastToMid);

        // Θを取得
        val angleRad = acos(angle);

        // ラジアンから度に変換
        var result = angleRad * 180 / kotlin.math.PI;

        // 180度以上になったら計算順が逆だったことになるので反転させる
        if (result > 180) { result = (360.0 - result); }

        // 小数点四捨五入
        return result.roundToInt();
    }
}