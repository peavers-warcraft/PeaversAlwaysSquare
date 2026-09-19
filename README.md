# PeaversAlwaysSquare

[![AddonSentry](https://addonsentry.io/api/public/repos/peavers-warcraft/PeaversAlwaysSquare/badge.svg)](https://addonsentry.io/dashboard/peavers-warcraft/PeaversAlwaysSquare)

A World of Warcraft addon that marks your party's tank with a square icon in a single press.

## Features

<!-- peavers:features -->
- Marks the tank with the square icon in one press: a button, a key binding or a macro
- Prompts you with a button whenever the tank has no marker
- Always aims at whoever holds the tank role, so there is nothing to target
<!-- /peavers:features -->

## Usage

<!-- peavers:usage -->
Since patch 12.0 the game no longer lets addons place raid markers on their own, so marking takes one press from you. When your party's tank has no marker a small button appears; click it and the tank is marked. Shift-drag moves the button.

You can also bind a key under Key Bindings > AddOns > Peavers Always Square. It works in combat and with the button hidden.

**As close to automatic as it gets:** add `/click PeaversAlwaysSquareMarkButton` as a line in a macro you already press, such as your mount or an opening ability. Every press then makes sure the tank has the square. It does nothing if they already have it, so it is safe to spam.

### Slash Commands

- `/pas` - How to mark, and the macro to do it
- `/pas reset` - Put the marker button back where it started
- `/pas config` - Open settings
- `/pas debug` - Toggle debug mode

<!-- /peavers:usage -->


## Installation

### Recommended: PeaversUpdater

Download and install [PeaversUpdater](https://github.com/peavers-warcraft/PeaversUpdater/releases/latest), the desktop updater for the whole Peavers collection. It installs PeaversAlwaysSquare together with its required dependencies and delivers updates before they reach CurseForge.

### Alternative: CurseForge

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/peaversalwayssquare)
2. Ensure [PeaversCommons](https://www.curseforge.com/wow/addons/peaverscommons) is also installed
3. Ensure [PeaversConfig](https://www.curseforge.com/wow/addons/peaversconfig) is also installed
4. Enable the addon on the character selection screen

---

*Part of the [Peavers](https://peavers.io) addon collection · [Report an issue](https://github.com/peavers-warcraft/PeaversAlwaysSquare/issues) · [Support development on Patreon](https://www.patreon.com/Peavers)*
