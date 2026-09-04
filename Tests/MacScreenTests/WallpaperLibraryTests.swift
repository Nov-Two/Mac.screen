import Foundation
import XCTest
@testable import MacScreen

final class FileSystemHelperTests: XCTestCase {
    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func testUniqueFileURLReturnsOriginalWhenNoConflict() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = FileSystemHelper.uniqueFileURL(for: "壁纸.mp4", in: directory)
        XCTAssertEqual(url.lastPathComponent, "壁纸.mp4")
    }

    func testUniqueFileURLAppendsIndexOnConflict() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try Data().write(to: directory.appendingPathComponent("壁纸.mp4"))

        let url = FileSystemHelper.uniqueFileURL(for: "壁纸.mp4", in: directory)
        XCTAssertEqual(url.lastPathComponent, "壁纸 2.mp4")
    }

    func testUniqueFileURLFallsBackToExtension() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = FileSystemHelper.uniqueFileURL(for: "无后缀", in: directory, fallbackExtension: "mp4")
        XCTAssertEqual(url.lastPathComponent, "无后缀.mp4")
    }
}

final class WallpaperItemCategoryTests: XCTestCase {
    func testCategoryAnime() {
        let item = WallpaperItem(url: URL(fileURLWithPath: "/tmp/二次元-剑士.mp4"))
        XCTAssertEqual(item.mainCategory, "二次元")
    }

    func testCategoryScenery() {
        let item = WallpaperItem(url: URL(fileURLWithPath: "/tmp/风景-露营.mp4"))
        XCTAssertEqual(item.mainCategory, "风景")
    }

    func testCategoryPerson() {
        let item = WallpaperItem(url: URL(fileURLWithPath: "/tmp/甜妹精灵-人物.mp4"))
        XCTAssertEqual(item.mainCategory, "人物")
    }

    func testCategoryOther() {
        let item = WallpaperItem(url: URL(fileURLWithPath: "/tmp/未知素材.mp4"))
        XCTAssertEqual(item.mainCategory, "其他")
    }

    func testDisplayTagsFiltersGenericWords() {
        let item = WallpaperItem(url: URL(fileURLWithPath: "/tmp/哲风壁纸 二次元 剑士.mp4"))
        XCTAssertEqual(item.displayTags, ["二次元", "剑士"])
    }
}
