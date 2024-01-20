set xpath=%1

if not "%xpath%"=="" set xpath=xpath=%xpath%

mvn exec:exec -Dexec.executable="java" -Dexec.args="%J_OPTS% -cp %%classpath net.sf.saxon.Transform -init:com.nkutsche.xslt.pkg.handler.PackageManager -config:src/test/xspec/qt3testsuite/saxon-config.xml -xsl:src/test/xsl/debugger.xsl -s:src/test/xsl/debugger.xsl -o:target/debug-result.xml %xpath%"


::mvn exec:exec -Dexec.executable="java" -Dexec.args="%J_OPTS% -cp %%classpath net.sf.saxon.Transform -config:src/test/xspec/qt3testsuite/saxon-config.xml -xsl:src/test/xsl/debugger2.xsl -s:src/test/xsl/debugger.xsl -o:target/debug-result.xml"
