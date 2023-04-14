import XMonad
import qualified XMonad.StackSet as Window
import qualified Data.Map        as Map
import Data.Monoid

import XMonad.Actions.CycleWS
import XMonad.Actions.FlexibleResize as Flex
import XMonad.Actions.Search
import XMonad.Actions.UpdatePointer
import XMonad.Actions.WindowGo
import qualified XMonad.Actions.Submap as SubMap

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers

import XMonad.Layout.LayoutHints
import XMonad.Layout.NoBorders
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.ToggleLayouts
import XMonad.Layout.WindowArranger
import XMonad.Layout.Mosaic

import XMonad.Prompt
import XMonad.Prompt.Input
import XMonad.Prompt.RunOrRaise
import XMonad.Prompt.Shell
import XMonad.Prompt.Window

import XMonad.Util.Run
import XMonad.Util.Scratchpad
import XMonad.Util.WorkspaceCompare
import XMonad.Util.XSelection

import System.Environment
import System.Process
import Control.Concurrent

myTerminal = "alacritty"

myKeys conf@(XConfig {XMonad.modMask = modMask}) = Map.fromList $
    [ ((modMask,                 xK_Return    ), spawn myTerminal)
    , ((modMask,                 xK_Down      ), scratchpadSpawnAction conf)
    , ((modMask,                 xK_Up        ), spawn "nautilus ~")
    , ((modMask,                 xK_c         ), spawn "/home/rupa/bin/short")
    , ((modMask,                 xK_space     ), runOrRaisePrompt mySP)
    , ((modMask .|. shiftMask,   xK_space     ), shellPrompt mySP)
--  , ((modMask .|. controlMask, xK_space     ), windowPrompt mySP)
    , ((modMask,                 xK_b         ), runOrRaise "firefox" (className =? "Firefox"))
--  , ((modMask,                 xK_x         ), emailPrompt mySP ["rupa@lrrr.us"])
    , ((modMask,                 xK_p         ), SubMap.submap $ searchEngineMap $ promptSearch mySP)
    , ((modMask .|. controlMask, xK_p         ), SubMap.submap $ searchEngineMap $ selectSearch)
    , ((modMask .|. shiftMask,   xK_p         ), safePromptSelection "firefox")
    , ((0,                       xK_Print     ), unsafeSpawn "scrot -e 'mv $f ~/Pictures'")
    , ((modMask,                 xK_Print     ), unsafeSpawn "/home/rupa/ubin/cap")
    , ((modMask,                 xK_Right     ), moveTo Next (WSIs (return $ not . (=="SP") . Window.tag)))
    , ((modMask,                 xK_Left      ), moveTo Prev (WSIs (return $ not . (=="SP") . Window.tag)))
    , ((modMask .|. shiftMask,   xK_Right     ), shiftTo Next (WSIs (return $ not . (=="SP") . Window.tag)))
    , ((modMask .|. shiftMask,   xK_Left      ), shiftTo Prev (WSIs (return $ not . (=="SP") . Window.tag)))
    , ((modMask .|. controlMask, xK_Right     ), shiftTo Next emptyWS)
    , ((modMask .|. controlMask, xK_Left      ), shiftTo Prev emptyWS)
    , ((modMask,                 xK_grave     ), sendMessage NextLayout >> (dynamicLogString myPP >>= \d -> safeSpawn "gnome-osd-client" [d]))
    , ((modMask,                 xK_j         ), windows Window.focusDown)
    , ((modMask,                 xK_Tab       ), windows Window.focusDown)
    , ((mod1Mask,                xK_Tab       ), windows Window.focusDown)
    , ((modMask,                 xK_k         ), windows Window.focusUp)
    , ((modMask .|. shiftMask,   xK_Tab       ), windows Window.focusUp)
    , ((mod1Mask .|. shiftMask,  xK_Tab       ), windows Window.focusUp)
    , ((modMask .|. shiftMask,   xK_j         ), windows Window.swapDown)
    , ((modMask .|. shiftMask,   xK_k         ), windows Window.swapUp)
    , ((modMask,                 xK_h         ), sendMessage Shrink)
    , ((modMask,                 xK_l         ), sendMessage Expand)
    , ((modMask .|. shiftMask,   xK_h         ), sendMessage MirrorShrink)
    , ((modMask .|. shiftMask,   xK_l         ), sendMessage MirrorExpand)
    , ((modMask,                 xK_semicolon ), windows Window.swapMaster)
    , ((modMask,                 xK_comma     ), sendMessage (IncMasterN 1))
    , ((modMask,                 xK_period    ), sendMessage (IncMasterN (-1)))
    , ((modMask,                 xK_n         ), refresh)
    , ((modMask .|. shiftMask,   xK_n         ), setLayout $ XMonad.layoutHook conf)
    , ((modMask ,                xK_a         ), sendMessage Taller)
    , ((modMask ,                xK_z         ), sendMessage Wider)
    , ((modMask .|. controlMask, xK_N         ), sendMessage Reset)
    , ((modMask,                 xK_m         ), sendMessage (Toggle "Full") >> (dynamicLogString myPP >>= \d -> safeSpawn "gnome-osd-client" [d]))
    , ((modMask,                 xK_s         ), withFocused $ windows . Window.sink)
    , ((modMask,                 xK_f         ), sendMessage ToggleStruts)
    , ((modMask,                 xK_w         ), kill)
    , ((modMask,                 xK_q         ), broadcastMessage ReleaseResources >> restart "xmonad" True) ]
    ++
    [ ((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(Window.greedyView, 0), (Window.shift, shiftMask)] ]
searchEngineMap method = Map.fromList $
    [ ((0, xK_g), method google)
    , ((0, xK_i), method imdb)
    , ((0, xK_w), method wikipedia) ]
myMouseBindings (XConfig {XMonad.modMask = modMask}) = Map.fromList $
    [ ((modMask, button1), (\w -> focus w >> mouseMoveWindow w))
    , ((modMask, button2), (\w -> focus w >> windows Window.swapMaster))
    , ((modMask, button3), (\w -> focus w >> Flex.mouseResizeWindow w)) ]
myDeco = def
    { activeColor         = "orange"
    , inactiveColor       = "#222222"
    , urgentColor         = "yellow"
    , activeBorderColor   = "orange"
    , inactiveBorderColor = "#222222"
    , urgentBorderColor   = "yellow"
    , activeTextColor     = "orange"
    , inactiveTextColor   = "#222222"
    , urgentTextColor     = "yellow"
    , decoHeight          = 10 }
myTab = def
    { activeColor         = "black"
    , inactiveColor       = "black"
    , urgentColor         = "yellow"
    , activeBorderColor   = "orange"
    , inactiveBorderColor = "#222222"
    , urgentBorderColor   = "black"
    , activeTextColor     = "orange"
    , inactiveTextColor   = "#222222"
    , urgentTextColor     = "yellow" }
mySP = def
    { bgColor           = "black"
    , fgColor           = "white"
    , bgHLight          = "gray"
    , fgHLight          = "black"
    , borderColor       = "orange"
    , promptBorderWidth = 1
    , position          = Bottom
    , height            = 20
    , historySize       = 1000 }
myPP = def
    { ppLayout  = (\ x -> case x of
      "Hinted ResizableTall"        -> "[|]"
      "Mirror Hinted ResizableTall" -> "[-]"
      "Hinted Tabbed Simplest"      -> "[T]"
      "Full"                 -> "[ ]"
      _                      -> x )
    , ppCurrent         = const ""
    , ppVisible         = const ""
    , ppHidden          = const ""
    , ppHiddenNoWindows = const ""
    , ppUrgent          = const ""
    , ppTitle           = const ""
    , ppWsSep           = ""
    , ppSep             = "" }
myLayout = avoidStruts $ toggleLayouts (noBorders Full)
    (smartBorders (tiled ||| mosaic 2 [3,2] ||| Mirror tiled ||| layoutHints (tabbed shrinkText myTab)))
    where
        tiled   = layoutHints $ ResizableTall nmaster delta ratio []
        nmaster = 1
        delta   = 2/100
        ratio   = 1/2
myManageHook = composeAll
    [ className =? "MPlayer"        --> doFloat
    , className =? "Gimp"           --> doFloat
    , title     =? "glxgears"       --> doFloat
    , className =? "Gnome-panel"    --> doIgnore
    , className =? "XVkbd"          --> doIgnore
    , className =? "Cellwriter"     --> doIgnore
    , className =? "Gtkdialog"      --> doFloat
    , resource  =? "desktop_window" --> doIgnore
    , isFullscreen                  --> doFullFloat
    , scratchpadManageHook $ Window.RationalRect 0 0 1 0.42
    , manageDocks ] <+> manageHook def
main = do
    env <- getEnvironment
    case lookup "DESKTOP_AUTOSTART_ID" env of
        Just id -> do
            forkIO $ (>> return ()) $ rawSystem "dbus-send" ["--session","--print-reply=string","--dest=org.gnome.SessionManager","/org/gnome/SessionManager","org.gnome.SessionManager.RegisterClient","string:xmonad","string:"++id]
            return ()
        Nothing -> return ()
    xmonad $ defaultConfig 
        { terminal           = myTerminal
        , borderWidth        = 2
        , normalBorderColor  = "black"
        , focusedBorderColor = "orange"
        , focusFollowsMouse  = True
        , modMask            = mod4Mask
        , keys               = myKeys
        , mouseBindings      = myMouseBindings
        , layoutHook         = myLayout
        , handleEventHook    = ewmhDesktopsEventHook
        , startupHook        = ewmhDesktopsStartup
        , manageHook         = myManageHook}
