//
//  LocationInfoViewCell.swift
//  low-effort-sensing
//
//  Created by Kapil Garg on 2/26/18.
//  Copyright © 2018 Kapil Garg. All rights reserved.
//

import UIKit

class LocationInfoViewCell: UITableViewCell {
    // MARK: Properties
    @IBOutlet weak var locationInfo: UILabel!
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var locationDistance: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
