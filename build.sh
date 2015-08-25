#!/bin/sh

echo Running...
rustdoc index.md -o . --html-in-header=header.inc.html --markdown-no-toc
