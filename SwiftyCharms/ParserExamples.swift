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
}

let digit = oneOf("0123456789+-.eE".characters.map{one(String($0))})

func makeNumber(digits:[String]) throws-> Double{
    if let number = Double(digits.reduce("",combine:+)){
        return number
    }
    throw ParserError.NotMatch
}

let noneQuote = {$0.reduce("",combine:+)} <^> many(not(one("\"")))

let number = makeNumber <^> many(digit)

let string = one("\"") *> (noneQuote <|> one("\\\"")) <* one("\"")

let array = one("[") *> many(makeJSON(), sepBy: one(",")) <* one("]")

let kvpair = {x in {y in (x,y)}} <^> string <* one(":") <*> makeJSON()

let objects = many(kvpair, sepBy: one(","))

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