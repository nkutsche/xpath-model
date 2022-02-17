<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    
    <sch:ns uri="http://www.nkutsche.com/xpath-model" prefix="nk"/>
    
    <sch:let name="var-global" value="/expr" xml:id="var-global"/>
    
    <sch:pattern>
        <sch:rule context="operation" subject="arg" id="rule1">
            <sch:let name="var-local" value="@type" xml:id="var-local"/>
            <sch:assert test="arg" id="assert1">is valid</sch:assert>
        </sch:rule>
        <sch:rule context="expr">
            <sch:assert test="arg" sqf:fix="fix">will select nothing</sch:assert>
            <sqf:fix id="fix">
                <sqf:description>
                    <sqf:title>Fix it</sqf:title>
                </sqf:description>
                <sqf:replace match="operation" select="arg" xml:id="sqf-replace"/>
                <sqf:replace match="operation" xml:id="sqf-replace2">
                    <sch:value-of select="arg" xml:id="sqf-replace2-valueof"/>
                </sqf:replace>
            </sqf:fix>
        </sch:rule>
    </sch:pattern>
    
</sch:schema>