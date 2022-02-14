<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    
    <sch:ns uri="http://www.nkutsche.com/xpath-model" prefix="nk"/>
    
    <sch:let name="var-global" value="/expr" xml:id="var-global"/>
    
    <sch:pattern>
        <sch:rule context="operation" id="rule1">
            <sch:let name="var-local" value="@type" xml:id="var-local"/>
            <sch:assert test="arg" id="assert1">is valid</sch:assert>
        </sch:rule>
        <sch:rule context="expr">
            <sch:assert test="arg">will select nothing</sch:assert>
        </sch:rule>
    </sch:pattern>
    
</sch:schema>