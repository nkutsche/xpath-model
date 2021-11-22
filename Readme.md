# XPath XML Model

This project contains an XPath parser and creates an XML model from it. The model can be used to make deeper analyzis, convert or serialize the expression to a normalizes XPath expression.

An XPath normalizer could:

* normalize ignoreable whitespace
* remove/normalize ignoreable brackets
* indention of the expressions


An analyzer could make statements abould:

* used/unused functions or variables
* validation of XPath version (I want to use XPath 2.0 only features though my processor supports 3.0)
* used location steps (comparing to a given schema?)

A converter could manipulate given XPath expressions:

* wrap all location steps by a function call
* wrap all sub expressions by a function call
* ...?


