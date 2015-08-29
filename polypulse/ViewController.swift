//
//  ViewController.swift
//  polypulse
//
//  Created by geb on 2015-06-04.
//  Copyright (c) 2015 geb. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, AudioEngineDelegate {

    
    var audioEngine:AudioEngine!
    
    @IBOutlet var engineToggle:UISwitch!
    @IBOutlet var bpmLabel:UILabel!
    @IBOutlet var collectionView:UICollectionView!
    @IBOutlet var controlView:UIView!
    @IBOutlet var indicatorView:UIView!
    @IBOutlet var ampSlider:UISlider!
    @IBOutlet var pageControl:UIPageControl!
    
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
                self.controlView.alpha = 0.9
            }
            
        })
    }
    
    @IBAction func sliderSlide(sender:UISlider!){
        if (audioEngine != nil) {
            audioEngine.amp = sender.value
        }
    }
    
    @IBAction func bpmChange(sender:UIStepper!){
        
        if (audioEngine != nil) {
            
            let period = 44100.0 * 60.0 / sender.value
            audioEngine.period = period
            
            bpmLabel.text = String(format:"%.0f", sender.value)
            
            for m in audioEngine.getMetronomes() {
                m.setPeriod(audioEngine.period)
            }
            
            
            self.collectionView.reloadData()
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
    
    
    func updatePageControl(){
        pageControl.numberOfPages = audioEngine.getMetronomes().count
        pageControl.currentPage = Int(self.collectionView.contentOffset.y / self.collectionView.frame.size.height)
        
    }
    
    func makeMetronomeAction(){
        
        let c = audioEngine.getMetronomes().count
        
        if c < 16 {
        
            let m = Metaronome()
            
            m.setPeriod(audioEngine.period)
            audioEngine.addMetronome(m)
            
            collectionView.reloadData()
            
            
            let p = NSIndexPath(forItem: c, inSection: 0)
            
            collectionView.scrollToItemAtIndexPath(p, atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: true)
            
            self.updatePageControl()
        }
    }
    
    func deleteMetronomeAction(sender:UIButton!){
        
        let a = audioEngine.getMetronomes()
        
        //Always keep one metronome
        if a.count > 1 {
            let m = a[sender.tag] as! Metaronome
            audioEngine.removeMetronome(m)
            collectionView.reloadData()
            
            self.updatePageControl()
        }
    }
    
    func tupletStepper(sender:UIStepper!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.tuplet = sender.value
        m.setPeriod(audioEngine.period)
        
        //update the cell UI
        let i = NSIndexPath(forRow: sender.tag, inSection: 0)
        let cell = collectionView.cellForItemAtIndexPath(i) as! MetronomeCell
        self.configureCell(cell, m: m, index: sender.tag)
        
    }
    
    func tupletGroupStepper(sender:UIStepper!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.tgroup = sender.value
        
        m.setPeriod(audioEngine.period)
        
        //update the cell UI
        let i = NSIndexPath(forRow: sender.tag, inSection: 0)
        let cell = collectionView.cellForItemAtIndexPath(i) as! MetronomeCell
        self.configureCell(cell, m: m, index: sender.tag)
        
    }
    
    func periodGroupStepper(sender:UIStepper!){
        
        let m = audioEngine.getMetronomes()[sender.tag] as! Metaronome
        m.pgroup = sender.value
        
        m.setPeriod(audioEngine.period)
        
        //update the cell UI
        let i = NSIndexPath(forRow: sender.tag, inSection: 0)
        let cell = collectionView.cellForItemAtIndexPath(i) as! MetronomeCell
        self.configureCell(cell, m: m, index: sender.tag)
        
        
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
        
        //keep app from going to background
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        //override the default thumb image
        ampSlider.setThumbImage(UIImage(named: "linew"), forState: UIControlState.Normal)
        ampSlider.setThumbImage(UIImage(named: "linew"), forState: UIControlState.Selected)
        ampSlider.setThumbImage(UIImage(named: "linew"), forState: UIControlState.Highlighted)
        
        collectionView.registerNib(UINib(nibName: "MetronomeCell", bundle: nil), forCellWithReuseIdentifier: "metronomeCell")
        
        audioEngine = AudioEngine()
        audioEngine.delegate = self
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
        
        self.configureCell(cell, m: m, index: indexPath.row)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return audioEngine.getMetronomes().count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        pageControl.currentPage = Int(self.collectionView.contentOffset.y / self.collectionView.frame.size.height)
    }
    
    func configureCell(cell:MetronomeCell, m:Metaronome, index:Int) {
        
        cell.contentView.layer.borderColor = UIColor.blackColor().CGColor
        cell.contentView.layer.borderWidth = 4.0
        
        //TODO: do this once instead
        let tag = index
        
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
        
        cell.deleteButton.tag = tag
        cell.deleteButton.addTarget(self, action: Selector("deleteMetronomeAction:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        
        //labels
        cell.freqLabel.text = String(format: "%0.2f", m.bpm)
        cell.pgroupLabel.text = String(format: "%0.0f", m.pgroup)
        cell.tupletLabel.text = String(format: "%0.0f", m.tuplet)
        cell.tgroupLabel.text = String(format: "%0.0f", m.tgroup)
        
    }
    
    override func viewWillLayoutSubviews() {
    
        super.viewWillLayoutSubviews()
        
        let f = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        f.itemSize = CGSize(width: self.collectionView.bounds.size.width, height: self.collectionView.bounds.size.height)
        
    }
    
    //MARK: audio engine delegate
    func updatedRepresentativeBufferValue(val: UnsafeMutablePointer<Float>) {
        
        
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.indicatorView.layer.backgroundColor = UIColor(red: CGFloat(val[0]), green: CGFloat(val[1]), blue: CGFloat(val[2]), alpha: 1.0).CGColor
                return
            })
        
        
    }
    
    func audioEngineStopped() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.engineToggle.setOn(false, animated: true);
            return
        })
        
    }
}

