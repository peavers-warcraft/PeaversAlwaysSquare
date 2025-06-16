# PeaversAlwaysSquare

**A World of Warcraft addon that automatically and persistently marks tanks with a square icon, because tanks need squares on their heads, not stars in their eyes.**

### New!
Check out [peavers.io](https://peavers.io) and [bootstrap.peavers.io](https://bootstrap.peavers.io) for all my WoW addons and support.

## Overview

PeaversAlwaysSquare solves the age-old problem of inconsistent raid markers by relentlessly marking your group's tank with a square icon. If someone dares to change it, the addon will immediately change it back, with unwavering dedication to proper dungeon etiquette.

## Features

- **Unwavering Dedication**: Automatically marks tanks with the square icon
- **Stubborn as a Dwarf**: Immediately reapplies the mark if someone changes it
- **Customizable Iconography**: Change which icon to use with a simple command
- **Debugging Tools**: Troubleshooting options when things don't work as expected

## Installation

1. Download from the repository
2. Extract to your `World of Warcraft/_retail_/Interface/AddOns/` folder
3. Ensure your folder structure is `Interface\AddOns\PeaversAlwaysSquare\PeaversAlwaysSquare.lua`
4. Reload your UI

## Usage

- The addon works automatically once installed
- Tanks in your party or raid will be marked with a square icon
- The marker will be reapplied if changed by another player

## Configuration

- `/tm` - Force mark all tanks right now
- `/tm icon N` - Change icon ID to N (1-8)
- `/tm test` - Test all icons on yourself
- `/tm debug` - Toggle debug mode

### Icon Reference

| ID | Icon Name | Description |
|----|-----------|-------------|
| 1  | Star      | Pretty but wrong for tanks |
| 2  | Circle    | Round like a tank's belly, but still wrong |
| 3  | Diamond   | Fancy, but tanks aren't made of carbon |
| 4  | Triangle  | A mathematical tribute to tanks, but no |
| 5  | Moon      | Only for druids and night elf cosplayers |
| 6  | Square    | THE ONE TRUE TANK MARKER |
| 7  | Cross     | For when your healer abandons you |
| 8  | Skull     | What happens when you pull without a tank |

## Support & Feedback

If you encounter any issues with the addon or have ideas for improvement, please submit them through the repository's issue tracker. Your feedback helps make dungeon and raid marking conventions more consistent for everyone.

*"Square tanks, square markers. It's not rocket engineering."*

<!-- Workflow triggered: 2025-06-16T10:46:02.358574 -->
