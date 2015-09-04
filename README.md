# linter-erlang package
Simple atom.io erlang linter that actually works. You need erlc installed.
It will try and be as smart as possible and try to add dependencies and such
on compile automatically. So it should work out of the box without any further settings.

## Installation
Linter package must be installed in order to use this plugin. If Linter is not installed, please follow the instructions [here](https://github.com/AtomLinter/Linter).

### Plugin installation
```
$ apm install linter-erlang
```

## Settings
You can configure linter-elixirc by editing ~/.atom/config.cson (choose Open Your Config in Atom menu):

```
"linter-erlang":
  includeDirs: "./include" #Space seperated list of include paths
  executablePath: "/usr/local/bin/erlc" # default.
  paPaths: "./ebin" # Space seperated list of paths added to -pa flag. This will be done automatically in a project folder.
```
