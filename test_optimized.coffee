#!/usr/bin/env coffee

cc = require "./src/coffeecup"

tests =
  'Literal text':
    template: "text 'Just text'"
    expected: 'Just text'

  'Default DOCTYPE':
    template: "doctype()"
    expected: '<!DOCTYPE html>'

  'DOCTYPE':
    template: "doctype 'xml'"
    expected: '<?xml version="1.0" encoding="utf-8" ?>'

  'Custom tag':
    template: "tag 'custom'"
    expected: '<custom></custom>'

  'Custom tag with attributes':
    template: "tag 'custom', foo: 'bar', ping: 'pong'"
    expected: '<custom foo="bar" ping="pong"></custom>'

  'Custom tag with attributes and inner content':
    template: "tag 'custom', foo: 'bar', ping: 'pong', -> 'zag'"
    expected: '<custom foo="bar" ping="pong">zag</custom>'

  'Self-closing tags':
    template: "img src: 'icon.png', alt: 'Icon'"
    expected: '<img src="icon.png" alt="Icon" />'

  'Common tag':
    template: "p 'hi'"
    expected: '<p>hi</p>'

  'Attributes':
    template: "a href: '/', title: 'Home'"
    expected: '<a href="/" title="Home"></a>'

  'HereDocs':
    template: '''
      script """
        $(document).ready(function(){
          alert('test');
        });
      """
    '''
    expected: "<script>$(document).ready(function(){\n  alert('test');\n});</script>"

  'CoffeeScript helper (function)':
    template: "coffeescript -> alert 'hi'"
    expected: "<script>(function() {\n  return alert(\"hi\");\n}).call(this);</script>"

  'CoffeeScript helper (string)':
    template: "coffeescript \"alert 'hi'\""
    expected: "<script>\nalert('hi');\n</script>"

  'Context vars':
    template: "h1 @foo"
    expected: '<h1>bar</h1>'
    params: {foo: 'bar'}

  'Local vars, hardcoded':
    template: 'h1 "harcoded: " + obj.foo'
    run: ->
      obj = {foo: 'bar'}
      @compiled = cc.compile(@template, hardcode: {obj})
      @expected = '<h1>harcoded: bar</h1>'
      @result = @compiled()
      @success = @result is @expected
      if @success
        obj.foo = 'baz'
        @result = @compiled()
        @success = @result is @expected

  'Local vars, hard-coded (functions)':
    template: "h1 \"The sum is: \#{sum 1, 2}\""
    expected: '<h1>The sum is: 3</h1>'
    params: {hardcode: {sum: (a, b) -> a + b}}

  'Local vars, hard-coded ("helpers")':
    template: "textbox id: 'foo'"
    expected: '<input id="foo" name="foo" type="text" />'
    params:
      hardcode:
        textbox: (attrs) ->
          tag 'input',
            id: attrs.id
            name: attrs.id
            type: 'text'

  'Local vars':
    template: 'h1 "dynamic: " + obj.foo'
    run: ->
      obj = {foo: 'bar'}
      @expected = '<h1>dynamic: bar</h1>'
      @result = render(@template, locals: {obj: obj})
      @success = @result is @expected
      if @success
        obj.foo = 'baz'
        @expected = '<h1>dynamic: baz</h1>'
        @result = render(@template, locals: {obj: obj})
        @success = @result is @expected

  'Comments':
    template: "comment 'Comment'"
    expected: '<!--Comment-->'

  'Escaping':
    template: "h1 h(\"<script>alert('\\\"pwned\\\" by c&a &copy;')</script>\")"
    expected: "<h1>&lt;script&gt;alert('&quot;pwned&quot; by c&amp;a &amp;copy;')&lt;/script&gt;</h1>"

  'Autoescaping':
    template: "h1 \"<script>alert('\\\"pwned\\\" by c&a &copy;')</script>\""
    expected: "<h1>&lt;script&gt;alert('&quot;pwned&quot; by c&amp;a &amp;copy;')&lt;/script&gt;</h1>"
    params:
      autoescape: yes

  'ID/class shortcut (combo)':
    template: "div '#myid.myclass1.myclass2', 'foo'"
    expected: '<div id="myid" class="myclass1 myclass2">foo</div>'

  'ID/class shortcut (ID only)':
    template: "div '#myid', 'foo'"
    expected: '<div id="myid">foo</div>'

  'ID/class shortcut (one class only)':
    template: "div '.myclass', 'foo'"
    expected: '<div class="myclass">foo</div>'

  'ID/class shortcut (multiple classes)':
    template: "div '.myclass.myclass2.myclass3', 'foo'"
    expected: '<div class="myclass myclass2 myclass3">foo</div>'

  'ID/class shortcut (no string contents)':
    template: "img '#myid.myclass', src: '/pic.png'"
    expected: '<img id="myid" class="myclass" src="/pic.png" />'

  'Attribute values':
    template: "br vrai: yes, faux: no, undef: @foo, nil: null, str: 'str', num: 42, arr: [1, 2, 3].join(','), obj: {foo: 'bar'}, func: ->"
    expected: '<br vrai="vrai" str="str" num="42" arr="1,2,3" obj-foo="bar" func="(function(){}).call(this);" />'

  'IE conditionals':
    template: """
      html ->
        head ->
          title 'test'
          ie 'gte IE8', ->
            link href: 'ie.css', rel: 'stylesheet'
    """
    expected: '<html><head><title>test</title><!--[if gte IE8]><link href="ie.css" rel="stylesheet" /><![endif]--></head></html>'

  'yield':
    template: "p \"This text could use \#{yield -> strong -> a href: '/', 'a link'}.\""
    expected: '<p>This text could use <strong><a href="/">a link</a></strong>.</p>'

cc = require './src/coffeecup'
render = cc.render

@run = ->
  {print} = require 'sys'
  colors = {red: "\033[31m", redder: "\033[91m", green: "\033[32m", normal: "\033[0m"}
  printc = (color, str) -> print colors[color] + str + colors.normal

  [total, passed, failed, errors] = [0, [], [], []]

  for name, test of tests
    total++
    try
      if not test.params?
        test.params =
          optimize: true
          cache: on unless total is 1
      else
        test.params.optimize = true
        test.params.cache = true
      test.original_params = JSON.stringify test.params

      if test.run
        test.run()
      else
        test.result = cc.render(test.template, test.params)
        test.success = test.result is test.expected
      if test.success
        passed.push name
        print "[Passed] #{name}\n"
      else
        failed.push name
        printc 'red', "[Failed] #{name}\n"
    catch ex
      test.result = ex
      errors.push name
      printc 'redder', "[Error]  #{name}\n"

  print "\n#{total} tests, #{passed.length} passed, #{failed.length} failed, #{errors.length} errors\n\n"
  
  if failed.length > 0
    printc 'red', "FAILED:\n\n"

    for name in failed
      t = tests[name]
      print "- #{name}:\n"
      print t.template + "\n"
      print t.original_params + "\n" if t.params
      printc 'green', t.expected + "\n"
      printc 'red', t.result + "\n\n"

  if errors.length > 0
    printc 'redder', "ERRORS:\n\n"

    for name in errors
      t = tests[name]
      print "- #{name}:\n"
      print t.template + "\n"
      printc 'green', t.expected + "\n"
      printc 'redder', t.result.stack + "\n\n"

@run()
