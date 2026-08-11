module Traveller.CommerceForm exposing (Config, Model, Msg(..), Tab(..), init, update, view)

{-| A self-contained commerce modal: pick a from/to system once, then roll
traffic for whichever commerce type is active (Passage, Freight, Mail,
Speculative Trade) against that tab's own manual referee modifiers.
Referee-only tool - there is no player-visible variant.

Like `Traveller.RoutePlanForm`, this module owns its own HTTP round trips, so
`update` returns a `Cmd Msg` and the parent wires it in with `Cmd.map`.

-}

import Browser.Dom
import HostConfig exposing (HostConfig)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events as HtmlEvents
import Http
import Json.Decode as JsDecode
import List.Extra
import RemoteData exposing (RemoteData(..))
import Task
import Traveller.FreightTraffic as FreightTraffic exposing (FreightTrafficResult, LotTypeResult, RollDetail)
import Traveller.MailTraffic as MailTraffic exposing (MailResult, MailTrafficResult)
import Traveller.PassengerTraffic as PassengerTraffic exposing (PassengerTrafficResult, PassengerTypeResult)
import Traveller.RoutePlan as RoutePlan exposing (RoutePlanEndpoint, RoutePlanSystemResult)
import Traveller.ToggleSwitch as ToggleSwitch
import Traveller.TradeGoods as TradeGoods exposing (AvailabilityResult, PriceRow, PricesResult, TradeGoodRow)
import Url.Builder


{-| DOM id of the "From" input, focused when the modal opens with no system pre-selected.
-}
fromInputId : String
fromInputId =
    "commerce-from-input"


{-| DOM id of the "To" input, focused when the modal opens with "From" already pre-selected.
-}
toInputId : String
toInputId =
    "commerce-to-input"


type alias Config =
    { hostConfig : HostConfig
    }


type Tab
    = Passage
    | Freight
    | Mail
    | Trade


type alias PickerState =
    { query : String
    , selected : Maybe RoutePlanEndpoint
    , results : RemoteData Http.Error (List RoutePlanSystemResult)
    , dropdownOpen : Bool
    , info : RemoteData Http.Error FreightTraffic.SystemInfo
    }


emptyPicker : PickerState
emptyPicker =
    { query = "", selected = Nothing, results = NotAsked, dropdownOpen = False, info = NotAsked }


type alias PassageState =
    { brokerEffect : Int
    , chiefStewardSkill : Int
    , refereeModifier : Int
    , trafficResult : RemoteData Http.Error PassengerTrafficResult
    }


emptyPassageState : PassageState
emptyPassageState =
    { brokerEffect = 0, chiefStewardSkill = 0, refereeModifier = 0, trafficResult = NotAsked }


type alias FreightState =
    { brokerEffect : Int
    , refereeModifier : Int
    , trafficResult : RemoteData Http.Error FreightTrafficResult
    }


emptyFreightState : FreightState
emptyFreightState =
    { brokerEffect = 0, refereeModifier = 0, trafficResult = NotAsked }


type alias MailState =
    { shipArmed : Bool
    , navalOrScoutRank : Int
    , socDm : Int
    , refereeModifier : Int
    , trafficResult : RemoteData Http.Error MailTrafficResult
    }


emptyMailState : MailState
emptyMailState =
    { shipArmed = False, navalOrScoutRank = 0, socDm = 0, refereeModifier = 0, trafficResult = NotAsked }


{-| Skill Effect / Broker Skill / Other DM apply the same to every good, so
Purchase and Sale each roll their whole price list in one request rather than
one good at a time - `purchaseResults` covers only the surveyed availability
list, `saleResults` covers every priceable good, since the Travellers may be
selling cargo bought anywhere.
-}
type alias TradeState =
    { availability : RemoteData Http.Error AvailabilityResult
    , purchaseSkillEffect : Int
    , purchaseBrokerSkill : Int
    , purchaseOtherDm : Int
    , purchaseUseBroker : Bool
    , purchaseBrokerLevel : Int
    , purchaseBrokerFeePercentage : Float
    , purchaseResults : RemoteData Http.Error PricesResult
    , saleSkillEffect : Int
    , saleBrokerSkill : Int
    , saleOtherDm : Int
    , saleUseBroker : Bool
    , saleBrokerLevel : Int
    , saleBrokerFeePercentage : Float
    , saleResults : RemoteData Http.Error PricesResult
    }


{-| `purchaseBrokerLevel`/`saleBrokerLevel` default to `2` and
`purchaseBrokerFeePercentage`/`saleBrokerFeePercentage` to `10`, mirroring the
campaign defaults `Campaign#local_broker_level_value`/`local_broker_fee_percentage_value`
on the Rails side (sourcebook average of a `2D/3` Broker skill roll, and its
flat 10% fee).
-}
emptyTradeState : TradeState
emptyTradeState =
    { availability = NotAsked
    , purchaseSkillEffect = 0
    , purchaseBrokerSkill = 2
    , purchaseOtherDm = 0
    , purchaseUseBroker = False
    , purchaseBrokerLevel = 2
    , purchaseBrokerFeePercentage = 10
    , purchaseResults = NotAsked
    , saleSkillEffect = 0
    , saleBrokerSkill = 2
    , saleOtherDm = 0
    , saleUseBroker = False
    , saleBrokerLevel = 2
    , saleBrokerFeePercentage = 10
    , saleResults = NotAsked
    }


type alias Model =
    { fromPicker : PickerState
    , toPicker : PickerState
    , activeTab : Tab
    , passageState : PassageState
    , freightState : FreightState
    , mailState : MailState
    , tradeState : TradeState
    }


{-| `initialFrom` pre-selects the "From" system — passed in when the modal is opened for a
system already on screen (e.g. the sidebar's Commerce button), so the referee only has to
pick the destination.
-}
init : Config -> Maybe RoutePlanEndpoint -> ( Model, Cmd Msg )
init config initialFrom =
    ( { fromPicker =
            case initialFrom of
                Just endpoint ->
                    { emptyPicker | query = endpoint.name, selected = Just endpoint, info = Loading }

                Nothing ->
                    emptyPicker
      , toPicker = emptyPicker
      , activeTab = Passage
      , passageState = emptyPassageState
      , freightState = emptyFreightState
      , mailState = emptyMailState
      , tradeState = emptyTradeState
      }
    , Cmd.batch
        [ Task.attempt (\_ -> NoOp)
            (Browser.Dom.focus
                (if initialFrom == Nothing then
                    fromInputId

                 else
                    toInputId
                )
            )
        , case initialFrom of
            Just endpoint ->
                sendSystemInfoRequest config.hostConfig endpoint.id GotFromSystemInfo

            Nothing ->
                Cmd.none
        ]
    )


type Msg
    = NoOp
    | Cancel
    | SetFromQuery String
    | GotFromResults (Result Http.Error (List RoutePlanSystemResult))
    | PickFrom RoutePlanSystemResult
    | GotFromSystemInfo (Result Http.Error FreightTraffic.SystemInfo)
    | CloseFromDropdown
    | SetToQuery String
    | GotToResults (Result Http.Error (List RoutePlanSystemResult))
    | PickTo RoutePlanSystemResult
    | GotToSystemInfo (Result Http.Error FreightTraffic.SystemInfo)
    | CloseToDropdown
    | SetTab Tab
    | SetPassageBrokerEffect Int
    | SetPassageChiefStewardSkill Int
    | SetPassageRefereeModifier Int
    | SubmitPassage
    | GotPassageResult (Result Http.Error PassengerTrafficResult)
    | SetFreightBrokerEffect Int
    | SetFreightRefereeModifier Int
    | SubmitFreight
    | GotFreightResult (Result Http.Error FreightTrafficResult)
    | SetMailShipArmed Bool
    | SetMailNavalOrScoutRank Int
    | SetMailSocDm Int
    | SetMailRefereeModifier Int
    | SubmitMail
    | GotMailResult (Result Http.Error MailTrafficResult)
    | SurveyMarket
    | GotAvailability (Result Http.Error AvailabilityResult)
    | SetPurchaseSkillEffect Int
    | SetPurchaseBrokerSkill Int
    | SetPurchaseOtherDm Int
    | SetPurchaseUseBroker Bool
    | SetPurchaseBrokerLevel Int
    | SetPurchaseBrokerFeePercentage Float
    | SubmitPurchase
    | GotPurchaseResults (Result Http.Error PricesResult)
    | SetSaleSkillEffect Int
    | SetSaleBrokerSkill Int
    | SetSaleOtherDm Int
    | SetSaleUseBroker Bool
    | SetSaleBrokerLevel Int
    | SetSaleBrokerFeePercentage Float
    | SubmitSale
    | GotSaleResults (Result Http.Error PricesResult)



-- UPDATE


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Cancel ->
            ( model, Cmd.none )

        SetFromQuery query ->
            let
                picker =
                    model.fromPicker

                newPicker =
                    { picker
                        | query = query
                        , selected = Nothing
                        , dropdownOpen = String.length query >= 3
                        , results =
                            if String.length query >= 3 then
                                Loading

                            else
                                NotAsked
                    }
            in
            ( clearResults { model | fromPicker = newPicker }
            , if String.length query >= 3 then
                sendSystemsRequest config.hostConfig query GotFromResults

              else
                Cmd.none
            )

        GotFromResults result ->
            ( { model | fromPicker = applyResults model.fromPicker result }, Cmd.none )

        PickFrom result ->
            ( clearResults
                { model
                    | fromPicker =
                        { emptyPicker
                            | query = result.name
                            , selected = Just { id = result.id, name = result.name }
                            , info = Loading
                        }
                }
            , sendSystemInfoRequest config.hostConfig result.id GotFromSystemInfo
            )

        GotFromSystemInfo result ->
            let
                picker =
                    model.fromPicker
            in
            ( { model | fromPicker = { picker | info = RemoteData.fromResult result } }, Cmd.none )

        CloseFromDropdown ->
            let
                picker =
                    model.fromPicker
            in
            ( { model | fromPicker = { picker | dropdownOpen = False } }, Cmd.none )

        SetToQuery query ->
            let
                picker =
                    model.toPicker

                newPicker =
                    { picker
                        | query = query
                        , selected = Nothing
                        , dropdownOpen = String.length query >= 3
                        , results =
                            if String.length query >= 3 then
                                Loading

                            else
                                NotAsked
                    }
            in
            ( clearResults { model | toPicker = newPicker }
            , if String.length query >= 3 then
                sendSystemsRequest config.hostConfig query GotToResults

              else
                Cmd.none
            )

        GotToResults result ->
            ( { model | toPicker = applyResults model.toPicker result }, Cmd.none )

        PickTo result ->
            ( clearResults
                { model
                    | toPicker =
                        { emptyPicker
                            | query = result.name
                            , selected = Just { id = result.id, name = result.name }
                            , info = Loading
                        }
                }
            , sendSystemInfoRequest config.hostConfig result.id GotToSystemInfo
            )

        GotToSystemInfo result ->
            let
                picker =
                    model.toPicker
            in
            ( { model | toPicker = { picker | info = RemoteData.fromResult result } }, Cmd.none )

        CloseToDropdown ->
            let
                picker =
                    model.toPicker
            in
            ( { model | toPicker = { picker | dropdownOpen = False } }, Cmd.none )

        SetTab tab ->
            ( { model | activeTab = tab }, Cmd.none )

        SetPassageBrokerEffect value ->
            ( updatePassageState (\s -> { s | brokerEffect = value, trafficResult = NotAsked }) model, Cmd.none )

        SetPassageChiefStewardSkill value ->
            ( updatePassageState (\s -> { s | chiefStewardSkill = value, trafficResult = NotAsked }) model, Cmd.none )

        SetPassageRefereeModifier value ->
            ( updatePassageState (\s -> { s | refereeModifier = value, trafficResult = NotAsked }) model, Cmd.none )

        SubmitPassage ->
            case ( model.fromPicker.selected, model.toPicker.selected ) of
                ( Just from, Just to ) ->
                    ( updatePassageState (\s -> { s | trafficResult = Loading }) model
                    , sendPassageRequest config.hostConfig
                        { fromId = from.id
                        , toId = to.id
                        , brokerEffect = model.passageState.brokerEffect
                        , chiefStewardSkill = model.passageState.chiefStewardSkill
                        , refereeModifier = model.passageState.refereeModifier
                        }
                    )

                _ ->
                    ( model, Cmd.none )

        GotPassageResult result ->
            ( updatePassageState (\s -> { s | trafficResult = RemoteData.fromResult result }) model, Cmd.none )

        SetFreightBrokerEffect value ->
            ( updateFreightState (\s -> { s | brokerEffect = value, trafficResult = NotAsked }) model, Cmd.none )

        SetFreightRefereeModifier value ->
            ( updateFreightState (\s -> { s | refereeModifier = value, trafficResult = NotAsked }) model, Cmd.none )

        SubmitFreight ->
            case ( model.fromPicker.selected, model.toPicker.selected ) of
                ( Just from, Just to ) ->
                    ( updateFreightState (\s -> { s | trafficResult = Loading }) model
                    , sendFreightRequest config.hostConfig
                        { fromId = from.id
                        , toId = to.id
                        , brokerEffect = model.freightState.brokerEffect
                        , refereeModifier = model.freightState.refereeModifier
                        }
                    )

                _ ->
                    ( model, Cmd.none )

        GotFreightResult result ->
            ( updateFreightState (\s -> { s | trafficResult = RemoteData.fromResult result }) model, Cmd.none )

        SetMailShipArmed value ->
            ( updateMailState (\s -> { s | shipArmed = value, trafficResult = NotAsked }) model, Cmd.none )

        SetMailNavalOrScoutRank value ->
            ( updateMailState (\s -> { s | navalOrScoutRank = value, trafficResult = NotAsked }) model, Cmd.none )

        SetMailSocDm value ->
            ( updateMailState (\s -> { s | socDm = value, trafficResult = NotAsked }) model, Cmd.none )

        SetMailRefereeModifier value ->
            ( updateMailState (\s -> { s | refereeModifier = value, trafficResult = NotAsked }) model, Cmd.none )

        SubmitMail ->
            case ( model.fromPicker.selected, model.toPicker.selected ) of
                ( Just from, Just to ) ->
                    ( updateMailState (\s -> { s | trafficResult = Loading }) model
                    , sendMailRequest config.hostConfig
                        { fromId = from.id
                        , toId = to.id
                        , shipArmed = model.mailState.shipArmed
                        , navalOrScoutRank = model.mailState.navalOrScoutRank
                        , socDm = model.mailState.socDm
                        , refereeModifier = model.mailState.refereeModifier
                        }
                    )

                _ ->
                    ( model, Cmd.none )

        GotMailResult result ->
            ( updateMailState (\s -> { s | trafficResult = RemoteData.fromResult result }) model, Cmd.none )

        SurveyMarket ->
            case model.fromPicker.selected of
                Just from ->
                    ( updateTradeState
                        (\s -> { s | availability = Loading, purchaseResults = NotAsked })
                        model
                    , sendAvailabilityRequest config.hostConfig from.id
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotAvailability result ->
            ( updateTradeState (\s -> { s | availability = RemoteData.fromResult result }) model, Cmd.none )

        SetPurchaseSkillEffect value ->
            ( updateTradeState (\s -> { s | purchaseSkillEffect = value }) model, Cmd.none )

        SetPurchaseBrokerSkill value ->
            ( updateTradeState (\s -> { s | purchaseBrokerSkill = value }) model, Cmd.none )

        SetPurchaseOtherDm value ->
            ( updateTradeState (\s -> { s | purchaseOtherDm = value }) model, Cmd.none )

        SetPurchaseUseBroker value ->
            ( updateTradeState (\s -> { s | purchaseUseBroker = value }) model, Cmd.none )

        SetPurchaseBrokerLevel value ->
            ( updateTradeState (\s -> { s | purchaseBrokerLevel = value }) model, Cmd.none )

        SetPurchaseBrokerFeePercentage value ->
            ( updateTradeState (\s -> { s | purchaseBrokerFeePercentage = value }) model, Cmd.none )

        SubmitPurchase ->
            case ( model.fromPicker.selected, RemoteData.toMaybe model.tradeState.availability ) of
                ( Just from, Just availability ) ->
                    let
                        purchaseableD66s =
                            availability.goods
                                |> List.filter (\g -> g.basePrice /= Nothing)
                                |> List.map .d66
                    in
                    ( updateTradeState (\s -> { s | purchaseResults = Loading }) model
                    , sendPricesRequest config.hostConfig
                        { id = from.id
                        , direction = "purchase"
                        , skillEffect = model.tradeState.purchaseSkillEffect
                        , counterpartBrokerSkill = model.tradeState.purchaseBrokerSkill
                        , otherDm = model.tradeState.purchaseOtherDm
                        , useBroker = model.tradeState.purchaseUseBroker
                        , brokerLevel = model.tradeState.purchaseBrokerLevel
                        , brokerFeePercentage = model.tradeState.purchaseBrokerFeePercentage
                        , d66s = purchaseableD66s
                        }
                        GotPurchaseResults
                    )

                _ ->
                    ( model, Cmd.none )

        GotPurchaseResults result ->
            ( updateTradeState (\s -> { s | purchaseResults = RemoteData.fromResult result }) model, Cmd.none )

        SetSaleSkillEffect value ->
            ( updateTradeState (\s -> { s | saleSkillEffect = value }) model, Cmd.none )

        SetSaleBrokerSkill value ->
            ( updateTradeState (\s -> { s | saleBrokerSkill = value }) model, Cmd.none )

        SetSaleOtherDm value ->
            ( updateTradeState (\s -> { s | saleOtherDm = value }) model, Cmd.none )

        SetSaleUseBroker value ->
            ( updateTradeState (\s -> { s | saleUseBroker = value }) model, Cmd.none )

        SetSaleBrokerLevel value ->
            ( updateTradeState (\s -> { s | saleBrokerLevel = value }) model, Cmd.none )

        SetSaleBrokerFeePercentage value ->
            ( updateTradeState (\s -> { s | saleBrokerFeePercentage = value }) model, Cmd.none )

        SubmitSale ->
            case model.toPicker.selected of
                Just to ->
                    ( updateTradeState (\s -> { s | saleResults = Loading }) model
                    , sendPricesRequest config.hostConfig
                        { id = to.id
                        , direction = "sale"
                        , skillEffect = model.tradeState.saleSkillEffect
                        , counterpartBrokerSkill = model.tradeState.saleBrokerSkill
                        , otherDm = model.tradeState.saleOtherDm
                        , useBroker = model.tradeState.saleUseBroker
                        , brokerLevel = model.tradeState.saleBrokerLevel
                        , brokerFeePercentage = model.tradeState.saleBrokerFeePercentage
                        , d66s = []
                        }
                        GotSaleResults
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotSaleResults result ->
            ( updateTradeState (\s -> { s | saleResults = RemoteData.fromResult result }) model, Cmd.none )


updatePassageState : (PassageState -> PassageState) -> Model -> Model
updatePassageState f model =
    { model | passageState = f model.passageState }


updateFreightState : (FreightState -> FreightState) -> Model -> Model
updateFreightState f model =
    { model | freightState = f model.freightState }


updateMailState : (MailState -> MailState) -> Model -> Model
updateMailState f model =
    { model | mailState = f model.mailState }


updateTradeState : (TradeState -> TradeState) -> Model -> Model
updateTradeState f model =
    { model | tradeState = f model.tradeState }


{-| Origin/destination changed, so all tabs' last-rolled results are stale.
-}
clearResults : Model -> Model
clearResults model =
    { model
        | passageState = { emptyPassageState | brokerEffect = model.passageState.brokerEffect, chiefStewardSkill = model.passageState.chiefStewardSkill, refereeModifier = model.passageState.refereeModifier }
        , freightState = { emptyFreightState | brokerEffect = model.freightState.brokerEffect, refereeModifier = model.freightState.refereeModifier }
        , mailState = { emptyMailState | shipArmed = model.mailState.shipArmed, navalOrScoutRank = model.mailState.navalOrScoutRank, socDm = model.mailState.socDm, refereeModifier = model.mailState.refereeModifier }
        , tradeState =
            { emptyTradeState
                | purchaseSkillEffect = model.tradeState.purchaseSkillEffect
                , purchaseBrokerSkill = model.tradeState.purchaseBrokerSkill
                , purchaseOtherDm = model.tradeState.purchaseOtherDm
                , saleSkillEffect = model.tradeState.saleSkillEffect
                , saleBrokerSkill = model.tradeState.saleBrokerSkill
                , saleOtherDm = model.tradeState.saleOtherDm
            }
    }


applyResults : PickerState -> Result Http.Error (List RoutePlanSystemResult) -> PickerState
applyResults picker result =
    case result of
        Ok results ->
            let
                stillValid =
                    String.length picker.query >= 3
            in
            { picker
                | results =
                    if stillValid then
                        Success results

                    else
                        NotAsked
                , dropdownOpen = stillValid && not (List.isEmpty results)
            }

        Err err ->
            { picker | results = Failure err, dropdownOpen = False }



-- HTTP


sendSystemInfoRequest : HostConfig -> Int -> (Result Http.Error FreightTraffic.SystemInfo -> Msg) -> Cmd Msg
sendSystemInfoRequest ( urlRoot, urlPath ) systemId toMsg =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "freight_traffic", "system" ])
                (FreightTraffic.systemQuery { id = systemId })
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg FreightTraffic.systemInfoDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


sendSystemsRequest : HostConfig -> String -> (Result Http.Error (List RoutePlanSystemResult) -> Msg) -> Cmd Msg
sendSystemsRequest ( urlRoot, urlPath ) query toMsg =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "route_plan", "systems" ])
                [ Url.Builder.string "q" query ]
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg (JsDecode.list RoutePlan.routePlanSystemResultDecoder)
        , timeout = Just 15000
        , tracker = Nothing
        }


sendPassageRequest :
    HostConfig
    -> { fromId : Int, toId : Int, brokerEffect : Int, chiefStewardSkill : Int, refereeModifier : Int }
    -> Cmd Msg
sendPassageRequest ( urlRoot, urlPath ) params =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "passenger_traffic" ])
                (PassengerTraffic.trafficQuery params)
        , body = Http.emptyBody
        , expect = Http.expectJson GotPassageResult PassengerTraffic.passengerTrafficResultDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


sendFreightRequest :
    HostConfig
    -> { fromId : Int, toId : Int, brokerEffect : Int, refereeModifier : Int }
    -> Cmd Msg
sendFreightRequest ( urlRoot, urlPath ) params =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "freight_traffic" ])
                (FreightTraffic.trafficQuery params)
        , body = Http.emptyBody
        , expect = Http.expectJson GotFreightResult FreightTraffic.freightTrafficResultDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


sendMailRequest :
    HostConfig
    -> { fromId : Int, toId : Int, shipArmed : Bool, navalOrScoutRank : Int, socDm : Int, refereeModifier : Int }
    -> Cmd Msg
sendMailRequest ( urlRoot, urlPath ) params =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "mail_traffic" ])
                (MailTraffic.trafficQuery params)
        , body = Http.emptyBody
        , expect = Http.expectJson GotMailResult MailTraffic.mailTrafficResultDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


sendAvailabilityRequest : HostConfig -> Int -> Cmd Msg
sendAvailabilityRequest ( urlRoot, urlPath ) systemId =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "trade_goods", "availability" ])
                (TradeGoods.availabilityQuery { id = systemId, seed = Nothing })
        , body = Http.emptyBody
        , expect = Http.expectJson GotAvailability TradeGoods.availabilityResultDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }


sendPricesRequest :
    HostConfig
    ->
        { id : Int
        , direction : String
        , skillEffect : Int
        , counterpartBrokerSkill : Int
        , otherDm : Int
        , useBroker : Bool
        , brokerLevel : Int
        , brokerFeePercentage : Float
        , d66s : List Int
        }
    -> (Result Http.Error PricesResult -> Msg)
    -> Cmd Msg
sendPricesRequest ( urlRoot, urlPath ) params toMsg =
    Http.request
        { method = "GET"
        , headers = []
        , url =
            Url.Builder.crossOrigin urlRoot
                (urlPath ++ [ "trade_goods", "prices" ])
                (TradeGoods.pricesQuery params)
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg TradeGoods.pricesResultDecoder
        , timeout = Just 15000
        , tracker = Nothing
        }



-- VIEW


view : Config -> Model -> Html Msg
view _ model =
    Html.div
        [ HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "z-index" "200"
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlAttrs.style "background-color" "rgba(0, 0, 0, 0.35)"
        , HtmlEvents.onClick Cancel
        ]
        [ Html.div
            [ HtmlAttrs.class "starmap-glass-panel"
            , HtmlAttrs.style "width" "min(760px, 94vw)"
            , HtmlAttrs.style "max-height" "85vh"
            , HtmlAttrs.style "overflow-y" "auto"
            , HtmlAttrs.style "border-radius" "6px"
            , HtmlAttrs.style "padding" "20px"
            , stopPropagation
            ]
            [ viewHeader
            , viewPickerField "From" model.fromPicker SetFromQuery PickFrom CloseFromDropdown
            , viewPickerField "To" model.toPicker SetToQuery PickTo CloseToDropdown
            , viewTabBar model.activeTab
            , viewActiveTab model
            ]
        ]


{-| Stops a click inside the panel from bubbling up to the backdrop's
`Cancel` handler. Dispatches `NoOp` (not `Cancel`) - `stopPropagationOn`
always sends its message, it only suppresses bubbling, so using `Cancel`
here would close the modal on every inner click.
-}
stopPropagation : Html.Attribute Msg
stopPropagation =
    HtmlEvents.stopPropagationOn "click" (JsDecode.succeed ( NoOp, True ))


viewHeader : Html Msg
viewHeader =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "justify-content" "space-between"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "margin-bottom" "14px"
        ]
        [ Html.span [ HtmlAttrs.style "font-size" "16px", HtmlAttrs.style "font-weight" "bold", HtmlAttrs.style "color" "var(--color-fg-bright)" ]
            [ Html.text "Commerce" ]
        , Html.span
            [ HtmlAttrs.style "cursor" "pointer"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlEvents.onClick Cancel
            ]
            [ Html.text "✕" ]
        ]


fieldLabel : String -> Html msg
fieldLabel label =
    Html.div
        [ HtmlAttrs.style "font-size" "11px"
        , HtmlAttrs.style "text-transform" "uppercase"
        , HtmlAttrs.style "letter-spacing" "0.15em"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        , HtmlAttrs.style "margin-bottom" "4px"
        ]
        [ Html.text label ]


viewPickerField : String -> PickerState -> (String -> Msg) -> (RoutePlanSystemResult -> Msg) -> Msg -> Html Msg
viewPickerField label picker onQuery onPick onClose =
    Html.div
        [ HtmlAttrs.style "margin-bottom" "12px", HtmlAttrs.style "position" "relative" ]
        [ fieldLabel label
        , Html.input
            ([ HtmlAttrs.type_ "text"
             , HtmlAttrs.value picker.query
             , HtmlAttrs.placeholder "Search for a system…"
             , HtmlAttrs.style "width" "100%"
             , HtmlAttrs.style "box-sizing" "border-box"
             , HtmlAttrs.style "font-size" "13px"
             , HtmlAttrs.style "color" "var(--color-fg-bright)"
             , HtmlAttrs.style "background-color" "var(--color-panel)"
             , HtmlAttrs.style "border" "1px solid var(--color-outline)"
             , HtmlAttrs.style "border-radius" "4px"
             , HtmlAttrs.style "padding" "6px"
             , HtmlEvents.onInput onQuery
             , HtmlEvents.stopPropagationOn "keydown"
                (JsDecode.field "key" JsDecode.string
                    |> JsDecode.map
                        (\key ->
                            if key == "Escape" then
                                ( onClose, True )

                            else
                                ( NoOp, True )
                        )
                )
             ]
                ++ (if label == "From" then
                        [ HtmlAttrs.id fromInputId ]

                    else if label == "To" then
                        [ HtmlAttrs.id toInputId ]

                    else
                        []
                   )
            )
            []
        , if picker.dropdownOpen then
            viewPickerDropdown picker onPick onClose

          else
            Html.text ""
        , viewSystemInfo picker.info
        ]


{-| UWP + trade codes + travel zone under a picked From/To system, matching
what the Rails-rendered Commerce page shows for every tab.
-}
viewSystemInfo : RemoteData Http.Error FreightTraffic.SystemInfo -> Html Msg
viewSystemInfo info =
    case info of
        Success systemInfo ->
            Html.div
                [ HtmlAttrs.style "margin-top" "6px"
                , HtmlAttrs.style "font-size" "11px"
                , HtmlAttrs.style "color" "var(--color-fg-muted)"
                ]
                [ Html.span
                    [ HtmlAttrs.style "font-family" "monospace", HtmlAttrs.style "color" "var(--color-fg-bright)" ]
                    [ Html.text (Maybe.withDefault "—" systemInfo.uwp) ]
                , Html.text (" · " ++ tradeCodesAndZoneLabel systemInfo)
                ]

        _ ->
            Html.text ""


tradeCodesAndZoneLabel : FreightTraffic.SystemInfo -> String
tradeCodesAndZoneLabel { tradeCodes, travelZone } =
    let
        codes =
            if List.isEmpty tradeCodes then
                "—"

            else
                String.join " " tradeCodes
    in
    case travelZone of
        Just zone ->
            codes ++ " · " ++ zone ++ " Zone"

        Nothing ->
            codes


viewPickerDropdown : PickerState -> (RoutePlanSystemResult -> Msg) -> Msg -> Html Msg
viewPickerDropdown picker onPick onClose =
    Html.div
        [ HtmlAttrs.class "starmap-glass-panel"
        , HtmlAttrs.style "position" "absolute"
        , HtmlAttrs.style "top" "100%"
        , HtmlAttrs.style "left" "0"
        , HtmlAttrs.style "right" "0"
        , HtmlAttrs.style "margin-top" "4px"
        , HtmlAttrs.style "border-radius" "4px"
        , HtmlAttrs.style "padding" "4px"
        , HtmlAttrs.style "z-index" "10"
        , HtmlAttrs.style "max-height" "220px"
        , HtmlAttrs.style "overflow-y" "auto"
        ]
        (case picker.results of
            Loading ->
                [ Html.div [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "Searching…" ]
                ]

            Success [] ->
                [ Html.div [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "No matches" ]
                ]

            Success results ->
                List.map (viewPickerResultRow onPick) results

            Failure _ ->
                [ Html.div [ HtmlAttrs.style "font-size" "12px", HtmlAttrs.style "color" "var(--color-danger)", HtmlAttrs.style "padding" "8px" ]
                    [ Html.text "Search failed" ]
                ]

            NotAsked ->
                []
        )


viewPickerResultRow : (RoutePlanSystemResult -> Msg) -> RoutePlanSystemResult -> Html Msg
viewPickerResultRow onPick result =
    Html.div
        [ HtmlAttrs.style "padding" "6px 8px"
        , HtmlAttrs.style "cursor" "pointer"
        , HtmlAttrs.style "border-radius" "3px"
        , HtmlAttrs.class "starmap-search-result"
        , HtmlEvents.onMouseDown (onPick result)
        ]
        [ Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-bright)" ] [ Html.text result.name ]
        , Html.div [ HtmlAttrs.style "font-size" "11px", HtmlAttrs.style "color" "var(--color-fg-muted)" ] [ Html.text result.meta ]
        ]



-- TAB BAR


allTabs : List Tab
allTabs =
    [ Passage, Freight, Mail, Trade ]


tabLabel : Tab -> String
tabLabel tab =
    case tab of
        Passage ->
            "Passage"

        Freight ->
            "Freight"

        Mail ->
            "Mail"

        Trade ->
            "Speculative Trade"


viewTabBar : Tab -> Html Msg
viewTabBar activeTab =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "gap" "4px"
        , HtmlAttrs.style "border-bottom" "1px solid var(--color-outline)"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        (List.map (viewTabButton activeTab) allTabs)


viewTabButton : Tab -> Tab -> Html Msg
viewTabButton activeTab tab =
    let
        isActive =
            tab == activeTab
    in
    Html.div
        [ HtmlAttrs.style "padding" "8px 12px"
        , HtmlAttrs.style "font-size" "12px"
        , HtmlAttrs.style "font-weight" "600"
        , HtmlAttrs.style "cursor" "pointer"
        , HtmlAttrs.style "border-bottom"
            (if isActive then
                "2px solid var(--color-highlight)"

             else
                "2px solid transparent"
            )
        , HtmlAttrs.style "color"
            (if isActive then
                "var(--color-fg-bright)"

             else
                "var(--color-fg-muted)"
            )
        , HtmlEvents.onClick (SetTab tab)
        ]
        [ Html.text (tabLabel tab) ]


viewActiveTab : Model -> Html Msg
viewActiveTab model =
    case model.activeTab of
        Passage ->
            viewPassageTab model.fromPicker model.toPicker model.passageState

        Freight ->
            viewFreightTab model.fromPicker model.toPicker model.freightState

        Mail ->
            viewMailTab model.fromPicker model.toPicker model.mailState

        Trade ->
            viewTradeTab model.fromPicker model.toPicker model.tradeState


viewNumberInput : String -> Int -> (Int -> Msg) -> Html Msg
viewNumberInput label value toMsg =
    Html.div []
        [ fieldLabel label
        , Html.input
            [ HtmlAttrs.type_ "number"
            , HtmlAttrs.value (String.fromInt value)
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "box-sizing" "border-box"
            , HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            , HtmlAttrs.style "background-color" "var(--color-panel)"
            , HtmlAttrs.style "border" "1px solid var(--color-outline)"
            , HtmlAttrs.style "border-radius" "4px"
            , HtmlAttrs.style "padding" "6px"
            , HtmlEvents.onInput (\s -> toMsg (String.toInt s |> Maybe.withDefault value))
            ]
            []
        ]


{-| Like `viewNumberInput`, but for values (e.g. Broker Fee %) that a referee
may want to enter as a decimal, mirroring the Rails Trade tab's fee field —
`step` stays `1` since most referees use whole-number percents, but a decimal
can still be typed in directly.
-}
viewFloatInput : String -> Float -> (Float -> Msg) -> Html Msg
viewFloatInput label value toMsg =
    Html.div []
        [ fieldLabel label
        , Html.input
            [ HtmlAttrs.type_ "number"
            , HtmlAttrs.step "1"
            , HtmlAttrs.value (formatFee value)
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "box-sizing" "border-box"
            , HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            , HtmlAttrs.style "background-color" "var(--color-panel)"
            , HtmlAttrs.style "border" "1px solid var(--color-outline)"
            , HtmlAttrs.style "border-radius" "4px"
            , HtmlAttrs.style "padding" "6px"
            , HtmlEvents.onInput (\s -> toMsg (String.toFloat s |> Maybe.withDefault value))
            ]
            []
        ]


{-| Formats a percentage without a trailing `.0` for whole numbers, mirroring
Rails' `number_with_precision(value, precision: 2, strip_insignificant_zeros: true)`.
-}
formatFee : Float -> String
formatFee value =
    if value == toFloat (round value) then
        String.fromInt (round value)

    else
        String.fromFloat value


viewStatRow : List ( String, String ) -> Html Msg
viewStatRow stats =
    Html.div
        [ HtmlAttrs.style "display" "grid"
        , HtmlAttrs.style "grid-template-columns" ("repeat(" ++ String.fromInt (List.length stats) ++ ", 1fr)")
        , HtmlAttrs.style "gap" "8px 16px"
        , HtmlAttrs.style "text-align" "center"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        (List.map viewStatTile stats)


viewStatTile : ( String, String ) -> Html Msg
viewStatTile ( label, value ) =
    Html.div []
        [ Html.div
            [ HtmlAttrs.style "font-size" "10px"
            , HtmlAttrs.style "text-transform" "uppercase"
            , HtmlAttrs.style "letter-spacing" "0.08em"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlAttrs.style "margin-bottom" "2px"
            ]
            [ Html.text label ]
        , Html.div
            [ HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "font-weight" "600"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            ]
            [ Html.text value ]
        ]


rollDescription : { a | dice : Int, sides : Int, dm : Int, rolls : List Int, total : Int } -> String
rollDescription roll =
    String.fromInt roll.dice
        ++ "D"
        ++ String.fromInt roll.sides
        ++ (if roll.dm /= 0 then
                signedString roll.dm

            else
                ""
           )
        ++ " ["
        ++ String.join ", " (List.map String.fromInt roll.rolls)
        ++ "] = "
        ++ String.fromInt roll.total


signedString : Int -> String
signedString value =
    if value >= 0 then
        "+" ++ String.fromInt value

    else
        String.fromInt value



-- PASSAGE TAB


viewPassageTab : PickerState -> PickerState -> PassageState -> Html Msg
viewPassageTab fromPicker toPicker state =
    Html.div []
        [ Html.div
            [ HtmlAttrs.style "display" "grid"
            , HtmlAttrs.style "grid-template-columns" "1fr 1fr 1fr"
            , HtmlAttrs.style "gap" "12px"
            , HtmlAttrs.style "margin-bottom" "12px"
            ]
            [ viewNumberInput "Skill Effect" state.brokerEffect SetPassageBrokerEffect
            , viewNumberInput "Steward" state.chiefStewardSkill SetPassageChiefStewardSkill
            , viewNumberInput "Other DM" state.refereeModifier SetPassageRefereeModifier
            ]
        , Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.style "margin-bottom" "12px"
            , HtmlAttrs.disabled (fromPicker.selected == Nothing || toPicker.selected == Nothing)
            , HtmlEvents.onClick SubmitPassage
            ]
            [ Html.text "Departure Board" ]
        , viewPassageResult state.trafficResult
        ]


viewPassageResult : RemoteData Http.Error PassengerTrafficResult -> Html Msg
viewPassageResult trafficResult =
    case trafficResult of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                [ Html.text "Updating board…" ]

        Failure _ ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-danger)" ]
                [ Html.text "Could not compute passenger traffic. Please try again." ]

        Success result ->
            Html.div []
                [ viewStatRow
                    [ ( "Origin", result.from.name )
                    , ( "Destination", result.to.name )
                    , ( "Parsec Distance", String.fromInt result.parsecDistance )
                    ]
                , Html.div
                    [ HtmlAttrs.style "display" "grid"
                    , HtmlAttrs.style "grid-template-columns" "1fr 1fr"
                    , HtmlAttrs.style "gap" "10px"
                    ]
                    [ viewPassengerTypeCard "Low" result.passengerTypes.low
                    , viewPassengerTypeCard "Basic" result.passengerTypes.basic
                    , viewPassengerTypeCard "Middle" result.passengerTypes.middle
                    , viewPassengerTypeCard "High" result.passengerTypes.high
                    ]
                ]


viewPassengerTypeCard : String -> PassengerTypeResult -> Html Msg
viewPassengerTypeCard label result =
    Html.div
        [ HtmlAttrs.style "border" "1px solid var(--color-outline)"
        , HtmlAttrs.style "border-radius" "6px"
        , HtmlAttrs.style "padding" "10px"
        ]
        [ Html.div
            [ HtmlAttrs.style "font-size" "10px"
            , HtmlAttrs.style "text-transform" "uppercase"
            , HtmlAttrs.style "letter-spacing" "0.08em"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            ]
            [ Html.text label ]
        , Html.div
            [ HtmlAttrs.style "font-size" "26px"
            , HtmlAttrs.style "font-weight" "700"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            ]
            [ Html.text (String.fromInt result.passengers) ]
        , Html.div [ HtmlAttrs.style "font-size" "11px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
            [ Html.text ("Total DM: " ++ signedString result.qualifyingRoll.dm) ]
        , if List.isEmpty result.modifiers then
            Html.text ""

          else
            Html.div [ HtmlAttrs.style "margin-top" "6px" ]
                (List.map
                    (\m ->
                        Html.div [ HtmlAttrs.style "font-size" "11px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                            [ Html.text ("• " ++ m.label ++ " (" ++ signedString m.value ++ ")") ]
                    )
                    result.modifiers
                )
        , Html.div
            [ HtmlAttrs.style "margin-top" "8px"
            , HtmlAttrs.style "padding-top" "6px"
            , HtmlAttrs.style "border-top" "1px solid color-mix(in srgb, var(--color-outline) 30%, transparent)"
            , HtmlAttrs.style "font-family" "monospace"
            , HtmlAttrs.style "font-size" "11px"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            ]
            (Html.div [] [ Html.text ("Qualifying: " ++ rollDescription result.qualifyingRoll) ]
                :: (case result.countRoll of
                        Just countRoll ->
                            [ Html.div [] [ Html.text ("Count: " ++ rollDescription countRoll) ] ]

                        Nothing ->
                            []
                   )
            )
        ]



-- FREIGHT TAB


viewFreightTab : PickerState -> PickerState -> FreightState -> Html Msg
viewFreightTab fromPicker toPicker state =
    Html.div []
        [ Html.div
            [ HtmlAttrs.style "display" "grid"
            , HtmlAttrs.style "grid-template-columns" "1fr 1fr"
            , HtmlAttrs.style "gap" "12px"
            , HtmlAttrs.style "margin-bottom" "12px"
            ]
            [ viewNumberInput "Skill Effect" state.brokerEffect SetFreightBrokerEffect
            , viewNumberInput "Other DM" state.refereeModifier SetFreightRefereeModifier
            ]
        , Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.style "margin-bottom" "12px"
            , HtmlAttrs.disabled (fromPicker.selected == Nothing || toPicker.selected == Nothing)
            , HtmlEvents.onClick SubmitFreight
            ]
            [ Html.text "Cargo Manifest" ]
        , viewFreightResult state.trafficResult
        ]


viewFreightResult : RemoteData Http.Error FreightTrafficResult -> Html Msg
viewFreightResult trafficResult =
    case trafficResult of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                [ Html.text "Compiling manifest…" ]

        Failure _ ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-danger)" ]
                [ Html.text "Could not compute freight traffic. Please try again." ]

        Success result ->
            Html.div []
                [ viewStatRow
                    [ ( "Origin", result.from.name )
                    , ( "Destination", result.to.name )
                    , ( "Parsec Distance", String.fromInt result.parsecDistance )
                    ]
                , Html.div
                    [ HtmlAttrs.style "display" "grid"
                    , HtmlAttrs.style "grid-template-columns" "1fr 1fr 1fr"
                    , HtmlAttrs.style "gap" "10px"
                    ]
                    [ viewLotTypeCard "Incidental" result.lotTypes.incidental
                    , viewLotTypeCard "Minor" result.lotTypes.minor
                    , viewLotTypeCard "Major" result.lotTypes.major
                    ]
                ]


viewLotTypeCard : String -> LotTypeResult -> Html Msg
viewLotTypeCard label result =
    Html.div
        [ HtmlAttrs.style "border" "1px solid var(--color-outline)"
        , HtmlAttrs.style "border-radius" "6px"
        , HtmlAttrs.style "padding" "10px"
        ]
        [ Html.div
            [ HtmlAttrs.style "font-size" "10px"
            , HtmlAttrs.style "text-transform" "uppercase"
            , HtmlAttrs.style "letter-spacing" "0.08em"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            ]
            [ Html.text label ]
        , if List.isEmpty result.lotSizeRolls then
            Html.text ""

          else
            Html.div [ HtmlAttrs.style "margin-top" "6px" ]
                (List.map
                    (\line -> Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg)" ] [ Html.text line ])
                    (lotSizeSummary result.lotSizeRolls)
                )
        , Html.div
            [ HtmlAttrs.style "margin-top" "6px"
            , HtmlAttrs.style "font-size" "11px"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            ]
            [ Html.text (pluralizeLots result.lots ++ " for " ++ pluralizeTons result.totalTons) ]
        , Html.div
            [ HtmlAttrs.style "margin-top" "8px"
            , HtmlAttrs.style "padding-top" "6px"
            , HtmlAttrs.style "border-top" "1px solid color-mix(in srgb, var(--color-outline) 30%, transparent)"
            , HtmlAttrs.style "font-size" "11px"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            ]
            (List.concat
                [ [ Html.div [] [ Html.text ("Total DM: " ++ signedString result.qualifyingRoll.dm) ] ]
                , List.map
                    (\m -> Html.div [] [ Html.text ("• " ++ m.label ++ " (" ++ signedString m.value ++ ")") ])
                    result.modifiers
                , [ Html.div [ HtmlAttrs.style "font-family" "monospace", HtmlAttrs.style "margin-top" "4px" ]
                        [ Html.text ("Qualifying: " ++ rollDescription result.qualifyingRoll) ]
                  ]
                , case result.lotsRoll of
                    Just lotsRoll ->
                        [ Html.div [ HtmlAttrs.style "font-family" "monospace" ] [ Html.text ("Lots: " ++ rollDescription lotsRoll) ] ]

                    Nothing ->
                        []
                ]
            )
        ]


{-| Combines individually-rolled lot sizes into "N lots of X tons each" groups,
largest first — the audit trail (which dice rolled which size) isn't useful to
the referee once the lots are found.
-}
lotSizeSummary : List RollDetail -> List String
lotSizeSummary rolls =
    rolls
        |> List.filterMap .tons
        |> List.Extra.gatherEquals
        |> List.map (\( tons, rest ) -> ( tons, List.length rest + 1 ))
        |> List.sortBy (\( tons, _ ) -> -tons)
        |> List.map
            (\( tons, count ) ->
                if count == 1 then
                    "1 lot of " ++ pluralizeTons tons

                else
                    String.fromInt count ++ " lots of " ++ pluralizeTons tons ++ " each"
            )


pluralizeLots : Int -> String
pluralizeLots lots =
    String.fromInt lots
        ++ " lot"
        ++ (if lots == 1 then
                ""

            else
                "s"
           )


pluralizeTons : Int -> String
pluralizeTons tons =
    String.fromInt tons
        ++ " ton"
        ++ (if tons == 1 then
                ""

            else
                "s"
           )



-- MAIL TAB


viewToggleInput : String -> Bool -> (Bool -> Msg) -> Html Msg
viewToggleInput label value toMsg =
    Html.div [ HtmlAttrs.style "padding-top" "4px" ]
        [ fieldLabel label
        , Html.div [ HtmlAttrs.style "padding-top" "2px" ]
            [ ToggleSwitch.view ToggleSwitch.Regular value (HtmlEvents.onClick (toMsg (not value))) ]
        ]


viewMailTab : PickerState -> PickerState -> MailState -> Html Msg
viewMailTab fromPicker toPicker state =
    Html.div []
        [ Html.div
            [ HtmlAttrs.style "display" "grid"
            , HtmlAttrs.style "grid-template-columns" "1fr 1fr 1fr 1fr"
            , HtmlAttrs.style "gap" "12px"
            , HtmlAttrs.style "margin-bottom" "12px"
            ]
            [ viewToggleInput "Ship Armed" state.shipArmed SetMailShipArmed
            , viewNumberInput "Naval/Scout Rank" state.navalOrScoutRank SetMailNavalOrScoutRank
            , viewNumberInput "SOC DM" state.socDm SetMailSocDm
            , viewNumberInput "Other DM" state.refereeModifier SetMailRefereeModifier
            ]
        , Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.style "margin-bottom" "12px"
            , HtmlAttrs.disabled (fromPicker.selected == Nothing || toPicker.selected == Nothing)
            , HtmlEvents.onClick SubmitMail
            ]
            [ Html.text "Mail Manifest" ]
        , viewMailResult state.trafficResult
        ]


viewMailResult : RemoteData Http.Error MailTrafficResult -> Html Msg
viewMailResult trafficResult =
    case trafficResult of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                [ Html.text "Compiling manifest…" ]

        Failure _ ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-danger)" ]
                [ Html.text "Could not compute mail traffic. Please try again." ]

        Success result ->
            Html.div []
                [ viewStatRow
                    [ ( "Origin", result.from.name )
                    , ( "Destination", result.to.name )
                    , ( "Freight Traffic DM", signedString result.freightTrafficDm )
                    ]
                , viewMailResultCard result.modifiers result.result
                ]


viewMailResultCard : List MailTraffic.Modifier -> MailResult -> Html Msg
viewMailResultCard modifiers result =
    Html.div
        [ HtmlAttrs.style "border" "1px solid var(--color-outline)"
        , HtmlAttrs.style "border-radius" "6px"
        , HtmlAttrs.style "padding" "10px"
        ]
        [ if result.available then
            Html.div
                [ HtmlAttrs.style "display" "grid"
                , HtmlAttrs.style "grid-template-columns" "1fr 1fr 1fr"
                , HtmlAttrs.style "gap" "10px"
                ]
                [ viewMailStatTile "Containers" (String.fromInt result.containers)
                , viewMailStatTile "Tonnage" (pluralizeTons result.totalTons)
                , viewMailStatTile "Payment" ("Cr" ++ String.fromInt result.totalPayment)
                ]

          else
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                [ Html.text "No mail is available for this route." ]
        , Html.div
            [ HtmlAttrs.style "margin-top" "8px"
            , HtmlAttrs.style "padding-top" "6px"
            , HtmlAttrs.style "border-top" "1px solid color-mix(in srgb, var(--color-outline) 30%, transparent)"
            , HtmlAttrs.style "font-size" "11px"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            ]
            (List.concat
                [ [ Html.div [] [ Html.text ("Total DM: " ++ signedString result.qualifyingRoll.dm) ] ]
                , List.map
                    (\m -> Html.div [] [ Html.text ("• " ++ m.label ++ " (" ++ signedString m.value ++ ")") ])
                    modifiers
                , [ Html.div [ HtmlAttrs.style "font-family" "monospace", HtmlAttrs.style "margin-top" "4px" ]
                        [ Html.text ("Qualifying: " ++ rollDescription result.qualifyingRoll) ]
                  ]
                , case result.containersRoll of
                    Just containersRoll ->
                        [ Html.div [ HtmlAttrs.style "font-family" "monospace" ] [ Html.text ("Containers: " ++ rollDescription containersRoll) ] ]

                    Nothing ->
                        []
                ]
            )
        ]


viewMailStatTile : String -> String -> Html Msg
viewMailStatTile label value =
    Html.div []
        [ Html.div
            [ HtmlAttrs.style "font-size" "10px"
            , HtmlAttrs.style "text-transform" "uppercase"
            , HtmlAttrs.style "letter-spacing" "0.08em"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            ]
            [ Html.text label ]
        , Html.div
            [ HtmlAttrs.style "font-size" "18px"
            , HtmlAttrs.style "font-weight" "700"
            , HtmlAttrs.style "color" "var(--color-fg-bright)"
            ]
            [ Html.text value ]
        ]



-- TRADE TAB


viewTradeTab : PickerState -> PickerState -> TradeState -> Html Msg
viewTradeTab fromPicker toPicker state =
    Html.div []
        [ Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.style "margin-bottom" "12px"
            , HtmlAttrs.disabled (fromPicker.selected == Nothing)
            , HtmlEvents.onClick SurveyMarket
            ]
            [ Html.text "Survey Market" ]
        , case state.availability of
            NotAsked ->
                Html.text ""

            Loading ->
                Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                    [ Html.text "Surveying market…" ]

            Failure _ ->
                Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-danger)" ]
                    [ Html.text "Could not survey the market. Please try again." ]

            Success availability ->
                viewTradeAvailability toPicker availability state
        ]


viewTradeAvailability : PickerState -> AvailabilityResult -> TradeState -> Html Msg
viewTradeAvailability toPicker availability state =
    Html.div []
        [ viewStatRow
            [ ( "Population", String.fromInt availability.population )
            , ( "Trade Codes", tradeCodesLabel availability.tradeCodes )
            ]
        , viewPurchaseSection availability.goods state
        , viewSaleSection toPicker state
        ]


tradeCodesLabel : List String -> String
tradeCodesLabel codes =
    if List.isEmpty codes then
        "—"

    else
        String.join " " codes


{-| Skill Effect / Broker Skill / Other DM apply the same to every good, so
one submit rolls Purchase Price for the whole surveyed goods list at once —
the result is shown as an extra column in that same table.

Hiring a local broker replaces the "Skill Effect" field with "Level"/"Fee %"
fields for that broker, mirroring the Rails Trade tab's `trade-broker-toggle`
Stimulus controller — the fields are swapped, not stacked, so the row's width
follows whichever set is active rather than reserving space for both.
-}
viewPurchaseSection : List TradeGoodRow -> TradeState -> Html Msg
viewPurchaseSection goods state =
    let
        fields =
            viewToggleInput "Local Broker" state.purchaseUseBroker SetPurchaseUseBroker
                :: (if state.purchaseUseBroker then
                        [ viewNumberInput "Level" state.purchaseBrokerLevel SetPurchaseBrokerLevel
                        , viewFloatInput "Fee %" state.purchaseBrokerFeePercentage SetPurchaseBrokerFeePercentage
                        ]

                    else
                        [ viewNumberInput "Skill Effect" state.purchaseSkillEffect SetPurchaseSkillEffect ]
                   )
                ++ [ viewNumberInput "Supplier Broker Skill" state.purchaseBrokerSkill SetPurchaseBrokerSkill
                   , viewNumberInput "Other DM" state.purchaseOtherDm SetPurchaseOtherDm
                   ]
    in
    Html.div []
        [ sectionHeading "Purchase"
        , Html.div
            [ HtmlAttrs.style "display" "grid"
            , HtmlAttrs.style "grid-template-columns" ("repeat(" ++ String.fromInt (List.length fields) ++ ", 1fr)")
            , HtmlAttrs.style "gap" "12px"
            , HtmlAttrs.style "margin-bottom" "12px"
            ]
            fields
        , Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.style "margin-bottom" "12px"
            , HtmlEvents.onClick SubmitPurchase
            ]
            [ Html.text "Negotiate Purchase Prices" ]
        , case state.purchaseResults of
            Loading ->
                Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "margin-bottom" "8px" ]
                    [ Html.text "Rolling purchase prices…" ]

            Failure _ ->
                Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-danger)", HtmlAttrs.style "margin-bottom" "8px" ]
                    [ Html.text "Could not roll purchase prices. Please try again." ]

            _ ->
                Html.text ""
        , viewGoodsTable goods state.purchaseResults
        ]


viewGoodsTable : List TradeGoodRow -> RemoteData Http.Error PricesResult -> Html Msg
viewGoodsTable goods purchaseResults =
    let
        priceFor d66 =
            case purchaseResults of
                Success prices ->
                    List.Extra.find (\r -> r.d66 == d66) prices.results

                _ ->
                    Nothing

        showPriceColumn =
            case purchaseResults of
                Success _ ->
                    True

                _ ->
                    False
    in
    Html.table
        [ HtmlAttrs.style "width" "100%"
        , HtmlAttrs.style "font-size" "12px"
        , HtmlAttrs.style "border-collapse" "collapse"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        [ Html.thead []
            [ Html.tr []
                (List.concat
                    [ [ viewHeaderCell "Good", viewHeaderCell "Tons", viewHeaderCell "Base Price" ]
                    , if showPriceColumn then
                        [ viewHeaderCell "Purchase Price" ]

                      else
                        []
                    ]
                )
            ]
        , Html.tbody [] (List.map (viewGoodRow priceFor showPriceColumn) goods)
        ]


viewGoodRow : (Int -> Maybe PriceRow) -> Bool -> TradeGoodRow -> Html Msg
viewGoodRow priceFor showPriceColumn good =
    Html.tr []
        (List.concat
            [ [ viewCell good.name
              , viewCell (good.tons |> Maybe.map String.fromInt |> Maybe.withDefault "—")
              , viewCell (good.basePrice |> Maybe.map (\p -> "Cr" ++ String.fromInt p) |> Maybe.withDefault "—")
              ]
            , if showPriceColumn then
                [ viewPriceCell (priceFor good.d66) ]

              else
                []
            ]
        )


viewPriceCell : Maybe PriceRow -> Html Msg
viewPriceCell maybeRow =
    Html.td
        [ HtmlAttrs.style "padding" "4px 6px"
        , HtmlAttrs.style "border-bottom" "1px solid color-mix(in srgb, var(--color-outline) 30%, transparent)"
        , HtmlAttrs.style "color" "var(--color-fg)"
        ]
        (case maybeRow of
            Nothing ->
                [ Html.text "—" ]

            Just row ->
                [ Html.div [] [ Html.text ("Cr" ++ String.fromInt row.result.netPricePerTon) ]
                , Html.div [ HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                    [ Html.text
                        (String.fromInt row.result.percent
                            ++ "% · DM "
                            ++ signedString row.result.qualifyingRoll.dm
                            ++ (if row.result.feePercentage > 0 then
                                    " · Broker fee " ++ formatFee row.result.feePercentage ++ "%"

                                else
                                    ""
                               )
                        )
                    ]
                ]
        )


{-| Rolls Sale Price for every priceable good, not only the ones from the
Purchase survey - the Travellers may be selling cargo bought anywhere.
-}
viewSaleSection : PickerState -> TradeState -> Html Msg
viewSaleSection toPicker state =
    let
        fields =
            viewToggleInput "Local Broker" state.saleUseBroker SetSaleUseBroker
                :: (if state.saleUseBroker then
                        [ viewNumberInput "Level" state.saleBrokerLevel SetSaleBrokerLevel
                        , viewFloatInput "Fee %" state.saleBrokerFeePercentage SetSaleBrokerFeePercentage
                        ]

                    else
                        [ viewNumberInput "Skill Effect" state.saleSkillEffect SetSaleSkillEffect ]
                   )
                ++ [ viewNumberInput "Buyer Broker Skill" state.saleBrokerSkill SetSaleBrokerSkill
                   , viewNumberInput "Other DM" state.saleOtherDm SetSaleOtherDm
                   ]
    in
    Html.div []
        [ sectionHeading "Sale"
        , Html.div
            [ HtmlAttrs.style "display" "grid"
            , HtmlAttrs.style "grid-template-columns" ("repeat(" ++ String.fromInt (List.length fields) ++ ", 1fr)")
            , HtmlAttrs.style "gap" "12px"
            , HtmlAttrs.style "margin-bottom" "12px"
            ]
            fields
        , Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "width" "100%"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.style "margin-bottom" "12px"
            , HtmlAttrs.disabled (toPicker.selected == Nothing)
            , HtmlEvents.onClick SubmitSale
            ]
            [ Html.text "Negotiate Sale Prices" ]
        , viewSaleResults state.saleResults
        ]


viewSaleResults : RemoteData Http.Error PricesResult -> Html Msg
viewSaleResults saleResults =
    case saleResults of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-fg-muted)" ]
                [ Html.text "Rolling sale prices…" ]

        Failure _ ->
            Html.div [ HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "color" "var(--color-danger)" ]
                [ Html.text "Could not roll sale prices. Please try again." ]

        Success prices ->
            Html.table
                [ HtmlAttrs.style "width" "100%"
                , HtmlAttrs.style "font-size" "12px"
                , HtmlAttrs.style "border-collapse" "collapse"
                , HtmlAttrs.style "margin-bottom" "12px"
                ]
                [ Html.thead []
                    [ Html.tr [] [ viewHeaderCell "Good", viewHeaderCell "Sale Price" ] ]
                , Html.tbody [] (List.map viewSaleRow prices.results)
                ]


viewSaleRow : PriceRow -> Html Msg
viewSaleRow row =
    Html.tr []
        [ viewCell row.name
        , viewPriceCell (Just row)
        ]


sectionHeading : String -> Html Msg
sectionHeading label =
    Html.div
        [ HtmlAttrs.style "font-size" "13px"
        , HtmlAttrs.style "font-weight" "600"
        , HtmlAttrs.style "color" "var(--color-fg-bright)"
        , HtmlAttrs.style "margin" "4px 0 8px"
        ]
        [ Html.text label ]


viewHeaderCell : String -> Html Msg
viewHeaderCell label =
    Html.th
        [ HtmlAttrs.style "text-align" "left"
        , HtmlAttrs.style "padding" "4px 6px"
        , HtmlAttrs.style "border-bottom" "1px solid var(--color-outline)"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        ]
        [ Html.text label ]


viewCell : String -> Html Msg
viewCell value =
    Html.td
        [ HtmlAttrs.style "padding" "4px 6px"
        , HtmlAttrs.style "border-bottom" "1px solid color-mix(in srgb, var(--color-outline) 30%, transparent)"
        , HtmlAttrs.style "color" "var(--color-fg)"
        ]
        [ Html.text value ]
