module Main exposing (main)

import Array exposing (Array)
import Browser
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Data exposing (baseMult, cardHeight, cardWidth, fontMult, spacingMult)
import Data.Base as Base exposing (Base(..))
import Data.Composition as Composition exposing (Composition)
import Data.Effect as Effect exposing (Effect(..))
import Data.Element as Elem
import View.Card as Card
import Framework
import Framework.Button as Button
import Framework.Card
import Framework.Color as Color
import Framework.Grid as Grid
import Framework.Input as Input
import Html exposing (Html)
import Data.Card as Card exposing (Card)
import File.Download as Download
import File.Select as Select
import File exposing (File)
import Codec
import Task
import Http

type alias Model =
    { cards : Array Card
    , cardsPerPage : Int
    , showGui : Bool
    , editing : Int
    }


type Msg
    = ToggledShowGui
    | AddComponent Base
    | RemoveComponent Base
    | IncreaseAmount
    | DecreaseAmount
    | ChangedName String
    | ChangedImg String
    | DeletedSelected
    | AddCard
    | Selected Int
    | Load
    | Save
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

        IncreaseAmount ->
            ( { model
                | cards =
                    model.cards
                        |> Array.set model.editing
                            { editedCard
                                | amount = min 3 <| editedCard.amount + 1
                            }
              }
            , Cmd.none
            )

        DecreaseAmount ->
            ( { model
                | cards =
                    model.cards
                        |> Array.set model.editing
                            { editedCard
                                | amount = max 1 <| editedCard.amount - 1
                            }
              }
            , Cmd.none
            )

        AddComponent base ->
            ( { model
                | cards =
                    model.cards
                        |> Array.set model.editing
                            { editedCard
                                | composition =
                                    editedCard.composition
                                        |> Composition.insert base
                            }
              }
            , Cmd.none
            )

        RemoveComponent base ->
            ( { model
                | cards =
                    model.cards
                        |> Array.set model.editing
                            { editedCard
                                | composition =
                                    editedCard.composition
                                        |> Composition.remove base
                            }
              }
            , Cmd.none
            )

        ChangedName name ->
            ( { model 
                | cards = model.cards 
                    |> Array.set model.editing 
                        { editedCard | name = name } 
              }
            , Cmd.none
            )
        ChangedImg img ->
            ( { model 
                | cards = model.cards 
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
                , cards =  model.cards |> Array.push (Card.empty 1)
                }
            , Cmd.none
            )
        
        Selected index ->
            ( { model | editing = index},Cmd.none)

        Save ->
            ( model
            , model.cards
                |> Codec.encodeToString 2 (Codec.array Card.codec)
                |> Download.string "flask_cards.json" "text/json"
            )
        
        Load ->
            ( model
            , Select.file ["text/json"] GotFile
            )
        
        GotFile file ->
            ( model
            , file |> File.toString
                |> Task.perform GotJson
            )
        
        GotJson json ->
            case
                json
                    |> Codec.decodeString (Codec.array Card.codec)
            of
                Ok cards ->
                    ( {model| editing = 0
                        , cards = cards
                        }
                        , Cmd.none
                        )
                Err _ ->
                    (model,Cmd.none)

        GotError ->
            ( model, Cmd.none)

            


init : () -> ( Model, Cmd Msg )
init _ =
    ( { cards = Array.empty
      , cardsPerPage = 10
      , showGui = True
      , editing = 0
      }
    , Http.get
                { url = "https://raw.githubusercontent.com/Orasund/flask/master/Deck/base.json"
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


card : Card -> List (Element msg)
card ({ name, hasDesc, img, amount } as config) =
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
        { name = name
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
                                    |> card
                                    |> List.head
                                    |> Maybe.map
                                        ( \label ->
                                            Input.button [Element.alignLeft] <|
                                            {label = Element.el
                                            (Color.info ++ [ Element.inFront <|
                                                Element.el
                                                    (if i == model.editing
                                                    then
                                                        Framework.Card.simple
                                                        ++ Color.info
                                                        ++ [ Border.roundEach
                                                                { topLeft = 0
                                                                , bottomLeft =0
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
                                            
                                            ] ++ (  if i == model.editing
                                                    then 
                                                        [ Border.color <| Color.cyan
                                                        , Border.width <| round <| 2 * spacingMult
                                                        ]
                                                    else 
                                                        []
                                                )
                                            ) <| label
                                            , onPress = Just (Selected i)
                                            }
                                            
                                            
                                        )
                            )
                            >> List.filterMap identity

                    else
                        List.map card >> List.concat
                   )

        emptyCards : Int
        emptyCards =
            model.cardsPerPage - (cards |> List.length) |> modBy model.cardsPerPage

        displayCards : Element Msg
        displayCards =
            Element.paragraph [ Element.width <| Element.fill ] <|
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
                          <| Element.none
                        ]

                      else
                        Card.empty emptyCards |> card
                    ]

        editedCard : Card
        editedCard =
            model.cards
                |> Array.get model.editing
                |> Maybe.withDefault (Card.empty 1)

        numberInput : { onIncrease : msg, onDecrease : msg, value : Int, label : String } -> Element msg
        numberInput { onDecrease, onIncrease, value, label } =
            Element.row [ Element.spacing 5, Element.width <| Element.fill ] <|
                [ Element.el Input.label <| Element.text label
                , Element.row ([ Element.width <| Element.fill ] ++ Grid.simple)
                    [ Input.button
                        ([ Element.width <| Element.fill, Element.alignLeft ] ++ Button.simple)
                        { onPress = Just <| onDecrease
                        , label = Element.text <| "-"
                        }
                    , Element.el [ Font.center, Element.width <| Element.fillPortion 2 ] <|
                        Element.text <|
                            String.fromInt <|
                                value
                    , Input.button
                        ([ Element.width <| Element.fill, Element.alignRight ]
                            ++ Button.simple
                            ++ Color.success
                        )
                        { onPress = Just <| onIncrease
                        , label = Element.text <| "+"
                        }
                    ]
                ]
        
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
            Element.row (Grid.spacedEvenly ++ [ Element.width Element.fill ]) <|
                [ Element.el
                    [ Element.width Element.fill] <|
                    displayCards
                , Element.column (Grid.simple ++ [ Element.width Element.shrink, Element.alignRight ]) <|
                    [ Element.column (Framework.Card.simple ++ Grid.simple) <|
                        (editedCard.composition
                            |> (\{ g1, g2, r1, r2, b1, b2, y1, y2 } ->
                                    [ Input.text Input.simple
                                        { onChange = ChangedName
                                        , text = editedCard.name
                                        , placeholder = Nothing
                                        , label = Input.labelLeft Input.label <| Element.text "Name"
                                        }
                                    , Input.text Input.simple
                                        { onChange = ChangedImg
                                        , text = editedCard.img
                                        , placeholder = Nothing
                                        , label = Input.labelLeft Input.label <| Element.text "Image Link"
                                        }
                                    , numberInput
                                        { onIncrease = IncreaseAmount
                                        , onDecrease = DecreaseAmount
                                        , value = editedCard.amount
                                        , label = "Amount"
                                        }
                                    , Input.checkbox [] <|
                                        { onChange =
                                            \b ->
                                                (if b then
                                                    AddComponent

                                                 else
                                                    RemoveComponent
                                                )
                                                    G2
                                        , icon = Input.defaultCheckbox
                                        , checked = g2
                                        , label = Input.labelLeft Input.label <| Element.text <| toTitle <| G2
                                        }
                                    , Input.checkbox [] <|
                                        { onChange =
                                            \b ->
                                                (if b then
                                                    AddComponent

                                                 else
                                                    RemoveComponent
                                                )
                                                    Y2
                                        , icon = Input.defaultCheckbox
                                        , checked = y2
                                        , label = Input.labelLeft Input.label <| Element.text <| toTitle <| Y2
                                        }
                                    , numberInput
                                        { onIncrease = AddComponent B2
                                        , onDecrease = RemoveComponent B2
                                        , value = b2
                                        , label = B2 |> toTitle
                                        }
                                    , numberInput
                                        { onIncrease = AddComponent B1
                                        , onDecrease = RemoveComponent B1
                                        , value = b1
                                        , label = B1 |> toTitle
                                        }
                                    , numberInput
                                        { onIncrease = AddComponent Y1
                                        , onDecrease = RemoveComponent Y1
                                        , value = y1
                                        , label = Y1 |> toTitle
                                        }
                                    , numberInput
                                        { onIncrease = AddComponent G1
                                        , onDecrease = RemoveComponent G1
                                        , value = g1
                                        , label = G1 |> toTitle
                                        }
                                    , numberInput
                                        { onIncrease = AddComponent R1
                                        , onDecrease = RemoveComponent R1
                                        , value = r1
                                        , label = R1 |> toTitle
                                        }
                                    , numberInput
                                        { onIncrease = AddComponent R2
                                        , onDecrease = RemoveComponent R2
                                        , value = r2
                                        , label = R2 |> toTitle
                                        }
                                    , Input.button (Button.simple ++ Color.danger ++ [ Element.alignRight ]) <|
                                        { onPress = Just DeletedSelected
                                        , label = Element.text <| "Remove"
                                        }
                                    ]
                               )
                        )
                    , Element.row Grid.simple
                    [Input.button (Button.simple ++ Color.primary) <|
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
                    ]]
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
