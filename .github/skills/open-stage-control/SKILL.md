---
name: open-stage-control
description: "Open Stage Control reference for OSC UI design. Use when: creating or editing OSC controller JSON sessions, designing widgets (buttons, sliders, dropdowns, panels, xy pads), writing widget scripts (onValue, onCreate, onTouch), configuring OSC addresses, building custom modules, or styling with CSS themes."
---

# Open Stage Control Reference

## When to Use
- Creating or modifying `.json` session files for Open Stage Control
- Designing UI widgets (buttons, sliders, panels, dropdowns, xy pads)
- Writing widget scripts (`onValue`, `onCreate`, `onTouch`)
- Configuring OSC message routing and addresses
- Building custom modules for server-side message processing
- Styling interfaces with CSS themes

## Architecture

Open Stage Control has 3 modules:
- **Server**: Node.js/Electron, handles OSC/MIDI, serves web client
- **Launcher**: Configuration GUI for the server
- **Client**: Web app served by the server, runs in any modern browser

## Widget Types

### Basics
| Type | Purpose |
|------|---------|
| `button` | Toggle or momentary trigger |
| `switch` | Multi-value button group |
| `dropdown` | Select from list |
| `menu` | Context menu selector |
| `input` | Text/number input field |
| `textarea` | Multi-line text input |
| `file` | File browser widget |

### Containers
| Type | Purpose |
|------|---------|
| `panel` | Layout container (vertical/horizontal/grid) |
| `modal` | Popup panel |
| `tab` | Tabbed container |
| `matrix` | Grid of cloned widgets |
| `clone` | Clone another widget |
| `fragment` | Reusable widget template |
| `folder` | File-system-like tree |
| `root` | Top-level session container |

### Sliders
| Type | Purpose |
|------|---------|
| `fader` | Linear slider |
| `knob` | Rotary control |
| `encoder` | Endless rotary |
| `range` | Min/max range slider |

### Pads
| Type | Purpose |
|------|---------|
| `xy` | 2D position pad |
| `multixy` | Multiple 2D points |
| `rgb` | Color picker |
| `canvas` | Scriptable drawing area |

### Indicators
| Type | Purpose |
|------|---------|
| `led` | On/off indicator |
| `text` | Static/dynamic text display |

### Graphs
| Type | Purpose |
|------|---------|
| `plot` | Line/bar chart |
| `eq` | EQ curve display |
| `visualizer` | Audio-style visualizer |

### Frames
| Type | Purpose |
|------|---------|
| `frame` | Embedded webpage |
| `svg` | SVG display |
| `html` | Raw HTML |
| `image` | Image display |

### Scripts
| Type | Purpose |
|------|---------|
| `script` | Invisible widget that runs JS |
| `variable` | Stores a value without UI |

## Key Widget Properties

```json
{
  "type": "button",
  "id": "my_button",
  "label": "Play",
  "address": "/play",
  "target": ["ip:port"],
  "default": 0,
  "on": 1,
  "off": 0,
  "css": "",
  "visible": true,
  "interaction": true,
  "bypass": false,
  "ignoreDefaults": false
}
```

### Common Properties
- `id` — Unique widget identifier (used in `get()`, `set()`)
- `address` — OSC path sent when value changes (e.g., `/bass_on`)
- `target` — Override default OSC target (`"ip:port"`)
- `label` — Display text (supports templates: `#{@{this} == 1 ? 'On' : 'Off'}`)
- `default` — Initial value
- `css` — Inline CSS styles
- `visible` / `interaction` — Show/enable widget

### Button-Specific
- `on` / `off` — Values for active/inactive states
- `mode` — `"toggle"` or `"momentary"` (tap)
- `colorWidget` / `colorFill` — Button colors

### Switch-Specific
- `values` — Object mapping labels to values: `{"Bass": 0, "L1": 1, "L2": 2}`

### Dropdown-Specific
- `values` — Array or object of options

### Slider/Fader-Specific
- `range` — `{"min": 0, "max": 1}` or with steps
- `steps` — Snap to N positions

### XY Pad-Specific
- `pointSize` — Size of points
- `rangeX` / `rangeY` — Value ranges per axis
- `snap` — Return to center on release

## Scripting

Widget scripts execute JavaScript on events.

### Event Types
- **`onCreate`** — When widget is created (after children)
- **`onValue`** — When widget value changes or receives a value
- **`onTouch`** — When widget is touched/released

### Available Variables in Scripts

```javascript
// Reading values
get("widget_id")                    // Get widget value
getProp("widget_id", "property")    // Get widget property
getVar("widget_id", "varName")      // Get custom variable

// Setting values
set("widget_id", value)             // Set widget value (triggers send)
set("widget_id", value, {send: false})  // Set without sending OSC
setVar("widget_id", "varName", value)   // Set custom variable

// Sending OSC
send("ip:port", "/address", arg1, arg2)  // Send to specific target
send("/address", arg1)                    // Send to default target

// Globals
globals.screen    // {width, height, orientation}
globals.env       // Client options
globals.ip        // Client IP
locals            // Widget-local storage object

// Timers
setTimeout(id, callback, delay)
setInterval(id, callback, delay)
clearTimeout(id)
clearInterval(id)

// State
stateGet("widget_id")               // Returns {id: value} state tree
stateSet(stateObject)                // Load state object

// Other
updateProp("widget_id", "propName") // Force property re-evaluation
setFocus("widget_id")               // Focus an input
storage                              // localStorage instance
```

### Script Example (onValue)
```javascript
// Toggle label based on value
if (value == 1) {
  set("status_text", "Playing")
} else {
  set("status_text", "Stopped")
}
```

### Script Example (onCreate)
```javascript
// Initialize dropdown with values
set("this", {"Reverb": "reverb", "Echo": "echo", "Distortion": "distortion"})
```

## OSC Communication

### Address Pattern
Widgets send OSC messages based on their `address` property:
- Widget value changes → OSC message sent to `target` with `address` and value as arguments
- Incoming OSC messages with matching `address` → widget value updated

### Receiving OSC to Update Widgets
Send an OSC message to the Open Stage Control server (default port 7777) matching a widget's `address` to update it:
```
/bass_on 1       → Sets bass_on widget to 1
/tempo 120       → Sets tempo widget to 120
```

### Sending from Scripts
```javascript
// In onValue script
send("/custom/address", value, 42)
send("192.168.1.10:4560", "/trigger", value)
```

## Custom Modules (Server-Side)

Custom modules run on the server and can intercept/modify OSC messages:

```javascript
module.exports = {
  oscInFilter: function(data) {
    // Modify incoming OSC before it reaches widgets
    var {address, args, host, port} = data
    // return data to forward, or false to block
    return data
  },
  oscOutFilter: function(data) {
    // Modify outgoing OSC before it's sent
    var {address, args, host, port} = data
    return data
  }
}
```

## CSS Theming

Apply CSS via widget `css` property or global theme file:

```css
/* Widget-level */
.widget { background: #222; }

/* Button colors */
.on { background: green; }

/* Label styling */
.label { font-size: 14px; color: white; }
```

Load a theme file via server config: `--theme /path/to/theme.css`

## Session JSON Structure

A session is a single JSON object with a root widget containing children:

```json
{
  "type": "root",
  "id": "root",
  "children": [
    {
      "type": "panel",
      "id": "main_panel",
      "layout": "vertical",
      "children": [
        {"type": "button", "id": "play_btn", "address": "/play"},
        {"type": "fader", "id": "volume", "address": "/volume"}
      ]
    }
  ]
}
```

## Sonic Stage Integration

In this project, Open Stage Control communicates with Sonic Pi on port 7777:
- UI widgets send OSC messages that `osc_monitor.rb` handles
- Sonic Pi sends back values via `osc_ctrl(path, *args)` to update UI state
- The session file is [osc_controller.json](../../osc_controller.json)
- Theme CSS is [osc_controller_theme.css](../../osc_controller_theme.css)
