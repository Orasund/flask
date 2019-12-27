module Data.Card exposing (Card,empty,codec)

import Data.Composition as Composition exposing (Composition)
import Codec exposing (Codec)

type alias Card =
    { name : String
    , composition : Composition
    , hasDesc : Bool
    , img : String
    , amount : Int
    }


empty : Int -> Card
empty amount =
    { name = " "
    , composition = Composition.empty
    , hasDesc = True
    , img = ""
    , amount = amount
    }

codec : Codec Card
codec =
  Codec.object Card
  |> Codec.field "name".name Codec.string
  |> Codec.field "composition" .composition Composition.codec
  |> Codec.field "hasDesc" .hasDesc Codec.bool
  |> Codec.field "img" .img Codec.string
  |> Codec.field "amount" .amount Codec.int
  |> Codec.buildObject