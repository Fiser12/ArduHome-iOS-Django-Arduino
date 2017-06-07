//
//  RestAPISingleton.swift
//  arduHome
//
//  Created by Fiser on 6/6/17.
//  Copyright © 2017 fiser. All rights reserved.
//

import Foundation
protocol Actualizame{
    func actualizar(json:[String: Any]?, id: String);
}

final class RestAPISingleton{
    private init() {
        self.url = "https://mobility-final-project.herokuapp.com/"
    }
    static let shared = RestAPISingleton()
    let url:String

    func get(Metodo metodo:String, Actualizame actualizame:Actualizame, id:String){
        
        // Setup the session to make REST GET call.  Notice the URL is https NOT http!!
        let todoEndpoint: String = self.url+metodo

        guard let url = URL(string: todoEndpoint) else {
            print("Error: cannot create URL")
            return;
        }
        let urlRequest = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error!)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as JSON, since that's what the API provides
            do {
                guard let jsonLet = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        print("error trying to convert data to JSON")
                        return
                }
                // now we have the todo
                // let's just print it to prove we can access it
                print("The todo is: " + jsonLet.description)
                actualizame.actualizar(json: jsonLet, id: id);
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
    
    
    func post(Metodo metodo:String, postParams : [String: AnyObject]) {

        let todosEndpoint: String = self.url+metodo
        guard let todosURL = URL(string: todosEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        var todosUrlRequest = URLRequest(url: todosURL)
        todosUrlRequest.httpMethod = "PUT"
//        let newTodo: [String: Any] = ["title": "My First todo", "completed": false, "userId": 1]
        let jsonTodo: Data
        do {
            jsonTodo = try JSONSerialization.data(withJSONObject: postParams, options: [])
            todosUrlRequest.httpBody = jsonTodo
            todosUrlRequest.addValue("Content-Type", forHTTPHeaderField: "application/json")
        } catch {
            print("Error: cannot create JSON from todo")
            return
        }
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: todosUrlRequest) {
            (data, response, error) in
            guard error == nil else {
                print("error calling POST on /todos/1")
                return
            }
       }
        task.resume()
        
    }
}
