//
//  NetworkHelper.swift
//  Photo Search
//
//  Created by Ewen on 2021/10/17.
//

import UIKit

class NetworkHelper {
    static let shared = NetworkHelper()
    
    struct Constant {
        static let imageCountPerPage = 30
        static let privateKey = "// YOUR PRIVATE KEY"
    }
    
    enum NetworkError: Error {
        case invalidUrl
        case requestFailed(Error)
        case invalidData
    }
    
    let imageCache = NSCache<NSURL, UIImage>()
    
    // 下載圖片
    func fetchImage(url: URL, completion: @escaping (Result<UIImage, NetworkError>) -> ()) {
        /// 圖片從Cache取出
        if let image = imageCache.object(forKey: url as NSURL) {
            completion(.success(image))
            return
        }
        ///
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                completion(.failure(.invalidData))
                return
            }
            /// 圖片存到Cache
            self.imageCache.setObject(image, forKey: url as NSURL)
            ///
            completion(.success(image))
        }.resume()
    }
    
    
    //下載 apiResults
    func fetchPhotos(query: String, completion: @escaping (Result<[APIResult], NetworkError>) -> Void) {
        guard let url = URL(string: "https://api.unsplash.com/search/photos?page=1&per_page=\(Constant.imageCountPerPage)&query=\(query)&client_id=\(Constant.privateKey)") else {
            completion(.failure(.invalidUrl))
            return
        }
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            else if let data = data {
//                data.prettyPrintedJSONString()
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(.success(apiResponse.results))
                }
                catch {
                    completion(.failure(.invalidData))
                }
            }
        }.resume()
    }
    
}

