from "functools.nut" import *

let {Task} = require("monads.nut")
let http = require("dagor.http")
//local dlog = require("log.nut")().dlog
/*
  todo:
    ? handle http code different from 200..300 as error
*/

let statusText = {
  [http.SUCCESS] = "SUCCESS",
  [http.FAILED] = "FAILED",
  [http.ABORTED] = "ABORTED",
}

let function httpGet(url, callback){
  http.request({
    url
    method = "GET"
    callback
  })
}
let function TaskHttpGet(url) {
  return Task(function(rejectFn, resolveFn) {
    println($"http 'get' requested for '{url}'")
    http.request({
      url
      method = "GET"
      callback = tryCatch(
        function(response){
          let status = response.status
          let sttxt = statusText?[status]
          println($"http status for '{url}' = {sttxt}")
          if (status != http.SUCCESS) {
            throw($"http error status = {sttxt}")
          }
          resolveFn(response.body)
        },
        rejectFn
      )
    })
  })
}

let UNRESOLVED = persist("UNRESOLVED", @() {})
let RESOLVED = persist("RESOLVED", @() {})
let REJECTED = persist("REJECTED", @() {})

let function TaskHttpMultiGet(urls, rejectOne=@(x) x, resolveOne=@(x) x) {
  assert(type(urls) == "array", @() $"expected urls as 'array' got '{type(urls)}'")
  assert(type(rejectOne) == "function" && type(resolveOne) == "function", "incorrect type of arguments")
  return Task(function(rejectFn, resolveFn) {
    let total = urls.len()
    let res = array(total)
    let statuses = array(total, UNRESOLVED)
    local executed = false
    let function checkStatus(){
      let rejected = statuses.findindex(@(v) v==REJECTED) != null
      let resolved = !rejected && statuses.filter(@(v) v==RESOLVED).len() == total
      if (resolved && !executed){
        executed = true
        resolveFn(res)
      }
      if (rejected && !executed){
        executed = true
        rejectFn(res)
      }
    }
    foreach (i, u in urls) {
      let id = i
      let url = u
      println($"http requested get for '{url}'")
      http.request({
        url
        method = "GET"
        callback = tryCatch(
          function(response){
            let status = response.status
            let sttxt = statusText?[status]
            println($"http status for '{url}' = {sttxt}")
            if (status != http.SUCCESS) {
              throw($"http error status = {sttxt}")
            }
            res[id] = resolveOne(response.body)
            statuses[id] = RESOLVED
            checkStatus()
          },
          function(r) {
            res[id] = rejectOne(r)
            statuses[id] = REJECTED
            checkStatus()
          }
        )
      })
    }
  })
}

return{
  TaskHttpGet
  httpGet
  TaskHttpMultiGet
}