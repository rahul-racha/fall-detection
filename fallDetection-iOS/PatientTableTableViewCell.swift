//
//  PatientTableTableViewCell.swift
//  fallDetection-iOS
//
//  Created by Rahul Racha on 2/26/18.
//  Copyright © 2018 Rahul Racha. All rights reserved.
//

import UIKit

class PatientTableTableViewCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
