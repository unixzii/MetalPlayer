//
//  PlayerViewController.swift
//  MetalPlayer
//
//  Created by Hongyu on 2019/4/28.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import Cocoa
import AVFoundation

class PlayerViewController: NSViewController, NSSplitViewDelegate {

    @IBOutlet weak var playerView: VideoPlayerView!
    
    var player: AVPlayer!
    var renderer: SimpleRenderer!
    
    deinit {
        // First, disconnect the texture source.
        self.renderer.textureSource = nil
        
        // Next, stop and release the player.
        self.player.pause()
        self.player = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = AVPlayer(url: URL(string: "<#Your video URL here#>")!)
        
        self.renderer = SimpleRenderer()
        
        // Try uncommenting below lines to apply addition render passes.
//        self.renderer.addRenderPass(InvertColorRenderPass())
//        self.renderer.addRenderPass(GaussianBlurRenderPass())
//        self.renderer.addRenderPass(DreamEffectRenderPass())
//        self.renderer.addRenderPass(GlitchEffectRenderPass())
        
        self.playerView.renderer = self.renderer
        
        self.renderer.textureSource = AVPlayerTextureSource(player: self.player, renderTarget: self.playerView)
        
        self.player.actionAtItemEnd = .none
        self.player.play()
    }
    
    @IBAction func openDocument(_ sender: Any) {
        
    }
    
    // MARK: - NSSplitViewDelegate
    
    func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        let leftPanel = splitView.subviews[0]
        let rightPanel = splitView.subviews[1]
        
        let rightPanelWidth = rightPanel.frame.width
        
        splitView.adjustSubviews()
        
        var leftPanelSize = leftPanel.frame.size
        var rightPanelSize = rightPanel.frame.size
        
        leftPanelSize.width = splitView.frame.width - splitView.dividerThickness - rightPanelSize.width
        rightPanelSize.width = rightPanelWidth
        
        leftPanel.setFrameSize(leftPanelSize)
        rightPanel.setFrameSize(rightPanelSize)
    }

    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 400
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return splitView.frame.width
    }
    
}
