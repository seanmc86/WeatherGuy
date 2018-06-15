//
//  ViewController.swift
//  WeatherGuy
//
//  Created by Sean McCalgan on 2018/06/13.
//  Copyright © 2018 Sean McCalgan. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

class MainViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var weatherDescrip: UILabel!
    @IBOutlet weak var weatherLocation: UILabel!
    @IBOutlet weak var tempCurrent: UILabel!
    @IBOutlet weak var tempMin: UILabel!
    @IBOutlet weak var tempMax: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let locationManager = CLLocationManager()
    var locationString: String?
    private var notification: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()

        enableBasicLocationServices()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchWeatherData(searchLat: Double, searchLon: Double) {
        
        self.activityIndicator.startAnimating()
        
        let priorDateRef = Date().addingTimeInterval(-10.0 * 60.0)
        
        print("UpdateLoc time: \(Date())")
        
        if let lastAPICall = UserDefaults.standard.object(forKey: "LastAPICall") as? Date {
            print("Prior call: \(String(describing: lastAPICall)) Date check: \(priorDateRef)")
            if priorDateRef > lastAPICall {
                
                print("Last API call more than 10min ago, fetching new data")
                
            } else {
                
                print("Last API call within 10min, using existing data already downloaded")
                
                let weatherDescrip = UserDefaults.standard.object(forKey: "WeatherDescrip") as? String

                if weatherDescrip != nil {
                    DispatchQueue.main.async {
                        
                        self.activityIndicator.stopAnimating()
                        
                        let baseDescrip = self.determineBGImage(image: weatherDescrip!)
                        self.bgImage.image = UIImage(named: "\(baseDescrip)bg")
                        self.weatherImage.image = UIImage(named: "\(baseDescrip)white")
                        
                        self.tempMin.text = UserDefaults.standard.object(forKey: "TempMin") as? String
                        self.tempMax.text = UserDefaults.standard.object(forKey: "TempMax") as? String
                        self.tempCurrent.text = UserDefaults.standard.object(forKey: "TempCurrent") as? String
                        self.weatherLocation.text = UserDefaults.standard.object(forKey: "WeatherLoc") as? String
                        self.weatherDescrip.text = weatherDescrip
                        
                    }
                    
                    return
                    
                }
            }
        } else {
            print("No LastAPICall key found yet")
        }
        
        DispatchQueue.global().async {
            
            Alamofire.request("http://api.openweathermap.org/data/2.5/weather?lat=\(searchLat)&lon=\(searchLon)&units=metric&appid=a22788efd277c761ca24f53fa7119e4b")
                
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                .responseData { response in
                    switch response.result {
                    case .success:
                        print("Validation Successful")
                    case .failure(let error):
                        print(error)
                        self.activityIndicator.stopAnimating()
                        return
                    }
                }
                
                .responseJSON { response in
                
                    //print("Request: \(String(describing: response.request))")   // original url request
                    //print("Response: \(String(describing: response.response))") // http url response
                    print("Result: \(response.result)")                         // response serialization result
                    
                    switch response.result {
                        
                    case .success(let json):
                        //print("JSON: \(json)") // serialized json response
                        
                        do {

                            let jsonDict = json as! Dictionary<String, AnyObject>
                            
                            try self.assignData(jsonDict: jsonDict)
                            
                        } catch {
                            print(error.localizedDescription)
                        }
                        
                    case .failure(let error):
                        self.activityIndicator.stopAnimating()
                        print("Request failed with error: \(error)")
                    }

            }
        }
    }
    
    func assignData(jsonDict: Dictionary<String, AnyObject>) throws -> Void {
        
        let tempDict = jsonDict["main"] as! [String:Any]
        let locDict = jsonDict["sys"] as! [String:Any]
        let weatherDict = jsonDict["weather"]
        let weatherDictChild = weatherDict! as! [[String:Any]]
        let weatherDictArray = weatherDictChild[0]
        let weatherLoc = jsonDict["name"]
        
        let tempMin = String("\(describing: (tempDict["temp_min"]!))°")
        let tempMax = String("\(describing: (tempDict["temp_max"]!))°")
        let tempCurrent = String("\(describing: (tempDict["temp"]!))°")
        let weatherDescrip = weatherDictArray["main"] as? String
        let weatherLocation = "\(weatherLoc!), \(locDict["country"] ?? "Unknown Location")"

        activityIndicator.stopAnimating()
        
        if jsonDict.isEmpty {
            return
        } else {
            UserDefaults.standard.set(Date(), forKey: "LastAPICall")
            UserDefaults.standard.set(tempMin, forKey: "TempMin")
            UserDefaults.standard.set(tempMax, forKey: "TempMax")
            UserDefaults.standard.set(tempCurrent, forKey: "TempCurrent")
            UserDefaults.standard.set(weatherDescrip, forKey: "WeatherDescrip")
            UserDefaults.standard.set(weatherLocation, forKey: "WeatherLoc")
        }
        
        DispatchQueue.main.async {
            
            let baseDescrip = self.determineBGImage(image: weatherDescrip!)
            self.bgImage.image? = UIImage(named: "\(baseDescrip)bg")!
            self.weatherImage.image = UIImage(named: "\(baseDescrip)white")
            
            self.tempMin.text = tempMin
            self.tempMax.text = tempMax
            self.tempCurrent.text = tempCurrent
            self.weatherDescrip.text = weatherDescrip
            self.weatherLocation.text = weatherLocation
            
        }
        
        return
        
    }
    
    func locationAlert() {
        
        if self.presentedViewController == nil {

            let alert = UIAlertController(title: "WeatherGuy Alert", message: "You must allow location services in Settings -> WeatherGuy", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {

            let thePresentedVC : UIViewController? = self.presentedViewController as UIViewController?
            if thePresentedVC != nil {
                if let _ : UIAlertController = thePresentedVC as? UIAlertController {
                    print("Alert not necessary, already on the screen")
                } else {
                    print("Alert comes up via another presented VC")
                }
            }
        }
        
        activityIndicator.stopAnimating()
    }
    
    func determineBGImage(image: String) -> String {
        
        var imageString = "cloud"
        
        //print("Description contains: \(image)")
        
        if (image.contains("Sun") || image.contains("Clear")) {
            imageString = "sun"
        }
        if (image.contains("Extreme") || image.contains("Storm") || image.contains("Lightning")) {
            imageString = "lightning"
        }
        if (image.contains("Rain")) {
            imageString = "rain"
        }
        
        return imageString
    }

}

extension MainViewController {

    func enableBasicLocationServices() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = true
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            
            locationManager.requestWhenInUseAuthorization()
            
            break
            
        case .restricted, .denied:
            
            DispatchQueue.main.async {
                self.locationAlert()
            }

            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            
            startReceivingLocationChanges()
            
            break
        }
    }
    
    func startReceivingLocationChanges() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways {
            return
        }
        
        if !CLLocationManager.locationServicesEnabled() {
            return
        }
        
        print("StartLoc time: \(Date())")

        self.activityIndicator.startAnimating()
        
        // Using start/stop rather than requestLocation() as it is much quicker to initially load
        locationManager.startUpdatingLocation()

    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        //Fetch data for user location
        fetchWeatherData(searchLat: locValue.latitude, searchLon: locValue.longitude)
        locationManager.stopUpdatingLocation()
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        enableBasicLocationServices()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
    }

}
