//
//  SSEClient.swift
//  TestWebConnections
//
//  Created by Anand Kumar on 8/28/25.
//

import Foundation

class SSEClient: NSObject, URLSessionDataDelegate {
    private var urlSession: URLSession!
    private var task: URLSessionDataTask?
    private var eventBuffer = ""

    init(url: URL) {
        super.init()
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        task = urlSession.dataTask(with: url)
    }

    func start() {
        task?.resume()
    }

    func stop() {
        task?.cancel()
    }

    // Called as new chunks of data arrive
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let chunk = String(data: data, encoding: .utf8) {
            eventBuffer += chunk
            processBuffer()
        }
    }

    private func processBuffer() {
        // Split by double newline which signals end of an SSE event
        let events = eventBuffer.components(separatedBy: "\n\n")
        for event in events.dropLast() {
            parseEvent(event)
        }
        eventBuffer = events.last ?? ""
    }

    private func parseEvent(_ rawEvent: String) {
        // SSE events typically look like: data: {"message": "Hello"}
        for line in rawEvent.split(separator: "\n") {
            if line.starts(with: "data:") {
                let data = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                print("Received SSE message: \(data)")
            }
        }
    }
}

