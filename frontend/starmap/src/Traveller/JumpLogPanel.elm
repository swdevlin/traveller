module Traveller.JumpLogPanel exposing (Config, Model, Msg(..), init, update, view)

{-| The starmap jump log: a read-only table of every jump for all viewers, plus
(for the referee only) an Add button and a per-row Edit button that open a form.

Everything is a real HTTP round trip, so `update` returns a `Cmd Msg` and the
parent wires it in with `Cmd.map`, the same shape as
`Traveller.JumpRouteLayerEditor`. On a successful save the panel reloads its
own table; the parent intercepts `GotSaveResult (Ok ())` to refresh the map lines.

Authorisation is enforced by `Api::JumpLogsController` (`create` and `update`
need the referee session or the API token); hiding the buttons here is only a
convenience.

-}

import HostConfig exposing (HostConfig)
import Html exposing (Html)
import Html.Attributes as HtmlAttrs
import Html.Events as HtmlEvents
import Http
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..))
import Traveller.JumpLog as JumpLog
    exposing
        ( JumpLog
        , ParsecOption
        , SectorOption
        , ShipOption
        )
import Traveller.ToggleSwitch as ToggleSwitch
import Url.Builder


type alias Config =
    { hostConfig : HostConfig
    , isReferee : Bool
    }


type alias Model =
    { jumps : RemoteData Http.Error (List JumpLog)
    , ships : List ShipOption
    , sectors : List SectorOption
    , page : Int
    , shipFilter : Maybe Int
    , form : Maybe Form
    , pendingDeleteId : Maybe Int
    , deleteError : Maybe String

    -- Universal coordinates of the destination of the jump last sent to be
    -- saved, so the parent can update what it has cached for that hex.
    , lastDestination : Maybe ( Int, Int )
    }


type alias Form =
    { editingId : Maybe Int
    , shipId : Maybe Int
    , fromSectorId : Maybe Int
    , fromParsecId : Maybe Int
    , fromParsecs : List ParsecOption
    , toSectorId : Maybe Int
    , toParsecId : Maybe Int
    , toParsecs : List ParsecOption
    , departYear : String
    , departDay : String
    , arriveYear : String
    , arriveDay : String
    , misjump : Bool
    , notes : String
    , saving : Bool
    , errors : List String
    }


type Side
    = From
    | To


type Msg
    = NoOp
    | Close
    | GotJumps (Result Http.Error (List JumpLog))
    | GotShips (Result Http.Error (List ShipOption))
    | GotSectors (Result Http.Error (List SectorOption))
    | PreviousPage
    | NextPage
    | SetShipFilter String
    | AddClicked
    | EditClicked JumpLog
    | CancelForm
    | RequestDelete Int
    | CancelDelete
    | ConfirmDelete Int
    | GotDeleteResult (Result (List String) ())
    | SetShip String
    | SetSector Side String
    | SetParsec Side String
    | GotParsecs Side Int (Result Http.Error (List ParsecOption))
    | GotLastJump (Result Http.Error (Maybe JumpLog.LastJump))
    | ClampDates
    | SetDepartYear String
    | SetDepartDay String
    | SetArriveYear String
    | SetArriveDay String
    | SetMisjump Bool
    | SetNotes String
    | Save
    | GotSaveResult (Result (List String) ())


pageSize : Int
pageSize =
    20


init : Config -> ( Model, Cmd Msg )
init config =
    ( { jumps = Loading
      , ships = []
      , sectors = []
      , page = 0
      , shipFilter = Nothing
      , form = Nothing
      , pendingDeleteId = Nothing
      , deleteError = Nothing
      , lastDestination = Nothing
      }
    , Cmd.batch
        [ fetchJumps config.hostConfig
        , fetchShips config.hostConfig
        , fetchSectors config.hostConfig
        ]
    )


emptyForm : Form
emptyForm =
    { editingId = Nothing
    , shipId = Nothing
    , fromSectorId = Nothing
    , fromParsecId = Nothing
    , fromParsecs = []
    , toSectorId = Nothing
    , toParsecId = Nothing
    , toParsecs = []
    , departYear = ""
    , departDay = ""
    , arriveYear = ""
    , arriveDay = ""
    , misjump = False
    , notes = ""
    , saving = False
    , errors = []
    }



-- UPDATE


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Close ->
            ( model, Cmd.none )

        GotJumps result ->
            ( { model | jumps = RemoteData.fromResult result }, Cmd.none )

        GotShips result ->
            ( { model | ships = Result.withDefault [] result }, Cmd.none )

        GotSectors result ->
            ( { model | sectors = Result.withDefault [] result }, Cmd.none )

        PreviousPage ->
            ( { model | page = max 0 (model.page - 1) }, Cmd.none )

        NextPage ->
            ( { model | page = model.page + 1 }, Cmd.none )

        SetShipFilter value ->
            ( { model | shipFilter = String.toInt value, page = 0 }, Cmd.none )

        AddClicked ->
            -- A ship filtered in the table is the ship being added to, so start
            -- from its last known position as choosing it in the form would.
            -- With only one ship there is nothing to choose, so it is used.
            case onlyShipId model |> Maybe.map Just |> Maybe.withDefault model.shipFilter of
                Just shipId ->
                    ( { model | form = Just { emptyForm | shipId = Just shipId } }
                    , fetchLastJump config.hostConfig shipId
                    )

                Nothing ->
                    ( { model | form = Just emptyForm }, Cmd.none )

        EditClicked jump ->
            startEdit config model jump

        CancelForm ->
            ( { model | form = Nothing }, Cmd.none )

        RequestDelete id ->
            ( { model | pendingDeleteId = Just id, deleteError = Nothing }, Cmd.none )

        CancelDelete ->
            ( { model | pendingDeleteId = Nothing }, Cmd.none )

        ConfirmDelete id ->
            ( { model | pendingDeleteId = Nothing }, sendDelete config.hostConfig id )

        GotDeleteResult (Ok ()) ->
            ( { model | jumps = Loading, deleteError = Nothing }, fetchJumps config.hostConfig )

        GotDeleteResult (Err errors) ->
            ( { model | deleteError = List.head errors }, Cmd.none )

        SetShip value ->
            case String.toInt value of
                Nothing ->
                    updateForm (\f -> { f | shipId = Nothing }) model

                Just shipId ->
                    let
                        ( newModel, _ ) =
                            updateForm (\f -> { f | shipId = Just shipId }) model

                        isNew =
                            model.form |> Maybe.map (\f -> f.editingId == Nothing) |> Maybe.withDefault False
                    in
                    ( newModel
                    , if isNew then
                        fetchLastJump config.hostConfig shipId

                      else
                        Cmd.none
                    )

        SetSector side value ->
            case String.toInt value of
                Nothing ->
                    updateForm (clearSide side) model

                Just sectorId ->
                    let
                        ( newModel, _ ) =
                            updateForm (clearSide side >> setSector side sectorId) model
                    in
                    ( newModel, fetchParsecs config.hostConfig side sectorId )

        SetParsec side value ->
            updateForm (setParsec side (String.toInt value)) model

        GotParsecs side sectorId result ->
            updateForm
                (\f ->
                    if sectorFor side f == Just sectorId then
                        setParsecs side (Result.withDefault [] result) f

                    else
                        f
                )
                model

        GotLastJump result ->
            case result of
                Ok (Just last) ->
                    let
                        ( year, day ) =
                            ( last.arriveYear, last.arriveDay )

                        ( arriveYear, arriveDay ) =
                            JumpLog.addDays JumpLog.defaultTravelDays ( year, day )

                        ( newModel, _ ) =
                            updateForm
                                (\f ->
                                    { f
                                        | fromSectorId = Just last.sectorId
                                        , fromParsecId = Just last.parsecId
                                        , departYear = String.fromInt year
                                        , departDay = String.fromInt day
                                        , arriveYear = String.fromInt arriveYear
                                        , arriveDay = String.fromInt arriveDay
                                    }
                                )
                                model
                    in
                    ( newModel, fetchParsecs config.hostConfig From last.sectorId )

                _ ->
                    ( model, Cmd.none )

        ClampDates ->
            updateForm (clampDates model) model

        SetDepartYear value ->
            updateForm (\f -> autoArrive { f | departYear = value }) model

        SetDepartDay value ->
            updateForm (\f -> autoArrive { f | departDay = value }) model

        SetArriveYear value ->
            updateForm (\f -> { f | arriveYear = value }) model

        SetArriveDay value ->
            updateForm (\f -> { f | arriveDay = value }) model

        SetMisjump value ->
            updateForm (\f -> clampDates model { f | misjump = value }) model

        SetNotes value ->
            updateForm (\f -> { f | notes = value }) model

        Save ->
            case model.form of
                Nothing ->
                    ( model, Cmd.none )

                Just form ->
                    case toDraft form of
                        Nothing ->
                            updateForm (\f -> { f | errors = [ "Please complete every field." ] }) model

                        Just draft ->
                            ( { model
                                | form = Just { form | saving = True, errors = [] }
                                , lastDestination = destinationCoordinates form
                              }
                            , sendSave config.hostConfig form.editingId draft
                            )

        GotSaveResult (Ok ()) ->
            ( { model | form = Nothing, jumps = Loading }
            , fetchJumps config.hostConfig
            )

        GotSaveResult (Err errors) ->
            updateForm (\f -> { f | saving = False, errors = errors }) model


{-| The ship's id when the campaign has exactly one ship.
-}
onlyShipId : Model -> Maybe Int
onlyShipId model =
    case model.ships of
        [ ship ] ->
            Just ship.id

        _ ->
            Nothing


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm change model =
    ( { model | form = Maybe.map change model.form }, Cmd.none )


startEdit : Config -> Model -> JumpLog -> ( Model, Cmd Msg )
startEdit config model jump =
    let
        sectorIdNamed name =
            model.sectors
                |> List.filter (\s -> s.name == name)
                |> List.head
                |> Maybe.map .id

        fromSectorId =
            sectorIdNamed jump.fromSectorName

        toSectorId =
            sectorIdNamed jump.toSectorName

        form =
            { emptyForm
                | editingId = Just jump.id
                , shipId = Just jump.shipId
                , fromSectorId = fromSectorId
                , fromParsecId = Just jump.fromParsecId
                , toSectorId = toSectorId
                , toParsecId = Just jump.toParsecId
                , departYear = String.fromInt jump.departYear
                , departDay = String.fromInt jump.departDay
                , arriveYear = String.fromInt jump.arriveYear
                , arriveDay = String.fromInt jump.arriveDay
                , misjump = jump.misjump
                , notes = jump.notes
            }
    in
    ( { model | form = Just form }
    , Cmd.batch
        [ fromSectorId |> Maybe.map (fetchParsecs config.hostConfig From) |> Maybe.withDefault Cmd.none
        , toSectorId |> Maybe.map (fetchParsecs config.hostConfig To) |> Maybe.withDefault Cmd.none
        ]
    )


clearSide : Side -> Form -> Form
clearSide side form =
    case side of
        From ->
            { form | fromSectorId = Nothing, fromParsecId = Nothing, fromParsecs = [] }

        To ->
            { form | toSectorId = Nothing, toParsecId = Nothing, toParsecs = [] }


setSector : Side -> Int -> Form -> Form
setSector side sectorId form =
    case side of
        From ->
            { form | fromSectorId = Just sectorId }

        To ->
            { form | toSectorId = Just sectorId }


sectorFor : Side -> Form -> Maybe Int
sectorFor side form =
    case side of
        From ->
            form.fromSectorId

        To ->
            form.toSectorId


setParsec : Side -> Maybe Int -> Form -> Form
setParsec side parsecId form =
    case side of
        From ->
            { form | fromParsecId = parsecId }

        To ->
            { form | toParsecId = parsecId }


setParsecs : Side -> List ParsecOption -> Form -> Form
setParsecs side parsecs form =
    case side of
        From ->
            { form | fromParsecs = parsecs }

        To ->
            { form | toParsecs = parsecs }


{-| Changing the departure date moves the arrival to departure plus the usual
travel time, as the Rails form does. Left alone if the departure is incomplete.
-}
autoArrive : Form -> Form
autoArrive form =
    case ( String.toInt form.departYear, String.toInt form.departDay ) of
        ( Just year, Just day ) ->
            let
                ( arriveYear, arriveDay ) =
                    JumpLog.addDays JumpLog.defaultTravelDays ( year, day )
            in
            { form | arriveYear = String.fromInt arriveYear, arriveDay = String.fromInt arriveDay }

        _ ->
            form


destinationCoordinates : Form -> Maybe ( Int, Int )
destinationCoordinates form =
    form.toParsecId
        |> Maybe.andThen (\id -> List.filter (\p -> p.id == id) form.toParsecs |> List.head)
        |> Maybe.map (\p -> ( p.x, p.y ))


toDraft : Form -> Maybe JumpLog.Draft
toDraft form =
    Maybe.map5
        (\shipId fromId toId ( departYear, departDay ) ( arriveYear, arriveDay ) ->
            { shipId = shipId
            , fromParsecId = fromId
            , toParsecId = toId
            , departYear = departYear
            , departDay = departDay
            , arriveYear = arriveYear
            , arriveDay = arriveDay
            , misjump = form.misjump
            , notes = form.notes
            }
        )
        form.shipId
        form.fromParsecId
        form.toParsecId
        (Maybe.map2 Tuple.pair (String.toInt form.departYear) (String.toInt form.departDay))
        (Maybe.map2 Tuple.pair (String.toInt form.arriveYear) (String.toInt form.arriveDay))


{-| Parsecs between the chosen origin and destination, when both are known.
-}
formDistance : Form -> Maybe Int
formDistance form =
    let
        find id parsecs =
            id |> Maybe.andThen (\i -> List.filter (\p -> p.id == i) parsecs |> List.head)
    in
    Maybe.map2
        (\a b -> JumpLog.hexDistance ( a.x, a.y ) ( b.x, b.y ))
        (find form.fromParsecId form.fromParsecs)
        (find form.toParsecId form.toParsecs)


{-| The limits on the dates, worked out from the ship's other jumps. Rails
enforces the same rules; here they stop bad dates being entered at all.

  - The departure is never earlier than the ship's previous arrival.
  - Unless the jump is a misjump, the arrival is at least
    `minimumTravelDays` after the departure.

The `...TooEarly` flags apply to new jumps and to edits that change the dates,
so an old record's notes can still be corrected after the rules were added.

-}
type alias DateRules =
    { earliestDeparture : Maybe ( Int, Int )
    , earliestArrival : Maybe ( Int, Int )
    , departureTooEarly : Bool
    , arrivalTooEarly : Bool
    }


dateRules : Model -> Form -> DateRules
dateRules model form =
    let
        depart =
            Maybe.map2 Tuple.pair (String.toInt form.departYear) (String.toInt form.departDay)

        arrive =
            Maybe.map2 Tuple.pair (String.toInt form.arriveYear) (String.toInt form.arriveDay)

        original =
            form.editingId
                |> Maybe.andThen
                    (\id ->
                        RemoteData.toMaybe model.jumps
                            |> Maybe.andThen (List.filter (\j -> j.id == id) >> List.head)
                    )

        earliestDeparture =
            case ( form.shipId, RemoteData.toMaybe model.jumps ) of
                ( Just shipId, Just jumps ) ->
                    JumpLog.previousArrival jumps shipId form.editingId

                _ ->
                    Nothing

        earliestArrival =
            if form.misjump then
                Nothing

            else
                Maybe.map (JumpLog.addDays JumpLog.minimumTravelDays) depart

        departChanged =
            case ( original, depart ) of
                ( Just jump, Just d ) ->
                    ( jump.departYear, jump.departDay ) /= d || Just jump.shipId /= form.shipId

                _ ->
                    True

        travelChanged =
            case ( original, arrive ) of
                ( Just jump, Just a ) ->
                    departChanged || ( jump.arriveYear, jump.arriveDay ) /= a || jump.misjump /= form.misjump

                _ ->
                    True

        isBefore limit value =
            case ( value, limit ) of
                ( Just v, Just l ) ->
                    v < l

                _ ->
                    False
    in
    { earliestDeparture = earliestDeparture
    , earliestArrival = earliestArrival
    , departureTooEarly = departChanged && isBefore earliestDeparture depart
    , arrivalTooEarly = travelChanged && isBefore earliestArrival arrive
    }


{-| Moves any date that breaks the rules up to its limit. A departure that is
raised also resets the arrival to the usual travel time after it.
-}
clampDates : Model -> Form -> Form
clampDates model form =
    let
        rules =
            dateRules model form

        withDeparture =
            case ( rules.departureTooEarly, rules.earliestDeparture ) of
                ( True, Just ( year, day ) ) ->
                    autoArrive { form | departYear = String.fromInt year, departDay = String.fromInt day }

                _ ->
                    form

        afterDeparture =
            dateRules model withDeparture
    in
    case ( afterDeparture.arrivalTooEarly, afterDeparture.earliestArrival ) of
        ( True, Just ( year, day ) ) ->
            { withDeparture | arriveYear = String.fromInt year, arriveDay = String.fromInt day }

        _ ->
            withDeparture


{-| Anything still wrong with the dates, which keeps Save disabled until the
fields are corrected (typed values are clamped when a field loses focus).
-}
formProblems : Model -> Form -> List String
formProblems model form =
    let
        rules =
            dateRules model form
    in
    List.filterMap identity
        [ if rules.departureTooEarly then
            rules.earliestDeparture
                |> Maybe.map
                    (\( year, day ) ->
                        "Departure cannot be earlier than the ship’s previous arrival (" ++ JumpLog.formatDate year day ++ ")."
                    )

          else
            Nothing
        , if rules.arrivalTooEarly then
            Just ("Arrival must be at least " ++ String.fromInt JumpLog.minimumTravelDays ++ " days after departure, unless the jump is a misjump.")

          else
            Nothing
        ]


shipJumpDrive : Model -> Form -> Maybe Int
shipJumpDrive model form =
    form.shipId
        |> Maybe.andThen (\id -> List.filter (\s -> s.id == id) model.ships |> List.head)
        |> Maybe.andThen .jumpDrive


jumpRange : Model -> Form -> Int
jumpRange model form =
    shipJumpDrive model form |> Maybe.withDefault JumpLog.defaultJumpRange


fromParsec : Form -> Maybe ParsecOption
fromParsec form =
    form.fromParsecId
        |> Maybe.andThen (\id -> List.filter (\p -> p.id == id) form.fromParsecs |> List.head)


{-| A misjump lands somewhere unintended, so it is not bounded by the ship's
range. Otherwise the destination choices need a ship and an origin to be
measured from.
-}
boundedByRange : Form -> Bool
boundedByRange form =
    not form.misjump


{-| Sectors that hold a hex within the ship's range of its origin. The sector
already chosen is always kept, so editing an old jump still shows it.
-}
toSectorChoices : Model -> Form -> List SectorOption
toSectorChoices model form =
    if not (boundedByRange form) then
        model.sectors

    else
        case ( form.shipId, fromParsec form ) of
            ( Just _, Just origin ) ->
                model.sectors
                    |> List.filter
                        (\s ->
                            Just s.id
                                == form.toSectorId
                                || JumpLog.sectorInRange (jumpRange model form) ( origin.x, origin.y ) s
                        )

            _ ->
                []


{-| Hexes of the destination sector within the ship's range of its origin.
-}
toParsecChoices : Model -> Form -> List ParsecOption
toParsecChoices model form =
    if not (boundedByRange form) then
        form.toParsecs

    else
        case fromParsec form of
            Just origin ->
                form.toParsecs
                    |> List.filter
                        (\p ->
                            Just p.id
                                == form.toParsecId
                                || JumpLog.hexDistance ( origin.x, origin.y ) ( p.x, p.y )
                                <= jumpRange model form
                        )

            Nothing ->
                []


{-| The jump exceeds the ship's drive rating. Only a warning on a misjump,
which by definition lands somewhere unintended.
-}
outOfRange : Model -> Form -> Bool
outOfRange model form =
    case formDistance form of
        Just distance ->
            distance > jumpRange model form && not form.misjump

        Nothing ->
            False



-- HTTP


apiUrl : HostConfig -> List String -> List Url.Builder.QueryParameter -> String
apiUrl ( urlRoot, urlPath ) segments query =
    Url.Builder.crossOrigin urlRoot (urlPath ++ segments) query


fetchJumps : HostConfig -> Cmd Msg
fetchJumps hostConfig =
    Http.get
        { url = apiUrl hostConfig [ "jumps" ] []
        , expect = Http.expectJson GotJumps (Decode.list JumpLog.jumpDecoder)
        }


fetchShips : HostConfig -> Cmd Msg
fetchShips hostConfig =
    Http.get
        { url = apiUrl hostConfig [ "ships" ] []
        , expect = Http.expectJson GotShips (Decode.list JumpLog.shipDecoder)
        }


fetchSectors : HostConfig -> Cmd Msg
fetchSectors hostConfig =
    Http.get
        { url = apiUrl hostConfig [ "sectors" ] []
        , expect = Http.expectJson GotSectors (Decode.list JumpLog.sectorDecoder)
        }


fetchParsecs : HostConfig -> Side -> Int -> Cmd Msg
fetchParsecs hostConfig side sectorId =
    Http.get
        { url = apiUrl hostConfig [ "parsecs" ] [ Url.Builder.int "sector_id" sectorId ]
        , expect = Http.expectJson (GotParsecs side sectorId) (Decode.list JumpLog.parsecDecoder)
        }


fetchLastJump : HostConfig -> Int -> Cmd Msg
fetchLastJump hostConfig shipId =
    Http.get
        { url = apiUrl hostConfig [ "ships", String.fromInt shipId, "last_jump" ] []
        , expect = Http.expectJson GotLastJump JumpLog.lastJumpDecoder
        }


sendSave : HostConfig -> Maybe Int -> JumpLog.Draft -> Cmd Msg
sendSave hostConfig editingId draft =
    Http.request
        { method =
            case editingId of
                Just _ ->
                    "PATCH"

                Nothing ->
                    "POST"
        , headers = []
        , url =
            apiUrl hostConfig
                ("jumps" :: (editingId |> Maybe.map (\id -> [ String.fromInt id ]) |> Maybe.withDefault []))
                []
        , body = Http.jsonBody (JumpLog.encodeDraft draft)
        , expect = Http.expectStringResponse GotSaveResult saveResponse
        , timeout = Just 15000
        , tracker = Nothing
        }


sendDelete : HostConfig -> Int -> Cmd Msg
sendDelete hostConfig id =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = apiUrl hostConfig [ "jumps", String.fromInt id ] []
        , body = Http.emptyBody
        , expect = Http.expectStringResponse GotDeleteResult saveResponse
        , timeout = Just 15000
        , tracker = Nothing
        }


{-| A 422 carries the model's validation messages; anything else is a generic
failure.
-}
saveResponse : Http.Response String -> Result (List String) ()
saveResponse response =
    case response of
        Http.GoodStatus_ _ _ ->
            Ok ()

        Http.BadStatus_ { statusCode } body ->
            case ( statusCode, Decode.decodeString JumpLog.errorsDecoder body ) of
                ( 422, Ok errors ) ->
                    Err errors

                ( 401, _ ) ->
                    Err [ "You are not signed in as the referee." ]

                _ ->
                    Err [ "Could not save this jump. Please try again." ]

        _ ->
            Err [ "Could not reach the server. Please try again." ]



-- VIEW


view : Config -> Model -> Html Msg
view config model =
    overlay 200
        Close
        [ console
            { width = "940px"
            , eyebrow = "Navigation / voyage record"
            , title = "Jump Log"
            , actions = addButton config
            , onClose = Close
            }
            [ Html.div
                [ HtmlAttrs.class "analysis-tab-content", HtmlAttrs.style "margin-top" "0" ]
                [ viewTable config model ]
            ]
        ]
        :: (case model.form of
                Just form ->
                    [ overlay 210
                        CancelForm
                        [ console
                            { width = "500px"
                            , eyebrow = "Voyage record / entry"
                            , title =
                                if form.editingId == Nothing then
                                    "Add Jump"

                                else
                                    "Edit Jump"
                            , actions = []
                            , onClose = CancelForm
                            }
                            (viewForm model form)
                        ]
                    ]

                Nothing ->
                    []
           )
        ++ viewDeleteConfirmation model
        |> Html.div []


{-| Dims the page behind a console, the same backdrop as the stellar object
details modal. Clicking it closes the console.
-}
overlay : Int -> Msg -> List (Html Msg) -> Html Msg
overlay zIndex onClose children =
    Html.div
        [ HtmlAttrs.class "analysis-backdrop"
        , HtmlAttrs.style "position" "fixed"
        , HtmlAttrs.style "inset" "0"
        , HtmlAttrs.style "z-index" (String.fromInt zIndex)
        , HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "justify-content" "center"
        , HtmlEvents.onClick onClose
        ]
        children


type alias ConsoleConfig =
    { width : String
    , eyebrow : String
    , title : String
    , actions : List (Html Msg)
    , onClose : Msg
    }


{-| A console panel in the style of the stellar object details modal: the
`analysis-*` classes in `application.css` give it the accent rule, the
asymmetric corners, the eyebrow/title header and the close button. The
`orbit-console` class resets the `white-space` inherited from the elm-ui
element this is mounted inside, which would otherwise stop text wrapping.
-}
console : ConsoleConfig -> List (Html Msg) -> Html Msg
console config children =
    Html.div
        [ HtmlAttrs.class "analysis-console orbit-console"
        , HtmlAttrs.attribute "role" "dialog"
        , HtmlAttrs.attribute "aria-modal" "true"
        , HtmlAttrs.attribute "aria-label" config.title
        , HtmlAttrs.style "width" config.width
        , HtmlAttrs.style "max-width" "95vw"
        , HtmlEvents.stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
        ]
        [ Html.div
            [ HtmlAttrs.class "analysis-header orbit-header" ]
            [ Html.div []
                [ Html.div [ HtmlAttrs.class "analysis-eyebrow" ] [ Html.text config.eyebrow ]
                , Html.h2 [ HtmlAttrs.class "analysis-title" ] [ Html.text config.title ]
                ]
            , Html.div
                [ HtmlAttrs.style "display" "flex"
                , HtmlAttrs.style "align-items" "center"
                , HtmlAttrs.style "gap" "12px"
                ]
                (config.actions
                    ++ [ Html.button
                            [ HtmlAttrs.class "analysis-close"
                            , HtmlAttrs.type_ "button"
                            , HtmlAttrs.attribute "aria-label" ("Close " ++ config.title)
                            , HtmlEvents.onClick config.onClose
                            ]
                            [ Html.text "✕" ]
                       ]
                )
            ]
        , Html.div [ HtmlAttrs.style "padding" "20px" ] children
        ]


viewShipFilter : Model -> Html Msg
viewShipFilter model =
    if onlyShipId model /= Nothing then
        Html.text ""

    else
        viewShipFilterSelect model


viewShipFilterSelect : Model -> Html Msg
viewShipFilterSelect model =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "gap" "8px"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        [ Html.label
            [ HtmlAttrs.style "font-size" "11px"
            , HtmlAttrs.style "text-transform" "uppercase"
            , HtmlAttrs.style "letter-spacing" "0.15em"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            ]
            [ Html.text "Ship" ]
        , Html.select
            (HtmlEvents.onInput SetShipFilter
                :: inputStyles
                ++ [ HtmlAttrs.style "width" "auto" ]
            )
            (Html.option [ HtmlAttrs.value "", HtmlAttrs.selected (model.shipFilter == Nothing) ] [ Html.text "All ships" ]
                :: List.map
                    (\ship ->
                        Html.option
                            [ HtmlAttrs.value (String.fromInt ship.id), HtmlAttrs.selected (model.shipFilter == Just ship.id) ]
                            [ Html.text ship.name ]
                    )
                    model.ships
            )
        ]


addButton : Config -> List (Html Msg)
addButton config =
    if config.isReferee then
        [ Html.button
            [ HtmlAttrs.class "btn"
            , HtmlAttrs.style "padding" "2px 10px"
            , HtmlAttrs.style "font-size" "12px"
            , HtmlEvents.onClick AddClicked
            ]
            [ Html.text "Add jump" ]
        ]

    else
        []


viewTable : Config -> Model -> Html Msg
viewTable config model =
    case model.jumps of
        Success jumps ->
            let
                sorted =
                    List.sortWith JumpLog.compareNewestFirst jumps

                filtered =
                    case model.shipFilter of
                        Just shipId ->
                            List.filter (\j -> j.shipId == shipId) sorted

                        Nothing ->
                            sorted

                pageCount =
                    max 1 (ceiling (toFloat (List.length filtered) / toFloat pageSize))

                page =
                    min model.page (pageCount - 1)

                visible =
                    filtered |> List.drop (page * pageSize) |> List.take pageSize
            in
            if List.isEmpty sorted then
                message "No jumps have been logged yet."

            else
                Html.div []
                    [ viewShipFilter model
                    , if List.isEmpty filtered then
                        message "This ship has no logged jumps."

                      else
                        Html.text ""
                    , Html.div [ HtmlAttrs.style "overflow-x" "auto" ]
                        [ Html.table [ HtmlAttrs.class "jump-log-table" ]
                            [ Html.thead [] [ Html.tr [] (List.map headerCell (columns config)) ]
                            , Html.tbody []
                                (List.map
                                    (\jump -> viewRow config (isLatestForShip sorted jump) jump)
                                    visible
                                )
                            ]
                        ]
                    , viewDeleteError model.deleteError
                    , viewPager page pageCount
                    ]

        Failure _ ->
            viewLoadFailure

        _ ->
            viewLoading


viewLoadFailure : Html Msg
viewLoadFailure =
    Html.div [ HtmlAttrs.class "jump-log-failure", HtmlAttrs.attribute "role" "alert" ]
        [ Html.i [ HtmlAttrs.class "fa-regular fa-triangle-exclamation", HtmlAttrs.attribute "aria-hidden" "true" ] []
        , Html.span [] [ Html.text "NAVIGATION RECORDS UNAVAILABLE" ]
        ]


viewLoading : Html Msg
viewLoading =
    Html.div
        [ HtmlAttrs.class "jump-log-loading"
        , HtmlAttrs.attribute "role" "status"
        , HtmlAttrs.attribute "aria-live" "polite"
        ]
        [ Html.div [ HtmlAttrs.class "jump-log-loading-dots", HtmlAttrs.attribute "aria-hidden" "true" ]
            [ Html.span [ HtmlAttrs.class "hex-dot hex-dot-1" ] []
            , Html.span [ HtmlAttrs.class "hex-dot hex-dot-2" ] []
            , Html.span [ HtmlAttrs.class "hex-dot hex-dot-3" ] []
            ]
        , Html.div [ HtmlAttrs.class "status-scan" ] [ Html.text "RETRIEVING NAVIGATION RECORDS…" ]
        ]


columns : Config -> List String
columns config =
    [ "Ship", "Depart", "From", "Arrive", "To", "" ]
        |> List.filter (\c -> c /= "" || config.isReferee)


headerCell : String -> Html Msg
headerCell label =
    Html.th [] [ Html.text label ]


{-| Whether this is the newest jump of its ship. `sorted` is newest first.
Matches the server's rule for which jumps may be deleted.
-}
isLatestForShip : List JumpLog -> JumpLog -> Bool
isLatestForShip sorted jump =
    sorted
        |> List.filter (\j -> j.shipId == jump.shipId)
        |> List.head
        |> Maybe.map .id
        |> (==) (Just jump.id)


viewRow : Config -> Bool -> JumpLog -> Html Msg
viewRow config isMostRecent jump =
    Html.tr [] <|
        [ cell [ Html.text jump.shipName ]
        , cell [ Html.text (JumpLog.formatDate jump.departYear jump.departDay) ]
        , cell [ Html.text (jump.fromSectorName ++ " " ++ jump.fromHex) ]
        , cell [ Html.text (JumpLog.formatDate jump.arriveYear jump.arriveDay) ]
        , cell
            (Html.text (jump.toSectorName ++ " " ++ jump.toHex)
                :: (if jump.misjump then
                        [ Html.span
                            [ HtmlAttrs.title "Misjump"
                            , HtmlAttrs.style "margin-left" "6px"
                            , HtmlAttrs.style "color" "var(--color-danger-text)"
                            ]
                            [ Html.text "⚠ Misjump" ]
                        ]

                    else
                        []
                   )
            )
        ]
            ++ (if config.isReferee then
                    [ cell
                        [ Html.span [ HtmlAttrs.style "display" "inline-flex", HtmlAttrs.style "gap" "12px", HtmlAttrs.style "align-items" "center" ]
                            [ iconButton "Edit" "fa-pen-to-square" (EditClicked jump)
                            , if isMostRecent then
                                iconButton "Delete this jump" "fa-trash" (RequestDelete jump.id)

                              else
                                -- Keeps the edit icons in line on every row.
                                Html.span [ HtmlAttrs.style "display" "inline-block", HtmlAttrs.style "width" "14px" ] []
                            ]
                        ]
                    ]

                else
                    []
               )


iconButton : String -> String -> Msg -> Html Msg
iconButton label icon onClick =
    Html.button
        [ HtmlAttrs.type_ "button"
        , HtmlAttrs.title label
        , HtmlAttrs.attribute "aria-label" label
        , HtmlAttrs.class "text-fg-muted cursor-pointer bg-transparent border-0 p-0"
        , HtmlEvents.onClick onClick
        ]
        [ Html.i [ HtmlAttrs.class ("fa-regular " ++ icon), HtmlAttrs.style "font-size" "14px" ] [] ]


viewDeleteConfirmation : Model -> List (Html Msg)
viewDeleteConfirmation model =
    let
        pending =
            model.pendingDeleteId
                |> Maybe.andThen
                    (\id ->
                        RemoteData.toMaybe model.jumps
                            |> Maybe.andThen (List.filter (\j -> j.id == id) >> List.head)
                    )
    in
    case pending of
        Just jump ->
            [ overlay 220
                CancelDelete
                [ console
                    { width = "400px"
                    , eyebrow = "Voyage record / expunge"
                    , title = "Delete Jump?"
                    , actions = []
                    , onClose = CancelDelete
                    }
                    [ Html.p
                        [ HtmlAttrs.style "color" "var(--color-fg)"
                        , HtmlAttrs.style "font-size" "13px"
                        , HtmlAttrs.style "margin" "0 0 16px 0"
                        ]
                        [ Html.text
                            ("Delete the jump of "
                                ++ jump.shipName
                                ++ " to "
                                ++ jump.toSectorName
                                ++ " "
                                ++ jump.toHex
                                ++ " on "
                                ++ JumpLog.formatDate jump.arriveYear jump.arriveDay
                                ++ "? This cannot be undone."
                            )
                        ]
                    , Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "gap" "8px" ]
                        [ Html.button
                            [ HtmlAttrs.class "btn"
                            , HtmlAttrs.style "flex" "1"
                            , HtmlAttrs.style "padding" "8px"
                            , HtmlEvents.onClick CancelDelete
                            ]
                            [ Html.text "Cancel" ]
                        , Html.button
                            [ HtmlAttrs.class "btn btn-primary"
                            , HtmlAttrs.style "flex" "1"
                            , HtmlAttrs.style "padding" "8px"
                            , HtmlEvents.onClick (ConfirmDelete jump.id)
                            ]
                            [ Html.text "Delete" ]
                        ]
                    ]
                ]
            ]

        Nothing ->
            []


viewDeleteError : Maybe String -> Html Msg
viewDeleteError error =
    case error of
        Just text ->
            Html.div [ HtmlAttrs.style "color" "var(--color-danger-text)", HtmlAttrs.style "font-size" "13px", HtmlAttrs.style "margin-top" "8px" ] [ Html.text text ]

        Nothing ->
            Html.text ""


cell : List (Html Msg) -> Html Msg
cell =
    Html.td []


viewPager : Int -> Int -> Html Msg
viewPager page pageCount =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "justify-content" "space-between"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "margin-top" "12px"
        , HtmlAttrs.style "font-size" "13px"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        ]
        [ Html.button
            [ HtmlAttrs.class "btn", HtmlAttrs.disabled (page <= 0), HtmlEvents.onClick PreviousPage ]
            [ Html.text "Newer" ]
        , Html.text ("Page " ++ String.fromInt (page + 1) ++ " of " ++ String.fromInt pageCount)
        , Html.button
            [ HtmlAttrs.class "btn", HtmlAttrs.disabled (page >= pageCount - 1), HtmlEvents.onClick NextPage ]
            [ Html.text "Older" ]
        ]


message : String -> Html Msg
message text =
    Html.div [ HtmlAttrs.style "color" "var(--color-fg-muted)", HtmlAttrs.style "font-size" "13px" ] [ Html.text text ]



-- FORM VIEW


viewForm : Model -> Form -> List (Html Msg)
viewForm model form =
    let
        rules =
            dateRules model form

        canSave =
            not form.saving && toDraft form /= Nothing && not (outOfRange model form) && List.isEmpty (formProblems model form)
    in
    [ if onlyShipId model /= Nothing then
        Html.text ""

      else
        field "Ship"
            (Html.select (HtmlEvents.onInput SetShip :: inputStyles)
                (blankOption form.shipId
                    :: List.map
                        (\s ->
                            Html.option
                                [ HtmlAttrs.value (String.fromInt s.id), HtmlAttrs.selected (form.shipId == Just s.id) ]
                                [ Html.text s.name ]
                        )
                        model.ships
                )
            )
    , misjumpToggle form.misjump
    , locationFields From "From" model.sectors form.fromSectorId form.fromParsecId form.fromParsecs
    , locationFields To "To" (toSectorChoices model form) form.toSectorId form.toParsecId (toParsecChoices model form)
    , distanceNote model form
    , Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "gap" "12px" ]
        [ numberField "Depart year" form.departYear (Maybe.map Tuple.first rules.earliestDeparture) SetDepartYear
        , numberField "Depart day" form.departDay (dayMinimum form.departYear rules.earliestDeparture) SetDepartDay
        , numberField "Arrive year" form.arriveYear (Maybe.map Tuple.first rules.earliestArrival) SetArriveYear
        , numberField "Arrive day" form.arriveDay (dayMinimum form.arriveYear rules.earliestArrival) SetArriveDay
        ]
    , viewDateHints rules
    , viewErrors (formProblems model form)
    , field "Notes"
        (Html.textarea
            (HtmlAttrs.rows 3 :: HtmlAttrs.value form.notes :: HtmlEvents.onInput SetNotes :: inputStyles)
            []
        )
    , viewErrors form.errors
    , Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "gap" "8px" ]
        [ Html.button
            [ HtmlAttrs.class "btn"
            , HtmlAttrs.style "flex" "1"
            , HtmlAttrs.style "padding" "8px"
            , HtmlEvents.onClick CancelForm
            ]
            [ Html.text "Cancel" ]
        , Html.button
            [ HtmlAttrs.class "btn btn-primary"
            , HtmlAttrs.style "flex" "1"
            , HtmlAttrs.style "padding" "8px"
            , HtmlAttrs.disabled (not canSave)
            , HtmlEvents.onClick Save
            ]
            [ Html.text
                (if form.saving then
                    "Saving…"

                 else
                    "Save"
                )
            ]
        ]
    ]


{-| Switch for a misjump. Turning it on lifts the jump range limit on the
destination lists, since a misjump can land anywhere in the campaign.
-}
misjumpToggle : Bool -> Html Msg
misjumpToggle isOn =
    Html.div
        [ HtmlAttrs.style "display" "flex"
        , HtmlAttrs.style "align-items" "center"
        , HtmlAttrs.style "gap" "10px"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        [ ToggleSwitch.view ToggleSwitch.Small isOn (HtmlEvents.onClick (SetMisjump (not isOn)))
        , Html.span
            [ HtmlAttrs.style "cursor" "pointer"
            , HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-fg)"
            , HtmlEvents.onClick (SetMisjump (not isOn))
            ]
            [ Html.text "Misjump" ]
        , if isOn then
            Html.span
                [ HtmlAttrs.style "font-size" "12px"
                , HtmlAttrs.style "color" "var(--color-fg-muted)"
                ]
                [ Html.text "Any destination in the campaign" ]

          else
            Html.text ""
        ]


locationFields : Side -> String -> List SectorOption -> Maybe Int -> Maybe Int -> List ParsecOption -> Html Msg
locationFields side label sectors sectorId parsecId parsecs =
    Html.div [ HtmlAttrs.style "display" "flex", HtmlAttrs.style "gap" "12px" ]
        [ Html.div [ HtmlAttrs.style "flex" "1" ]
            [ field (label ++ " sector")
                (Html.select (HtmlEvents.onInput (SetSector side) :: inputStyles)
                    (blankOption sectorId
                        :: List.map
                            (\s ->
                                Html.option
                                    [ HtmlAttrs.value (String.fromInt s.id), HtmlAttrs.selected (sectorId == Just s.id) ]
                                    [ Html.text s.name ]
                            )
                            (List.sortBy .name sectors)
                    )
                )
            ]
        , Html.div [ HtmlAttrs.style "flex" "1" ]
            [ field (label ++ " hex")
                (Html.select (HtmlEvents.onInput (SetParsec side) :: inputStyles)
                    (blankOption parsecId
                        :: List.map
                            (\p ->
                                Html.option
                                    [ HtmlAttrs.value (String.fromInt p.id), HtmlAttrs.selected (parsecId == Just p.id) ]
                                    [ Html.text (parsecLabel p) ]
                            )
                            parsecs
                    )
                )
            ]
        ]


parsecLabel : ParsecOption -> String
parsecLabel parsec =
    case parsec.systemName of
        Just name ->
            parsec.hexCode ++ " " ++ name

        Nothing ->
            parsec.hexCode


blankOption : Maybe Int -> Html Msg
blankOption selected =
    Html.option [ HtmlAttrs.value "", HtmlAttrs.selected (selected == Nothing) ] [ Html.text "—" ]


distanceNote : Model -> Form -> Html Msg
distanceNote model form =
    case formDistance form of
        Nothing ->
            Html.text ""

        Just distance ->
            let
                rating =
                    shipJumpDrive model form
            in
            Html.div
                [ HtmlAttrs.style "font-size" "13px"
                , HtmlAttrs.style "margin-bottom" "12px"
                , HtmlAttrs.style "color"
                    (if outOfRange model form then
                        "var(--color-danger-text)"

                     else
                        "var(--color-fg-muted)"
                    )
                ]
                [ Html.text
                    (String.fromInt distance
                        ++ " parsecs"
                        ++ (case rating of
                                Just drive ->
                                    " (ship's drive: J" ++ String.fromInt drive ++ ")"

                                Nothing ->
                                    ""
                           )
                    )
                ]


{-| A number input. `minimum` stops the spinner going below a limit; a typed
value below it is moved up to it when the field loses focus.
-}
numberField : String -> String -> Maybe Int -> (String -> Msg) -> Html Msg
numberField label value minimum onInput =
    Html.div [ HtmlAttrs.style "flex" "1" ]
        [ field label
            (Html.input
                (HtmlAttrs.type_ "number"
                    :: HtmlAttrs.value value
                    :: HtmlEvents.onInput onInput
                    :: HtmlEvents.onBlur ClampDates
                    :: (case minimum of
                            Just min ->
                                [ HtmlAttrs.min (String.fromInt min) ]

                            Nothing ->
                                []
                       )
                    ++ inputStyles
                )
                []
            )
        ]


{-| The least a day field may hold: the limit's day when the year field is at
the limit's year, otherwise the first of the year.
-}
dayMinimum : String -> Maybe ( Int, Int ) -> Maybe Int
dayMinimum yearText limit =
    case limit of
        Just ( year, day ) ->
            if String.toInt yearText == Just year then
                Just day

            else
                Just 1

        Nothing ->
            Nothing


viewDateHints : DateRules -> Html Msg
viewDateHints rules =
    let
        hint label limit =
            limit
                |> Maybe.map (\( year, day ) -> Html.div [] [ Html.text (label ++ " " ++ JumpLog.formatDate year day) ])
    in
    Html.div
        [ HtmlAttrs.style "font-size" "12px"
        , HtmlAttrs.style "color" "var(--color-fg-muted)"
        , HtmlAttrs.style "margin-bottom" "12px"
        ]
        (List.filterMap identity
            [ hint "Earliest departure" rules.earliestDeparture
            , hint "Earliest arrival" rules.earliestArrival
            ]
        )


field : String -> Html Msg -> Html Msg
field label control =
    Html.div [ HtmlAttrs.style "margin-bottom" "12px" ]
        [ Html.div
            [ HtmlAttrs.style "font-size" "11px"
            , HtmlAttrs.style "text-transform" "uppercase"
            , HtmlAttrs.style "letter-spacing" "0.15em"
            , HtmlAttrs.style "color" "var(--color-fg-muted)"
            , HtmlAttrs.style "margin-bottom" "4px"
            ]
            [ Html.text label ]
        , control
        ]


inputStyles : List (Html.Attribute Msg)
inputStyles =
    [ HtmlAttrs.style "width" "100%"
    , HtmlAttrs.style "box-sizing" "border-box"
    , HtmlAttrs.style "font-size" "13px"
    , HtmlAttrs.style "color" "var(--color-fg-bright)"
    , HtmlAttrs.style "background-color" "var(--color-panel)"
    , HtmlAttrs.style "border" "1px solid var(--color-outline)"
    , HtmlAttrs.style "border-radius" "4px"
    , HtmlAttrs.style "padding" "6px"
    ]


viewErrors : List String -> Html Msg
viewErrors errors =
    if List.isEmpty errors then
        Html.text ""

    else
        Html.div
            [ HtmlAttrs.style "font-size" "13px"
            , HtmlAttrs.style "color" "var(--color-danger-text)"
            , HtmlAttrs.style "margin-bottom" "8px"
            ]
            (List.map (\e -> Html.div [] [ Html.text e ]) errors)
