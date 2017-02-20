module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Array.Hamt as Array exposing (..)
import Time exposing (millisecond)
import Task


worldSize =
    50


type Message
    = Tick
    | Pause
    | Play
    | Edit
    | ToggleCell Int Int
    | Clear
    | ToggleAll


type State
    = Running
    | Editing


type Cell
    = Alive
    | Dead


type alias Neighborhood =
    List Cell


type alias Row =
    Array Cell


type alias Patch =
    Array Row


type alias World =
    Array Row


type alias Model =
    { world : World, state : State }


next cell neighbors =
    let
        liveNeighbors =
            List.filter (\e -> e == Alive) neighbors |> List.length
    in
        case ( cell, liveNeighbors ) of
            ( Alive, 2 ) ->
                Alive

            ( Alive, 3 ) ->
                Alive

            ( Dead, 3 ) ->
                Alive

            ( _, _ ) ->
                Dead


patch size cellState =
    Array.fromList (List.repeat size (Array.fromList (List.repeat size cellState)))


mapPatch update patch =
    Array.indexedMap (\rowIdx -> Array.indexedMap (update rowIdx)) patch


emptyWorld : World
emptyWorld =
    patch worldSize Dead


fullWorld : World
fullWorld =
    patch worldSize Alive


px n =
    (Basics.toString n) ++ "px"


renderCell canEdit rowIdx idx cell =
    let
        topPos =
            ( "top", (rowIdx * 10) |> px )

        leftPos =
            ( "left", (idx * 10) |> px )

        actions =
            if canEdit then
                [ onClick (ToggleCell idx rowIdx) ]
            else
                []
    in
        span
            ([ style [ topPos, leftPos ]
             , class "cell"
             , classList [ ( "alive", cell == Alive ), ( "dead", cell == Dead ) ]
             ]
                ++ actions
            )
            []


renderRow canEdit idx row =
    Array.indexedMap (renderCell canEdit idx) row |> Array.toList |> div [ class "row" ]


renderWorld { world, state } =
    Array.indexedMap (renderRow (state == Editing)) world |> Array.toList |> div [ class "world" ]


renderControls state =
    let
        playBtn =
            button [ type_ "button", onClick Play ]
                [ text "Play"
                ]

        nextBtn =
            button [ type_ "button", onClick Tick ] [ text "Next" ]

        editBtn =
            button [ type_ "button", onClick Edit ] [ text "Edit" ]

        clearBtn =
            button [ type_ "button", onClick Clear ] [ text "Clear" ]

        toggleAllBtn =
            button [ type_ "button", onClick ToggleAll ] [ text "Toggle all" ]

        buttons =
            case state of
                Editing ->
                    [ nextBtn, playBtn, clearBtn, toggleAllBtn ]

                Running ->
                    [ editBtn ]
    in
        div [ class "controls" ]
            [ div [ class "tick" ]
                [ span [] [ text "Controls" ]
                , div [] buttons
                ]
            ]


view model =
    div [] [ (renderWorld model), renderControls model.state ]


getCell world ( x, y ) =
    Array.get y world |> Maybe.andThen (Array.get x)


matrix =
    [ ( -1, -1 ), ( 0, -1 ), ( 1, -1 ), ( -1, 0 ), ( 1, 0 ), ( -1, 1 ), ( 0, 1 ), ( 1, 1 ) ]


getNeighbors world rowIdx cellIdx =
    let
        asArrayCoords =
            List.map (\( x, y ) -> ( cellIdx + x, rowIdx + y )) matrix

        validCoords ( x, y ) =
            x >= 0 && x <= worldSize && y >= 0 && y <= worldSize

        valid =
            List.filter validCoords asArrayCoords
    in
        List.map (getCell world >> Maybe.withDefault Dead) valid


updateCell world rowIdx cellIdx cell =
    next cell (getNeighbors world rowIdx cellIdx)


updateRow world idx row =
    Array.indexedMap (updateCell world idx) row


nextPatch patch =
    Array.indexedMap (updateRow patch) patch


updateWorld world =
    nextPatch world


arrayUpdate idx fn arr =
    arr |> Array.get idx |> Maybe.map (fn >> (\newVal -> Array.set idx newVal arr))


toggleCell cell =
    case cell of
        Alive ->
            Dead

        Dead ->
            Alive


toggleSingleCell world x y =
    Maybe.withDefault world (arrayUpdate y (\row -> Maybe.withDefault row (arrayUpdate x toggleCell row)) world)


sendMsg msg =
    Task.perform identity (Task.succeed msg)


update msg model =
    case Debug.log "Message = " msg of
        Tick ->
            let
                nextWorld =
                    updateWorld model.world
            in
                { model | world = nextWorld }
                    ! if nextWorld == model.world then
                        [ sendMsg Pause ]
                      else
                        []

        Pause ->
            { model | state = Editing } ! []

        Edit ->
            { model | state = Editing } ! []

        Play ->
            { model | state = Running } ! []

        ToggleCell x y ->
            { model | world = toggleSingleCell model.world x y } ! []

        ToggleAll ->
            { model | world = mapPatch (\_ _ cell -> toggleCell cell) model.world } ! []

        Clear ->
            { model | world = emptyWorld } ! []


withPatches : List ( Int, Int, World ) -> World -> World
withPatches ps world =
    List.foldl (\( x, y, p ) w -> (applyPatch x y w p)) world ps


firstWorld =
    emptyWorld
        |> withPatches
            [ ( 3, 3, blockPatch )
            , ( 0, 0, gliderPatch )
            , ( 21, 21, infinitePatch1 )
            , ( 10, 40, blinkerPatch |> nextPatch )
            ]


model =
    ( { world = firstWorld, state = Editing }
    , Cmd.none
    )


blockPatch =
    patch 4 Dead
        |> mapPatch
            (\x y _ ->
                case ( x, y ) of
                    ( 1, 1 ) ->
                        Alive

                    ( 2, 1 ) ->
                        Alive

                    ( 1, 2 ) ->
                        Alive

                    ( 2, 2 ) ->
                        Alive

                    _ ->
                        Dead
            )


blinkerPatch =
    patch 5 Dead
        |> mapPatch
            (\x y _ ->
                case ( x, y ) of
                    ( 2, 2 ) ->
                        Alive

                    ( 2, 3 ) ->
                        Alive

                    ( 2, 4 ) ->
                        Alive

                    _ ->
                        Dead
            )


gliderPatch =
    patch 5 Dead
        |> mapPatch
            (\x y _ ->
                case ( x, y ) of
                    ( 2, 1 ) ->
                        Alive

                    ( 3, 2 ) ->
                        Alive

                    ( 1, 4 ) ->
                        Alive

                    ( 2, 4 ) ->
                        Alive

                    ( 3, 4 ) ->
                        Alive

                    _ ->
                        Dead
            )


infinitePatch1 =
    patch 5 Dead
        |> mapPatch
            (\x y _ ->
                case ( x, y ) of
                    ( 0, 0 ) ->
                        Alive

                    ( 0, 1 ) ->
                        Alive

                    ( 0, 4 ) ->
                        Alive

                    ( 1, 0 ) ->
                        Alive

                    ( 1, 3 ) ->
                        Alive

                    ( 2, 0 ) ->
                        Alive

                    ( 2, 3 ) ->
                        Alive

                    ( 2, 4 ) ->
                        Alive

                    ( 3, 2 ) ->
                        Alive

                    ( 4, 0 ) ->
                        Alive

                    ( 4, 2 ) ->
                        Alive

                    ( 4, 3 ) ->
                        Alive

                    ( 4, 4 ) ->
                        Alive

                    _ ->
                        Dead
            )


validCell patch x y =
    let
        patchSize =
            Array.length patch
    in
        x >= 0 && x < patchSize && y >= 0 && y < patchSize


applyPatch x y patch1 patch2 =
    if validCell patch1 x y then
        let
            patchSize =
                Array.length patch2

            updatePatchCell px py oldState =
                if px >= x && py >= y && (validCell patch2 (px - x) (py - y)) then
                    getCell patch2 ( (px - x), (py - y) ) |> Maybe.withDefault oldState
                else
                    oldState
        in
            mapPatch updatePatchCell patch1
    else
        patch1


main =
    Html.program { init = model, view = view, update = update, subscriptions = subscriptions }


subscriptions : Model -> Sub Message
subscriptions model =
    if model.state == Running then
        Time.every (200 * millisecond) (\_ -> Tick)
    else
        Sub.none
