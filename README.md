<h1><p align=center>EG-Statusline</p></h1>
<h3><p align=center><sup>Simplicity oriented neovim statusline plugin</sup></p></h3>
<br \><br \>

## ⚙️ Features
- Performant (utilizing caches, profiling)
- <200 lines of Lua
- Simple to setup and customize

## 📦 Installation
- With [folke/lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ "Ernest1338/eg-statusline.nvim" },
```
- With [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use "Ernest1338/eg-statusline.nvim"
```

## 🔧 Configuration

- For [folke/lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ "Ernest1338/eg-statusline.nvim", config = true },
```

- For [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
    "Ernest1338/eg-statusline.nvim",
    config = function()
        require("eg-statusline").setup()
    end
}
```

## ⚡ Requirements
- Neovim >= **v0.7.0**

