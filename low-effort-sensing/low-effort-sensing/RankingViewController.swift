//
//  RankingViewController.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/22/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation

class RankingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let appUserDefaults = UserDefaults.init(suiteName: appGroup)
    
    @IBOutlet var tableView: UITableView!
    var categories: [String] = ["Free or Sold Food", "Lines at Popular Places (e.g. Tech Express)", "Space Availability (e.g. Coffee Lab, Main Library)", "Surprising Things (e.g. cute animals, celebrities)"]
    
    var snapShot: UIView?
    var sourceIndexPath: IndexPath?
    
    // MARK: Class Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.tableFooterView = UIView()
        self.tableView.estimatedRowHeight = 50.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        addLongGestureRecognizerForTableView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        cell.textLabel?.text = self.categories[(indexPath as NSIndexPath).row]
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.5
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell #\((indexPath as NSIndexPath).row)!")
    }
    
    func addLongGestureRecognizerForTableView() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(RankingViewController.handleTableViewLongGesture(_:)) )
        tableView.addGestureRecognizer(longGesture)
    }
    
    
    func handleTableViewLongGesture(_ sender: UILongPressGestureRecognizer) {
        let state = sender.state
        let location = sender.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return
        }
        
        switch state {
        case .began:
            sourceIndexPath = indexPath
            guard let cell = tableView.cellForRow(at: indexPath) else {
                return
            }
            
            //Take a snapshot of the selected row using helper method.
            snapShot = customSnapShotFromView(cell)
            
            // Add the snapshot as subview, centered at cell's center...
            var center = CGPoint(x: cell.center.x, y: cell.center.y)
            snapShot?.center = center
            snapShot?.alpha = 0.0
            tableView.addSubview(snapShot!)
            UIView.animate(withDuration: 0.25, animations: {
                // Offset for gesture location.
                center.y = location.y
                self.snapShot?.center = center
                self.snapShot?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.snapShot?.alpha = 0.98
                
                cell.alpha = 0.0
                }, completion: { _ in
                    cell.isHidden = true
            })
        case .changed:
            guard let snapShot = snapShot else {
                return
            }
            guard let sourceIndexPathTmp = sourceIndexPath else {
                return
            }
            var center = snapShot.center
            center.y = location.y
            snapShot.center = center
            
            // Is destination valid and is it different from source?
            if indexPath != sourceIndexPathTmp {
                //self made exchange method
                let oldIndices = [(indexPath as NSIndexPath).row, (sourceIndexPathTmp as NSIndexPath).row]
                let oldValues = [categories[oldIndices[0]], categories[oldIndices[1]]]
                
                self.categories[oldIndices[0]] = oldValues[1]
                self.categories[oldIndices[1]] = oldValues[0]
                
                // ... move the rows.
                tableView.moveRow(at: sourceIndexPathTmp, to: indexPath)
                // ... and update source so it is in sync with UI changes.
                sourceIndexPath = indexPath
            }
            
        default:
            guard let sourceIndexPathTmp = sourceIndexPath else {
                return
            }
            guard let cell = tableView.cellForRow(at: sourceIndexPathTmp) else {
                return
            }
            cell.isHidden = false
            cell.alpha = 0.0
            
            UIView.animate(withDuration: 0.25, animations: {
                self.snapShot?.center = cell.center
                self.snapShot?.transform = CGAffineTransform.identity
                self.snapShot?.alpha = 0.0
                
                cell.alpha = 1.0
                }, completion: { _ in
                    self.sourceIndexPath = nil
                    self.snapShot?.removeFromSuperview()
                    self.snapShot = nil
            })
        }
    }
    
    func customSnapShotFromView(_ inputView: UIView) -> UIImageView{
        // Make an image from the input view.
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let snapshot = UIImageView(image: image)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0.0
        snapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        snapshot.layer.shadowRadius = 5.0
        snapshot.layer.shadowOpacity = 0.4
        
        return snapshot
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "RankingSegue") {
            var userInfo = appUserDefaults?.dictionary(forKey: "welcomeData")
            userInfo!["firstPreference"] = simplifyTag(categories[0])
            userInfo!["secondPreference"] = simplifyTag(categories[1])
            userInfo!["thirdPreference"] = simplifyTag(categories[2])
            userInfo!["fourthPreference"] = simplifyTag(categories[3])
                
            self.appUserDefaults?.set(userInfo, forKey: "welcomeData")
            self.appUserDefaults?.synchronize()
        }
    }
    
    func simplifyTag(_ labelText: String) -> String {
        switch labelText {
        case "Free or Sold Food":
            return "food"
        case "Lines at Popular Places (e.g. Tech Express)":
            return "queue"
        case "Space Availability (e.g. Coffee Lab, Main Library)":
            return "space"
        case "Surprising Things (e.g. cute animals, celebrities)":
            return "surprising"
        default:
            return ""
        }
    }
}
