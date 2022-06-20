# Meta Schematron

© Nico Kutscherauer, 2022

This Meta Schematron Schema is a sample project for the usage of the [XPath Model](https://github.com/nkutsche/xpath-model). It provides a [meta-schematron.sch](meta-schematron.sch) which checks the node test inside of other Schematron schema against a configuration file.

## Requirements

The [meta-schematron.sch](meta-schematron.sch) is an regular Schematron Schema embedding XSLT stylesheets by `xsl:import`. The used Schematron implementation has to support embeded XSLT. It is tested with Oxygen XML Editor v20.1 & v24.0.

## Usage

Download the complete project. Make a regular Schematron validation with your Schematron Schema file as input and the [meta-schematron.sch](meta-schematron.sch) as Schematron schema. How to do this in Oxygen can be learned [here](https://www.oxygenxml.com/doc/versions/24.0/ug-editor/topics/validating-XML-documents-against-schema.html).

## Configuration

The configuration is searched in the following order:

1. A top-level element `<nk:meta-sch-config>` in the source schema.
1. A file parallel to the source schema with the name *meta-sch-config.xml*.
1. A file parallel to the meta-schematron.sch with the name *config.xml*.

The root element of the config files should also be `<nk:meta-sch-config>` in the namespace `http://www.nkutsche.com/xpath-model`. 

### Check for Namespaces with config file

If a config is available it will be used to specify which namespaces are invalid and a possible replacement namespace.

Example config:

```xml
<meta-sch-config xmlns="http://www.nkutsche.com/xpath-model">
    <namespace-maping>
        <map invalid="" valid="http://www.nkutsche.com/xpath-model"/>
        <map invalid="http://www.nkutsche.com/an-old-namespace" valid="http://www.nkutsche.com/a-new-namespace"/>
    </namespace-maping>
</meta-sch-config>
```

* The `null` namespace and the namespace `http://www.nkutsche.com/an-old-namespace` are invalide. Expressions which contains lookups for nodes into these namespaces will occur a validation error.
* The errors will provide a QuickFix which fixes the invalid node tests by replacing `null` namespace lookups by corresponding lookups into the `http://www.nkutsche.com/xpath-model` namespace and lookups into `http://www.nkutsche.com/an-old-namespace` by `http://www.nkutsche.com/a-new-namespace`.
    * The replacement works on prefixes and uses the namespace declarations of the source Schematron schema (`sch:ns`).
    * If no prefix was defined for that namespace a namespace declaration will be added by the QuickFix with a generic prefix (`ns1`, `ns2`, ...).

### Default behavior (no config file)

If the config.xml can not be found or parsed as XML document, the default behavior is applied. That means:

* All namespaces declared by `sch:ns` are valid.
* The `null` namespace is invalid if any other namespace is declared by `sch:ns` elements and if the root element `sch:schema` does not have an attribute `nk:allow-null-namespace="true"` (` xmlns:nk="http://www.nkutsche.com/xpath-model"`).
* QuickFixes are not available in this cases.


### Focus Logic for Large Schematron Schemas

For checking large Schematron schemas the performance can be a bit low. For this it is possible to set the focus on specific patterns or phases by adding an attribute `nk:focus=""` to the `sch:pattern` or `sch:phase` element. If there is at least one `nk:focus` attribute in the schema only the patterns are checked which have one or are activated by a phase which have one.

