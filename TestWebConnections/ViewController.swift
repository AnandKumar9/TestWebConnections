//
//  ViewController.swift
//  TestWebConnections
//
//  Created by Anand Kumar on 8/25/25.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    var sseClient: SSEClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        testButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    @IBAction func testButtonTapped(_ sender: UIButton) {
        print("Test button was tapped!")
        
        makeSSEAPICall()
    }
    
    @IBAction func stopButtonTapped(_ sender: Any) {
        sseClient?.stop()
    }
    
    private func makeRegularAPICall() {
        guard let url = URL(string: "http://localhost:8080/hello/vapor") else {
            showAlert(title: "Error", message: "Invalid URL")
            return
        }
        
        // Show loading state
        testButton.isEnabled = false
        testButton.setTitle("Loading...", for: .disabled)
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                
                self?.testButton.isEnabled = true
                self?.testButton.setTitle("Test Button", for: .normal)
                
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    print("Network Error \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Error - Invalid response")
                    return
                }
                
                print("Response status code: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response payload: \(responseString)")
                } else {
                    print("No response payload")
                }
            }
        }
        
        task.resume()
    }
    
    private func makeSSEAPICall() {
        let url = URL(string: "http://localhost:8080/events")!
        sseClient = SSEClient(url: url) { hasAnActiveConnection in
            DispatchQueue.main.async {
                self.testButton.isEnabled = !hasAnActiveConnection
                self.stopButton.isEnabled = hasAnActiveConnection
            }
        }
        sseClient?.start()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

