//
//  ContributionDataCell.swift
//  low-effort-sensing
//
//  Copyright © 2017 Kapil Garg. All rights reserved.
//

import Foundation

class ContributionDataCell: UITableViewCell {
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var contributionImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: true)
        
        // Configure the view for the selected state
    }
}
