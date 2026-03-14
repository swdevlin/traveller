module Traveller.Starport exposing (Starport, description, parser)

{-

   Starport Classifications
   Class A
   Excellent quality installation. Refined fuel available. Annual maintenance overhaul available. Shipyard capable of both starship and non-starship construction present.
   Class B
   Good quality installation. Refined fuel available. Annual maintenance overhaul available. Shipyard capable of constructing non-starships present.
   Class C
   Routine quality installation. Only unrefined fuel available. Reasonable repair facilities are present.
   Class D
   Poor quality installation. Only unrefined fuel available. No repair or shipyard facilities present.
   Class E
   Frontier installation. Essentially a bare spot of bedrock with no fuel, facilities, or bases present.
   Class X
   No starport. Class X starports are generally indicative of an interdiction. No provision is made for any starship landings and such landings are probably prohibited.
-}

import Parser exposing ((|.), Parser)


type Starport
    = ClassA
    | ClassB
    | ClassC
    | ClassD
    | ClassE
    | ClassX


description : Starport -> String
description class =
    case class of
        ClassA ->
            "Excellent quality installation. Refined fuel available. Annual maintenance overhaul available. Shipyard capable of both starship and non-starship construction present."

        ClassB ->
            "Good quality installation. Refined fuel available. Annual maintenance overhaul available. Shipyard capable of constructing non-starships present."

        ClassC ->
            "Routine quality installation. Only unrefined fuel available. Reasonable repair facilities are present."

        ClassD ->
            "Poor quality installation. Only unrefined fuel available. No repair or shipyard facilities present."

        ClassE ->
            "Frontier installation. Essentially a bare spot of bedrock with no fuel, facilities, or bases present."

        ClassX ->
            "No starport."


parser : Parser Starport
parser =
    Parser.oneOf
        [ Parser.succeed ClassA |. Parser.symbol "A"
        , Parser.succeed ClassB |. Parser.symbol "B"
        , Parser.succeed ClassC |. Parser.symbol "C"
        , Parser.succeed ClassD |. Parser.symbol "D"
        , Parser.succeed ClassE |. Parser.symbol "E"
        , Parser.succeed ClassX |. Parser.symbol "X"
        ]
