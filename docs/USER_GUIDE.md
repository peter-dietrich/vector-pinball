# Vector Pinball — macOS Help (Unity 6.3 Physics Laboratory)

**Status:** Experimental Unity 6.3 LTS physics laboratory. This is not yet the finished commercial-quality Vector Pinball table. The repo's Unity editor version is pinned in `ProjectSettings/ProjectVersion.txt`.

## Play and controls

Open the project in Unity Hub, select **Fun City → Pinball → Build Physics Lab Scene**, then press **Play**.

| Control | Action |
| --- | --- |
| Return | Reset the steel ball and flippers |
| Space | Launch the ball with the physics plunger |
| A or Left Shift | Activate left flipper |
| D or Right Shift | Activate right flipper |
| F1 or HELP button | Toggle in-game offline Help |

The game uses Unity rigid bodies and hinge joints. The laboratory has no score leaderboard, game saves, or finished themed table yet.

## Mac app icon and menu actions

- **Fun City → Pinball → Configure macOS App Icon** generates an original dark-neon pinball icon using locally generated PNG pixels and registers it with Unity's standalone macOS player icon settings.
- **Fun City → Pinball → Help / Controls** opens a controls and scope guide in the Unity editor.
- **Fun City → Pinball → Build macOS Physics Lab** automatically configures the app icon and builds the standalone Mac application.
- The standalone app includes its own offline **F1 Help** overlay. A dedicated native Cocoa Help menu is not yet implemented; Unity's Mac player menus are owned by Unity, not SwiftUI.

## Build validation

These changes are committed but cannot be compiled or played here without the pinned Unity 6.3 editor. Open the project in Unity, build the scene and verify the icon is visible in Finder's app bundle and the built app's F1 overlay works.

The Game menu and Mac Help windows in the other Fun City games are native SwiftUI. The Unity-specific help implementation is deliberately separate.
