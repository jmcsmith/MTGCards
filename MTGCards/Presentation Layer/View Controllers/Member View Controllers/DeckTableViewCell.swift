//
//  DeckTableViewCell.swift
//  MTGCards
//
//  Created by Joseph Smith on 3/14/19.
//  Copyright © 2019 Robotic Snail Software. All rights reserved.
//

import UIKit

class DeckTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var quantity: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
