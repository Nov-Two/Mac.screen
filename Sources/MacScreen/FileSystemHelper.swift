import Foundation

enum FileSystemHelper {
    /// 返回目标目录中不冲突的文件 URL：若同名文件已存在，则在扩展名前追加序号。
    /// `fallbackExtension` 仅在 `filename` 不带扩展名时作为兜底（如导入视频默认 `.mp4`）。
    static func uniqueFileURL(
        for filename: String,
        in directory: URL,
        fallbackExtension: String? = nil
    ) -> URL {
        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: filename)
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let pathExtension = sourceURL.pathExtension.isEmpty
            ? (fallbackExtension ?? "")
            : sourceURL.pathExtension

        var candidate: URL
        if pathExtension.isEmpty {
            candidate = directory.appendingPathComponent(baseName)
        } else {
            candidate = directory.appendingPathComponent("\(baseName).\(pathExtension)")
        }

        var index = 2
        while fileManager.fileExists(atPath: candidate.path) {
            let suffixName: String
            if pathExtension.isEmpty {
                suffixName = "\(baseName) \(index)"
            } else {
                suffixName = "\(baseName) \(index).\(pathExtension)"
            }
            candidate = directory.appendingPathComponent(suffixName)
            index += 1
        }

        return candidate
    }
}
