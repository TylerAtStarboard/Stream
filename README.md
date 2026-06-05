<div align="center">

# Stream

**A reactive state library for Roblox**

[Documentation](https://TylerAtStarboard.github.io/Stream) · [Releases](https://github.com/TylerAtStarboard/Stream/releases/latest)

---

</div>

## What is Stream?

Stream is a simple reactive state library for Roblox, inspired by libraries like [Fusion](https://elttob.uk/Fusion/0.2/). It gives you **values** that hold state, **computeds** that derive from them automatically, and **scopes** that clean everything up when you're done. It also ships with a built-in [Iris](https://github.com/SirMallard/Iris) debugger for inspecting your reactive graph at runtime.

Stream is **not** a UI library. It doesn't include springs, tweens, component constructors, or any other UI-specific tooling. It does one thing — reactive state — and provides a clean way to bind that state to Instances or anything else. If you need animation or a full UI framework, pair Stream with whatever you already use for that.

<div align="center">
<img src="docs/debugger.png" alt="Stream Debugger" width="520">
</div>

## Quick Example

```luau
local Stream = require(ReplicatedStorage.Stream)

local scope = Stream.Scope("UI", "HealthBar")

local hp = scope:Value(100)
local label = scope:Computed(function()
    return hp:get() .. " HP"
end)

scope:Bind(textLabel){
    Text = label,
}

hp:set(75) -- textLabel.Text updates to "75 HP"

scope:Destroy() -- cleans up everything
```

## Installation

### Wally

Add to your `wally.toml`:

```toml
[dependencies]
Stream = "TylerAtStarboard/stream@1.0.0"
```

Then run:

```sh
wally install
```

### GitHub Releases

Download the latest `.rbxm` from [Releases](https://github.com/TylerAtStarboard/Stream/releases/latest) and drop it into your project.

### Example Place

Open `StreamExamplePlace.rbxl` in Studio to see Stream in action with the debugger enabled.

## Documentation

Full API reference, examples, and debugger guide:

**[https://TylerAtStarboard.github.io/Stream](https://TylerAtStarboard.github.io/Stream)**

## License

[MIT](LICENSE)
