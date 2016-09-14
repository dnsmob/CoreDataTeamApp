
import Foundation
import Signals


class DownloadTask:NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
	
	let onLoadStart = Signal<Any?>()
	let onLoadUpdate = Signal<Double!>()
	let onLoadComplete = Signal<NSData!>()
	let onLoadError = Signal<NSError!>()
	
	var isLoading = false
	
	private var session:NSURLSession?
	private weak var feed:NSURLSessionDownloadTask?
	
	
	init(url:String, useCache:Bool = false){
		super.init()
		print("Download task created")
		
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		if useCache {
			config.URLCache = nil
			config.requestCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
		}
		
		session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
		feed?.cancel()
		feed = session!.downloadTaskWithRequest(NSURLRequest(URL: NSURL(string: url)!))
		isLoading = false
	}
	
	deinit{
		print("Download task removed")
	}
	
	func start(){
		isLoading = true
		NetworkActivityIndicatorManager.start()
		onLoadStart.fire(nil)
		feed?.resume()
	}
	
	func cancel (){
		isLoading = false
		NetworkActivityIndicatorManager.stop()
		
		feed?.cancel()
		session?.invalidateAndCancel()
	}
	
	
	// MARK:  NSURLSessionDataDelegate
	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		if let data = NSData(contentsOfURL: location) {
			isLoading = false
			dispatch_async (dispatch_get_main_queue()) {
				NetworkActivityIndicatorManager.stop()
				self.onLoadComplete.fire(data)
				session.finishTasksAndInvalidate()
			}
		}
		else {
			print("data download error")
			let error = NSError(domain: "local error", code:0, userInfo: ["message" : "Data download failed."])
			sendError(session, error: error)
		}
	}
	
	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		let percentage = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
		dispatch_async (dispatch_get_main_queue ()) {
			self.onLoadUpdate.fire(percentage)
		}
	}
	
	func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
		if error != nil {
			sendError(session, error: error)
		}
	}
	
	func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if error != nil {
			sendError(session, error: error)
		}
	}
	
	private func sendError(session:NSURLSession, error:NSError!) {
		print("received error \(error)")
		isLoading = false
		session.invalidateAndCancel()
		dispatch_async (dispatch_get_main_queue ()) {
			NetworkActivityIndicatorManager.stop()
			self.onLoadError.fire(error)
		}
	}
}















