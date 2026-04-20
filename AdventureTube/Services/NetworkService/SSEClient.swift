//
//  SSEClient.swift
//  AdventureTube
//
//  Created by chris Lee on 9/3/2026.
//

import Foundation
import Combine

/// Generic SSE (Server-Sent Events) client using URLSessionDataDelegate for streaming.
/// Maintains a buffer, parses `data:` lines, and emits events on double-newline boundaries.
class SSEClient: NSObject, URLSessionDataDelegate {

    private let subject = PassthroughSubject<Data, Error>()
    private var dataTask: URLSessionDataTask?
    private var session: URLSession?
    private var buffer = ""

    var publisher: AnyPublisher<Data, Error> {
        subject.eraseToAnyPublisher()
    }

    func connect(url: URL, headers: [String: String] = [:]) {
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 300
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 600
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        dataTask = session?.dataTask(with: request)
        dataTask?.resume()
    }

    func disconnect() {
        dataTask?.cancel()
        dataTask = nil
        session?.invalidateAndCancel()
        session = nil
        subject.send(completion: .finished)
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer.append(chunk)

        // SSE events are separated by double newlines
        //Search for \n\n — the SSE event delimiter. while because the buffer might contain multiple complete events at once.
        //Loop until no more \n\n found.
        while let range = buffer.range(of: "\n\n") {
            let eventBlock = String(buffer[buffer.startIndex..<range.lowerBound])
            buffer = String(buffer[range.upperBound...])

            // Parse data lines from the event block
            let dataLines = eventBlock
                .components(separatedBy: "\n")
                .filter { $0.hasPrefix("data:") }
                .map { line -> String in
                    let value = line.dropFirst(5) // Remove "data:"
                    // Trim leading space per SSE spec
                    if value.hasPrefix(" ") {
                        return String(value.dropFirst())
                    }
                    return String(value)
                }

            guard !dataLines.isEmpty else { continue }

            let joined = dataLines.joined(separator: "\n")
            if let eventData = joined.data(using: .utf8) {
                subject.send(eventData)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            // Don't send error for explicit cancellation
            if (error as NSError).code == NSURLErrorCancelled {
                subject.send(completion: .finished)
            } else {
                subject.send(completion: .failure(error))
            }
        } else {
            subject.send(completion: .finished)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            subject.send(completion: .failure(BackendError.serverError(message: "SSE connection failed with status \(httpResponse.statusCode)")))
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }
}
