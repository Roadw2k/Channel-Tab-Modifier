# Channel Tab Modifier

A lightweight World of Warcraft addon for personalizing the names, colors, and opacity of your chat tabs.

Channel Tab Modifier provides a clean, movable settings panel where you can customize each active chat window without changing its underlying Blizzard chat-window name. Your settings are saved between sessions and reapplied automatically when chat windows are opened, renamed, or docked.

## Features

- Rename each active chat tab with a custom display label
- Choose a custom color for every tab
- Adjust tab opacity through the color picker
- Restore individual tabs or all tabs to their original appearance
- Automatically reapply customizations after Blizzard updates the chat dock
- Movable minimap button with a saved position
- Lightweight implementation with no external dependencies

## Installation

1. Download or clone this repository.
2. Copy the `ChannelTabModifier` folder into your World of Warcraft addons directory:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/
   ```

3. Confirm that the installed files have this structure:

   ```text
   Interface/AddOns/ChannelTabModifier/ChannelTabModifier.toc
   Interface/AddOns/ChannelTabModifier/ChannelTabModifier.lua
   ```

4. Restart World of Warcraft or reload the UI.
5. Enable **Channel Tab Modifier** from the **AddOns** menu on the character-selection screen.

## Usage

### Minimap button

- **Left-click:** Open or close the settings panel
- **Right-click:** Refresh and reapply chat-tab settings
- **Drag:** Reposition the button around the minimap

### Settings panel

Each detected chat window is shown with its original name.

1. Enter the label you want displayed on the tab.
2. Click the color swatch to choose a color and opacity.
3. Click **Save changes** to save and apply your customizations. A confirmation is printed in chat and the panel closes.

Use **Restore** to reset one row, or **Restore all** to reset every displayed tab. Restored settings are not applied until you click **Save changes**.

## Slash Commands

| Command | Action |
| --- | --- |
| `/ctm` | Toggle the settings panel |
| `/channelnames` | Toggle the settings panel |
| `/ctm refresh` | Reapply saved tab labels, colors, and opacity |
| `/ctm reset` | Remove all saved tab customizations immediately |

The `refresh` and `reset` options also work with `/channelnames`.

## How It Works

Custom names only affect the text displayed on Blizzard's chat tabs. The original chat-window names remain unchanged and are used to associate each tab with its saved settings.

Configuration is stored in the account-wide `CTMDB` saved-variable table and persists across logins and UI reloads. Pending edits are committed when you click **Save changes**; closing the panel without saving discards them.

## Compatibility

- World of Warcraft Retail
- Addon interface version: `120100`
- No external libraries required

If World of Warcraft marks the addon as out of date after a game update, the addon may still work when **Load out of date AddOns** is enabled, but compatibility is not guaranteed until it has been tested against that client version.

## Troubleshooting

### A customization is not visible

Run:

```text
/ctm refresh
```

You can also right-click the minimap button to perform the same refresh.

### A chat tab is missing from the settings panel

Create or open the chat window first, then close and reopen the Channel Tab Modifier settings panel.

### Reset all settings

Run:

```text
/ctm reset
```

This removes all saved custom labels and colors and restores Blizzard's default tab appearance.

## Author

Created by **Roadw2k**.
