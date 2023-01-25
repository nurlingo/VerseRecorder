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
    
    private func getClientID() async {
        
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
    
    
    internal func uploadNewlyRecordedAudios(_ tracks: [String], for audioId: String) {
        
        Task {
            do {
                await self.getToken()
                await self.getClientID()
                
                var uploaded = 0
                
                for track in tracks {
                    
                    guard recordingStorage.doesRecordingExist(track) else {continue}
                    
                    uploaded += 1

                    if !recordingStorage.didUploadRecording(track) {
                        await self.upload(track)
                    }
                }
                
                print("upload complete")
                
                clientStorage.saveUploadProgress(audioId, progress: Double(uploaded)/Double(tracks.count))
                
            } catch {
                //FIXME: add catch exceptions
                print(#file, #function, #line, #column, error.localizedDescription)
            }
        }
        
    }
    
    private func upload(_ trackId: String) async {
        
        // FIXME: this is not reusable actually.
        
        print("uploading \(trackId)")
        
        let surahNumber = trackId.prefix(trackId.count-3)
        let ayahNumber = trackId.suffix(3)
        print(surahNumber)
        print(ayahNumber)
        
        let url = URL(string: "\(creds.remoteAPI)audios?client_id=nurios&surra_number=\(surahNumber)&aya_number=\(ayahNumber)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        do {
            let path = recordingStorage.getPath(for: trackId)
            let audioData = try Data(contentsOf: path)
            
            var data = Data()

            // Add the image data to the raw http request data
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"recording-\(trackId).m4a\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
//            print(response)
            recordingStorage.registerUploading(trackId)
            
        } catch {
            print(#file, #function, #line, #column, error.localizedDescription)
        }
    }
    
}
