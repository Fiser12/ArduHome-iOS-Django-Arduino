//
//  ViewControllerBlind.swift
//  arduHome
//
//  Created by Fiser on 6/6/17.
//  Copyright © 2017 fiser. All rights reserved.
//

import UIKit

class ViewControllerBlind: UIViewController, Actualizame {
    
    @IBOutlet weak var persiana: UISlider!
    var timer:Timer!
    override func viewDidLoad() {
        super.viewDidLoad()
        actualizarPersiana()
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ViewControllerBlind.actualizarPersiana), userInfo: nil, repeats: true)
    }
    func actualizarPersiana(){
        RestAPISingleton.shared.get(Metodo: "api/persiana/persiana1", Actualizame: self, id: "0")
    }
    @IBAction func valueChanged(_ sender: UISlider) {
        RestAPISingleton.shared.post(Metodo: "api/persiana", postParams: ["nombre":"persiana1" as AnyObject, "porcentajeAbierta": sender.value as AnyObject])
    }
    
    func actualizar(json: [String : Any]?, id:String) {
        if(json == nil){
            return
        }
        guard let porcentajeAbierta = json?["porcentajeAbierta"] else {
            print("Could not get from JSON")
            return
        }
        DispatchQueue.main.async() {
            if(id == "0"){
                self.persiana.value = NSString(string: String(describing: porcentajeAbierta)).floatValue;
            }
            
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        actualizarPersiana()
    }
}

