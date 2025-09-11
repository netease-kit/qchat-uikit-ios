//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class DemoService: NSObject {
  public class func getSearchTypeData(completion: @escaping (Error?, NECommonResult?) -> Void) {
    let uri = "im/group/searchType/list"
    if var request = getRequest(uri: uri) {
      // 发送请求
      dataTaskCallBackInMain(with: request, completionHandler: { data, response, error in
        if error == nil {
          guard let d = data else {
            completion(getError(msg: nil, code: nil), nil)
            return
          }
          if let result = parseResult(data: d) {
            completion(nil, result)
          } else {
            completion(getError(msg: nil, code: nil), nil)
          }
        } else {
          completion(error, nil)
        }
      })
    }
  }

  public class func getSquareData(searchType: Int, completion: @escaping (Error?, NECommonResult?) -> Void) {
    let uri = "im/group/server/\(AppKey.appKey)/\(searchType)/list"
    print("getSquareData : ", uri)

    if var request = getRequest(uri: uri) {
      // 发送请求
      dataTaskCallBackInMain(with: request, completionHandler: { data, response, error in
        if error == nil {
          guard let d = data else {
            completion(getError(msg: nil, code: nil), nil)
            return
          }
          if let result = parseResult(data: d) {
            completion(nil, result)
          } else {
            completion(getError(msg: nil, code: nil), nil)
          }
        } else {
          completion(error, nil)
        }
      })
    }
  }

  private class func getError(msg: String?, code: Int?) -> NSError {
    if let message = msg, let errorCode = code {
      return NSError(domain: "com.netease.qchat", code: errorCode, userInfo: [NSLocalizedDescriptionKey: message])
    }
    return NSError(domain: "com.netease.qchat", code: -1, userInfo: [NSLocalizedDescriptionKey: "operation failed"])
  }

  private class func parseResult(data: Data) -> NECommonResult? {
    do {
      print("json string : ", String(data: data, encoding: .utf8) ?? "")
      if let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
        let result = NECommonResult()
        if let code = jsonObject["code"] as? Int {
          result.code = code
        }
//          if let msg = jsonObject["msg"] as? String {
//            result.msg = msg
//          }
        result.originData = jsonObject
        return result
      }
    } catch {
      print("Error: \(error.localizedDescription)")
    }
    return nil
  }

  private class func getRequest(uri: String) -> URLRequest? {
    let requestUrl = getHost() + uri
    guard let url = URL(string: requestUrl) else {
      return nil
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(AppKey.appKey, forHTTPHeaderField: "appkey")
    request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue(account, forHTTPHeaderField: "accountId")
    request.setValue(token, forHTTPHeaderField: "accessToken")
    return request
  }

  private class func dataTaskCallBackInMain(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, NSError?) -> Void) {
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        completionHandler(data, response, error as NSError?)
      }
    }
    task.resume()
  }

  private class func getHost() -> String {
    #if DEBUG
      "https://yiyong-qa.netease.im/"
    #else
      "https://yiyong.netease.im/"
    #endif
  }
}
