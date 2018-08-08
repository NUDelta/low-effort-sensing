//
//  LocationDataCell.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 5/28/16.
//  Copyright © 2016 Kapil Garg. All rights reserved.
//

import Foundation
import UIKit

class LocationDataCell: UITableViewCell {
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var userImageLabel: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: true)
        
        // Configure the view for the selected state
    }
}
