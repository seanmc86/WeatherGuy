//
//  SplashViewController.swift
//  WeatherGuy
//
//  Created by Sean McCalgan on 2018/06/13.
//  Copyright © 2018 Sean McCalgan. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
    
    @IBOutlet weak var animationView: UIView!
    
    fileprivate var rootViewController: UIViewController? = nil
    
    var imageView: UIImageView!
    
    weak var imageCloud: UIImage!
    weak var imageSun: UIImage!
    weak var imageRain: UIImage!
    weak var imageLightning: UIImage!
    var animatedImage: UIImage!
    var images: [UIImage]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createView()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createView() {
        
        // Create a background view
        let viewWidth: CGFloat = view.bounds.width
        let viewHeight: CGFloat = view.bounds.height
        
        // Create a circle view
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: viewWidth / 2,y: viewHeight / 2), radius: CGFloat(120), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor

        // Create an image view and add it to background view
        let xPoint = (view.bounds.width / 2) - 64
        let yPoint = (view.bounds.height / 2) - 64
        imageView = UIImageView(frame: CGRect(x: xPoint, y: yPoint, width: 128, height: 128))
        
        // Add the view stack
        animationView.layer.addSublayer(shapeLayer)
        animationView.addSubview(imageView)

        animateView()
        
    }
    
    func animateView() {
        
        imageCloud = UIImage(named: "cloud")
        imageSun = UIImage(named: "sun")
        imageRain = UIImage(named: "rain")
        imageLightning = UIImage(named: "lightning")
        images = [imageCloud, imageSun, imageRain, imageLightning]
        
        animatedImage = UIImage.animatedImage(with: images, duration: 1.5)
        imageView.image = animatedImage
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.animationView.removeFromSuperview()
            self.showMainViewController()
        }
        
    }
    
    func showMainViewController() {
        guard !(rootViewController != nil) else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nav =  storyboard.instantiateViewController(withIdentifier: "MainNavigation")
        nav.willMove(toParentViewController: self)
        addChildViewController(nav)
        
        if let rootViewController = self.rootViewController {
            self.rootViewController = nav
            rootViewController.willMove(toParentViewController: nil)
            
            transition(from: rootViewController, to: nav, duration: 0.55, options: [.transitionCrossDissolve, .curveEaseOut], animations: { () -> Void in
                
            }, completion: { _ in
                nav.didMove(toParentViewController: self)
                rootViewController.removeFromParentViewController()
                rootViewController.didMove(toParentViewController: nil)
            })
        } else {
            rootViewController = nav
            view.addSubview(nav.view)
            nav.didMove(toParentViewController: self)
        }
    }
    
    open override var prefersStatusBarHidden : Bool {
        return true
    }

}
