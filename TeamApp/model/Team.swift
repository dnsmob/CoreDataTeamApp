

import Foundation
import CoreData


class Team: NSManagedObject {
	
	@NSManaged var name: String
	@NSManaged var id: String
	@NSManaged var everybody: NSSet?
	
}
