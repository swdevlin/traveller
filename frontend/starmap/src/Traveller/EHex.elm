module Traveller.EHex exposing (EHex, eHex)

import Codec exposing (Codec)
import Json.Decode as JsDecode
import Json.Encode as JsEncode
import Parser exposing ((|.), (|=), Parser)
import Parser.Extras as Parser


{-| Expanded Hexadecimal (EHex) is a base-33 number system that uses the digits 0-9 and the letters A-Z (excluding I and O) to represent numbers. This module provides a parser for EHex numbers in UWP
-}
type EHex
    = EHex { raw : Char, value : Int }


eHex : Parser EHex
eHex =
    Parser.andThen
        (\rawString ->
            case rawString of
                Just ( c, _ ) ->
                    case c of
                        '0' ->
                            Parser.succeed <| EHex { raw = c, value = 0 }

                        '1' ->
                            Parser.succeed <| EHex { raw = c, value = 1 }

                        '2' ->
                            Parser.succeed <| EHex { raw = c, value = 2 }

                        '3' ->
                            Parser.succeed <| EHex { raw = c, value = 3 }

                        '4' ->
                            Parser.succeed <| EHex { raw = c, value = 4 }

                        '5' ->
                            Parser.succeed <| EHex { raw = c, value = 5 }

                        '6' ->
                            Parser.succeed <| EHex { raw = c, value = 6 }

                        '7' ->
                            Parser.succeed <| EHex { raw = c, value = 7 }

                        '8' ->
                            Parser.succeed <| EHex { raw = c, value = 8 }

                        '9' ->
                            Parser.succeed <| EHex { raw = c, value = 9 }

                        'A' ->
                            Parser.succeed <| EHex { raw = c, value = 10 }

                        'B' ->
                            Parser.succeed <| EHex { raw = c, value = 11 }

                        'C' ->
                            Parser.succeed <| EHex { raw = c, value = 12 }

                        'D' ->
                            Parser.succeed <| EHex { raw = c, value = 13 }

                        'E' ->
                            Parser.succeed <| EHex { raw = c, value = 14 }

                        'F' ->
                            Parser.succeed <| EHex { raw = c, value = 15 }

                        'G' ->
                            Parser.succeed <| EHex { raw = c, value = 16 }

                        'H' ->
                            Parser.succeed <| EHex { raw = c, value = 17 }

                        --NOTE: I is not included
                        'J' ->
                            Parser.succeed <| EHex { raw = c, value = 18 }

                        'K' ->
                            Parser.succeed <| EHex { raw = c, value = 19 }

                        'L' ->
                            Parser.succeed <| EHex { raw = c, value = 20 }

                        'M' ->
                            Parser.succeed <| EHex { raw = c, value = 21 }

                        'N' ->
                            Parser.succeed <| EHex { raw = c, value = 22 }

                        -- O is not included
                        'P' ->
                            Parser.succeed <| EHex { raw = c, value = 23 }

                        'Q' ->
                            Parser.succeed <| EHex { raw = c, value = 24 }

                        'R' ->
                            Parser.succeed <| EHex { raw = c, value = 25 }

                        'S' ->
                            Parser.succeed <| EHex { raw = c, value = 26 }

                        'T' ->
                            Parser.succeed <| EHex { raw = c, value = 27 }

                        'U' ->
                            Parser.succeed <| EHex { raw = c, value = 28 }

                        'V' ->
                            Parser.succeed <| EHex { raw = c, value = 29 }

                        'W' ->
                            Parser.succeed <| EHex { raw = c, value = 30 }

                        'X' ->
                            Parser.succeed <| EHex { raw = c, value = 31 }

                        'Y' ->
                            Parser.succeed <| EHex { raw = c, value = 32 }

                        'Z' ->
                            Parser.succeed <| EHex { raw = c, value = 33 }

                        invalidChar ->
                            Parser.problem <| "Invalid EHex character: " ++ String.fromChar invalidChar

                Nothing ->
                    Parser.problem "Could not parse EHex"
        )
    <|
        Parser.map String.uncons <|
            Parser.getChompedString <|
                (Parser.succeed ()
                    |. Parser.chompIf
                        (\c ->
                            Char.isAlphaNum c
                                && not (Char.isLower c)
                                && not (Char.toUpper c == 'I')
                                && not (Char.toUpper c == 'O')
                        )
                )
