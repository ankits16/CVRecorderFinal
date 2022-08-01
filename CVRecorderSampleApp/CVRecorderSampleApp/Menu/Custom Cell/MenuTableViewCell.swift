//
//  MenuTableViewCell.swift
//  CVRecorderSampleApp
//
//  Created by Ankit Sachan on 01/08/22.
//

import UIKit

class MenuTableViewCell: UITableViewCell {
    @IBOutlet weak var menuItemTitleLbl : UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
