
import Foundation


class JsonParser {
	
	static private var teams = Set<NSDictionary>()
	
	static func getNames(data:NSData) -> [NSDictionary] {
		
		var array = [NSDictionary]()
		do {
			let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? NSArray
			
			var teamIndex = 0
			for entry in json! {
				let node = entry as! NSDictionary
				if node["teamName"] as? String == nil {
					node.setValue("Management", forKey: "teamName")
					array += [node]
					
					teams.insert([
						"name": "Management",
						"id": String(teamIndex)
						])
				}
				else {
					let membersNode = node["members"] as? NSArray
					for person in membersNode! {
						let obj = person as! NSDictionary
						obj.setValue(node["teamName"], forKey: "teamName")
						array += [obj]
						
						teams.insert([
							"name": node["teamName"]!,
							"id": String(teamIndex)
							])
					}
				}
				teamIndex += 1
			}
			
		} catch let error {
			print(error)
		}
		
		return array
	}
	
	static func getTeams(data:NSData) -> Set<NSDictionary> {
		return teams
	}
}


extension Array where Element: Equatable {
	var orderedSetValue: Array  {
		return reduce([]){ $0.contains($1) ? $0 : $0 + [$1] }
	}
}

//let integers = [1, 4, 2, 2, 6, 24, 15, 2, 60, 15, 6]
//let integersOrderedSetValue = integers.orderedSetValue





