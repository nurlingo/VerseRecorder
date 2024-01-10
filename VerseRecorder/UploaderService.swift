//
//  AudioPlayer.swift
//  namaz
//
//  Created by Daniya on 11/01/2020.
//  Copyright © 2020 Nursultan Askarbekuly. All rights reserved.
//

import Foundation

public struct Credentials {
    let remoteAPI: String
    let username: String
    let password: String
    
    public init(remoteAPI: String, username: String, password: String) {
        self.remoteAPI = remoteAPI
        self.username = username
        self.password = password
    }
}

@available(iOS 15.0.0, *)
class UploaderService {
    
    let creds: Credentials
    let clientStorage: ClientStorage
    let recordingStorage = RecordingStorage.shared
    
    init(credentials: Credentials, clientStorage: ClientStorage) {
        self.creds = credentials
        self.clientStorage = clientStorage
    }
    
    private func getToken() async {
        let url = URL(string: "\(creds.remoteAPI)token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "username": creds.username,
            "password": creds.password
        ]
        
        request.httpBody = parameters.percentEncoded()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let dataDict = try JSONDecoder().decode([String:String].self, from: data)
            
            if let token = dataDict["access_token"] {
                self.token = token
//                print(self.token)
            }
            
//            print(response)
//            print(data)
            
            // handle the result
        } catch {
            print(#file, #function, #line, #column,  "Token initiation failed")
        }

    }
    
    var token: String = ""
    var user_id: String = ""
    
    private func getUserID() async {
        
        let url = URL(string: "\(creds.remoteAPI)me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let dataDict = try JSONDecoder().decode([String:String].self, from: data)
            
//            print(response)
//            print(dataDict)
            // handle the result
            
            if let user_id = dataDict["user_id"] {
                self.user_id = user_id
//                print(self.user_id)
            }
            
        } catch {
            print(#file, #function, #line, #column,  "Token initiation failed")
        }

    }
    
    private func updateReciterInfo() async {
        // FIXME: this is not reusable actually.
        
        print("updating reciters info")
        
        let url: URL
        
        let storedReciterId = clientStorage.getReciterId()
        
        if storedReciterId.isEmpty {
            url = URL(string: "\(creds.remoteAPI)reciters")!
        } else {
            url = URL(string: "\(creds.remoteAPI)reciters/\(storedReciterId)")!
        }
        
        
        var request = URLRequest(url: url)
        
        if clientStorage.getReciterId().isEmpty {
            request.httpMethod = "POST"
        } else {
            request.httpMethod = "PUT"
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var json: [String: Any] = [
            "gender": clientStorage.getGender(),
            "qiraah": clientStorage.getQiraaah(),
            "platform": clientStorage.getPlatform()
        ]
        
        if !clientStorage.getCountryCode().isEmpty {
            json["country"] = clientStorage.getCountryCode()
        }
        
        if !clientStorage.getAge().isEmpty {
            json["age"] = clientStorage.getAge()
        }
        
        do {
            
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: String.Encoding.ascii)!
//            print(#file, #function, #line, jsonString)

            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let stringData = String(data: data, encoding: .utf8) {
//                print(#file, #function, stringData)
            }
            
            let dataDict = try JSONDecoder().decode([String:String?].self, from: data)
            
            if let fetchedReciterId = dataDict["client_id"] as? String {
                self.clientStorage.saveReciterId(fetchedReciterId)
//                print(#file, #function,fetchedReciterId)
            }
            
//            print(#file, #function, response)
            
        } catch {
            print(#file, #function, #line, #column,  "updateReciterInfo failed")
        }
    }
    
    
    internal func uploadRangeRecording(_ rangeRecording: RangeRecording, actionAfterUploadingEachTrack: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        
        struct ResponseData: Codable {
            let fileName: String

            enum CodingKeys: String, CodingKey {
                case fileName = "file_name"
            }
        }
        
        Task {
            do {
                await self.getToken()
                await self.getUserID()
                await self.updateReciterInfo()
                                
                for track in rangeRecording.tracks.values.sorted(by: {$0.id < $1.id}) {
                    
                    guard rangeRecording.trackRecordingExists(track.id),
                          track.remoteId == nil else {continue}
                    
                    let trackFileName = "\(rangeRecording.id.uuidString)-\(track.id)"
                    
                    print("uploading \(track.id)")
                    
                    let surahNumber = track.id.prefix(track.id.count-3)
                    let ayahNumber = track.id.suffix(3)
                    print(surahNumber)
                    print(ayahNumber)
                    
                    let url = URL(string: "\(creds.remoteAPI)audios?client_id=\(clientStorage.getReciterId())&surra_number=\(surahNumber)&aya_number=\(ayahNumber)")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    // generate boundary string using a unique per-app string
                    let boundary = UUID().uuidString
                    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                    
                    let path = rangeRecording.getPathForTrack(track.id)
                        let audioData = try Data(contentsOf: path)
                        
                        var data = Data()
                        
                    // Add the image data to the raw http request data
                    data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                    data.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"\(trackFileName).m4a\"\r\n".data(using: .utf8)!)
                    data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
                    data.append(audioData)
                    data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
                    
                    let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)

                    // Check if the response is an HTTPURLResponse and the status code is in the 200 range
                    if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {

                        do {
                            // Decode the JSON data
                            let decoder = JSONDecoder()
                            let decodedData = try decoder.decode(ResponseData.self, from: responseData)

                            // Extract the file name
                            let fileName = decodedData.fileName
                            print("File name is: \(fileName)")
                            rangeRecording.tracks[track.id] = track.updatedRecording(with: fileName)
                            actionAfterUploadingEachTrack?()
                        } catch {
                            print("Error decoding JSON: \(error)")
                        }
                    } else {
                        // Handle unexpected response
                        print("Unexpected response or status code")
                    }
                    
                }
                
                print("upload complete")
                completion?()
                
            } catch {
                //FIXME: add catch exceptions
                completion?()
                print(#file, #function, #line, #column, error.localizedDescription)
            }
        }
        
    }
}
