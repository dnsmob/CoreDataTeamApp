

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {
	
	var detailViewController: DetailViewController? = nil
	var context: NSManagedObjectContext!
	
	var task:DownloadTask?
	
	private var entity:NSEntityDescription!
	private let orderById = NSSortDescriptor(key: "id", ascending: true)
	private let entityEverybody = "Everybody"
	private let entityTeams = "Teams"
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let split = self.splitViewController {
			let controllers = split.viewControllers
			self.detailViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? DetailViewController
		}
		
		// fetch json
		task = DownloadTask(url: "https://raw.githubusercontent.com/dnsmob/CoreDataTeamApp/master/assets/team.json")
		task?.onLoadComplete.listen(self, callback: { data in
			
			let everybody = JsonParser.getNames(data)
			let teams = JsonParser.getTeams(data)
			
			// remove entries that dont exist in the json
			self.purgeData(everybody)
			
			// insert/update entries based on json
			self.seedTeams(teams)
			for entry in everybody {
				self.seedPerson(entry)
			}
			
			// display data
			self.fetchData()
			self.tableView.reloadData()
		})
		
		task?.onLoadError.listen(self, callback: { error in
			self.fetchData()
			self.tableView.reloadData()
		})
		
		task?.start()
	}
	
	private func fetchData (){
		do {
			try self.resultsController.performFetch()
			
		} catch {
			abort()
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
		super.viewWillAppear(animated)
	}
	
	func purgeData(data:[NSDictionary]) {
		do {
			let ids = data.map { $0["id"] as! String } // ["001", "002", "003" ... ]
			
			// fetch all row ids
			let request = NSFetchRequest(entityName: entityEverybody)
			request.propertiesToFetch = ["id"]
			request.resultType = NSFetchRequestResultType.DictionaryResultType
			request.sortDescriptors = [orderById]
			
			// remove ids that exist in json
			let results = try context.executeFetchRequest(request)
				.filter { (ids.indexOf($0["id"] as! String) != nil) ? false : true } // [ { id: "025" }, { id: "032" } ... ]
			
			if results.count > 0 {
				// delete extra rows
				for obj in results { // obj = { id: "025" }
					let predicate = NSPredicate(format: "id == %@", obj["id"] as! String)
					let request = NSFetchRequest(entityName: entityEverybody)
					request.predicate = predicate
					
					do {
						let results = try context.executeFetchRequest(request) as! [Person]
						for entity in results {
							context.deleteObject(entity)
						}
					} catch let error as NSError {
						print("purge data \(error), \(error.userInfo)")
						abort()
					}
				}
				try context.save()
			}
			
		} catch let error as NSError {
			print("purge data \(error), \(error.userInfo)")
			abort()
		}
	}
	
	func seedTeams(data:Set<NSDictionary>){
		do {
			// remove all teams
			let request = NSFetchRequest(entityName: entityTeams)
			let results = try context.executeFetchRequest(request) as! [Team]
			for entity in results {
				context.deleteObject(entity)
			}
			
			// add it from scratch
			for item in data {
				let team = Team(entity: NSEntityDescription.entityForName(entityTeams, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
				team.name = item["name"] as! String
				team.id = item["id"] as! String
			}
			
			try context.save()
			
		} catch let error as NSError {
			print("seed teams \(error.userInfo)")
			abort()
		}
	}
	
	func seedPerson(data:NSDictionary){
		let id = data["id"] as! String
		let firstName = data["firstName"] as! String
		let lastName = data["lastName"] as! String
		let role = data["role"] as! String
		let profileImageURL = data["profileImageURL"] as! String
		let teamLead = data["teamLead"] as? Int == 1 ? true : false
		
		do {
			// get team objects
			var predicate = NSPredicate(format: "name == %@", data["teamName"] as! String)
			var request = NSFetchRequest(entityName: entityTeams)
			request.predicate = predicate
			let team = (try context.executeFetchRequest(request) as! [Team]).first
			
			// filter new or update
			// fetch if existing row
			predicate = NSPredicate(format: "id == %@", id)
			request = NSFetchRequest(entityName: entityEverybody)
			request.predicate = predicate
			let results = try context.executeFetchRequest(request) as! [Person]
			
			var item:Person
			if results.count > 0 {
				// found an entry, will reset row
				item = results.first!
				if item.profileImageURL != profileImageURL {
					item.profileImageData = nil
				}
			}
			else {
				// insert new row
				item = Person(entity: NSEntityDescription.entityForName(entityEverybody, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
			}
			item.id = id
			item.firstName = firstName
			item.lastName = lastName
			item.role = role
			item.profileImageURL = profileImageURL
			item.teamLead = teamLead
			item.team = team!
			
			try context.save()
			
		} catch let error as NSError {
			print("seed person \(error), \(error.userInfo)")
			abort()
		}
	}
	
	private var cachedResultsController: NSFetchedResultsController?
	private lazy var resultsController: NSFetchedResultsController = {
		if self.cachedResultsController != nil {
			return self.cachedResultsController!
		}
		
		let request = NSFetchRequest(entityName: self.entityEverybody)
		let first = NSSortDescriptor(key: "team.name", ascending: true)
		let second = NSSortDescriptor(key: "team.id", ascending: true)
		request.sortDescriptors = [ second ]
		
		self.cachedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: "team.id", cacheName: nil)
		self.cachedResultsController!.delegate = self
		
		return self.cachedResultsController!
	}()
	
	// MARK: - Segues
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showDetail" {
			if let indexPath = self.tableView.indexPathForSelectedRow {
				let object = self.resultsController.objectAtIndexPath(indexPath) as! Person
				let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
				controller.detailItem = object
				controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
				controller.navigationItem.leftItemsSupplementBackButton = true
				
				// listen for image download
				controller.imageTask?.onLoadComplete.listen(self, callback: { data in
					do {
						// update image data
						object.profileImageData = data
						try self.context.save()
						controller.configureView()
						
					} catch let error as NSError {
						print("save image \(error), \(error.userInfo)")
						abort()
					}
				})
				
			}
		}
	}
	
	// MARK: - Table View
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if let sections = resultsController.sections {
			return sections.count
		}
		return 0
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let sections = resultsController.sections {
			let currentSection = sections[section]
			return currentSection.numberOfObjects
		}
		return 0
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
		let item = resultsController.objectAtIndexPath(indexPath) as! Person
		
		cell.textLabel?.text = "\(item.firstName) \(item.lastName)"
		cell.detailTextLabel?.text = item.teamLead ? "Team lead" : ""
		
		return cell
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if let sections = resultsController.sections {
			let obj = sections[section].objects?.first as! Person
			return obj.team!.name
		}
		
		return nil
	}
}











