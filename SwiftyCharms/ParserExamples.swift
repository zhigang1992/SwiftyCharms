//
//  ParserExamples.swift
//  SwiftyCharms
//
//  Created by Ruoyu Fu on 16/2/2016.
//  Copyright © 2016 Ruoyu Fu. All rights reserved.
//

enum JSON{
    case JString(String)
    case JNumber(Double)
    case JBool(Bool)
    case JArray([JSON])
    case JObject([(String,JSON)])
    case JNull

    func toNSObject()->NSObject{
        switch self{
        case .JNull:
            return NSNull()
        case .JBool(let b):
            return b
        case .JNumber(let n):
            return n
        case .JString(let s):
            return s
        case .JArray(let jsonArray):
            return jsonArray.map{$0.toNSObject()}
        case .JObject(let jsonObject):
            var obj:[String:NSObject] = [:]
            jsonObject.forEach{
                obj[$0.0] = $0.1.toNSObject()
            }
            return obj
        }
    }
}

let digit = oneOf("0123456789+-.eE".characters.map{one(String($0))})

func makeNumber(digits:[String]) throws-> Double{
    if let number = Double(digits.reduce("",combine:+)){
        return number
    }
    throw ParserError.NotMatch
}

func trim<T>(parser:Parser<T>)->Parser<T>{
    let whitespace = many(oneOf(" \t\n\r".characters.map{one(String($0))})) <|> .unit([])
    return whitespace *> parser <* whitespace
}

let noneQuote = {$0.reduce("",combine:+)} <^> many(({_ in "\""} <^> one("\\\"")) <|> not(one("\"")))
let number = makeNumber <^> many(digit)
let string = one("\"") *> noneQuote <* one("\"")
let array = trim(one("[")) *> many(makeJSON(), sepBy: trim(one(","))) <* trim(one("]"))
let kvpair = {x in {y in (x,y)}} <^> string <* trim(one(":")) <*> makeJSON()
let objects = trim(one("{")) *> many(kvpair, sepBy: trim(one(","))) <* trim(one("}"))
let bool = ({_ in true} <^> one("true")) <|> ({_ in false} <^> one("false"))
let null = one("null")

func makeJSON()->Parser<JSON>{
    return Parser{
        try (
            {.JString($0)}  <^> string  <|>
            {.JNumber($0)}  <^> number  <|>
            {.JBool($0)}    <^> bool    <|>
            {.JArray($0)}   <^> array   <|>
            {.JObject($0)}  <^> objects <|>
            {_ in .JNull}   <^> null
        ).trunk($0)
    }
}