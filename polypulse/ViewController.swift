//
//  ViewController.swift
//  polypulse
//
//  Created by geb on 2015-06-04.
//  Copyright (c) 2015 geb. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    var audioEngine:AudioEngine!
    @IBOutlet var bpmLabel:UILabel!
    
    @IBAction func sliderSlide(sender:UISlider!){
        if (audioEngine != nil) {
            audioEngine.amp = sender.value
        }
    }
    
    @IBAction func periodChange(sender:UISlider!){
        if (audioEngine != nil) {
            audioEngine.period = Int(floor(sender.value))
            
            //TODO: gonna need this function
            let bpm = 44100.0 * 60.0 / floor(sender.value)
            
            bpmLabel.text = String(format:"%.0f bpm", bpm)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        audioEngine = AudioEngine()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

