//
//  LeaderboardDataCell.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 11/16/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation

class LeaderboardDataCell: UITableViewCell {
    @IBOutlet weak var rankingLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: true)
        
        // Configure the view for the selected state
    }
}
