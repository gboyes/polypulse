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
    @IBOutlet var controlView:UIView!
    
    @IBAction func controlAction(sender:UIBarButtonItem!){
        
        var down:Bool
        if controlView.alpha > 0 {
            down = true
        } else {
            down = false
        }
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            
            if down {
                self.controlView.alpha = 0.0
            } else {
                self.controlView.alpha = 1.0
            }
            
        })
    }
    
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
    
    @IBAction func addMetronome(){
        
        self.makeMetronomeAction()
        
    }
    
    func makeMetronomeAction(){
        
        let m = Metaronome()
        audioEngine.addMetronome(m)
        
        collectionView.reloadData()
        
        let p = NSIndexPath(forItem: audioEngine.getMetronomes().count-1, inSection: 0)
        
        collectionView.scrollToItemAtIndexPath(p, atScrollPosition: UICollectionViewScrollPosition.Left, animated: true)
    }
    
    func tupletStepper(sender:UIStepper!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.tuplet = sender.value
        
    }
    
    func tupletGroupStepper(sender:UIStepper!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.tgroup = sender.value
        
    }
    
    func periodGroupStepper(sender:UIStepper!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.pgroup = sender.value
        
    }
    
    func freqSliderAction(sender:UISlider!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.freq = sender.value
        
    }
    
    func panSliderAction(sender:UISlider!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.pan = sender.value
        
    }
    
    func ampSliderAction(sender:UISlider!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.amp = sender.value
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        collectionView.registerNib(UINib(nibName: "MetronomeCell", bundle: nil), forCellWithReuseIdentifier: "metronomeCell")
        
        audioEngine = AudioEngine()
        audioEngine.period = 44100.0
        
        self.makeMetronomeAction()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: collectionview implementation
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let m = audioEngine.getMetronomes()[indexPath.row] as! Metaronome
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("metronomeCell", forIndexPath: indexPath) as! MetronomeCell
        
        cell.freqLabel.text = String(format: "%d", indexPath.row)
        
        let tag = indexPath.row
        
        //should add the target only once
        cell.tupletStepper.tag = tag
        cell.tupletStepper.addTarget(self, action: Selector("tupletStepper:"), forControlEvents: UIControlEvents.TouchUpInside)
        cell.tupletStepper.value = m.tuplet
        
        cell.tupletGroupStepper.tag = tag
        cell.tupletGroupStepper.addTarget(self, action: Selector("tupletGroupStepper:"), forControlEvents: UIControlEvents.TouchUpInside)
        cell.tupletGroupStepper.value = m.tgroup
        
        cell.periodGroupStepper.tag = tag
        cell.periodGroupStepper.addTarget(self, action: Selector("periodGroupStepper:"), forControlEvents: UIControlEvents.TouchUpInside)
        cell.periodGroupStepper.value = m.pgroup
        
        cell.freqSlider.tag = tag
        cell.freqSlider.addTarget(self, action: Selector("freqSliderAction:"), forControlEvents: UIControlEvents.ValueChanged)
        cell.freqSlider.setValue(m.freq, animated: false)
        
        cell.panSlider.tag = tag
        cell.panSlider.addTarget(self, action: Selector("panSliderAction:"), forControlEvents: UIControlEvents.ValueChanged)
        cell.panSlider.setValue(m.pan, animated: false)
        
        cell.ampSlider.tag = tag
        cell.ampSlider.addTarget(self, action: Selector("ampSliderAction:"), forControlEvents: UIControlEvents.ValueChanged)
        cell.ampSlider.setValue(m.amp, animated: false)
        
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return audioEngine.getMetronomes().count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
}

