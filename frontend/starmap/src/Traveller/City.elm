module Traveller.City exposing (CitiesPage, City, citiesPageDecoder)

import Json.Decode as JsDecode


type alias City =
    { name : String
    , typeLabel : Maybe String
    , capitalLabel : Maybe String
    , population : Int
    }


decodeCity : JsDecode.Decoder City
decodeCity =
    JsDecode.map4 City
        (JsDecode.field "name" JsDecode.string)
        (JsDecode.maybe (JsDecode.field "type_label" JsDecode.string))
        (JsDecode.maybe (JsDecode.field "capital_label" JsDecode.string))
        (JsDecode.field "population" JsDecode.int)


type alias CitiesPage =
    { cities : List City
    , count : Int
    , page : Int
    , pages : Int
    }


citiesPageDecoder : JsDecode.Decoder CitiesPage
citiesPageDecoder =
    JsDecode.map4 CitiesPage
        (JsDecode.field "cities" (JsDecode.list decodeCity))
        (JsDecode.field "count" JsDecode.int)
        (JsDecode.field "page" JsDecode.int)
        (JsDecode.field "pages" JsDecode.int)
