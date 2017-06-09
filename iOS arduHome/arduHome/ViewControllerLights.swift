//
//  ViewControllerLights.swift
//  arduHome
//
//  Created by Fiser on 6/6/17.
//  Copyright © 2017 fiser. All rights reserved.
//

import UIKit

class ViewControllerLights: UIViewController, Actualizame {
    
    @IBOutlet weak var lucesSalon: UISwitch!
    @IBOutlet weak var lucesHabitacion: UISwitch!
    @IBOutlet weak var lucesCocina: UISwitch!
    var timer:Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        actualizarLuces()
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ViewControllerLights.actualizarLuces), userInfo: nil, repeats: true)
    }
    func actualizarLuces(){
        RestAPISingleton.shared.get(Metodo: "api/bombilla/salon", Actualizame: self, id: "lucesSalon")
        RestAPISingleton.shared.get(Metodo: "api/bombilla/cocina", Actualizame: self, id: "lucesCocina")
        RestAPISingleton.shared.get(Metodo: "api/bombilla/habitacion", Actualizame: self, id: "lucesHabitacion")
    }
    func actualizar(json: [String : Any]?, id:String) {
        if(json == nil){
            return
        }
        guard let encendida = json?["encendida"] else {
            print("Could not get todo title from JSON")
            return
        }
        DispatchQueue.main.async() {
            if(id == "lucesSalon"){
                self.lucesSalon.setOn(Int(String(describing: encendida)) == 1 ? true : false, animated: false)
            }
            if(id == "lucesHabitacion"){
                self.lucesHabitacion.setOn(Int(String(describing: encendida)) == 1 ? true : false, animated: false)
            }
            if(id == "lucesCocina"){
                self.lucesCocina.setOn(Int(String(describing: encendida)) == 1 ? true : false, animated: false)
            }

        }
    }
    @IBAction func lucesSalonChange(_ sender: UISwitch) {
        RestAPISingleton.shared.post(Metodo: "api/bombilla", postParams: ["nombre":"salon" as AnyObject, "encendida": sender.isOn as AnyObject])
    }
    @IBAction func lucesCocinaChange(_ sender: UISwitch) {
        RestAPISingleton.shared.post(Metodo: "api/bombilla", postParams: ["nombre":"cocina" as AnyObject, "encendida": sender.isOn as AnyObject])
    }
    @IBAction func lucesHabitaciónChange(_ sender: UISwitch) {
        RestAPISingleton.shared.post(Metodo: "api/bombilla", postParams: ["nombre":"habitacion" as AnyObject, "encendida": sender.isOn as AnyObject])
    }
    override func viewWillAppear(_ animated: Bool) {
        actualizarLuces()
    }

}
