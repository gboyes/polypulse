//
//  MetronomeCell.swift
//  polypulse
//
//  Created by geb on 2015-06-08.
//  Copyright (c) 2015 geb. All rights reserved.
//

import UIKit

class MetronomeCell: UICollectionViewCell {
    
    @IBOutlet var freqLabel:UILabel!
    @IBOutlet var tupletStepper:UIStepper!
    @IBOutlet var tupletGroupStepper:UIStepper!
    @IBOutlet var periodGroupStepper:UIStepper!
    
    
    @IBOutlet var freqSlider:UISlider!
    @IBOutlet var ampSlider:UISlider!
    @IBOutlet var panSlider:UISlider!
    
}
