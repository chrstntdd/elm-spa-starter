module Main exposing (..)

import Html exposing (Html, button, div, p, program, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Port exposing (..)


{- MODEL -}


type alias Model =
    { count : Int
    , screenData : Maybe ScreenData
    }


initialModel : Model
initialModel =
    { count = 0
    , screenData = Nothing
    }



{- VIEW -}


view : Model -> Html Msg
view model =
    div []
        [ p [] [ "The count is " ++ toString model.count |> text ]
        , button [ class "button", onClick Increment ] [ text "+1" ]
        , button [ class "button", onClick Decrement ] [ text "-1" ]
        ]



{- UPDATE -}


type Msg
    = NoOp
    | Increment
    | Decrement
    | Outside InfoForElm
    | LogErr String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        Outside infoForElm ->
            case infoForElm of
                ScrollOrResize data ->
                    { model | screenData = Just data } ! []

        LogErr err ->
            model ! [ sendInfoToJS (LogErrorToConsole err) ]

        Increment ->
            { model | count = model.count + 1 } ! []

        Decrement ->
            { model | count = model.count - 1 } ! []



{- SUBSCRIPTIONS -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



{- MAIN -}


init : ( Model, Cmd Msg )
init =
    initialModel ! []


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions =
            \model ->
                Sub.batch
                    [ receiveInfoFromJS Outside LogErr ]
        }
