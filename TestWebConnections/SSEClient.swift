//
//  SSEClient.swift
//  TestWebConnections
//
//  Created by Anand Kumar on 8/28/25.
//

import Foundation

class SSEClient: NSObject, URLSessionDataDelegate {
    
    private let printVerboseLogs = false
    private let stopAfterOneEvent = false
    
    private var urlSession: URLSession!
    private var task: URLSessionDataTask?
    private var responsePayloadBuffer = ""

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

    // Called as new data arrives, note that a single piece of data received on device may still mean multiple callbacks for this delegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let delegateChunk = String(data: data, encoding: .utf8) else { return }
        
        if printVerboseLogs {
            print("DELEGATE CHUNK - \(delegateChunk.replacingOccurrences(of: "\n", with: "~"))")
        }
        
        responsePayloadBuffer += delegateChunk
        processResponsePayloadBuffer()
    }

    private func processResponsePayloadBuffer() {
        if printVerboseLogs {
            print("RESPONSE PAYLOAD BUFFER - \(responsePayloadBuffer.replacingOccurrences(of: "\n", with: "~"))")
        }
        
        // Split by double newline (will signify end of a single SSE event) to see if at least one full SSE event has accumulated
        let doubleNewlineDelimitedParts = responsePayloadBuffer.components(separatedBy: "\n\n")
        guard doubleNewlineDelimitedParts.count > 1 else {
            return
        }
        
        if printVerboseLogs {
            print("FULL RESPONSE PAYLOAD ACCUMULATED")
        }
        
        // Usually there will be just one event here
        for event in doubleNewlineDelimitedParts.dropLast() {
            parseSSEPayload(event)
        }
        
        responsePayloadBuffer = ""
    }

    private func parseSSEPayload(_ rawEvent: String) {
        if printVerboseLogs {
            print("Parsing accumulated SSE payload - \(rawEvent.replacingOccurrences(of: "\n", with: "~"))")
        }
        
        /* SSE events typically look like this (different keys are separated by newlines)
         ```
         event: tick                 // Optional key
         data: {"message": "Hello"}  // The actual payload
         id: 1234                    // Optional key, but this is what provides SSE's USP. The ID that is then used for automatic retry if needed.
         retry: 1000                 // Optional ley. Recommended wait time (in ms) by server for the client to retry if the connection drops.
         ```
         */
        for line in rawEvent.split(separator: "\n") {
            let eventKey = "event: "
            let dataKey = "data: "
            let idKey = "id: "
            let retryKey = "retry: "
            
            if line.starts(with: eventKey) {
                let event = line.dropFirst(eventKey.count).trimmingCharacters(in: .whitespaces)
                print("Event: \(event)")
            }
            else if line.starts(with: dataKey) {
                let data = line.dropFirst(dataKey.count).trimmingCharacters(in: .whitespaces)
                print("Data: \(data)")
                
                if stopAfterOneEvent {
                    stop()
                }
            }
            else if line.starts(with: idKey) {
                let idKey = line.dropFirst(idKey.count).trimmingCharacters(in: .whitespaces)
                print("id: \(idKey)")
            }
            else if line.starts(with: retryKey) {
                let retryKey = line.dropFirst(retryKey.count).trimmingCharacters(in: .whitespaces)
                print("Retry: \(retryKey)")
            }
        }
        
        print("*****************")
    }
}
