{BufferedProcess, CompositeDisposable} = require 'atom'
path = require 'path'
helpers = require('atom-linter')
os = require 'os'
fs = require 'fs'

module.exports =
  config:
    executablePath:
      type: 'string'
      title: 'Erlc Executable Path'
      default: '/usr/local/bin/erlc'
    includeDirs:
      type: 'string'
      title: 'Include dirs'
      description: 'Path to include dirs. Seperated by space.'
      default: './include'
    paPaths:
      type: 'string'
      title: 'pa paths'
      default: "./ebin"
      description: "Paths seperated by space"
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-erlang.executablePath',
      (executablePath) =>
        @executablePath = executablePath
    @subscriptions.add atom.config.observe 'linter-erlang.includeDirs',
      (includeDirs) =>
        @includeDirs = includeDirs
    @subscriptions.add atom.config.observe 'linter-erlang.paPaths',
      (paPaths) =>
        @paPaths = paPaths
  deactivate: ->
    @subscriptions.dispose()
  provideLinter: ->
    provider =
      grammarScopes: ['source.erlang']
      scope: 'file' # or 'project'
      lintOnFly: false # must be false for scope: 'project'
      lint: (textEditor) =>
        return new Promise (resolve, reject) =>
          filePath = textEditor.getPath()
          project_path = atom.project.getPaths()
          project_deps_ebin = ""

          try
            fs.readdirSync(project_path.toString() + "/deps/").filter(
              (item) ->
                project_deps_ebin = project_deps_ebin + " ./deps/" + item + "/ebin/"
            )

            @paPaths = @paPaths + project_deps_ebin
          catch error


          compile_result = ""
          erlc_args = ["-Wall"]
          erlc_args.push "-I", dir.trim() for dir in @includeDirs.split(" ")
          erlc_args.push "-pa", pa.trim() for pa in @paPaths.split(" ") unless @paPaths == ""
          erlc_args.push "-o", os.tmpDir()
          erlc_args.push filePath

          error_stack = []

          ## This fun will parse the row and split stuff nicely
          parse_row = (row) ->
            if row.indexOf("Module name") != -1
              error_msg = row.split(":")[1]
              linenr = 1
              error_type = "Error"
            else
              row_splittreedA = row.slice(0, row.indexOf(":"))
              re = /[\w\/.]+:(\d+):(.+)/
              re_result = re.exec(row)
              error_type = if re_result? and
                re_result[2].trim().startsWith("Warning") then "Warning" else "Error"
              linenr = parseInt(re_result[1], 10)
              error_msg = re_result[2].trim()
            error_stack.push
              type: error_type
              text: error_msg
              filePath: filePath
              range: helpers.rangeFromLineNumber(textEditor, linenr - 1)
          process = new BufferedProcess
            command: @executablePath
            args: erlc_args
            options:
              cwd: project_path[0] # Should use better folder perhaps
            stdout: (data) ->
              compile_result += data
            exit: (code) ->
              errors = compile_result.split("\n")
              errors.pop()
              parse_row error for error in errors unless !errors?
              resolve error_stack
          process.onWillThrowError ({error,handle}) ->
            atom.notifications.addError "Failed to run #{@executablePath}",
              detail: "#{error.message}"
              dismissable: true
            handle()
            resolve []
