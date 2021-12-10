import std/[strutils, sequtils]
import nimib
import nimib/renders

const document = """
<!DOCTYPE html>
<html>
  <head>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.2.0/reveal.min.css" integrity="sha512-vFD6wFRj2whK8/X/dMgxJHinKfGlwMYtN+yRCxvxvmOgIiMIlgrFb5iOuCoqwCID+Qcq2/gY8DpmNHcAjfHWxw==" crossorigin="anonymous" referrerpolicy="no-referrer" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.2.0/theme/{{{slidesTheme}}}.min.css" crossorigin="anonymous" referrerpolicy="no-referrer" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.2.0/plugin/highlight/monokai.min.css" integrity="sha512-z8wQkuDRFwCBfoj7KOiu1MECaRVoXx6rZQWL21x0BsVVH7JkqCp1Otf39qve6CrCycOOL5o9vgfII5Smds23rg==" crossorigin="anonymous" referrerpolicy="no-referrer" />
  </head>
  <body>
    <div class="reveal">
      <div class="slides">
        {{{ slides }}}
      </div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.2.0/reveal.js" integrity="sha512-+Dy2HJZ3Z1DWerDhqFE7AH2HTfnbq8RC1pKOashfMwx1s01fjPUebWoHqrRedU1yFimkexmzJJRilKxjs7lz8g==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.2.0/plugin/highlight/highlight.min.js" integrity="sha512-U3fPDUX5bMrn1wnYqjaK44MFA9E6MKS+zPAg9WPAGF5XhReBeDj3FGaA831CjueG+YJxYA3WaO/m33kMIoOs/A==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
    {{#latex}}
    <script src="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.2.1/plugin/math/math.min.js" integrity="sha512-8eviRBLZHoiXLqXeMl5XurkjNEGizTI8DHbSUoGxkYFd4RslHpIYTEQmLYtWUemc5FfMYOkPDFUcQKefPLjF7A==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
    {{/latex}}
    <script>
      Reveal.initialize({
        plugins: [ 
          RevealHighlight,
          {{#latex}}
          RevealMath.KaTeX
          {{/latex}}
        ]
      });
    </script>
  </body>
</html>
"""

type
  FragmentAnimation* = enum
    fadeIn = "fade-in" # the default
    fadeOut = "fade-out"
    fadeUp = "fade-up"
    fadeDown = "fade-down"
    fadeLeft = "fade-left"
    fadeRight = "fade-right"
    fadeInThenOut = "fade-in-then-out"
    fadeInThenSemiOut = "fade-in-then-semi-out"
    grow = "grow"
    semiFadeOut = "semi-fade-out"
    shrink = "shrink"
    strike = "strike"
    highlightRed = "highlight-red"
    highlightGreen = "highlight-green"
    highlightBlue = "highlight-blue"
    highlightCurrentRed = "highlight-current-red"
    highlightCurrentGreen = "highlight-current-green"
    highlightCurrentBlue = "highlight-current-blue"
  Slide* = ref object
    pos*: tuple[start: int, finish: int]
    notes*: seq[string]
  SlidesCtx* = ref object
    sections*: seq[seq[Slide]]
  SlidesTheme* = enum
    Black, Beige, Blood, League, Moon, Night, Serif, Simple, Sky, Solarized, White

template initReveal*() =
  ## Call this after nbInit
  var slidesCtx {.inject.} = SlidesCtx(sections: @[@[Slide(pos: (start: 0, finish: -1))]])

  template slideRight() =
    ## Add a slide to the right of the current one
    slidesCtx.sections[^1][^1].pos.finish = nb.blocks.len - 1
    slidesCtx.sections.add @[Slide(pos: (start: nb.blocks.len, finish: -1))]

  template slideDown() =
    ## Add a slide below the current one
    slidesCtx.sections[^1][^1].pos.finish = nb.blocks.len - 1
    slidesCtx.sections[^1].add (Slide(pos: (start: nb.blocks.len, finish: -1)))

  template slideRight(body: untyped) =
    slideRight()
    body
  
  template slideDown(body: untyped) =
    slideDown()
    body

  template fragment(animations: varargs[seq[FragmentAnimation]] = @[@[fadeIn]], body: untyped): untyped =
    ## Creates a fragment of the content of body. Nesting works.
    ## animations: each seq of the varargs are animations that are to be applied at the same time. The first seq's animations
    ##             are applied on the first button click, and the second seq's animations on the second click etc.
    ## Example: 
    ## `fragment(@[fadeIn, highlightBlue], @[shrink, semiFadeOut]): block` will at the first click of a button fadeIn and highlightBlue
    ## the content of the block. At the second click the same content will shrink and semiFadeOut. This code is also equivilent with
    ## `fragment(@[fadeIn, highlightBlue]): fragment(@[shrink, semiFadeOut]): block`.
    for level in animations: # level are the animations to be applied simulataniously to a fragment
      let classStr = join(level, " ")
      nbText: "<div class=\"fragment " & classStr & "\">"
    body
    nbText: "</div>".repeat(@animations.len) # add a closing tag for every level

  template fragment(animation: FragmentAnimation, body: untyped) =
    ## fragment(animation) is shorthand for fragment(@[animation])
    fragment(@[animation]):
      body

  template fragmentFadeIn(animation: FragmentAnimation, body: untyped) =
    fragment(@[fadeIn], @[animation]):
      body

  template removeCodeOutput =
    if nb.blocks.len > 0:
      var blk = nb.blocks[^1]
      if blk.kind == nbkCode:
        blk.output = ""

  template setSlidesTheme(theme: SlidesTheme) =
    nb.context["slidesTheme"] = ($theme).toLower

  proc renderSlide(doc: NbDoc, slide: Slide): string =
    let upper = 
      if slide.pos.finish != -1: slide.pos.finish
      else: doc.blocks.len - 1
    
    result = "<section>\n"
    for i in slide.pos.start .. upper:
      result &= doc.blocks[i].renderHtmlBlock
    result &= "</section>\n"

  proc renderReveal*(doc: NbDoc): string =
    var content: string
    for horiz in slidesCtx.sections:
      content &= "<section>\n" # this is the top level section
      for vertical in horiz:
        # vertical corresponds to a single slide with many blocks. Must loop over them all and call `renderHTMLBlock` 
        # if vertical.finish == -1: it is the last slide, grab the rest of all blocks
        content &= doc.renderSlide(vertical)
      content &= "</section>\n"

    doc.context["slides"] = content
    # This is neccecary because it will show the <span> tag otherwise:
    result = "{{> document}}".render(doc.context).replace("<code class=\"nim hljs\">", "<code class=\"nim hljs\" data-noescape>")
    result = result.replace("<pre><samp", "<pre style=\"width: 100%;\"><samp class=\"hljs\"") # add some background to code output block
    result = result.replace("<pre>", "<pre style=\"width: 100%\">") # this makes code blocks a little bit wider

  nb.render = renderReveal    

proc revealTheme*(doc: var NbDoc) =
  doc.partials["document"] = document
  doc.context["slidesTheme"] = "black"


