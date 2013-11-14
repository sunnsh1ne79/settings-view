{_, $, $$$, View, Editor} = require 'atom'
path = require 'path'

module.exports =
class KeybindingPanel extends View
  @content: ->
    @div class: 'keybinding-panel section', =>
      @h1 class: 'section-heading', 'Keybindings'
      @div class: 'block', =>
        @label 'Filter:'
        @subview 'filter', new Editor(mini: true)
      @table =>
        @col class: 'keystroke'
        @col class: 'command'
        @col class: 'source'
        @col class: 'selector'
        @thead =>
          @tr =>
            @th class: 'keystroke', 'Keystroke'
            @th class: 'command', 'Command'
            @th class: 'source', 'Source'
            @th class: 'selector', 'Selector'
        @tbody outlet: 'keybindingRows'

  initialize: ->
    @keyMappings = _.sortBy(global.keymap.allMappings(), (x) -> x.keystroke)
    @appendKeyMappings(@keyMappings)

    @filter.getBuffer().on 'contents-modified', =>
      @filterKeyMappings(@keyMappings, @filter.getText())

  filterKeyMappings: (keyMappings, filterString) ->
    @keybindingRows.empty()
    for keyMapping in keyMappings
      {selector, keystroke, command, source} = keyMapping
      searchString = "#{selector}#{keystroke}#{command}#{source}"
      continue unless searchString

      if /^\s*$/.test(filterString) or searchString.indexOf(filterString) != -1
        @keybindingRows.append @elementForKeyMapping(keyMapping)

  appendKeyMappings: (keyMappings) ->
    for keyMapping in keyMappings
      @keybindingRows.append @elementForKeyMapping(keyMapping)

  elementForKeyMapping: (keyMapping) ->
    {selector, keystroke, command, source} = keyMapping
    source = @determineSource(source)
    $$$ ->
      @tr =>
        @td class: 'keystroke', keystroke
        @td class: 'command', command
        @td class: 'source', source
        @td class: 'selector', selector

    # Private: Returns a user friendly description of where a keybinding was
  # loaded from.
  #
  # * filePath:
  #   The absolute path from which the keymap was loaded
  #
  # Returns one of:
  # * `Core` indicates it comes from a bundled package.
  # * `User` indicates that it was defined by a user.
  # * `<package-name>` the package which defined it.
  # * `Unknown` if an invalid path was passed in.
  determineSource: (filePath) ->
    return 'Unknown' unless filePath

    pathParts = filePath.split(path.sep)
    if _.contains(pathParts, 'node_modules') or _.contains(pathParts, 'atom') or _.contains(pathParts, 'src')
      'Core'
    else if _.contains(pathParts, '.atom') and _.contains(pathParts, 'keymaps') and !_.contains(pathParts, 'packages')
      'User'
    else
      packageNameIndex = pathParts.length - 3
      pathParts[packageNameIndex]