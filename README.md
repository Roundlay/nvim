**Roundlay/nvim** _Minimum effective dose Neovim configuration_
- No fancy stuff
- Aesthetically pleasing
- Neatfreak file-structure
- Uses _Lazy_ package manager
- Includes _Plug_ configuration examples
- Includes _Tree-sitter_ query/highlight examples
- Boots in <40ms on _Windows 11_ in _Alacritty_ running as Admin (wOrKs oN My mAcHiNe)
- Boots into large source files (~3000 lines of code) in about 130-330ms depending on the language

![image](https://github.com/Roundlay/nvim/assets/4133752/b5667cd3-62d6-4114-839a-b6f67c89e5e0)

- - -

**Things to remember about Lazy**

- **Dependencies** are plugins that must be initialized before the plugin that relies on them. This might appear straightforward, but managing the load order of Lazy-loaded plugins can become complex.
- Simply listing a plugin as a _dependency_ will trigger its installation and setup, regardless of whether you've explicitly defined it in your own configuration files.
> "First of all, lua dependencies don't need to be explicitly set. So if a package uses lua modules from another plugin, you don't need to add those dependencies. That's being done automatically." [↗](https://github.com/folke/lazy.nvim/discussions/611#discussioncomment-5175400)
- Using the `name` attribute to rename plugins can result in duplicate entries in the Lazy dashboard. This seems to occur when the renamed plugin is also a _dependency_.

- - -

**TODOs:**

- [Script]: Add virtual date and time on/near lines whenever a line begins with a TODO flag.
