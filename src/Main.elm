module Main exposing (main)

import Array exposing (Array)
import Browser
import Codec
import Data exposing (baseMult, cardHeight, cardWidth, fontMult, spacingMult)
import Data.Base as Base exposing (Base(..))
import Data.Card as Card exposing (Card)
import Data.Composition as Composition exposing (Composition)
import Data.Effect as Effect exposing (Effect(..))
import Data.Element as Elem
import Data.FormField as FormField exposing (FormField)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import File.Download as Download
import File.Select as Select
import Framework
import Framework.Button as Button
import Framework.Card
import Framework.Color as Color
import Framework.Grid as Grid
import Framework.Input as Input
import Html exposing (Html)
import Http
import Task
import View.Card as Card
import View.RangeInput as RangeInput
import View.ToggleInput as ToggleInput


type ConfigField
    = CardsPerPage String
    | BlackAndWhite Bool


type alias Config =
    { cardsPerPage : FormField Int ()
    , blackAndWhite : Bool
    }


type Tab
    = EditTab
    | DecksTab
    | ConfigTab


type alias Model =
    { config : Config
    , cards : Array Card
    , currentTab : Tab
    , showGui : Bool
    , editing : Int
    }


type Msg
    = ChangedTab Tab
    | ToggledShowGui
    | ChangedConfigField ConfigField
    | ChangeComponent Base Int
    | ChangeAmount Int
    | ChangedName String
    | ChangedImg String
    | DeletedSelected
    | AddCard
    | Selected Int
    | Load
    | Save
    | LoadFromLink String
    | GotFile File
    | GotJson String
    | GotError


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        editedCard : Card
        editedCard =
            model.cards
                |> Array.get model.editing
                |> Maybe.withDefault (Card.empty 1)
    in
    case msg of
        ToggledShowGui ->
            ( { model | showGui = not model.showGui }, Cmd.none )

        ChangedTab tab ->
            ( { model | currentTab = tab }, Cmd.none )

        ChangedConfigField configField ->
            let
                config : Config
                config =
                    model.config
            in
            ( case configField of
                CardsPerPage string ->
                    { model
                        | config =
                            { config
                                | cardsPerPage =
                                    config.cardsPerPage
                                        |> FormField.update (String.toInt >> Result.fromMaybe [ () ])
                                            string
                            }
                    }

                BlackAndWhite bool ->
                    { model | config = { config | blackAndWhite = bool } }
            , Cmd.none
            )

        ChangeAmount int ->
            ( { model
                | cards =
                    model.cards
                        |> Array.set model.editing
                            { editedCard
                                | amount = int
                            }
              }
            , Cmd.none
            )

        ChangeComponent base int ->
            ( { model
                | cards =
                    model.cards
                        |> Array.set model.editing
                            { editedCard
                                | composition =
                                    editedCard.composition
                                        |> Composition.update base int
                            }
              }
            , Cmd.none
            )

        ChangedName name ->
            ( { model
                | cards =
                    model.cards
                        |> Array.set model.editing
                            { editedCard | name = name }
              }
            , Cmd.none
            )

        ChangedImg img ->
            ( { model
                | cards =
                    model.cards
                        |> Array.set model.editing
                            { editedCard | img = img }
              }
            , Cmd.none
            )

        DeletedSelected ->
            ( { model
                | editing = max 0 <| model.editing - 1
                , cards =
                    Array.append
                        (model.cards |> Array.slice 0 model.editing)
                        (model.cards |> Array.slice (model.editing + 1) (model.cards |> Array.length))
              }
            , Cmd.none
            )

        AddCard ->
            ( { model
                | editing = model.cards |> Array.length
                , cards = model.cards |> Array.push (Card.empty 1)
              }
            , Cmd.none
            )

        Selected index ->
            ( { model | editing = index }, Cmd.none )

        Save ->
            ( model
            , model.cards
                |> Codec.encodeToString 2 (Codec.array Card.codec)
                |> Download.string "flask_cards.json" "text/json"
            )

        LoadFromLink string ->
            ( model
            , Http.get
                { url = string
                , expect =
                    Http.expectString
                        (\result ->
                            case result of
                                Ok json ->
                                    GotJson json

                                Err error ->
                                    GotError
                        )
                }
            )

        Load ->
            ( model
            , Select.file [ "text/json" ] GotFile
            )

        GotFile file ->
            ( model
            , file
                |> File.toString
                |> Task.perform GotJson
            )

        GotJson json ->
            case
                json
                    |> Codec.decodeString (Codec.array Card.codec)
            of
                Ok cards ->
                    ( { model
                        | editing = 0
                        , cards = cards
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        GotError ->
            ( model, Cmd.none )


init : () -> ( Model, Cmd Msg )
init _ =
    let
        cardsPerPage : Int
        cardsPerPage =
            10

        blackAndWhite : Bool
        blackAndWhite =
            False
    in
    ( { cards = Array.empty
      , config =
            { cardsPerPage =
                FormField.create
                    { default = cardsPerPage
                    , value = cardsPerPage |> String.fromInt
                    }
            , blackAndWhite = blackAndWhite
            }
      , showGui = True
      , currentTab = EditTab
      , editing = 0
      }
    , Http.get
        { url = "https://raw.githubusercontent.com/Orasund/flask/master/deck/base.json"
        , expect =
            Http.expectString
                (\result ->
                    case result of
                        Ok json ->
                            GotJson json

                        Err error ->
                            GotError
                )
        }
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


card : Bool -> Card -> List (Element msg)
card blackAndWhite ({ name, hasDesc, img, amount } as config) =
    let
        composition =
            config.composition
                |> Composition.toList
                |> List.map Base.card
                |> List.foldl
                    (\input { cost, effects } ->
                        { cost = ( input.cost ++ (cost |> Tuple.first), input.discard + (cost |> Tuple.second) )
                        , effects = input.effect :: effects
                        }
                    )
                    { cost = ( [], 0 ), effects = [] }
    in
    Card.view
        { blackAndWhite = blackAndWhite
        , name = name
        , cost = composition.cost |> Tuple.mapFirst Elem.order
        , effects = composition.effects |> Effect.simplify
        , hasDesc = hasDesc
        , code = config.composition |> Composition.toString
        , img = img
        }
        |> List.repeat amount


view : Model -> Html Msg
view model =
    let
        cards : List (Element Msg)
        cards =
            model.cards
                |> Array.toList
                |> (if model.showGui then
                        List.indexedMap
                            (\i c ->
                                c
                                    |> card model.config.blackAndWhite
                                    |> List.head
                                    |> Maybe.map
                                        (\label ->
                                            Input.button [ Element.alignLeft ] <|
                                                { label =
                                                    Element.el
                                                        (Color.info
                                                            ++ [ Element.inFront <|
                                                                    Element.el
                                                                        (if i == model.editing then
                                                                            Framework.Card.simple
                                                                                ++ Color.info
                                                                                ++ [ Border.roundEach
                                                                                        { topLeft = 0
                                                                                        , bottomLeft = 0
                                                                                        , topRight = round <| 16 * baseMult
                                                                                        , bottomRight = round <| 16 * baseMult
                                                                                        }
                                                                                   , Element.centerY
                                                                                   , Element.alignLeft
                                                                                   ]

                                                                         else
                                                                            Framework.Card.simple
                                                                                ++ Color.info
                                                                                ++ [ Border.roundEach
                                                                                        { topLeft = round <| 16 * baseMult
                                                                                        , bottomLeft = round <| 16 * baseMult
                                                                                        , topRight = 0
                                                                                        , bottomRight = 0
                                                                                        }
                                                                                   , Element.centerY
                                                                                   , Element.alignRight
                                                                                   ]
                                                                        )
                                                                    <|
                                                                        Element.text (String.fromInt c.amount ++ "x")
                                                               , Element.width <| Element.px <| cardWidth
                                                               , Element.height <| Element.px <| cardHeight
                                                               ]
                                                            ++ (if i == model.editing then
                                                                    [ Border.color <| Color.cyan
                                                                    , Border.width <| round <| 2 * spacingMult
                                                                    ]

                                                                else
                                                                    []
                                                               )
                                                        )
                                                    <|
                                                        label
                                                , onPress = Just (Selected i)
                                                }
                                        )
                            )
                            >> List.filterMap identity

                    else
                        List.map (card model.config.blackAndWhite) >> List.concat
                   )

        cardsPerPage : Int
        cardsPerPage =
            model.config.cardsPerPage
                |> FormField.toValue

        emptyCards : Int
        emptyCards =
            cardsPerPage - (cards |> List.length) |> modBy cardsPerPage

        displayCards : Element Msg
        displayCards =
            Element.paragraph [ Element.width <| Element.fill, Element.spacing <| 0 ] <|
                List.concat
                    [ cards
                    , if model.showGui then
                        [ Element.el
                            [ Element.height <| Element.px <| cardHeight
                            , Element.alignLeft
                            , Element.width <| Element.px <| cardWidth
                            , Element.inFront <|
                                Input.button
                                    (Button.simple
                                        ++ Color.success
                                        ++ [ Border.rounded <| round <| 16 * baseMult
                                           , Element.centerY
                                           , Element.alignLeft
                                           ]
                                    )
                                <|
                                    { onPress = Just <| AddCard
                                    , label = Element.text <| "+"
                                    }
                            , Element.centerY
                            ]
                          <|
                            Element.none
                        ]

                      else
                        Card.empty emptyCards |> card model.config.blackAndWhite
                    ]

        editedCard : Card
        editedCard =
            model.cards
                |> Array.get model.editing
                |> Maybe.withDefault (Card.empty 1)

        toTitle : Base -> String
        toTitle =
            Base.card >> .effect >> Effect.toTextField >> .title
    in
    (if model.showGui then
        Framework.layout [] << Element.el Framework.container

     else
        Element.layout []
    )
    <|
        if model.showGui then
            Element.paragraph (Grid.spacedEvenly ++ [ Element.width Element.fill ]) <|
                [ Element.column
                    (Grid.simple
                        ++ [ Element.width <| Element.px <| 390
                           , Element.alignRight
                           ]
                    )
                  <|
                    [ Element.column Grid.compact <|
                        [ Element.row Grid.spaceEvenly <|
                            [ Input.button
                                (Button.groupTop
                                    ++ (if model.currentTab == EditTab then
                                            Color.info

                                        else
                                            []
                                       )
                                )
                                { onPress = Just <| ChangedTab EditTab
                                , label = Element.text <| "Edit Card"
                                }
                            , Input.button
                                (Button.groupTop
                                    ++ (if model.currentTab == DecksTab then
                                            Color.info

                                        else
                                            []
                                       )
                                )
                                { onPress = Just <| ChangedTab DecksTab
                                , label = Element.text <| "Community"
                                }
                            , Input.button
                                (Button.groupTop
                                    ++ (if model.currentTab == ConfigTab then
                                            Color.info

                                        else
                                            []
                                       )
                                )
                                { onPress = Just <| ChangedTab ConfigTab
                                , label = Element.text <| "Configuration"
                                }
                            ]
                        , Element.el
                            (Framework.Card.simple
                                ++ [ Element.height <| Element.minimum 600 <| Element.shrink
                                   , Element.width <| Element.fill
                                   ]
                            )
                          <|
                            Element.column
                                (Grid.simple
                                    ++ [ Border.rounded 0 ]
                                )
                            <|
                                case model.currentTab of
                                    DecksTab ->
                                        [ Element.row Grid.spaceEvenly <|
                                            [ Element.el
                                                [ Element.width <| Element.fill
                                                , Element.centerX
                                                ]
                                              <|
                                                Element.text <|
                                                    "Green Deck"
                                            , Input.button
                                                (Button.simple
                                                    ++ Color.primary
                                                    ++ [ Element.width <| Element.fill
                                                       ]
                                                )
                                              <|
                                                { onPress = Just <| LoadFromLink <| "https://raw.githubusercontent.com/Orasund/flask/master/deck/green.json"
                                                , label = Element.text <| "Load"
                                                }
                                            ]
                                        , Element.row Grid.spaceEvenly <|
                                            [ Element.el [ Element.width <| Element.fill, Element.centerX ] <|
                                                Element.text <|
                                                    "Red Deck"
                                            , Input.button (Button.simple ++ Color.primary ++ [ Element.width <| Element.fill, Element.centerX ]) <|
                                                { onPress = Just <| LoadFromLink <| "https://raw.githubusercontent.com/Orasund/flask/master/deck/red.json"
                                                , label = Element.text <| "Load"
                                                }
                                            ]
                                        , Element.row Grid.spaceEvenly <|
                                            [ Element.el [ Element.width <| Element.fill, Element.centerX ] <|
                                                Element.text <|
                                                    "Yellow Deck"
                                            , Input.button (Button.simple ++ Color.primary ++ [ Element.width <| Element.fill, Element.centerX ]) <|
                                                { onPress = Just <| LoadFromLink <| "https://raw.githubusercontent.com/Orasund/flask/master/deck/yellow.json"
                                                , label = Element.text <| "Load"
                                                }
                                            ]
                                        , Element.row Grid.spaceEvenly <|
                                            [ Element.el [ Element.width <| Element.fill, Element.centerX ] <|
                                                Element.text <|
                                                    "Blue Deck"
                                            , Input.button (Button.simple ++ Color.primary ++ [ Element.width <| Element.fill, Element.centerX ]) <|
                                                { onPress = Just <| LoadFromLink <| "https://raw.githubusercontent.com/Orasund/flask/master/deck/blue.json"
                                                , label = Element.text <| "Load"
                                                }
                                            ]
                                        ]

                                    ConfigTab ->
                                        [ Element.row Grid.spaceEvenly <|
                                            [ Element.el [ Element.width <| Element.fill ] <|
                                                Element.text <|
                                                    "Cards Per Page"
                                            , Input.text
                                                ((if model.config.cardsPerPage |> FormField.unWrap |> .errors |> List.isEmpty then
                                                    []

                                                  else
                                                    Color.danger
                                                 )
                                                    ++ Input.simple
                                                )
                                                { onChange = ChangedConfigField << CardsPerPage
                                                , text = model.config.cardsPerPage |> FormField.unWrap |> .raw
                                                , placeholder = Nothing
                                                , label = Input.labelHidden "Cards Per Page"
                                                }
                                            ]
                                        , ToggleInput.view
                                            { onChange = ChangedConfigField << BlackAndWhite
                                            , value = model.config.blackAndWhite
                                            , label = "Black and White Mode"
                                            }
                                        ]

                                    EditTab ->
                                        editedCard.composition
                                            |> (\{ g1, g2, r1, r2, b1, b2, y1, y2 } ->
                                                    List.concat
                                                        [ [ Element.row Grid.spaceEvenly <|
                                                                [ Element.el [ Element.width <| Element.fill ] <|
                                                                    Element.text <|
                                                                        "Name"
                                                                , Input.text Input.simple
                                                                    { onChange = ChangedName
                                                                    , text = editedCard.name
                                                                    , placeholder = Nothing
                                                                    , label = Input.labelHidden "Name"
                                                                    }
                                                                ]
                                                          , Element.row Grid.spaceEvenly <|
                                                                [ Element.el [ Element.width <| Element.fill ] <|
                                                                    Element.text <|
                                                                        "Image Link"
                                                                , Input.text Input.simple
                                                                    { onChange = ChangedImg
                                                                    , text = editedCard.img
                                                                    , placeholder = Nothing
                                                                    , label = Input.labelHidden "Image Link"
                                                                    }
                                                                ]
                                                          , RangeInput.view
                                                                { minValue = 1
                                                                , maxValue = 3
                                                                , onChange = ChangeAmount
                                                                , value = editedCard.amount
                                                                , label = "Amount"
                                                                }
                                                          , Element.row Grid.simple <|
                                                                [ ToggleInput.view
                                                                    { onChange =
                                                                        \b ->
                                                                            if b then
                                                                                ChangeComponent G2 1

                                                                            else
                                                                                ChangeComponent G2 0
                                                                    , value = g2
                                                                    , label = toTitle <| G2
                                                                    }
                                                                , ToggleInput.view
                                                                    { onChange =
                                                                        \b ->
                                                                            if b then
                                                                                ChangeComponent Y2 1

                                                                            else
                                                                                ChangeComponent Y2 0
                                                                    , value = y2
                                                                    , label = toTitle <| Y2
                                                                    }
                                                                ]
                                                          ]
                                                        , [ ( b2, B2 ), ( b1, B1 ), ( y1, Y1 ), ( g1, G1 ), ( r1, R1 ), ( r2, R2 ) ]
                                                            |> List.map
                                                                (\( value, base ) ->
                                                                    RangeInput.view
                                                                        { minValue = 0
                                                                        , maxValue = 3
                                                                        , onChange = ChangeComponent base
                                                                        , value = value
                                                                        , label = base |> toTitle
                                                                        }
                                                                )
                                                        , [ Input.button (Button.simple ++ Color.danger ++ [ Element.alignRight ]) <|
                                                                { onPress = Just DeletedSelected
                                                                , label = Element.text <| "Remove"
                                                                }
                                                          ]
                                                        ]
                                               )
                        ]
                    , Element.row Grid.simple
                        [ Input.button (Button.simple ++ Color.primary) <|
                            { onPress = Just ToggledShowGui
                            , label = Element.text <| "Print"
                            }
                        , Input.button (Button.simple ++ Color.primary) <|
                            { onPress = Just Load
                            , label = Element.text <| "Load"
                            }
                        , Input.button (Button.simple ++ Color.primary) <|
                            { onPress = Just Save
                            , label = Element.text <| "Save"
                            }
                        ]
                    ]
                , Element.el
                    [ Element.width <| Element.fill, Element.scrollbarY, Element.height <| Element.px <| 650 ]
                  <|
                    displayCards
                ]

        else
            Element.column [ Element.spacing <| round <| 2 * spacingMult, Element.width Element.fill ] <|
                [ displayCards
                , Input.button (Button.simple ++ Color.primary) <|
                    { onPress = Just ToggledShowGui
                    , label = Element.text <| "Edit"
                    }
                ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
