import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import XCTest
@testable import MacScreen

// MARK: - 分辨率判定
//
// 这组用例现场生成真实视频文件，验证 `WallpaperLibrary.isHighEnoughResolution`
// 在各种规格下的判定结果，避免"检测本身误判"这一类回归。
//
// 注意：判定按横屏基准（宽 >= 1920 且高 >= 1080）。
// 竖屏素材（1080x1920）会被判定为不合格，这是刻意的产品取舍，由
// `testPortraitOrientationIsRejectedByLandscapeThreshold` 锁定。

final class VideoResolutionDetectionTests: XCTestCase {
    private var workingDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        workingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacScreenResolutionTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let workingDirectory {
            try? FileManager.default.removeItem(at: workingDirectory)
        }
        workingDirectory = nil
        try super.tearDownWithError()
    }

    // MARK: - 合格分辨率

    func testLandscape1080pPasses() async throws {
        let url = try makeVideo(name: "landscape-1080p.mp4", width: 1920, height: 1080)
        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertTrue(passed, "1920x1080 是最低标准，应当通过")
    }

    func testLandscape1440pPasses() async throws {
        let url = try makeVideo(name: "landscape-1440p.mp4", width: 2560, height: 1440)
        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertTrue(passed, "2560x1440 应当通过")
    }

    // MARK: - 不合格分辨率

    func testLandscape720pIsRejected() async throws {
        let url = try makeVideo(name: "landscape-720p.mp4", width: 1280, height: 720)
        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertFalse(passed, "1280x720 低于阈值，应当被拒绝")
    }

    func testLowResolutionIsRejected() async throws {
        let url = try makeVideo(name: "low-360p.mp4", width: 640, height: 360)
        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertFalse(passed, "640x360 远低于阈值，应当被拒绝")
    }

    func testWidthMetButHeightShortIsRejected() async throws {
        let url = try makeVideo(name: "ultrawide-short.mp4", width: 2560, height: 720)
        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertFalse(passed, "高度不足 1080 时应当被拒绝，即使宽度达标")
    }

    // MARK: - 旋转与朝向
    //
    // 竖屏视频有两种常见形态，两者都应被横屏基准拒绝：
    // 1. 编码就是竖屏（naturalSize 1080x1920）
    // 2. 编码为横屏但带 90° 旋转元数据（iPhone 竖拍），显示尺寸为 1080x1920

    func testNativelyEncodedPortraitIsRejected() async throws {
        let url = try makeVideo(name: "portrait-encoded.mp4", width: 1080, height: 1920)
        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertFalse(passed, "1080x1920 竖屏素材不满足横屏基准")
    }

    func testRotatedLandscapeIsEvaluatedByDisplaySize() async throws {
        // 编码为 1920x1080，带 90° 旋转元数据，实际显示为 1080x1920。
        // 判定必须使用旋转后的显示尺寸，而不是编码尺寸。
        let rotation = CGAffineTransform(rotationAngle: .pi / 2)
        let url = try makeVideo(
            name: "rotated-portrait.mp4",
            width: 1920,
            height: 1080,
            transform: rotation
        )

        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        let track = try XCTUnwrap(tracks.first)
        let naturalSize = try await track.load(.naturalSize)
        XCTAssertEqual(Int(naturalSize.width), 1920, "编码尺寸应为横屏")
        XCTAssertEqual(Int(naturalSize.height), 1080, "编码尺寸应为横屏")

        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertFalse(passed, "带 90° 旋转的素材应按显示尺寸 1080x1920 判定")
    }

    // MARK: - 读不出分辨率时放行
    //
    // 未下载完整、编码暂无法解析等情况下不拦截，
    // 避免把真实的高清素材误报为"分辨率太低"。

    func testUnreadableFileIsNotRejected() async throws {
        let url = workingDirectory.appendingPathComponent("broken.mp4")
        try Data("这不是一个合法的 mp4 文件".utf8).write(to: url)

        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertTrue(passed, "读不出分辨率时应放行，而不是误报为低分辨率")
    }

    func testMissingFileIsNotRejected() async {
        let url = workingDirectory.appendingPathComponent("not-exists.mp4")
        let passed = await WallpaperLibrary.isHighEnoughResolution(url)
        XCTAssertTrue(passed, "文件不存在时不应误报为低分辨率")
    }

    // MARK: - 辅助

    private func makeVideo(
        name: String,
        width: Int,
        height: Int,
        transform: CGAffineTransform = .identity,
        frameCount: Int = 5
    ) throws -> URL {
        let url = workingDirectory.appendingPathComponent(name)
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)

        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
        )
        input.transform = transform

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )

        XCTAssertTrue(writer.canAdd(input), "AVAssetWriter 应能接受 \(width)x\(height) 视频轨道")
        writer.add(input)
        XCTAssertTrue(writer.startWriting(), "AVAssetWriter 应能开始写入")
        writer.startSession(atSourceTime: .zero)

        var pool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary, &pool)

        for index in 0..<frameCount {
            while !input.isReadyForMoreMediaData {
                usleep(1_000)
            }

            var pixelBuffer: CVPixelBuffer?
            guard
                let pool,
                CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess,
                let buffer = pixelBuffer
            else {
                continue
            }

            CVPixelBufferLockBaseAddress(buffer, [])
            if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
                memset(baseAddress, Int32((index * 17) % 255), CVPixelBufferGetDataSize(buffer))
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])

            adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: 30))
        }

        input.markAsFinished()

        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting { semaphore.signal() }
        semaphore.wait()

        XCTAssertEqual(writer.status, .completed, "测试视频写入应成功：\(String(describing: writer.error))")
        return url
    }
}
