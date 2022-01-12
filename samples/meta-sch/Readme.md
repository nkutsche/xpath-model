# Meta Schematron

© Nico Kutscherauer, 2022

This Meta Schematron Schema is a sample project for the usage of the [XPath Model](https://github.com/nkutsche/xpath-model). It provides a [meta-schematron.sch](meta-schematron.sch) which checks for other Schematron schema if they containing XPath expressions with node tests which are asking for nodes in the null namespace or for non-declared namespaces. *Note:* The last case would occur an static error anyway.

## Requirements

The [meta-schematron.sch](meta-schematron.sch) is an regular Schematron Schema embedding XSLT stylesheets by `xsl:import`. The used Schematron implementation has to support embeded XSLT. It is tested with Oxygen XML Editor v20.1. 

## Usage

Download the complete project. Make a regular Schematron validation with your Schematron Schema file as input and the [meta-schematron.sch](meta-schematron.sch) as Schematron schema. How to do this in Oxygen can be learned [here](https://www.oxygenxml.com/doc/versions/24.0/ug-editor/topics/validating-XML-documents-against-schema.html).

### Check For Null-Namespace

The check for the null namespace is active if the schema contains at lease one `<sch:ns>` declartion and if it does not have an attribute `nk:allow-null-namespace="true"` (` xmlns:nk="http://www.nkutsche.com/xpath-model"`) at the root element `sch:schema`.

### Configuration

For checking large Schematron schemas the performance can be a bit low. For this it is possible to set the focus on specific patterns or phases by adding an attribute `nk:focus=""` to the `sch:pattern` or `sch:phase` element. If there is at least one `nk:focus` attribut in the schema only the patterns are checked which have one or are activated by a phase which have one. 