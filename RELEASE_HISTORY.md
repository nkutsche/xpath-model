## Release History
-------------------------------

### Version 1.1.0

* Implements XPath evaluation function `xpe:xpath-evaluate()`

* Model parser
    * Adds configuration option to allow/dissallow undeclared prefixes in the input XPath expression
    * Adds parser function `nk:xpath-type-model` to API to parse item type declarations 
    * Minor bug fixing

* XPath model schema
    * Adds missing support for partial function applications
    * Changes model of the type `empty-sequence()` from `<empty/>` to `<itemType occurrence="zero"/>`

* Misc
    * Replace included RelaxNG implementation by referencing it as Maven dependency
    * Removes dependency to Saxon and XSLT Package Manager to avoid restriction on a specific Saxon version for using projects.

### Version 1.0.1

* Features:
    * Adds `nk:parent-or-self-el` function to *xpath-model-tools.xsl* for reuse common tasks.

* Bugfixes:
    * Parameter type in `nk:value-tempalate-serializer-hl` function was corrupt.
    * `nk:context-provider-handler` produced an sequence error, if a variable provides more than one context.

### Version 1.0.0

* First public release
