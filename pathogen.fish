# Pathogen Helpers for Fish
# These commands allow for easy management of pathogen (vim) plugins
# Copyright 2015 Roman Hargrave <roman@hargrave.info>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
set -q PATHOGEN_BUNDLES; or set -g PATHOGEN_BUNDLES $HOME/.vim/bundle
set -q PATHOGEN_BUNDLES_DISABLED; or set -g PATHOGEN_BUNDLES_DISABLED $HOME/.vim/bundle.available

test -d $PATHOGEN_BUNDLES_DISABLED; or mkdir -p $PATHOGEN_BUNDLES_DISABLED ^ /dev/null

# namespace pathogen {{{
# General-purpous helpers
function pathogen.bundles_present
	test -d $PATHOGEN_BUNDLES
	return $status
end

function pathogen.dir_exists -a 'dir'
	test -d $dir
end

function pathogen.is_git_repo -a 'dir'
	test -d $dir/.git
end

function pathogen.rm_dir -d 'RM Wrapper. Prefers safe rm' -a 'directory'
	if pathogen.dir_exists $directory
		set -l cmd
		if which safe-rm ^ /dev/null
			set cmd safe-rm
		else
			# Basic safety checks, still not as good as safe-rm
			# 1. Check that the user owns the folder they want to delete
			test -O $directory; or return 2
			set cmd rm
		end
		# Unfortunately, -f must be passed to RM because GIT marks indexes as read-only
		eval $cmd -rdf "$directory" ^ /dev/null > /dev/null
		return $status
	else
		return 1
	end
end
#}}}

# namespace pathogen.plugin {{{
function pathogen.plugin.needs_update -d 'Return true if a plugin needs to be updated' -a 'path'
	if pathogen.is_git_repo $path
		set -x GIT_DIR $path
		git fetch origin --tags
		set -l current_rev  (git rev-parse HEAD)
		set -l remote_rev   (git rev-parse FETCH_HEAD)
		set -e GIT_DIR	
		return (test $current_rev -eq $remote_rev)
	else
		return 1
	end
end

function pathogen.plugin.is_disabled -d 'Returns true if a plugin is in the available plugins folder' -a 'name'
	pathogen.dir_exists (realpath "$PATHOGEN_BUNDLES_DISABLED/$name")
end

function pathogen.plugin.get_all_plugins -d 'Get a list of all plugins (including disabled) in terms of their path'
	find  $PATHOGEN_BUNDLES_DISABLED/*/ $PATHOGEN_BUNDLES/*/ -maxdepth 0 -type d ^ /dev/null
end

function pathogen.plugin.exists -d 'Returns true if the plugin is installed' -a 'name'
	test -d "$PATHOGEN_BUNDLES/$name" -o -d "$PATHOGEN_BUNDLES_DISABLED/$name"
end
#}}}

function pathogen.install --description 'Wrapper for entering ~/.vim/autoload and cloning a repository' #{{{
	# Enter bundles
	pushd $PATHOGEN_BUNDLES
	
	set -l statusfile (mktemp pathogen_install.XXXXX.log)

	printf "Fetching plugin: "
	# Clone repository
	git clone --recursive $argv 2>&1 > $statusfile
	set -l git_status $status

	if test $git_status = 0
		set_color green
		echo OK
		set_color normal
		rm $statusfile
	else
		set_color red
		echo "Error (see log file: $statusfile)"
		set_color normal
	end

	# Exit bundles
	popd

	return $git_status
end # }}}

# update helpers {{{

function pathogen.update.prefix
	date +'[%H:%M %Y-%m-%d]'
end

function pathogen.update.log_file -a 'prefix'
	set -l _path "$prefix/pathogen_update.log"
	touch $_path
	echo $_path
end

function pathogen.update.log -a 'message'
	echo (pathogen.update.prefix) "$message" >> (pathogen.update.log_file $PWD)
end

function pathogen.update.log.format_stdin
	string replace -ra '^(.*)$' (pathogen.update.prefix)' $0'
end

# }}}

function pathogen.update --description 'Wrapper for updating pathogen plugins' # {{{
	set -l _plugins

	set -l fetch_only
	begin
		set -l index (contains -i -- --fetch-only $argv)
		set fetch_only $status
		test $status != 0; or set -e argv[$index]
	end

	# Check whether to get plugins from the command line or all installed plugins
	if test (count $argv) -gt 0
		# Determine real paths for user-specified plugins
		for plugin in $argv
			if pathogen.plugin.exists $plugin
				if pathogen.plugin_is_disabled "$plugin"
					set _plugins "$PATHOGEN_BUNDLES_DISABLED/$plugin"
				else
					set _plugins "$PATHOGEN_BUNDLES/$plugin"
				end
			else
				set_color red
				echo "Plugin `$plugin` is not installed"
				set_color normal
			end
		end
	else
		set _plugins (pathogen.plugin.get_all_plugins)
	end

	# Collect git repositories
	set -l plugins
	for plugin in $_plugins
		if pathogen.is_git_repo $plugin
			set plugins $plugins $plugin
		else
			set_color yellow
			echo "$plugin will not be updated because it is not a git repository"
			set_color normal
		end
	end
	set -e _plugins

	if test (count $plugins) = 0
		echo "Nothing to do"
		return 2
	else
		for plugin in $plugins
			printf "Updating "(basename $plugin)": " 
			
			# hack to remove trailing slash
			set -l logfile (pathogen.update.log_file $plugin)

			# Enter plugin directory
			set -x GIT_DIR $plugin

			if test $fetch_only = 0
				pathogen.update.log "Fetching remote objects"
				git fetch ^&1 | pathogen.update.log.format_stdin >> $logfile
				or pathogen.update.log "Fetch failed"
				set_color green
				echo OK
			else
				pathogen.update.log "Starting Update"

				git pull ^&1 | pathogen.update.log.format_stdin >> $logfile
				set -l git_status $status
				git submodule foreach git pull ^&1 | pathogen.update.log.format_stdin >> $logfile
				set git_status $git_status $status

				pathogen.update.log "Update finished with exit status $git_status[1]"

				test $git_status[2] = 0; or pathogen.update.log "Warning: submodule update did not exit successfully"

				switch $git_status[1]
					case 0
						set_color green
						echo "OK"
						if test $git_status[2] != 0
							set_color yellow
							echo "Note: Submodule update failed"
						end
					case '*'
						set_color red
						echo "error. see $logfile for details"
				end
			end

			set -e GIT_DIR

			set_color normal
		end
	end
end # }}}

function pathogen.list_plugins --description "List pathogen plugins" # {{{
	
	contains -- --fetch $argv
	set -l update_repos $status

	for file in (pathogen.plugin.get_all_plugins)

		if test $update_repos = 0
			if pathogen.plugin.needs_update $file
				set_color yellow
				printf '*'
			end
		end

		if pathogen.plugin.is_disabled (basename $file)
			set_color red
			printf '-'
		else
			set_color green
			printf '+'
		end

		set_color normal

		# I hope you don't have a plugin with >24 characters in the name, seeing as the column utility was designed by satan himself.
		printf "%-24s\t\n" (basename $file)
	end | column
end # }}}

function pathogen.remove_plugin --description "Uninstall plugins" # {{{
	pushd $PATHOGEN_BUNDLES; or return 1
	for file in $argv
		printf "Removing "(basename $file)": "
		pathogen.rm_dir $file
		switch $status
			case 0
				set_color green
				echo OK
			case 1
				set_color yellow
				echo Not Installed
			case 2
				set_color red
				echo Insufficient Permission
			case \*
				set_color red
				echo Error
		end
		set_color normal
	end
	popd
end # }}}

function pathogen.disable_plugins --description 'Disable plugins' # {{{
	for plugin in $argv
		printf "Disabling "$plugin": "
		set plugin "$PATHOGEN_BUNDLES/$plugin"
		if pathogen.dir_exists $plugin
			if mv $plugin $PATHOGEN_BUNDLES_DISABLED ^ /dev/null
				set_color green
				echo OK
			else
				set_color red
				echo Error
			end
		else
			set_color red
			echo "Not Found ($plugin)"
		end
		set_color normal
	end
end # }}}

function pathogen.enable_plugins --description 'Enabled plugins' # {{{
	for plugin in $argv
		printf "Enabling "$plugin": "
		set plugin "$PATHOGEN_BUNDLES_DISABLED/$plugin"
		if pathogen.dir_exists $plugin
			if mv $plugin $PATHOGEN_BUNDLES ^ /dev/null
				set_color green
				echo OK
			else
				set_color red
				echo Error
			end
		else
			set_color red
			echo Not Found
		end
		set_color normal
	end
end # }}}

function pathogen.help --description 'Pathogen help command' -a 'command_name' # {{{
	echo "
Pathogen Package Manager (originally written by https://github.com/rhargrave)
Streamlines pathogen bundle installation by providing various commands for managing bundles

Usage:
	$command_name <install|update|list|remove|disable|enable|help>

	Commands:

		install <...>			- Install a package

			This command will enter your bundles directory, specified by environment variable `PATHOGEN_BUNDLES` and
			run `git clone` with the provided arguments.

			For instance:

				$command_name install https://github.com/vim-scripts/YankRing.vim.git
			
			will install `YankRing.vim` in to PATHOGEN_BUNDLES/YankRing.vim

			Being that this is effectively a git wrapper, anything that you can pass to your GIT's
			clone command will work. This can be especially useful if you have `hub` (https://github.com/github/hub)
			installed, which would effectively make the following command equivalent to the former
				
				$command_name install vim-scripts/YankRing.vim\

		update [plugin names]	- Update plugins

			This command will update the specified plugins, or, if none are specified, all plugins (including disabled plugins)

			Example:

				~> $command_name update YankRing.vim
				Updating YankRing.vim: OK

		list					- List plugins

			Options:

				--fetch		- Fetch remote in git repositories. This will update repos, and you will thusly be notified of the latest changes.

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
"
end # }}}

function pathogen --description "Pathogen helper command" -a 'action'

	if test (count $argv) = 0
		pathogen help
		return $status
	end

	set -l arguments
	if test (count $argv) -gt 1
		set arguments $argv[2..(count $argv)]
	end

	if test ! -d $PATHOGEN_BUNDLES
		set_color yellow
		echo "Warning: Pathogen bundles directory ($PATHOGEN_BUNDLES) is not present, if your bundles go somewhere else, see `$_ help`"
		set_color normal
	end

	switch $action
		case 'add' 'inst' 'install'
			pathogen.install $arguments
		case 'up' 'update' 'upgrade'
			pathogen.update $arguments
		case 'ls' 'list' 'show'
			pathogen.list_plugins $arguments
		case 'rm' 'remove' 'del' 'delete' 'uninstall'
			pathogen.remove_plugin $arguments
		case 'dis' 'disable'
			pathogen.disable_plugins $arguments
		case 'enable'
			pathogen.enable_plugins $arguments
		case 'help' \*
			pathogen.help $_
	end

	return $status
end
