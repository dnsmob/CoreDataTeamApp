//
//  Person.swift
//  mubaloo
//
//  Created by Denis Santos on 04/09/2016.
//  Copyright © 2016 dnsmob. All rights reserved.
//

import Foundation
import CoreData

class Person: NSManagedObject {
	
	@NSManaged var id:String
	@NSManaged var firstName:String
	@NSManaged var lastName:String
	@NSManaged var role:String
	@NSManaged var profileImageURL:String
	@NSManaged var profileImageData:NSData?
	@NSManaged var teamLead:Bool
	@NSManaged var team:Team?
	
}