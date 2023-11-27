
mvn exec:exec -Dexec.executable="java" -Dexec.args="%J_OPTS% -cp %%classpath net.sf.saxon.Transform -init:com.nkutsche.xslt.pkg.handler.PackageManager -xsl:src/test/xsl/debugger.xsl -s:src/test/xsl/debugger.xsl -o:target/debug-result.xml"
