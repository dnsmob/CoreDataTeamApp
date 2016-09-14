
import Foundation
import UIKit


class NetworkActivityIndicatorManager {
	
	private static var count = 0
	
	static func start(){
		count += 1
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
	}
	
	static func stop(){
		count -= 1
		if count <= 0 {
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
		}
	}
}