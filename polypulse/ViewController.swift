//
//  ViewController.swift
//  polypulse
//
//  Created by geb on 2015-06-04.
//  Copyright (c) 2015 geb. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    
    var audioEngine:AudioEngine!
    
    @IBOutlet var bpmLabel:UILabel!
    @IBOutlet var collectionView:UICollectionView!
    
    @IBAction func sliderSlide(sender:UISlider!){
        if (audioEngine != nil) {
            audioEngine.amp = sender.value
        }
    }
    
    @IBAction func periodChange(sender:UISlider!){
        
        if (audioEngine != nil) {
            
            audioEngine.period = Double(sender.value)
            
            //TODO: gonna need this function
            let bpm = 44100.0 * 60.0 / sender.value
            
            bpmLabel.text = String(format:"%.0f bpm", bpm)
        }
    }
    
    @IBAction func toggleMetronome(sender:UISwitch!){
        
        if sender.on {
            self.audioEngine.start()
        } else {
            self.audioEngine.stop()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        audioEngine = AudioEngine()
        audioEngine.period = 44100.0
        
        let m:Metaronome = Metaronome()
        m.pgroup = 1
        m.tuplet = 1
        m.tgroup = 1
        m.amp = 0.25
        m.freq = 5555
        audioEngine.addMetronome(m)
        
        var i = 0
        while i < 3 {
            
            let i_ = Double(i)
            
            let m:Metaronome = Metaronome()
            m.pgroup = 1.1 + i_
            m.tuplet = 3
            m.tgroup = i_ + 1
            m.amp = 0.25
            m.freq = 12000.0 - Float(i) * 277.0
            audioEngine.addMetronome(m)
            
            print(String(format: "%0.7f\n", m.period(audioEngine.period)))
            
            i++
            
        }
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: collectionview implementation
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:UICollectionViewCell! = nil
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 0
    }

}

