//
//  model.swift
//  Photo Search
//
//  Created by Ewen on 2021/10/16.
//

struct APIResponse: Codable {
    let total: Int
    let total_pages: Int
    let results: [APIResult]
}
struct APIResult: Codable {
    let urls: URLs
}
struct URLs: Codable {
    let regular: String
}
