This document outlines all custom commands built into this environment.

# The mambogen Command
A custom utility to parse selected theme to correct format.
```bash
mbcolor [theme] [format] [target_path]
```

## Available Themes

| Theme         | Description |
| ------------- | ----------- |
| MamboHeritage |             |
| MamboOrche    |             |
| MamboOutback  |             |
> [!NOTE]
> The [theme] is not case sensitive, any input will be formatted to all lower caps.

## Available Formats

| Format   | Description |
| -------- | ----------- |
| Hyprland |             |
| Waybar   |             |
| Tailwind |             |
> [!NOTE]
> The [format] is not case sensitive, any input will be formatted to all lower caps.

## Examples
```bash
# Generate the MamboHeritage theme in Hyprland format to Downloads folder
mbcolor mamboheritage hyprland ~/Downloads
```