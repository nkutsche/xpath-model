<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    
    <sch:ns uri="http://www.nkutsche.com/xpath-model" prefix="nk"/>
    
    <sch:pattern>
        <sch:rule context="nk:expr/nk:operation" id="rule1">
            <sch:assert test="nk:arg" id="assert1">is valid</sch:assert>
        </sch:rule>
        <sch:rule context="nk:expr">
            <sch:assert test="nk:arg">will select nothing</sch:assert>
        </sch:rule>
    </sch:pattern>
    
</sch:schema>