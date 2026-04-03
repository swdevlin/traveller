port module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Navigation as Nav
import Dialog
import Element
import HostConfig
import Html exposing (Html, a, div, text)
import Html.Attributes exposing (class, href)
import Json.Encode
import Task
import Traveller
import Url
import Url.Parser exposing (Parser, map, oneOf, top)


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Maybe Route
    , dialogBody : Html Msg
    , isDarkMode : Bool
    , travellerModel : Maybe Traveller.Model
    , flags : Flags
    , referee : Bool
    , hostConfig : HostConfig.HostConfig
    }


type Msg
    = NoOp
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ToggleErrorDialog
    | GotTravellerMsg Traveller.Msg
    | GotViewport Browser.Dom.Viewport


type Route
    = TravellerPage


port writeToLocalStorage : ( String, String ) -> Cmd msg


port listenToLocalStorage : (Json.Encode.Value -> msg) -> Sub msg


port toggleDialog : String -> Cmd msg


port toggleDarkMode : Bool -> Cmd msg


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map TravellerPage top
        ]


type alias Flags =
    { upperLeft : Maybe ( Int, Int )
    , hexSize : Float
    , referee : Bool
    , campaignSlug : String
    , campaignName : Maybe String
    , shipName : Maybe String
    , apiBaseUrl : String
    , allSectorsMapUrl : Maybe String
    , nativeSophontColour : Maybe String
    , extinctSophontColour : Maybe String
    , viewMode : Maybe String
    }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        hostConfig : HostConfig.HostConfig
        hostConfig =
            HostConfig.fromApiBaseUrl flags.apiBaseUrl

        model : Model
        model =
            { key = key
            , url = url
            , route = Url.Parser.parse routeParser url
            , isDarkMode = False
            , dialogBody = text "Error dialog"
            , flags = flags
            , hostConfig = hostConfig
            , travellerModel = Nothing
            , referee = flags.referee
            }
    in
    ( model
    , Cmd.batch
        [ Browser.Dom.getViewport
            |> Task.perform GotViewport
        ]
    )


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


subscriptions : Model -> Sub Msg
subscriptions { travellerModel } =
    case travellerModel of
        Just ( t, tm ) ->
            Traveller.subscriptions t tm
                |> Sub.map GotTravellerMsg

        Nothing ->
            Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model
                | url = url
                , route = Url.Parser.parse routeParser url
              }
            , Cmd.none
            )

        ToggleErrorDialog ->
            ( model, toggleDialog "error-dialog" )

        GotTravellerMsg travellerMsg ->
            case model.travellerModel of
                Just tm ->
                    let
                        ( newTravellerModel, newTravellerCmds ) =
                            Traveller.update travellerMsg tm
                    in
                    ( { model | travellerModel = Just newTravellerModel }
                    , Cmd.map GotTravellerMsg newTravellerCmds
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotViewport viewport ->
            case model.travellerModel of
                Just tm ->
                    let
                        ( newTraveller, cmd ) =
                            Traveller.update (Traveller.GotViewport viewport) tm
                    in
                    ( { model | travellerModel = Just newTraveller }, Cmd.map GotTravellerMsg cmd )

                Nothing ->
                    let
                        ( newTraveller, cmd ) =
                            Traveller.init
                                viewport
                                { upperLeft = model.flags.upperLeft
                                , hexSize = model.flags.hexSize
                                , campaignName = model.flags.campaignName
                                , shipName = model.flags.shipName
                                , allSectorsMapUrl = model.flags.allSectorsMapUrl
                                , nativeSophontColour = model.flags.nativeSophontColour
                                , extinctSophontColour = model.flags.extinctSophontColour
                                , viewMode = model.flags.viewMode
                                }
                                model.key
                                model.hostConfig
                                model.referee
                        newModel =
                            { model | travellerModel = Just newTraveller }
                    in
                    ( newModel, Cmd.map GotTravellerMsg cmd )



elmUiHackLayout : Html.Html msg
elmUiHackLayout =
    Html.div [ Html.Attributes.style "height" "0" ]
        [ Element.layoutWith
            { options =
                [ Element.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                ]
            }
            [ Element.htmlAttribute <| Html.Attributes.id "hack" ]
          <|
            Element.none
        ]


view : Model -> Browser.Document Msg
view model =
    { title = model.flags.shipName |> Maybe.withDefault "Starmap"
    , body =
        [ Dialog.view "error-dialog" ToggleErrorDialog model.dialogBody
        , div
            [ Html.Attributes.style "height" "100vh"
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "padding-top" "8px"
            ]
            [ elmUiHackLayout
            , case model.travellerModel of
                Just tm ->
                    Traveller.view tm
                        |> Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
                            [ Element.centerX, Element.height Element.fill ]
                        |> Html.map GotTravellerMsg

                Nothing ->
                    Html.div [] [ Html.text "Loading" ]
            ]
        ]
    }