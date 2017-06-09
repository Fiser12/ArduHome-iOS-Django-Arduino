//
//  ViewController.swift
//  arduHome
//
//  Created by Fiser on 31/5/17.
//  Copyright © 2017 fiser. All rights reserved.
//

import UIKit

class ViewControllerTemperature: UIViewController, Actualizame {

    @IBOutlet weak var controlTemperatura: UISlider!
    @IBOutlet weak var labelTemperaturaControl: UILabel!
    @IBOutlet weak var labelTemperaturaSensor: UILabel!
    var timer:Timer!
    var temperaturaActual:Int = 20
    override func viewDidLoad() {
        super.viewDidLoad()
        self.controlTemperatura.maximumValue = 32;
        self.controlTemperatura.minimumValue = 12;
        self.controlTemperatura.value = 22;
        self.actualizarTemperatura()
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ViewControllerTemperature.actualizarTemperatura), userInfo: nil, repeats: true)
    }
    func actualizarTemperatura(){
        RestAPISingleton.shared.get(Metodo: "api/climatizador/sala", Actualizame: self, id: "0")
    }

    @IBAction func sliderValueChanged(sender: UISlider) {
        RestAPISingleton.shared.post(Metodo: "api/climatizador", postParams: ["nombre":"sala" as AnyObject, "temperaturaObjetivo": sender.value as AnyObject, ])
        self.labelTemperaturaControl.text = String(describing: Int(sender.value)) + "º";

    }

    func actualizar(json: [String : Any]?, id:String) {
        if(json == nil){
            return
        }
        guard let temperaturaObjetivo = json?["temperaturaObjetivo"] else {
            print("Could not get from JSON")
            return
        }
        guard let temperaturaActual = json?["temperaturaActual"] else {
            print("Could not get from JSON")
            return
        }

        DispatchQueue.main.async() {
            if(id == "0"){
                self.temperaturaActual = temperaturaActual as! Int;
                self.controlTemperatura.value = NSString(string: String(describing: temperaturaObjetivo)).floatValue;
                self.labelTemperaturaControl.text = String(describing: temperaturaObjetivo as! Int)+"º";
                self.labelTemperaturaSensor.text = String(describing: self.temperaturaActual) + "º";
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        actualizarTemperatura()
    }

}

