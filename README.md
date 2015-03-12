Pathogen Plugin for OMF
=======================

I wrote this to ease the installation and management of pathogen plugins.
It is meant to install pathogen plugins from git repositories.
It can be used easily with other services, such as darqs, with some modification.
It is also a framework that can easily be adapted to use with other plugin systems
of a similar nature, such as OMF.

There are probably bugs. If there are bugs, you are welcom to open a pull request.

Installation
============

Do the following to install the plugin:

```sh
set -q fish_path; or set fish_path ~/.oh_my_fish
cd $fish_path/custom/plugins	
git clone https://github.com/rhargrave/pathogen-manager
```

As with other OMF plugins, you will also want to add it to your $fish\_plugins variable.
You will want to add the value `pathogen` to your $fish\_plugins in the manner that is most consistent
with your setup.

Usage
=====

*This can be viewed using `pathogen help`*

```
Usage:
	pathogen <install|update|list|remove|disable|enable|help>

	Commands:

		install <...>			- Install a package

			This command will enter your bundles directory, specified by environment variable `PATHOGEN_BUNDLES` and
			run `git clone` with the provided arguments.

			For instance:

				pathogen install https://github.com/vim-scripts/YankRing.vim.git
			
			will install `YankRing.vim` in to PATHOGEN_BUNDLES/YankRing.vim

			Being that this is effectively a git wrapper, anything that you can pass to your GIT's
			clone command will work. This can be especially useful if you have `hub` (https://github.com/github/hub)
			installed, which would effectively make the following command equivalent to the former
				
				pathogen install vim-scripts/YankRing.vim

		update [plugin names]	- Update plugins

			This command will update the specified plugins, or, if none are specified, all plugins (including disabled plugins)

			Example:

				~> pathogen update YankRing.vim
				Updating YankRing.vim: OK

		list					- List plugins

			Options:

				--fetch			- Fetch remote in git repositories. This will update repos, and you will thusly be notified of the latest changes.

			This command will list all installed plugins, including disabled plugins.
			If a plugin has updates available, it will have a `*` placed next to it. (You may need to specify `--fetch`)
			If it is disabled, it will have a `-` placed next to it.

			This will be formatted as your *NIXs installation of `column` pleases

		remove [plugin names]	- Remove plugins

			This command will remove the speicifed plugins
			If you have `safe-rm` installed, that will be used instead of `rm`

		disable [plugin names]	- Disable plugins

			This command will disable all listed plugins by moving them in to `PATHOGEN_BUNDLES_DISABLED`
			
		enable [plugin names]	- Enable plugins

			This command will enable all listed plugins by moving them out of `PATHOGEN_BUNDLES_DISABLED`, and in to `PATHOGEN_BUNDLES`

		help					- Get help

			You are looking at the output of this command

Environment Variables:

		PATHOGEN_BUNDLES
			Location of the `bundle` folder or equivalent in your environment.
			This is set to `$HOME/.vim/bundle` by default

		PATHOGEN_BUNDLES_DISABLED
			Locale of the folder wherein disabled plugins will be stored
			This is set to `$HOME/.vim/bundle.available` by default, and will be created
			if it does not exist
```
