# Package

version       = "0.2.2"
author        = "Hugo Granström"
description   = "Reveal.js theme for nimib"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.0"
requires "nimib >= 0.3.3"
requires "toml_serialization >= 0.2.0"

import os

task docsDeps, "install dependencies required to build docs":
    exec "nimble -y install ggplotnim@0.5.6 karax numericalnim"

task buildDocs, "build all .nim files in docs/":
    for (kind, path) in walkDir("docs/"):
        if path.endsWith(".nim"):
            echo "Building: " & path
            let buildCommand = "nim r " & path
            exec buildCommand
            if "index" in path:
                let buildCommand = "nim r -d:themeWhite " & path
                exec buildCommand

task docs, "Generate automatic docs":
    exec "nim doc --project --index:on --git.url:https://github.com/HugoGranstrom/nimiSlides --git.commit:master --outdir:docs/docs src/nimiSlides.nim"
    exec "echo \"<meta http-equiv=\\\"Refresh\\\" content=\\\"0; url='theindex.html'\\\" />\" >> docs/docs/index.html"

