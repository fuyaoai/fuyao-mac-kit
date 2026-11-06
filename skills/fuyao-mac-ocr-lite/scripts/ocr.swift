#!/usr/bin/env swift
// miao-ocr: macOS Vision framework OCR script
// 用法: swift ocr.swift <图片或PDF路径> [识别语言,逗号分隔] [识别级别 accurate|fast]
// 默认: 语言 zh-Hans,en-US | 级别 accurate
// 输出: 按阅读顺序(从上到下,从左到右)打印识别文字,每行一条
//
// 图片文件: 直接 Vision OCR
// PDF 文件: 双引擎策略 (v1.1)
//   1) PDFKit 优先提取文字层 —— 输出带 "=== Page N ===" 页标
//   2) 文字层过薄(平均每页<20字符, 判定为扫描件) → 逐页渲染成位图 → Vision OCR 兜底
//      兜底输出页标为 "=== Page N (OCR) ==="

import Vision
import AppKit
import Foundation
import PDFKit

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("用法: swift ocr.swift <图片或PDF路径> [识别语言,逗号分隔,默认zh-Hans,en-US] [识别级别 accurate|fast,默认accurate]")
    exit(1)
}

let path = args[1]
let langs = args.count >= 3 ? args[2].split(separator: ",").map(String.init) : ["zh-Hans", "en-US"]
let levelStr = args.count >= 4 ? args[3].lowercased() : "accurate"
let url = URL(fileURLWithPath: path)
let stderr = FileHandle.standardError

func stderrLog(_ s: String) {
    stderr.write((s + "\n").data(using: .utf8)!)
}

// MARK: - Vision OCR 核心函数

func ocr(cgImage: CGImage) -> [String] {
    var lines: [String] = []
    let request = VNRecognizeTextRequest { request, error in
        if let error = error {
            print("ERROR: \(error.localizedDescription)")
            exit(1)
        }
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        // 按阅读顺序排序: 先按行(midY 从高到低), 同行内按 x 从左到右
        let sorted = observations.sorted { a, b in
            if abs(a.boundingBox.midY - b.boundingBox.midY) > 0.01 {
                return a.boundingBox.midY > b.boundingBox.midY
            }
            return a.boundingBox.minX < b.boundingBox.minX
        }
        for obs in sorted {
            if let candidate = obs.topCandidates(1).first {
                lines.append(candidate.string)
            }
        }
    }
    request.recognitionLevel = (levelStr == "fast") ? .fast : .accurate
    request.recognitionLanguages = langs
    request.usesLanguageCorrection = true
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("ERROR: \(error.localizedDescription)")
        exit(1)
    }
    return lines
}

// MARK: - PDF 双引擎分支

if url.pathExtension.lowercased() == "pdf" {
    guard let doc = PDFDocument(url: url) else {
        print("ERROR: 无法打开 PDF: \(path)")
        exit(1)
    }
    guard doc.pageCount > 0 else {
        print("ERROR: PDF 无页面")
        exit(1)
    }
    let pageCount = doc.pageCount

    // 引擎1: PDFKit 提取文字层
    var textLayer: [String] = []
    var totalChars = 0
    for i in 0..<pageCount {
        let s = doc.page(at: i)?.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        textLayer.append(s)
        totalChars += s.count
    }
    let avgChars = Double(totalChars) / Double(pageCount)

    if avgChars >= 20 {
        // 有文字层: 直接输出, 不走 OCR
        for (i, s) in textLayer.enumerated() {
            print("=== Page \(i + 1) ===")
            print(s.isEmpty ? "(本页无文字)" : s)
        }
    } else {
        // 引擎2: 扫描件 → 逐页渲染成位图 → Vision OCR 兜底
        stderrLog("文字层过薄(平均每页 \(Int(avgChars)) 字符), 走 Vision OCR 兜底")
        for i in 0..<pageCount {
            guard let page = doc.page(at: i) else { continue }
            let box = page.bounds(for: .mediaBox).size
            let targetSize = CGSize(width: box.width * 2, height: box.height * 2)
            let img = page.thumbnail(of: targetSize, for: .mediaBox)
            guard let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                print("=== Page \(i + 1) (OCR) ===")
                print("(本页渲染失败)")
                continue
            }
            print("=== Page \(i + 1) (OCR) ===")
            for line in ocr(cgImage: cgImage) { print(line) }
        }
    }
    exit(0)
}

// MARK: - 原图片分支

guard let img = NSImage(contentsOfFile: path),
      let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("ERROR: 无法加载图片: \(path)")
    exit(1)
}

for line in ocr(cgImage: cgImage) { print(line) }
