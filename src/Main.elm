module Main exposing (..)

import Html exposing (Attribute, Html, a, button, div, li, p, program, text, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Navigation
import Port exposing (..)
import Routes exposing (Route)
import Util exposing (onClickLink, unwrap)


type alias LinkData msg =
    { url : Route
    , attrs : List (Attribute msg)
    , label : String
    }


link : LinkData Msg -> Html Msg
link { url, attrs, label } =
    {- HELPER FUNCTION FOR SPA NAVIGATION -}
    a (List.append attrs [ Routes.href url, onClickLink (NavigateTo url) ]) [ text label ]



{- MODEL -}


type alias Model =
    { count : Int
    , page : Route
    , screenData : Maybe ScreenData
    }


initialModel : Model
initialModel =
    { count = 0
    , page = Routes.Home
    , screenData = Nothing
    }



{- VIEW -}


view : Model -> Html Msg
view model =
    let
        appShell : List (Html Msg) -> Html Msg
        appShell children =
            div []
                ([ navBar ] |> List.append children)
    in
    case model.page of
        Routes.Home ->
            appShell
                [ p [] [ text "Home" ]
                , counter model.count
                ]

        Routes.About ->
            appShell
                [ p [] [ text "About" ]
                , counter model.count
                ]

        _ ->
            appShell
                [ p [] [ text "Fallback" ]
                , counter model.count
                ]


counter : Int -> Html Msg
counter count =
    div []
        [ p [] [ "The count is " ++ toString count |> text ]
        , button [ class "button", onClick Increment ] [ text "+1" ]
        , button [ class "button", onClick Decrement ] [ text "-1" ]
        ]


navBar : Html Msg
navBar =
    ul []
        [ li []
            [ link { url = Routes.Home, attrs = [], label = "Home" } ]
        , li []
            [ link { url = Routes.About, attrs = [], label = "About" } ]
        , li []
            [ link { url = Routes.Projects, attrs = [], label = "Projects" } ]
        , li []
            [ link { url = Routes.Contact, attrs = [], label = "Contact" } ]
        ]



{- UPDATE -}


type Msg
    = NoOp
    | SetRoute (Maybe Route)
    | Increment
    | Decrement
    | NavigateTo Route
    | Outside InfoForElm
    | LogErr String


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    case maybeRoute of
        Nothing ->
            { model | page = Routes.NotFound } ! []

        Just Routes.Home ->
            { model | page = Routes.Home } ! []

        Just Routes.About ->
            { model | page = Routes.About } ! []

        Just Routes.Projects ->
            { model | page = Routes.Projects } ! []

        Just Routes.Contact ->
            { model | page = Routes.Contact } ! []

        _ ->
            { model | page = Routes.NotFound } ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        SetRoute maybeRoute ->
            setRoute maybeRoute model

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

        NavigateTo page ->
            {- THE SECOND ARGUMENT TO routeToString IS A JWT FOR VALIDATION, IF NEEDED -}
            model ! [ Navigation.newUrl (Routes.routeToString page "") ]



{- SUBSCRIPTIONS -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



{- MAIN -}


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        maybeRoute =
            location |> Routes.fromLocation
    in
    setRoute maybeRoute initialModel


main : Program Never Model Msg
main =
    Navigation.program (Routes.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions =
            \model ->
                Sub.batch
                    [ receiveInfoFromJS Outside LogErr ]
        }
