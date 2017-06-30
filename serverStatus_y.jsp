<%@page session="false"
%><%@page contentType="text/html" pageEncoding="UTF-8"

%><%@page import="java.lang.management.ManagementFactory"
%><%@page import="java.lang.reflect.UndeclaredThrowableException"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.text.DecimalFormat"
%><%@page import="java.text.DecimalFormatSymbols"
%><%@page import="java.text.NumberFormat"
%><%@page import="java.text.SimpleDateFormat"
%><%@page import="java.util.Date"
%><%@page import="java.util.HashMap"
%><%@page import="java.util.Locale"
%><%@page import="java.util.Map"
%><%@page import="java.util.Properties"
%><%@page import="java.util.ResourceBundle"
%><%@page import="java.util.TreeMap"
%><%@page import="javax.management.Attribute"
%><%@page import="javax.management.AttributeList"
%><%@page import="javax.management.InstanceNotFoundException"
%><%@page import="javax.management.MBeanServerConnection"
%><%@page import="javax.management.MBeanServerInvocationHandler"
%><%@page import="javax.management.ObjectName"
%><%@page import="javax.management.QueryExp"
%><%@page import="javax.management.openmbean.CompositeData"
%><%@page import="javax.management.openmbean.TabularData"
%><%@page import="javax.management.remote.JMXConnector"

%><%@page import="org.apache.log4j.Logger"

%><%@page import="wt.access.AccessControlException"
%><%@page import="wt.intersvrcom.SiteMonitorMBean"
%><%@page import="wt.jmx.core.MBeanRegistry"
%><%@page import="wt.jmx.core.MBeanUtilities"
%><%@page import="wt.jmx.core.SelfAwareMBean"
%><%@page import="wt.jmx.core.mbeans.Dumper"
%><%@page import="wt.log4j.LogR"
%><%@page import="wt.manager.RemoteServerManager"
%><%@page import="wt.manager.jmx.MethodServerMProxyMBean"
%><%@page import="wt.method.jmx.JmxConnectInfo"
%><%@page import="wt.method.jmx.MethodServer"
%><%@page import="wt.util.WTAppServerPropertyHelper"
%><%@page import="wt.util.WTContext"
%><%@page import="wt.util.WTProperties"
%><%@page import="wt.util.jmx.WDSJMXConnector"
%><%@page import="wt.util.jmx.AccessUtil"
%><%@page import="wt.util.jmx.JmxConnectUtil"
%><%@page import="wt.util.jmx.serverStatusResource"

%><%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"
%><%@taglib uri="http://www.ptc.com/windchill/taglib/util" prefix="util"

%><%-- Set up various constants for re-use between requests
--%><%!
 private static final Logger  logger = LogR.getLogger( "wtcore.jsp.jmx.serverStatus" );  // must be assigned prior to newObjectName() calls

 private static final String  WHC_PREFIX = "Whc";
 private static final String  SOLR_PREFIX = "Solr";

 private static final String  windchillWebAppPath;
 private static final String  whcWebAppPath;
 private static final String  solrWebAppPath;
 private static final String  helpUrl;
 private static final boolean  restrictToSiteAdministrators;
 static
 {
   final Properties  wtProps = MBeanUtilities.getProperties();
   windchillWebAppPath = "/" + wtProps.getProperty( "wt.webapp.name" );
   whcWebAppPath = windchillWebAppPath + "-WHC";
   solrWebAppPath = "/" + wtProps.getProperty( "wt.solr.webapp.name" );
   helpUrl = wt.help.HelpLinkHelper.createHelpHREF( "ServerStatusAbout" );
   restrictToSiteAdministrators = !"false".equals( wtProps.getProperty( "wt.serverStatus.restrictToSiteAdministrators" ) );
 }

 private static final String  thisJvmName = ManagementFactory.getRuntimeMXBean().getName();
 private static final String  thisMethodServerName = MethodServer.getStaticDisplayName();

 private static final ObjectName  dumperMBeanName = newObjectName( "com.ptc:wt.subsystem=Dumper" );
 private static final ObjectName  runtimeMBeanName = newObjectName( ManagementFactory.RUNTIME_MXBEAN_NAME );
 private static final ObjectName  gcMonitorMBeanName = newObjectName( "com.ptc:wt.subsystem=Monitors,wt.monitorType=GarbageCollection" );
 private static final ObjectName  memMonitorMBeanName = newObjectName( "com.ptc:wt.subsystem=Monitors,wt.monitorType=Memory" );
 private static final ObjectName  cpuMonitorMBeanName = newObjectName( "com.ptc:wt.subsystem=Monitors,wt.monitorType=ProcessCpuTime" );
 private static final ObjectName  osMBeanName = newObjectName( ManagementFactory.OPERATING_SYSTEM_MXBEAN_NAME );
 private static final ObjectName  methodServerMProxyMBeanName = newObjectName( "com.ptc:wt.processGroup=MethodServers" );
 private static final ObjectName  methodServerMBeanName = newObjectName( "com.ptc:wt.type=MethodServer" );
 private static final ObjectName  methodContextsMBeanName = newObjectName( "com.ptc:wt.subsystem=Monitors,wt.monitorType=MethodContexts" );
 private static final ObjectName  seRequestMonitorMBeanName = newObjectName( "com.ptc:wt.servlet.system=WebAppContexts,wt.webAppContext=" + windchillWebAppPath +
                                                                             ",wt.subsystem=Monitors,wt.servlet.subsystem=ServletRequests" );
 private static final ObjectName  sessionMonitorMBeanName = newObjectName( "com.ptc:wt.servlet.system=WebAppContexts,wt.webAppContext=" + windchillWebAppPath +
                                                                           ",wt.subsystem=Monitors,wt.servlet.subsystem=ServletSessions" );
 private static final ObjectName  whcRequestMonitorMBeanName = newObjectName( "com.ptc:wt.servlet.system=WebAppContexts,wt.webAppContext=" + whcWebAppPath +
                                                                              ",wt.subsystem=Monitors,wt.servlet.subsystem=ServletRequests" );
 private static final ObjectName  solrRequestMonitorMBeanName = newObjectName( "com.ptc:wt.servlet.system=WebAppContexts,wt.webAppContext=" + solrWebAppPath +
                                                                               ",wt.subsystem=Monitors,wt.servlet.subsystem=ServletRequests" );
 private static final ObjectName  activeUsersMBeanName = newObjectName( "com.ptc:wt.subsystem=Monitors,Name=ActiveUsers" );
 private static final ObjectName  serverManagerMBeanName = newObjectName( "com.ptc:wt.type=ServerManager" );
 private static final ObjectName  vaultSitesMBeanName = newObjectName( "com.ptc:wt.subsystem=Monitors,wt.monitorType=VaultSites" );

 private static final String  dumperMBeanAttrs[] = new String[] { "DeadlockedThreadIds" };
 private static final String  runtimeMBeanAttrs[] = new String[] { "StartTime", "Uptime" };
 private static final String  msRuntimeMBeanAttrs[] = new String[] { "StartTime", "Name", "Uptime" };
 private static final String  dsRuntimeMBeanAttrs[] = new String[] { "Name", "Uptime" };
 private static final String  gcMonitorMBeanAttrs[] = new String[] { "PercentTimeSpentInGCThreshold", "RecentPercentTimeSpentInGC", "OverallPercentTimeSpentInGC" };
 private static final String  memMonitorMBeanAttrs[] = new String[] { "HeapPercentUsageThreshold", "HeapPercentUsage", "PermGenPercentUsageThreshold", "PermGenPercentUsage" };
 private static final String  cpuMonitorMBeanAttrs[] = new String[] { "ProcessPercentCpuThreshold", "RecentCpuData", "AverageProcessPercentCpu" };
 private static final String  osMBeanAttrs[] = new String[] { "FreePhysicalMemorySize", "TotalPhysicalMemorySize", "FreeSwapSpaceSize", "TotalSwapSpaceSize", "SystemLoadAverage" };
 private static final String  methodServerMBeanAttrs[] = new String[] { "JmxServiceURL" };
 private static final String  methodContextsMBeanAttrs[] = new String[] { "MaxAverageActiveContextsThreshold", "RecentStatistics", "BaselineStatistics" };
 private static final String  seRequestMonitorMBeanAttrs[] = new String[] { "MaxAverageActiveRequestsThreshold", "RequestTimeWarnThreshold", "RecentStatistics", "BaselineStatistics" };
 private static final String  sessionMonitorMBeanAttrs[] = new String[] { "MaxAverageActiveSessionsThreshold", "ActiveSessions", "BaselineStatistics" };
 private static final String  serverManagerMBeanAttrs[] = new String[] { "CacheMaster", "JmxServiceURL" };

 private static final Object  windchillDsGetAttrsArgs[] =
 {
   new ObjectName[]
   {
     runtimeMBeanName,
     gcMonitorMBeanName,
     memMonitorMBeanName,
     cpuMonitorMBeanName,
     dumperMBeanName,
     osMBeanName
   },
   null,
   new String[][]
   {
     dsRuntimeMBeanAttrs,
     gcMonitorMBeanAttrs,
     memMonitorMBeanAttrs,
     cpuMonitorMBeanAttrs,
     dumperMBeanAttrs,
     osMBeanAttrs
   }
 };
 private static final Object  serverManagerGetAttrsArgs[] =
 {
   new ObjectName[]
   {
     runtimeMBeanName,
     gcMonitorMBeanName,
     memMonitorMBeanName,
     cpuMonitorMBeanName,
     dumperMBeanName,
     osMBeanName,
     serverManagerMBeanName
   },
   null,
   new String[][]
   {
     runtimeMBeanAttrs,
     gcMonitorMBeanAttrs,
     memMonitorMBeanAttrs,
     cpuMonitorMBeanAttrs,
     dumperMBeanAttrs,
     osMBeanAttrs,
     serverManagerMBeanAttrs
   }
 };
 private static final Object  methodServersGetAttrsArgs[] =
 {
   new ObjectName[]
   {
     runtimeMBeanName,
     gcMonitorMBeanName,
     memMonitorMBeanName,
     cpuMonitorMBeanName,
     dumperMBeanName,
     methodServerMBeanName,
     methodContextsMBeanName,
     sessionMonitorMBeanName,
     seRequestMonitorMBeanName,
     whcRequestMonitorMBeanName,
     solrRequestMonitorMBeanName
   },
   null,
   new String[][]
   {
     msRuntimeMBeanAttrs,
     gcMonitorMBeanAttrs,
     memMonitorMBeanAttrs,
     cpuMonitorMBeanAttrs,
     dumperMBeanAttrs,
     methodServerMBeanAttrs,
     methodContextsMBeanAttrs,
     sessionMonitorMBeanAttrs,
     seRequestMonitorMBeanAttrs,
     seRequestMonitorMBeanAttrs,
     seRequestMonitorMBeanAttrs
   }
 };
 private static final ObjectName  thisMethodServerGetAttrsBeans[] =
 {
   runtimeMBeanName,
   gcMonitorMBeanName,
   memMonitorMBeanName,
   cpuMonitorMBeanName,
   dumperMBeanName,
   methodServerMBeanName,
   methodContextsMBeanName,
   sessionMonitorMBeanName,
   seRequestMonitorMBeanName,
   whcRequestMonitorMBeanName,
   solrRequestMonitorMBeanName,
   osMBeanName
 };
 private static final String  thisMethodServerGetAttrsAttrs[][] =
 {
   runtimeMBeanAttrs,
   gcMonitorMBeanAttrs,
   memMonitorMBeanAttrs,
   cpuMonitorMBeanAttrs,
   dumperMBeanAttrs,
   methodServerMBeanAttrs,
   methodContextsMBeanAttrs,
   sessionMonitorMBeanAttrs,
   seRequestMonitorMBeanAttrs,
   seRequestMonitorMBeanAttrs,
   seRequestMonitorMBeanAttrs,
   osMBeanAttrs
 };

 private static final String  getAttributesSignature[] = { ObjectName[].class.getName(), QueryExp[].class.getName(), String[][].class.getName() };

 private static final String  rbClassname = serverStatusResource.class.getName();
%><%-- Determine current locale and set up base localization objects
--%><util:locale
/><%
 final ResourceBundle  RB = ResourceBundle.getBundle( rbClassname, localeObj );
%><%-- Determine if current user is a privileged user; if not and restricting access to this page to site administrators, then error out now
--%><%
 final boolean  isPrivilegedUser = AccessUtil.isSiteAdministrator();
 if ( restrictToSiteAdministrators )
   if ( !isPrivilegedUser )
     throw new AccessControlException( RB.getString( serverStatusResource.MUST_BE_SYS_ADMIN_MSG ) );
%><%-- Gather all data
--%><%
 // get JVM name of default server manager
 final String  defaultSmJvmName = getDefaultServerManagerJvmName();

 // get time right before we start result collection
 final long  dataCollectionStart = System.currentTimeMillis();

 // collect data for WindchillDS
 Map<ObjectName,AttributeList>  windchillDSResults[] = null;
 Object  dsJmxUrlString = null;
 Throwable  wcDsResultRetrievalException = null;
 try
 {
   try ( JMXConnector wcDsJmxConnection = WDSJMXConnector.getWDSJMXConnector() )
   {
     dsJmxUrlString = WDSJMXConnector.getWDSJMXServiceURL();
     final MBeanServerConnection  mbeanServer = wcDsJmxConnection.getMBeanServerConnection();
     windchillDSResults = (Map<ObjectName,AttributeList>[]) mbeanServer.invoke(
                             dumperMBeanName, "getAttributes", windchillDsGetAttrsArgs, getAttributesSignature );
   }
 }
 catch ( VirtualMachineError e )
 {
   throw e;
 }
 catch ( Throwable t )
 {
   logger.error( "Failed to retrieve results from WindchillDS", t );
   wcDsResultRetrievalException = t;  // remember but otherwise eat exception
 }

 // fetch VaultSite status information
 final CompositeData  vaultSiteStatusInfo = ( WTAppServerPropertyHelper.isAppServerDeployment() ? null : getVaultSiteStatusInfo() );  // don't bother collecting vaultSiteStatusInfo in SC Ohio deployments

 // collect data on method servers and server managers
 Integer  activeUsers = null;
 Map<String,Object>  methodServerResults = null;
 Map<String,Object>  serverManagerResults = null;
 Throwable  resultRetrievalException = null;
 try
 {
   // establish JMX connection to default server manager to collect JMX data from server managers and method servers
   try ( JMXConnector smConnection = JmxConnectUtil.getDefaultServerManagerLocalConnector() )
   {
     final MBeanServerConnection  mbeanServer = smConnection.getMBeanServerConnection();

     // produce dynamic proxy for the "MethodServers" MBean in default server manager
     final MethodServerMProxyMBean  methodServersMBeanProxy =
             MBeanServerInvocationHandler.newProxyInstance( mbeanServer, methodServerMProxyMBeanName,
                                                            MethodServerMProxyMBean.class, false );

     // grab data from all method servers (yes, this is a bit ugly, but it is all done in one request -- no chatter)
     methodServerResults = methodServersMBeanProxy.invokeInfoOpInAllClusterMethodServers(
                             dumperMBeanName, "getAttributes", methodServersGetAttrsArgs, getAttributesSignature );
		System.out.print("=================>" + methodServerResults + "<================");
     // fetch active user count (done separately as we only need the result from one server manager, not all)
     try
     {
       activeUsers = (Integer) mbeanServer.getAttribute( activeUsersMBeanName, "TotalActiveUserCount" );
     }
     catch ( InstanceNotFoundException e )
     {
       logger.debug( "Active users MBean not found", e );
       activeUsers = 0;  // must not have been any active users yet and thus this MBean has not yet been registered
     }
     catch ( VirtualMachineError e )
     {
       throw e;
     }
     catch ( Throwable t )
     {
       // don't let a problem here prevent us from acquiring serverManagerResults where possible
       // activeUsers is still null, clearly signaling lack of data to page rendering below
       logger.error( "Problem acquiring total active user count", t );
     }

     // grab data from all server managers (yes, this is a bit ugly, but it is all done in one request -- no chatter)
     serverManagerResults = methodServersMBeanProxy.invokeInfoOpInAllServerManagers(
                             dumperMBeanName, "getAttributes", serverManagerGetAttrsArgs, getAttributesSignature );
   }
 }
 catch ( VirtualMachineError e )
 {
   throw e;
 }
 catch ( Throwable t )
 {
   logger.error( "Failed to retrieve results from server manager", t );
   resultRetrievalException = t;  // remember but otherwise eat exception
 }

 // we're done collecting data now (usually, but not quite always, hence the lack of 'final' here)
 long  dataCollectionEnd = System.currentTimeMillis();

 // collate server manager, method server, and servlet engine results into somewhat easier to use format
 final Map<String,Map<String,Object>>  smToAttrMap = new TreeMap<>();
 final Map<String,Throwable>  smToExceptionMap = new TreeMap<>();
 final Map<String,Map<String,Map<String,Object>>>  smToMsToAttrMap = new HashMap<>();
 final Map<String,Map<String,Throwable>>  smToMsToExceptionMap = new HashMap<>();
 if ( serverManagerResults != null )
   for ( Map.Entry<String,Object> serverManagerResultEntry : serverManagerResults.entrySet() )
   {
     final String  serverManagerName = serverManagerResultEntry.getKey();
     final Map<String,Map<String,Object>>  msToAttrMap = new TreeMap<>();
     smToMsToAttrMap.put( serverManagerName, msToAttrMap );
     final Map<String,Throwable>  msToExceptionMap = new TreeMap<>();
     smToMsToExceptionMap.put( serverManagerName, msToExceptionMap );
     final Object  smResult = serverManagerResultEntry.getValue();
     if ( smResult instanceof Map[] )
     {
       smToAttrMap.put( serverManagerName, collate( (Map<ObjectName,AttributeList>[]) smResult ) );
       collateResultsFromServerManager( serverManagerName, methodServerResults, msToAttrMap, msToExceptionMap );
     }
     else if ( smResult instanceof Throwable )
       smToExceptionMap.put( serverManagerName, (Throwable) smResult );
   }

 // grab all data of interest from this method server *if* it's not already covered by the data we have so far (which it should be)
 Map<String,Object>  thisMsAttrMap = null;
 Exception  localMsException = null;
 if ( !containsResultsForMs( smToMsToAttrMap, thisMethodServerName ) )
 {
   logger.error( "Could not obtain data for local method server from server manager!" );
   try
   {
     // could obtain this via a variety of direct API calls (and used to), but this is more consistent with the rest of the code here
     final Dumper  dumper = Dumper.getInstance( null, true );
     final Map<ObjectName,AttributeList>  msResults[] = dumper.getAttributes( thisMethodServerGetAttrsBeans, null,
                                                                              thisMethodServerGetAttrsAttrs );
     dataCollectionEnd = System.currentTimeMillis();  // reset end of data collection, since we just collected more data
     thisMsAttrMap = collate( msResults );
   }
   catch ( Exception e )
   {
     logger.error( "Failed to retrieve results from local method server", e );
     localMsException = e;
   }
 }

 // collate Windchill DS results into handy map
 final Map<String,Object>  wcDsAttrMap = ( ( windchillDSResults != null ) ? collate( windchillDSResults ) : null );

 // get siteStatusData
 final TabularData  siteStatusData = ( ( vaultSiteStatusInfo != null ) ? (TabularData) vaultSiteStatusInfo.get( "siteStatusData" ) : null );

%><%-- All data of interest is now gathered, so now we just have to present it
--%><%
 // determine resource bundle, decimal and date format, and localized percent symbol for use throughout and set up various other data for re-use
 final DecimalFormatSymbols  decimalSymbols = new DecimalFormatSymbols( localeObj );
 final DecimalFormat  decimalFormat = new DecimalFormat( "0.###", decimalSymbols );
 final String  percentString = xmlEscape( decimalSymbols.getPercent() );  // pre-escaped localized % symbol
 final SimpleDateFormat  dateFormat = new SimpleDateFormat( "yyyy-MM-dd HH:mm:ss.SSS Z" );
 dateFormat.setTimeZone( WTContext.getContext().getTimeZone() );
 final String  webAppContextPaths[] = { windchillWebAppPath, whcWebAppPath, solrWebAppPath };
 final String  webAppPrefixes[] = { "", WHC_PREFIX, SOLR_PREFIX };
 final String  webAppLabelKeys[] = { serverStatusResource.GENERAL_SERVLET_REQUESTS_LABEL,
                                     serverStatusResource.HELP_SERVLET_REQUESTS_LABEL,
                                     serverStatusResource.SOLR_SERVLET_REQUESTS_LABEL };
 final String  percContextTimeAttrNames[] =
 {
   "percentageOfContextTimeInJDBCCalls",
   "percentageOfContextTimeInJDBCConnWait",
   "percentageOfContextTimeInJNDICalls",
   "percentageOfContextTimeInRemoteCacheCalls"
 };
 final String  percContextTimeLabels[] =
 {
   RB.getString( serverStatusResource.IN_JDBC_CALLS ),
   RB.getString( serverStatusResource.IN_JDBC_CONN_WAIT ),
   RB.getString( serverStatusResource.IN_JNDI_CALLS ),
   RB.getString( serverStatusResource.IN_REMOTE_CACHE_CALLS )
 };
 final String  percContextTimeChartJsps[] =
 {
   "percTimeInJdbcChart.jsp",
   "percTimeInJdbcWaitChart.jsp",
   "percTimeInJndiChart.jsp",
   "percTimeInRemoteCacheChart.jsp",
 };
%><html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<title><%=getXmlEscapedString( RB, serverStatusResource.SERVER_STATUS )%></title>
<link rel="stylesheet" href="serverStatusStyles.css" type="text/css" media="screen" />
<script type="text/javascript">
function launchWindow(url,title,options) { var x = window.open(url, title, options); x.focus(); }
</script>
</head>
<body class="wizbodybg">
<%-- Page title banner/header --%>
<table class="wizHdr" width="100%">
<tbody>
<tr>
<td class="wizTitleTD" align="left">&#160;<%=getXmlEscapedString( RB, serverStatusResource.SERVER_STATUS )%></td>
<td class="wizTitle" align="right">
<table border="0" cellspacing="0" cellpadding="2">
<tr>
<td class="wizTitle" width="1"> &#160; </td>
<td class="wizTitle" width="1" align="right">
<a onClick="launchWindow('<%=helpUrl%>','HelpWindow','toolbar=yes,location=yes,directories=yes,status=yes,menubar=yes,scrollbars=yes,resizable=yes'); return false;"
   href="<%=helpUrl%>" class="hlpTxt" title="<%=getXmlEscapedString( RB, serverStatusResource.HELP )%>">
<img border="0" class="hlpBg hlpBdr" src="../../../netmarkets/images/help_tablebutton.gif"
     alt="<%=getXmlEscapedString( RB, serverStatusResource.HELP )%>" title="<%=getXmlEscapedString( RB, serverStatusResource.HELP )%>"/>
</a>
</td>
</tr>
</table>
</td>
</tr>
</tbody>
</table>
<%-- Current user, server manager link, e-mail technical support, WindchillDS, and file vault links layout table --%>
<table width="100%">
<%-- Current user, server manager link, and e-mail technical support links layout row --%>
<tr valign="top">
<td>
<table>
<tr valign="top">
<th nowrap="nowrap" scope="row"><%=getXmlEscapedString( RB, serverStatusResource.CURRENT_ACTIVE_USERS )%>: </th>
<td><a href='chartWrapper.jsp?chartPg=totalActiveUserChart.jsp'><%=( activeUsers != null ) ? decimalFormat.format( activeUsers ) : "?"%></a></td><td> </td>
</tr>
</table>
</td>
<td>
<table>
<tr valign="top">
<th nowrap="nowrap" scope="row"><%=getXmlEscapedString( RB, serverStatusResource.SERVER_MANAGERS )%>: </th>
<td>
<%
 if ( serverManagerResults != null )
   for ( String serverManagerName : serverManagerResults.keySet() )
   {
     final Map<String,Object>  smAttrMap = smToAttrMap.get( serverManagerName );
     final boolean  cacheMaster = ( ( smAttrMap != null ) && Boolean.TRUE.equals( smAttrMap.get( "CacheMaster" ) ) );
     final boolean  isDefaultSm = ( ( defaultSmJvmName != null ) && defaultSmJvmName.equals( serverManagerName ) );
%>
<a href='#<%=serverManagerName%>'><%=serverManagerName%></a><c:if test='<%=isDefaultSm%>'>*</c:if><c:if test='<%=cacheMaster%>'> (<%=getXmlEscapedString( RB, serverStatusResource.MASTER )%>)</c:if><br />
<%
   }
%>
</td>
</tr>
</table>
</td>
<c:if test='<%=isPrivilegedUser%>'>
<td align='right'>
<jsp:useBean  id="url_factory" class="wt.httpgw.URLFactory" scope="request"/>
<c:choose>
<c:when test='<%=WTAppServerPropertyHelper.isAppServerDeployment()%>'>
<a title="<%=getXmlEscapedString( RB, serverStatusResource.CONTACT_TECHNICAL_SUPPORT_TOOLTIP )%>"
   onClick="launchWindow('contactTechSupport.jsp','ContactTechSupport','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,height=200,width=450'); return false;"
   href="contactTechSupport.jsp">
<%=getXmlEscapedString( RB, serverStatusResource.CONTACT_TECHNICAL_SUPPORT )%>
</a>
</c:when>
<c:otherwise>
<a title="<%=getXmlEscapedString( RB, serverStatusResource.CONTACT_TECHNICAL_SUPPORT_TOOLTIP )%>"
   onClick="launchWindow('<%=url_factory.getBaseURL().toString() %>app/#netmarkets/jsp/customersupport/customerSupportPage.jsp','System Configuration Collector','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,height=740,width=865'); return false;"
   href="<%=url_factory.getBaseURL().toString() %>app/#netmarkets/jsp/customersupport/customerSupportPage.jsp">
<%=getXmlEscapedString( RB, serverStatusResource.SITE_INFORMATION_LINK )%>
</a>
</c:otherwise>
</c:choose>
</td>
</c:if>
</tr>
<%-- WindchillDS and File Vaults links layout row --%>
<tr valign="top">
<td>
<table>
<tr valign="top">
<th nowrap="nowrap" scope="row"><%=getXmlEscapedString( RB, serverStatusResource.WINDCHILL_DS )%>: </th>
<td><a href="#WindchillDS"><%=getXmlEscapedString( RB, (wcDsResultRetrievalException == null ) ? serverStatusResource.UP : serverStatusResource.UNREACHABLE )%></a></td>
</tr>
</table>
</td>
<c:if test='<%=vaultSiteStatusInfo != null%>'>
<td>
<%
 int  reachableSites = 0;
 int  unreachableSites = 0;
 for ( Object siteStatusObject : siteStatusData.values() )
 {
   final CompositeData  siteStatus = (CompositeData) siteStatusObject;
   final String  lastStatus = (String) siteStatus.get( "lastStatus" );
   if ( SiteMonitorMBean.OK_STATUS.equals( lastStatus ) )
     ++reachableSites;
   else
     ++unreachableSites;
 }
%>
<table>
<tr valign="top">
<th nowrap="nowrap" scope="row"><%=getXmlEscapedString( RB, serverStatusResource.FILE_VAULT_SITES )%>: </th>
<td>
<a href="#FileVaultSites">
<%=xmlEscape( ( unreachableSites == 0 ) ? RB.getString( serverStatusResource.REACHABLE )
                                        : MBeanUtilities.formatMessage( RB.getString( serverStatusResource.REACHABLE_SITES_MSG ),
                                                                        reachableSites, unreachableSites ) )%>
</a>
</td>
</tr>
</table>
</td>
</c:if>
<c:if test='<%=isPrivilegedUser%>'>
<td align='right' <%=( vaultSiteStatusInfo != null ) ? "" : "colspan='2'"%>>
<a href="index.jsp" title="<%=getXmlEscapedString( RB, serverStatusResource.MONITORING_TOOLS_TOOLTIP )%>">
<%=getXmlEscapedString( RB, serverStatusResource.MONITORING_TOOLS )%>
</a>
</td>
</c:if>
</tr>
</table>
<%-- Local method server data (only shown here when we couldn't get it through a server manager) --%>
<c:if test='<%=thisMsAttrMap != null%>'>
<% { // explicitly limit scope of variables herein %>
<table>
<tbody>
<tr valign="top">
<td>
<div class="frame, frame_outer">
<span style="width: 100%">  <%-- Necessary for MSIE to get this right --%>
<%-- Local method server data header --%>
<div class="frameTitle">
<table class="pp" width="100%">
<tbody>
<tr>
<td align="left" valign="top">
<table class="pp">
<tbody>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.METHOD_SERVER )%>: </td>
<td class="ppdata"><%=xmlEscape( thisMethodServerName )%>* (<%=xmlEscape( thisJvmName )%>)</td>
</tr>
<%
 final Object  msJmxUrl = thisMsAttrMap.get( "JmxServiceURL" );
%>
<c:if test='<%=msJmxUrl != null%>'>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.JMX_URL )%>: </td>
<td class="ppdata"><%=xmlEscape( msJmxUrl )%></td>
</tr>
</c:if>
</tbody>
</table>
</td>
<td align="right" valign="top">
<table class="pp">
<tbody>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.UPTIME )%>: </td>
<td class="ppdata"><%=xmlEscape( renderMillis( (Long) thisMsAttrMap.get( "Uptime" ), RB, localeObj ) )%></td>
</tr>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.DEADLOCKED )%>: </td>
<%
 final boolean  msDeadlocked = ( thisMsAttrMap.get( "DeadlockedThreadIds" ) != null );
%>
<td class="ppdata" <%=msDeadlocked ? "style='color: red'" : ""%>><%=getXmlEscapedString( RB, msDeadlocked ? serverStatusResource.YES : serverStatusResource.NO )%></td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
<%-- Local method server data tables --%>
<div class="frameContent">
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody>
<tr valign="top">
<td>
<%-- Main local method server data table --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<thead>
<tr>
<th/>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.RECENT )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.BASELINE )%>&#160;</span></th>
</tr>
</thead>
<tbody class="tablebody">
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.TIME_IN_GC )%>&#160;</th>
<%
 final double  msPercTimeInGCLimit = (Double) thisMsAttrMap.get( "PercentTimeSpentInGCThreshold" );
 final double  msPercTimeInGCRecent = (Double) thisMsAttrMap.get( "RecentPercentTimeSpentInGC" );
 final double  msPercTimeInGCOverall = (Double) thisMsAttrMap.get( "OverallPercentTimeSpentInGC" );  // using overall rather than baseline...
 final String  thisMsChartQueryString = "jvmId=" + URLEncoder.encode( thisJvmName, "UTF-8" ) + "&amp;jvmStartTime=" + thisMsAttrMap.get( "StartTime" ) +
                                        "&amp;msName=" + URLEncoder.encode( thisMethodServerName, "UTF-8" );
%>
<td class="c" <%=( ( msPercTimeInGCLimit > 0 ) && ( msPercTimeInGCRecent > msPercTimeInGCLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( msPercTimeInGCRecent )%><%=percentString%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=msGcChart.jsp&amp;<%=thisMsChartQueryString%>'
   <%=( ( msPercTimeInGCLimit > 0 ) && ( msPercTimeInGCOverall > msPercTimeInGCLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercTimeInGCOverall )%><%=percentString%>
</a>
</td>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.CPU_USED_BY_PROCESS )%>&#160;</th>
<%
 final double  msPercCpuLimit = (Double) thisMsAttrMap.get( "ProcessPercentCpuThreshold" );
 final double  msPercCpuUsedOverall = (Double) thisMsAttrMap.get( "AverageProcessPercentCpu" );  // using overall rather than baseline...
 final CompositeData  recentCpuData = (CompositeData) thisMsAttrMap.get( "RecentCpuData" );
 final double  smPercCpuUsedRecent = ( ( recentCpuData != null ) ? (Double) recentCpuData.get( "processPercentCpu" ) : msPercCpuUsedOverall );
%>
<td class="c" <%=( ( msPercCpuLimit > 0 ) && ( smPercCpuUsedRecent > msPercCpuLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( smPercCpuUsedRecent )%><%=percentString%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=msCpuChart.jsp&amp;<%=thisMsChartQueryString%>'
   <%=( ( msPercCpuLimit > 0 ) && ( msPercCpuUsedOverall > msPercCpuLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercCpuUsedOverall )%><%=percentString%>
</a>
</td>
</tr>
<%
 for ( int webAppIdx = 0; webAppIdx < webAppPrefixes.length; ++webAppIdx )
 {
   final String  webAppContextPath = webAppContextPaths[webAppIdx];
   final String  encodedWebAppContextPath = URLEncoder.encode( webAppContextPath, "UTF-8" );
   final String  webAppPrefix = webAppPrefixes[webAppIdx];
   // if we do not have any data for this web app in any method server for this server manager, then don't generate empty table lines
   final CompositeData  seRequestDataBaseline = (CompositeData) thisMsAttrMap.get( webAppPrefix + "RequestRecentStatistics" );
   if ( seRequestDataBaseline == null )
     continue;
   final String  webAppLabelKey = webAppLabelKeys[webAppIdx];
   int  rowCount = 0;
%>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, webAppLabelKey )%></span>
</th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel">&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel">&#160;</span></th>
</tr>
<c:if test='<%="".equals( webAppPrefix )%>'>  <%-- We currently only collect (or are interested in) session data for the Windchill web app --%>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.ACTIVE_SESSIONS )%></th>
<%
   final int  seSessionLimit = (Integer) thisMsAttrMap.get( webAppPrefix + "MaxAverageActiveSessionsThreshold" );
   final int  activeSessions = (Integer) thisMsAttrMap.get( webAppPrefix + "ActiveSessions" );  // do Integer to int conversion only once
   final double  activeSessionsBaseline = (Double) ((CompositeData)thisMsAttrMap.get( webAppPrefix + "SessionBaselineStatistics" )).get( "activeSessionsAverage" );
%>
<td class="c" <%=( ( seSessionLimit > 0 ) && ( activeSessions > seSessionLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( activeSessions )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=sessionsChart.jsp&amp;<%=thisMsChartQueryString%>&amp;contextPath=<%=encodedWebAppContextPath%>'
   <%=( ( seSessionLimit > 0 ) && ( activeSessionsBaseline > seSessionLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( activeSessionsBaseline )%>
</a>
</td>
</tr>
</c:if>
<%
   CompositeData  seRequestDataRecent = (CompositeData) thisMsAttrMap.get( webAppPrefix + "RequestBaselineStatistics" );
   if ( seRequestDataRecent == null )
     seRequestDataRecent = seRequestDataBaseline;
%>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.COMPLETED_REQUESTS )%></th>
<%
   final long  seCompletedRequestsRecent = (Long) seRequestDataRecent.get( "completedRequests" );
   final long  seCompletedRequestsBaseline = (Long) seRequestDataBaseline.get( "completedRequests" );
%>
<td class="c"><%=decimalFormat.format( seCompletedRequestsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=requestsPerMinuteChart.jsp&amp;<%=thisMsChartQueryString%>&amp;contextPath=<%=encodedWebAppContextPath%>'>
<%=decimalFormat.format( seCompletedRequestsBaseline )%>
</a>
</td>
</tr>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.AVERAGE_RESPONSE_TIME )%></th>
<%
   final double  seRespLimit = (Double) thisMsAttrMap.get( webAppPrefix + "RequestTimeWarnThreshold" );
   final double  seAvgRespSecsRecent = (Double) seRequestDataRecent.get( "requestSecondsAverage" );
   final double  seAvgRespSecsBaseline = (Double) seRequestDataBaseline.get( "requestSecondsAverage" );
%>
<td class="c" <%=( ( seRespLimit > 0 ) && ( seAvgRespSecsRecent > seRespLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( seAvgRespSecsRecent )%>&#160;<%=getXmlEscapedString( RB, serverStatusResource.SECONDS )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=responseTimeChart.jsp&amp;<%=thisMsChartQueryString%>&amp;contextPath=<%=encodedWebAppContextPath%>'
   <%=( ( seRespLimit > 0 ) && ( seAvgRespSecsBaseline > seRespLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( seAvgRespSecsBaseline )%>&#160;<%=getXmlEscapedString( RB, serverStatusResource.SECONDS )%>
</a>
</td>
</tr>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.MAXIMUM_CONCURRENCY )%></th>
<%
   final int  seRequestLimit = (Integer) thisMsAttrMap.get( webAppPrefix + "MaxAverageActiveRequestsThreshold" );
   final int  seMaxRequestsRecent = (Integer) seRequestDataRecent.get( "activeRequestsMax" );
   final int  seMaxRequestsBaseline = (Integer) seRequestDataBaseline.get( "activeRequestsMax" );
%>
<td class="c" <%=( ( seRequestLimit > 0 ) && ( seMaxRequestsRecent > seRequestLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( seMaxRequestsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=maxRequestConcChart.jsp&amp;<%=thisMsChartQueryString%>&amp;contextPath=<%=encodedWebAppContextPath%>'
   <%=( ( seRequestLimit > 0 ) && ( seMaxRequestsBaseline > seRequestLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( seMaxRequestsBaseline )%>
</a>
</td>
</tr>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.AVERAGE_CONCURRENCY )%></th>
<%
   final double  seAvgRequestsRecent = (Double) seRequestDataRecent.get( "activeRequestsAverage" );
   final double  seAvgRequestsBaseline = (Double) seRequestDataBaseline.get( "activeRequestsAverage" );
%>
<td class="c" <%=( ( seRequestLimit > 0 ) && ( seAvgRequestsRecent > seRequestLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( seAvgRequestsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=avgRequestConcChart.jsp&amp;<%=thisMsChartQueryString%>&amp;contextPath=<%=encodedWebAppContextPath%>'
   <%=( ( seRequestLimit > 0 ) && ( seAvgRequestsBaseline > seRequestLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( seAvgRequestsBaseline )%>
</a>
</td>
</tr>
<%
 }
%>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.METHOD_CONTEXTS )%></span>
</th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel">&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel">&#160;</span></th>
</tr>
<%
 CompositeData  recentMcData = (CompositeData) thisMsAttrMap.get( "RecentStatistics" );
 final CompositeData  baselineMcData = (CompositeData) thisMsAttrMap.get( "BaselineStatistics" );
 if ( recentMcData == null )
   recentMcData = baselineMcData;
%>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.COMPLETED_CONTEXTS )%></th>
<%
 final long  completedContextsRecent = (Long) recentMcData.get( "completedContexts" );
 final long  completedContextsBaseline = (Long) baselineMcData.get( "completedContexts" );
%>
<td class="c"><%=decimalFormat.format( completedContextsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=contextsPerMinuteChart.jsp&amp;<%=thisMsChartQueryString%>'>
<%=decimalFormat.format( completedContextsBaseline )%>
</a>
</td>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.MAXIMUM_CONCURRENCY )%></th>
<%
 final int  contextLimit = (Integer) thisMsAttrMap.get( "MaxAverageActiveContextsThreshold" );
 final int  maxContextsRecent = (Integer) recentMcData.get( "activeContextsMax" );
 final int  maxContextsBaseline = (Integer) baselineMcData.get( "activeContextsMax" );
%>
<td class="c" <%=( ( contextLimit > 0 ) && ( maxContextsRecent > contextLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( maxContextsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=maxContextConcChart.jsp&amp;<%=thisMsChartQueryString%>'>
<%=decimalFormat.format( maxContextsBaseline )%>
</a>
</td>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.AVERAGE_CONCURRENCY )%></th>
<%
 final double  avgContextsRecent = (Double) recentMcData.get( "activeContextsAverage" );
 final double  avgContextsBaseline = (Double) baselineMcData.get( "activeContextsAverage" );
%>
<td class="c" <%=( ( contextLimit > 0 ) && ( avgContextsRecent > contextLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( avgContextsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=avgContextConcChart.jsp&amp;<%=thisMsChartQueryString%>'
   <%=( ( contextLimit > 0 ) && ( avgContextsBaseline > contextLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( avgContextsBaseline )%>
</a>
</td>
</tr>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.METHOD_CONTEXT_TIME )%></span>
</th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel">&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel">&#160;</span></th>
</tr>
<%
 for ( int ii = 0; ii < percContextTimeAttrNames.length; ++ii )
 {
   final String  attrName = percContextTimeAttrNames[ii];
   final String  chartJsp = percContextTimeChartJsps[ii];
%>
<tr class='<%=( ( ii % 2 ) == 0 ) ? "o" : "e" %>'>
<th nowrap="nowrap" scope="row" class="c"><%=xmlEscape( percContextTimeLabels[ii] )%></th>
<%
   final double  percTimeRecent = (Double) recentMcData.get( attrName );
   final double  percTimeBaseline = (Double) baselineMcData.get( attrName );
%>
<td class="c"><%=decimalFormat.format( percTimeRecent )%><%=percentString%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=<%=chartJsp%>&amp;<%=thisMsChartQueryString%>'>
<%=decimalFormat.format( percTimeBaseline )%><%=percentString%>
</a>
</td>
</tr>
<%
 }
%>
</tbody>
</table>
</td>
<td>&#160;&#160;</td>
<td>
<%-- Local method server memory and system data table --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody class="tablebody">
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.MEMORY_USED )%>&#160;</span>
</th>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.HEAP )%>&#160;</th>
<%
 final double  msPercHeapLimit = (Double) thisMsAttrMap.get( "HeapPercentUsageThreshold" );
 final double  msPercHeapUsed = (Double) thisMsAttrMap.get( "HeapPercentUsage" );
%>
<td class="c">
<a href='chartWrapper.jsp?chartPg=msHeapChart.jsp&amp;<%=thisMsChartQueryString%>'
   <%=( ( msPercHeapLimit > 0 ) && ( msPercHeapUsed > msPercHeapLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercHeapUsed )%><%=percentString%>
</a>
</td>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.PERM_GEN )%></th>
<%
 final double  msPercPermLimit = (Double) thisMsAttrMap.get( "PermGenPercentUsageThreshold" );
 final double  msPercPermUsed = (Double) thisMsAttrMap.get( "PermGenPercentUsage" );
%>
<td class="c">
<a href='chartWrapper.jsp?chartPg=msPermGenChart.jsp&amp;<%=thisMsChartQueryString%>'
   <%=( ( msPercPermLimit > 0 ) && ( msPercPermUsed > msPercPermLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercPermUsed )%><%=percentString%>
</a>
</td>
</tr>
<%
 final String  msPhysMemInfo = renderSysMemInfo( thisMsAttrMap, "FreePhysicalMemorySize", "TotalPhysicalMemorySize", decimalFormat, RB );
 final String  msSwapMemInfo = renderSysMemInfo( thisMsAttrMap, "FreeSwapSpaceSize", "TotalSwapSpaceSize", decimalFormat, RB );
%>
<c:if test='<%=( msPhysMemInfo != null ) || ( msSwapMemInfo != null )%>'>
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.AVAILABLE_SYSTEM_MEMORY )%>&#160;</span>
</th>
</tr>
<c:if test='<%=msPhysMemInfo != null%>'>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.PHYSICAL )%>&#160;</th>
<td class="c" nowrap="nowrap"><%=xmlEscape( msPhysMemInfo )%></td>
</tr>
</c:if>
<c:if test='<%=msSwapMemInfo != null%>'>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.SWAP )%>&#160;</th>
<td class="c" nowrap="nowrap"><%=xmlEscape( msSwapMemInfo )%></td>
</tr>
</c:if>
</c:if>
<%
 final Double  msSystemLoadAverage = (Double) thisMsAttrMap.get( "SystemLoadAverage" );
%>
<c:if test='<%=( msSystemLoadAverage != null ) && ( msSystemLoadAverage >= 0 )%>'>
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.OTHER_SYSTEM_INFO )%>&#160;</span>
</th>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.LOAD_AVERAGE )%>&#160;</th>
<td class="c"><%=decimalFormat.format( msSystemLoadAverage )%></td>
</tr>
</c:if>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
<a href="#" class="ppdata"><%=getXmlEscapedString( RB, serverStatusResource.BACK_TO_TOP )%></a>
</span>
</div>
</td>
</tr>
</tbody>
</table>
<% } %>
</c:if>
<%-- If we tried to get info for this method server and failed, then say so now (should probably *never* happen) --%>
<c:if test='<%=localMsException != null%>'>
<h3 style='color: red'><%=getXmlEscapedString( RB, serverStatusResource.FAILED_TO_RETRIEVE_METHOD_SERVER_DATA )%>: </h3>
<table>
<tbody>
<tr valign="top">
<th nowrap="nowrap" scope="row" align="left" style='color: red'><%=getXmlEscapedString( RB, serverStatusResource.ERROR_EMPHASIZED )%>: </th>
<td><%=xmlEscape( localMsException )%></td>
</tr>
</tbody>
</table>
</c:if>
<%-- If we couldn't get any server manager data, then say so now --%>
<c:if test='<%=resultRetrievalException != null%>'>
<h3 style='color: red'><%=getXmlEscapedString( RB, serverStatusResource.FAILED_TO_RETRIEVE_SERVER_MANAGER_DATA )%>: </h3>
<table>
<tbody>
<tr valign="top">
<th nowrap="nowrap" scope="row" align="left" style='color: red'><%=getXmlEscapedString( RB, serverStatusResource.ERROR_EMPHASIZED )%>: </th>
<td><%=xmlEscape( resultRetrievalException )%></td>
</tr>
</tbody>
</table>
</c:if>
<%-- If we got some server manager data, then show each server manager's data in turn --%>
<%
 for ( Map.Entry<String,Map<String,Object>> smToAttrsEntry : smToAttrMap.entrySet() )
 {
   final String  serverManagerName = smToAttrsEntry.getKey();
   final String  encodedServerManagerName = URLEncoder.encode( serverManagerName, "UTF-8" );
   final boolean  isDefaultSm = ( ( defaultSmJvmName != null ) && defaultSmJvmName.equals( serverManagerName ) );
   final Map<String,Object>  smAttrMap = smToAttrsEntry.getValue();
   final Map<String,Map<String,Object>>  msToAttrMap = smToMsToAttrMap.get( serverManagerName );
   final Map<String,Throwable>  msToExceptionMap = smToMsToExceptionMap.get( serverManagerName );
   final String  smChartQueryString = "jvmId=" + encodedServerManagerName + "&amp;jvmStartTime=" + smAttrMap.get( "StartTime" );
   final Map<String,String>  msChartQueryStrings = MBeanUtilities.newHashMap( msToAttrMap.size(), 0.75f );
   for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
   {
     final String  methodServerName = msToAttrMapEntry.getKey();
     final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
     final String  msChartQueryString = "jvmId=" + URLEncoder.encode( (String) msAttrs.get( "Name" ), "UTF-8" ) +
                                        "&amp;jvmStartTime=" + msAttrs.get( "StartTime" ) + "&amp;msName=" + URLEncoder.encode( methodServerName, "UTF-8" ) +
                                        "&amp;smName=" + encodedServerManagerName;
     msChartQueryStrings.put( methodServerName, msChartQueryString );
   }
%>
<%-- Output data for a given server manager --%>
<a name="<%=xmlEscape( serverManagerName )%>"/>
<table>
<tbody>
<tr valign="top">
<td>
<div class="frame, frame_outer">
<span style="width: 100%">  <%-- Necessary for MSIE to get this right --%>
<%-- Server manager data header --%>
<div class="frameTitle">
<table class="pp" width="100%">
<tbody>
<tr>
<td align="left" valign="top">
<table class="pp">
<tbody>
<%
   final boolean  cacheMaster = Boolean.TRUE.equals( smAttrMap.get( "CacheMaster" ) );
%>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, ( cacheMaster ? serverStatusResource.MASTER_SERVER_MANAGER : serverStatusResource.SERVER_MANAGER ) )%>: </td>
<td class="ppdata">
<c:choose>
<c:when test='<%=isPrivilegedUser%>'>
<a href='mbeanDump.jsp?sm=<%=encodedServerManagerName%>'
><%=xmlEscape( serverManagerName )%></a><c:if test='<%=isDefaultSm%>'>*</c:if>
</c:when>
<c:otherwise>
<%=xmlEscape( serverManagerName )%><c:if test='<%=isDefaultSm%>'>*</c:if>
</c:otherwise>
</c:choose>
</td>
</tr>
<%
   final Object  smJmxUrlString = smAttrMap.get( "JmxServiceURL" );
%>
<c:if test='<%=smJmxUrlString != null%>'>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.JMX_URL )%>: </td>
<td class="ppdata"><%=xmlEscape( smJmxUrlString )%></td>
</tr>
</c:if>
</tbody>
</table>
</td>
<td align="right" valign="top">
<table class="pp">
<tbody>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.UPTIME )%>: </td>
<td class="ppdata"><%=xmlEscape( renderMillis( (Long) smAttrMap.get( "Uptime" ), RB, localeObj ) )%></td>
</tr>
<%
   final boolean  smDeadlocked = ( smAttrMap.get( "Deadlocked" ) != null );
%>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.DEADLOCKED )%>: </td>
<td class="ppdata" <%=smDeadlocked ? "style='color: red'" : ""%>><%=getXmlEscapedString( RB, smDeadlocked ? serverStatusResource.YES : serverStatusResource.NO )%></td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
<%-- Container for all data tables for server manager (including associated method server tables) --%>
<div class="frameContent">
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody>
<tr valign="top">
<td>
<%-- Layout table for server manager data tables --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody>
<tr valign="top">
<td>
<%-- Server manager GC and CPU data table --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<thead>
<tr>
<th/>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.RECENT )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.BASELINE )%>&#160;</span></th>
</tr>
</thead>
<tbody class="tablebody">
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.TIME_IN_GC )%>&#160;</th>
<%
   final double  smPercTimeInGCLimit = (Double) smAttrMap.get( "PercentTimeSpentInGCThreshold" );
   final double  smPercTimeInGCRecent = (Double) smAttrMap.get( "RecentPercentTimeSpentInGC" );
   final double  smPercTimeInGCBaseline = (Double) smAttrMap.get( "OverallPercentTimeSpentInGC" );
%>
<td class="c">
<a href='liveGcChart.jsp?<%=smChartQueryString%>'
   <%=( ( smPercTimeInGCLimit > 0 ) && ( smPercTimeInGCRecent > smPercTimeInGCLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( smPercTimeInGCRecent )%><%=percentString%>
</a>
</td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=smGcChart.jsp&amp;<%=smChartQueryString%>'
   <%=( ( smPercTimeInGCLimit > 0 ) && ( smPercTimeInGCBaseline > smPercTimeInGCLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( smPercTimeInGCBaseline )%><%=percentString%>
</a>
</td>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.CPU_USED_BY_PROCESS )%>&#160;</th>
<%
   final double  smPercCpuLimit = (Double) smAttrMap.get( "ProcessPercentCpuThreshold" );
   final double  smPercCpuUsedOverall = (Double) smAttrMap.get( "AverageProcessPercentCpu" );  // using overall rather than baseline...
   final CompositeData  smRecentCpuData = (CompositeData) smAttrMap.get( "RecentCpuData" );
   final double  smPercCpuUsedRecent = ( ( smRecentCpuData != null ) ? (Double) smRecentCpuData.get( "processPercentCpu" ) : smPercCpuUsedOverall );
%>
<td class="c">
<a href='liveCpuChart.jsp?<%=smChartQueryString%>'
   <%=( ( smPercCpuLimit > 0 ) && ( smPercCpuUsedRecent > smPercCpuLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( smPercCpuUsedRecent )%><%=percentString%>
</a>
</td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=smCpuChart.jsp&amp;<%=smChartQueryString%>'
   <%=( ( smPercCpuLimit > 0 ) && ( smPercCpuUsedOverall > smPercCpuLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( smPercCpuUsedOverall )%><%=percentString%>
</a>
</td>
</tr>
</tbody>
</table>
</td>
<td>&#160;&#160;</td>
<td>
<%-- Server manager memory table --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody class="tablebody">
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.MEMORY_USED )%>&#160;</span>
</th>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c">
<a href='liveMemUsageChart.jsp?<%=smChartQueryString%>'><%=getXmlEscapedString( RB, serverStatusResource.HEAP )%></a>&#160;
</th>
<% final double  smPercHeapLimit = (Double) smAttrMap.get( "HeapPercentUsageThreshold" ), smPercHeapUsed = (Double) smAttrMap.get( "HeapPercentUsage" ); %>
<td class="c">
<a href='chartWrapper.jsp?chartPg=smHeapChart.jsp&amp;<%=smChartQueryString%>'
   <%=( ( smPercHeapLimit > 0 ) && ( smPercHeapUsed > smPercHeapLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( smPercHeapUsed )%><%=percentString%>
</a>
</td>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c">
<a href='liveMemUsageChart.jsp?<%=smChartQueryString%>&amp;permGen=true'><%=getXmlEscapedString( RB, serverStatusResource.PERM_GEN )%></a>&#160;
</th>
<% final double  smPercPermLimit = (Double) smAttrMap.get( "PermGenPercentUsageThreshold" ), smPercPermUsed = (Double) smAttrMap.get( "PermGenPercentUsage" ); %>
<td class="c">
<a href='chartWrapper.jsp?chartPg=smPermGenChart.jsp&amp;<%=smChartQueryString%>'
   <%=( ( smPercPermLimit > 0 ) && ( smPercPermUsed > smPercPermLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( smPercPermUsed )%><%=percentString%>
</a>
</td>
</tr>
</tbody>
</table>
</td>
<%
   final String  smPhysMemInfo = renderSysMemInfo( smAttrMap, "FreePhysicalMemorySize", "TotalPhysicalMemorySize", decimalFormat, RB );
   final String  smSwapMemInfo = renderSysMemInfo( smAttrMap, "FreeSwapSpaceSize", "TotalSwapSpaceSize", decimalFormat, RB );
%>
<%-- Server manager system memory table --%>
<c:if test='<%=( smPhysMemInfo != null ) || ( smSwapMemInfo != null )%>'>
<td>&#160;&#160;</td>
<td>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody class="tablebody">
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.AVAILABLE_SYSTEM_MEMORY )%>&#160;</span>
</th>
</tr>
<c:if test='<%=smPhysMemInfo != null%>'>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.PHYSICAL )%>&#160;</th>
<td class="c" nowrap="nowrap"><%=xmlEscape( smPhysMemInfo )%></td>
</tr>
</c:if>
<c:if test='<%=smSwapMemInfo != null%>'>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.SWAP )%>&#160;</th>
<td class="c" nowrap="nowrap"><%=xmlEscape( smSwapMemInfo )%></td>
</tr>
</c:if>
</tbody>
</table>
</td>
</c:if>
<%
   final Double  smSystemLoadAverage = (Double) smAttrMap.get( "SystemLoadAverage" );
%>
<%-- Server manager system load average table --%>
<c:if test='<%=( smSystemLoadAverage != null ) && ( smSystemLoadAverage >= 0 )%>'>
<td>&#160;&#160;</td>
<td>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody class="tablebody">
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.OTHER_SYSTEM_INFO )%>&#160;</span>
</th>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.LOAD_AVERAGE )%>&#160;</th>
<td class="c"><a href='liveLoadAverageChart.jsp?<%=smChartQueryString%>'><%=decimalFormat.format( smSystemLoadAverage )%></a></td>
</tr>
</tbody>
</table>
</td>
</c:if>
</tr>
</tbody>
</table>
</td>
</tr>
<%-- Method server data table --%>
<c:if test='<%=( ( msToAttrMap != null ) && !msToAttrMap.isEmpty() )%>'>
<% { // explicitly limit scope of variables herein %>
<tr><td height="14"/></tr>
<tr valign="top">
<td>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<thead>
<tr valign="top">
<th nowrap="nowrap" scope="row">
<div class="frameTitle"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.METHOD_SERVER_DATA )%></span></div>
</th>
<% for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
   {
     final String  methodServerName = msToAttrMapEntry.getKey();
     final boolean  isThisMethodServer = thisMethodServerName.equals( methodServerName );
     final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
     final Object  msJmxUrl = msAttrs.get( "JmxServiceURL" );
%>
<th width="1"/>
<th nowrap="nowrap" scope="col" colspan="2">
<div class="frameTitle">
<span class="pplabel" <c:if test='<%=msJmxUrl != null%>'>title="<%=getXmlEscapedString( RB, serverStatusResource.JMX_URL )%>: <%=xmlEscape( msJmxUrl )%>"</c:if>>
<c:choose>
<c:when test='<%=isPrivilegedUser%>'>
<a href='mbeanDump.jsp?sm=<%=URLEncoder.encode(serverManagerName,"UTF-8")%>&amp;ms=<%=URLEncoder.encode(methodServerName,"UTF-8")%>'
><%=xmlEscape( methodServerName )%></a><c:if test='<%=isThisMethodServer%>'>*</c:if>
</c:when>
<c:otherwise>
<%=xmlEscape( methodServerName )%><c:if test='<%=isThisMethodServer%>'>*</c:if>
</c:otherwise>
</c:choose>
</span>
</div>
</th>
<%
   }
%>
</tr>
</thead>
<tbody class="tablebody">
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.UPTIME )%></th>
<% for ( Map<String,Object> msAttrs : msToAttrMap.values() ) { %>
<th/>
<td colspan="2" class="c"><%=xmlEscape( renderMillis( (Long) msAttrs.get( "Uptime" ), RB, localeObj ) )%></td>
<% } %>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.DEADLOCKED )%></th>
<% for ( Map<String,Object> msAttrs : msToAttrMap.values() )
   {
     final boolean  msDeadlocked = ( msAttrs.get( "DeadlockedThreadIds" ) != null );
%>
<th/>
<td colspan="2" class="c" <%=msDeadlocked ? "style='color: red'" : ""%>><%=getXmlEscapedString( RB, msDeadlocked ? serverStatusResource.YES : serverStatusResource.NO )%></td>
<% } %>
</tr>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.MEMORY_USED )%></span>
</th>
<c:forEach items='<%=msToAttrMap.keySet()%>'>
<th/>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg"><span class="pplabel">&#160;</span></th>
</c:forEach>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c">
<a href="liveMemUsageChart.jsp?smName=<%=encodedServerManagerName%>&amp;msName=*"><%=getXmlEscapedString( RB, serverStatusResource.HEAP )%></a>&#160;
</th>
<% for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
   {
     final String  methodServerName = msToAttrMapEntry.getKey();
     final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
     final double  msPercHeapLimit = (Double) msAttrs.get( "HeapPercentUsageThreshold" ), msPercHeapUsed = (Double) msAttrs.get( "HeapPercentUsage" );
%>
<th/>
<td colspan="2" class="c">
<a href='chartWrapper.jsp?chartPg=msHeapChart.jsp&amp;<%=msChartQueryStrings.get( methodServerName )%>'
   <%=( ( msPercHeapLimit > 0 ) && ( msPercHeapUsed > msPercHeapLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercHeapUsed )%><%=percentString%>
</a>
</td>
<%
   }
%>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c">
<a href="liveMemUsageChart.jsp?smName=<%=encodedServerManagerName%>&amp;msName=*&amp;permGen=true"><%=getXmlEscapedString( RB, serverStatusResource.PERM_GEN )%></a>&#160;
</th>
<% for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
   {
     final String  methodServerName = msToAttrMapEntry.getKey();
     final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
     final double  msPercPermLimit = (Double) msAttrs.get( "PermGenPercentUsageThreshold" ), msPercPermUsed = (Double) msAttrs.get( "PermGenPercentUsage" );
%>
<th/>
<td colspan="2" class="c">
<a href='chartWrapper.jsp?chartPg=msPermGenChart.jsp&amp;<%=msChartQueryStrings.get( methodServerName )%>'
   <%=( ( msPercPermLimit > 0 ) && ( msPercPermUsed > msPercPermLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercPermUsed )%><%=percentString%>
</a>
</td>
<%
   }
%>
</tr>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.OTHER_STATS )%>&#160;</span></th>
<c:forEach items='<%=msToAttrMap.keySet()%>'>
<th/>
<th scope="col" nowrap="nowrap" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.RECENT )%>&#160;</span></th>
<th scope="col" nowrap="nowrap" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.BASELINE )%>&#160;</span></th>
</c:forEach>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.TIME_IN_GC )%>&#160;</th>
<% for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
   {
     final String  methodServerName = msToAttrMapEntry.getKey();
     final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
     final double  msPercGCLimit = (Double) msAttrs.get( "PercentTimeSpentInGCThreshold" );
     final double  msPercGC[] = { (Double) msAttrs.get( "RecentPercentTimeSpentInGC" ), (Double) msAttrs.get( "OverallPercentTimeSpentInGC" ) };
     final String  msChartQueryString = msChartQueryStrings.get( methodServerName );
%>
<th/>
<td class="c">
<a href='liveGcChart.jsp?<%=msChartQueryString%>'
   <%=( ( msPercGCLimit > 0 ) && ( msPercGC[0] > msPercGCLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercGC[0] )%><%=percentString%>
</a>
</td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=msGcChart.jsp&amp;<%=msChartQueryString%>'
   <%=( ( msPercGCLimit > 0 ) && ( msPercGC[1] > msPercGCLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercGC[1] )%><%=percentString%>
</a>
</td>
<%
   }
%>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c">
<a href="liveCpuChart.jsp?smName=<%=encodedServerManagerName%>&amp;msName=*"><%=getXmlEscapedString( RB, serverStatusResource.CPU_USED_BY_PROCESS )%></a>&#160;
</th>
<% for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
   {
     final String  methodServerName = msToAttrMapEntry.getKey();
     final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
     final double  msPercCPULimit = (Double) msAttrs.get( "ProcessPercentCpuThreshold" );
     final double  msPercCPUUsed[] = { 0.0, (Double) msAttrs.get( "AverageProcessPercentCpu" ) };
     final CompositeData  msRecentCpuData = (CompositeData) msAttrs.get( "RecentCpuData" );
     final String  msChartQueryString = msChartQueryStrings.get( methodServerName );
     msPercCPUUsed[0] = ( ( msRecentCpuData != null ) ? (Double) msRecentCpuData.get( "processPercentCpu" ) : msPercCPUUsed[1] );
%>
<th/>
<td class="c">
<a href='liveCpuChart.jsp?<%=msChartQueryString%>'
   <%=( ( msPercCPULimit > 0 ) && ( msPercCPUUsed[0] > msPercCPULimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercCPUUsed[0] )%><%=percentString%>
</a>
</td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=msCpuChart.jsp&amp;<%=msChartQueryString%>'
   <%=( ( msPercCPULimit > 0 ) && ( msPercCPUUsed[1] > msPercCPULimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( msPercCPUUsed[1] )%><%=percentString%>
</a>
</td>
<%
   }
%>
</tr>
<%
   for ( int webAppIdx = 0; webAppIdx < webAppPrefixes.length; ++webAppIdx )
   {
     final String  webAppContextPath = webAppContextPaths[webAppIdx];
     final String  encodedWebAppContextPath = URLEncoder.encode( webAppContextPath, "UTF-8" );
     final String  webAppPrefix = webAppPrefixes[webAppIdx];
     {  // if we do not have any data for this web app in any method server for this server manager, then don't generate empty table lines
       boolean  hasDataForWebApp = false;
       for ( Map<String,Object> msAttrs : msToAttrMap.values() )
         if ( msAttrs.get( webAppPrefix + "RequestBaselineStatistics" ) != null )
         {
           hasDataForWebApp = true;
           break;
         }
       if ( !hasDataForWebApp )
         continue;
     }
     final String  webAppLabelKey = webAppLabelKeys[webAppIdx];
     int  rowCount = 0;
%>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, webAppLabelKey )%></span>
</th>
<c:forEach items='<%=msToAttrMap.keySet()%>'>
<th/>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.RECENT )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.BASELINE )%>&#160;</span></th>
</c:forEach>
</tr>
<c:if test='<%="".equals( webAppPrefix )%>'>  <%-- We currently only collect (or are interested in) session data for the Windchill web app --%>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.ACTIVE_SESSIONS )%></th>
<%   for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
     {
       final String  methodServerName = msToAttrMapEntry.getKey();
       final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
%>
<th/>
<%
       final Integer  activeSessionsObj = (Integer) msAttrs.get( webAppPrefix + "ActiveSessions" );  // using current rather than recent...
       if ( activeSessionsObj != null )  // the given method server may not have this web app and thus have no data for it
       {
         final int  seSessionLimit = (Integer) msAttrs.get( webAppPrefix + "MaxAverageActiveSessionsThreshold" );
         final int  activeSessions = activeSessionsObj;  // do Integer to int conversion only once
         final double  activeSessionsBaseline = (Double) ((CompositeData)msAttrs.get( webAppPrefix + "SessionBaselineStatistics" )).get( "activeSessionsAverage" );
%>
<td class="c" <%=( ( seSessionLimit > 0 ) && ( activeSessions > seSessionLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( activeSessions )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=sessionsChart.jsp&amp;<%=msChartQueryStrings.get( methodServerName )%>&amp;contextPath=<%=encodedWebAppContextPath%>'
   <%=( ( seSessionLimit > 0 ) && ( activeSessionsBaseline > seSessionLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( activeSessionsBaseline )%>
</a>
</td>
<%
       }
       else
       {
%>
<td class="c">&#160;</td>
<td class="c">&#160;</td>
<%
       }
     }
%>
</tr>
</c:if>
<%
     final CompositeData  seRequestDataRecent[] = new CompositeData[msToAttrMap.size()];
     final CompositeData  seRequestDataBaseline[] = new CompositeData[msToAttrMap.size()];
     {
       int  ii = 0;
       for ( Map<String,Object> msAttrs : msToAttrMap.values() )
       {
         seRequestDataBaseline[ii] = (CompositeData) msAttrs.get( webAppPrefix + "RequestBaselineStatistics" );
         final CompositeData  recentData = (CompositeData) msAttrs.get( webAppPrefix + "RequestRecentStatistics" );
         seRequestDataRecent[ii] = ( ( recentData != null ) ? recentData : seRequestDataBaseline[ii] );
         ++ii;
       }
     }
%>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.COMPLETED_REQUESTS )%></th>
<%
     {
       int  ii = 0;
       for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
       {
         final String  methodServerName = msToAttrMapEntry.getKey();
         final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
%>
<th/>
<%
         final CompositeData  requestBaselineData = seRequestDataBaseline[ii];
         if ( requestBaselineData != null )  // the given method server may not have this web app and thus have no data for it
         {
           final long  seCompletedRequestsRecent = (Long) seRequestDataRecent[ii].get( "completedRequests" );
           final long  seCompletedRequestsBaseline = (Long) requestBaselineData.get( "completedRequests" );
%>
<td class="c"><%=decimalFormat.format( seCompletedRequestsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=requestsPerMinuteChart.jsp&amp;<%=msChartQueryStrings.get( methodServerName )%>&amp;contextPath=<%=encodedWebAppContextPath%>'>
<%=decimalFormat.format( seCompletedRequestsBaseline )%>
</a>
</td>
<%
         }
         else
         {
%>
<td class="c">&#160;</td>
<td class="c">&#160;</td>
<%
         }
         ++ii;
       }
     }
%>
</tr>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.AVERAGE_RESPONSE_TIME )%></th>
<%
     {
       int  ii = 0;
       for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
       {
         final String  methodServerName = msToAttrMapEntry.getKey();
         final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
%>
<th/>
<%
         final CompositeData  requestBaselineData = seRequestDataBaseline[ii];
         if ( requestBaselineData != null )  // the given method server may not have this web app and thus have no data for it
         {
           final double  seRespLimit = (Double) msAttrs.get( webAppPrefix + "RequestTimeWarnThreshold" );
           final double  seAvgRespSecsRecent = (Double) seRequestDataRecent[ii].get( "requestSecondsAverage" );
           final double  seAvgRespSecsBaseline = (Double) requestBaselineData.get( "requestSecondsAverage" );
%>
<td class="c" <%=( ( seRespLimit > 0 ) && ( seAvgRespSecsRecent > seRespLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( seAvgRespSecsRecent )%>&#160;<%=getXmlEscapedString( RB, serverStatusResource.SECONDS )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=responseTimeChart.jsp&amp;<%=msChartQueryStrings.get( methodServerName )%>&amp;contextPath=<%=encodedWebAppContextPath%>'
   <%=( ( seRespLimit > 0 ) && ( seAvgRespSecsBaseline > seRespLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( seAvgRespSecsBaseline )%>&#160;<%=getXmlEscapedString( RB, serverStatusResource.SECONDS )%>
</a>
</td>
<%
         }
         else
         {
%>
<td class="c">&#160;</td>
<td class="c">&#160;</td>
<%
         }
         ++ii;
       }
     }
%>
</tr>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.MAXIMUM_CONCURRENCY )%></th>
<%
     {
       int  ii = 0;
       for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
       {
         final String  methodServerName = msToAttrMapEntry.getKey();
         final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
%>
<th/>
<%
         final CompositeData  requestBaselineData = seRequestDataBaseline[ii];
         if ( requestBaselineData != null )  // the given method server may not have this web app and thus have no data for it
         {
           final int  seRequestLimit = (Integer) msAttrs.get( webAppPrefix + "MaxAverageActiveRequestsThreshold" );
           final int  seMaxRequestsRecent = (Integer) seRequestDataRecent[ii].get( "activeRequestsMax" );
           final int  seMaxRequestsBaseline = (Integer) requestBaselineData.get( "activeRequestsMax" );
%>
<td class="c" <%=( ( seRequestLimit > 0 ) && ( seMaxRequestsRecent > seRequestLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( seMaxRequestsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=maxRequestConcChart.jsp&amp;<%=msChartQueryStrings.get( methodServerName )%>&amp;contextPath=<%=encodedWebAppContextPath%>'
   <%=( ( seRequestLimit > 0 ) && ( seMaxRequestsBaseline > seRequestLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( seMaxRequestsBaseline )%>
</a>
</td>
<%
         }
         else
         {
%>
<td class="c">&#160;</td>
<td class="c">&#160;</td>
<%
         }
         ++ii;
       }
     }
%>
</tr>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<th nowrap="nowrap" scope="row" class="c">
<a href='liveAvgRequestConcChart.jsp?smName=<%=encodedServerManagerName%>&amp;contextPath=<%=encodedWebAppContextPath%>'>
<%=getXmlEscapedString( RB, serverStatusResource.AVERAGE_CONCURRENCY )%>
</a>
</th>
<%
     {
       int  ii = 0;
       for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
       {
         final String  methodServerName = msToAttrMapEntry.getKey();
         final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
%>
<th/>
<%
         final CompositeData  requestBaselineData = seRequestDataBaseline[ii];
         if ( requestBaselineData != null )  // the given method server may not have this web app and thus have no data for it
         {
           final int  seRequestLimit = (Integer) msAttrs.get( webAppPrefix + "MaxAverageActiveRequestsThreshold" );
           final double  seAvgRequestsRecent = (Double) seRequestDataRecent[ii].get( "activeRequestsAverage" );
           final double  seAvgRequestsBaseline = (Double) requestBaselineData.get( "activeRequestsAverage" );
           final String  msChartQueryString = msChartQueryStrings.get( methodServerName ) + "&amp;contextPath=" + encodedWebAppContextPath;
%>
<td class="c">
<a href='liveAvgRequestConcChart.jsp?<%=msChartQueryString%>'
   <%=( ( seRequestLimit > 0 ) && ( seAvgRequestsRecent > seRequestLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( seAvgRequestsRecent )%>
</a>
</td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=avgRequestConcChart.jsp&amp;<%=msChartQueryString%>'
   <%=( ( seRequestLimit > 0 ) && ( seAvgRequestsBaseline > seRequestLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( seAvgRequestsBaseline )%>
</a>
</td>
<%
         }
         else
         {
%>
<td class="c">&#160;</td>
<td class="c">&#160;</td>
<%
         }
         ++ii;
       }
     }
%>
</tr>
<%
   }
%>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.METHOD_CONTEXTS )%></span>
</th>
<c:forEach items='<%=msToAttrMap.keySet()%>'>
<th/>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.RECENT )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.BASELINE )%>&#160;</span></th>
</c:forEach>
</tr>
<%
   final CompositeData  recentData[] = new CompositeData[msToAttrMap.size()];
   final CompositeData  baselineData[] = new CompositeData[msToAttrMap.size()];
   {
     int  ii = 0;
     for ( Map<String,Object> msAttrs : msToAttrMap.values() )
     {
       baselineData[ii] = (CompositeData) msAttrs.get( "BaselineStatistics" );
       final CompositeData  recentStats = (CompositeData) msAttrs.get( "RecentStatistics" );
       recentData[ii] = ( ( recentStats != null ) ? recentStats : baselineData[ii] );
       ++ii;
     }
   }
%>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.COMPLETED_CONTEXTS )%></th>
<%
   {
     int  ii = 0;
     for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
     {
       final String  methodServerName = msToAttrMapEntry.getKey();
       final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
       final long  completedContextsRecent = (Long) recentData[ii].get( "completedContexts" );
       final long  completedContextsBaseline = (Long) baselineData[ii].get( "completedContexts" );
%>
<th/>
<td class="c"><%=decimalFormat.format( completedContextsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=contextsPerMinuteChart.jsp&amp;<%=msChartQueryStrings.get( methodServerName )%>'>
<%=decimalFormat.format( completedContextsBaseline )%>
</a>
</td>
<%
       ++ii;
     }
   }
%>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.MAXIMUM_CONCURRENCY )%></th>
<%
   {
     int  ii = 0;
     for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
     {
       final String  methodServerName = msToAttrMapEntry.getKey();
       final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
       final int  contextLimit = (Integer) msAttrs.get( "MaxAverageActiveContextsThreshold" );
       final int  maxContextsRecent = (Integer) recentData[ii].get( "activeContextsMax" );
       final int  maxContextsBaseline = (Integer) baselineData[ii].get( "activeContextsMax" );
%>
<th/>
<td class="c" <%=( ( contextLimit > 0 ) && ( maxContextsRecent > contextLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( maxContextsRecent )%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=maxContextConcChart.jsp&amp;<%=msChartQueryStrings.get( methodServerName )%>'>
<%=decimalFormat.format( maxContextsBaseline )%>
</a>
</td>
<%
       ++ii;
     }
   }
%>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c">
<a href='liveAvgContextConcChart.jsp?smName=<%=encodedServerManagerName%>'><%=getXmlEscapedString( RB, serverStatusResource.AVERAGE_CONCURRENCY )%></a>
</th>
<%
   {
     int  ii = 0;
     for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
     {
       final String  methodServerName = msToAttrMapEntry.getKey();
       final Map<String,Object>  msAttrs = msToAttrMapEntry.getValue();
       final int  contextLimit = (Integer) msAttrs.get( "MaxAverageActiveContextsThreshold" );
       final double  avgContexts[] = { (Double) recentData[ii].get( "activeContextsAverage" ), (Double) baselineData[ii].get( "activeContextsAverage" ) };
       final String msChartQueryString = msChartQueryStrings.get( methodServerName );
%>
<th/>
<td class="c">
<a href='liveAvgContextConcChart.jsp?<%=msChartQueryString%>'
   <%=( ( contextLimit > 0 ) && ( avgContexts[0] > contextLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( avgContexts[0] )%>
</a>
</td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=avgContextConcChart.jsp&amp;<%=msChartQueryString%>'
   <%=( ( contextLimit > 0 ) && ( avgContexts[1] > contextLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( avgContexts[1] )%>
</a>
</td>
<%
       ++ii;
     }
   }
%>
</tr>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.METHOD_CONTEXT_TIME )%></span>
</th>
<c:forEach items='<%=msToAttrMap.keySet()%>'>
<th/>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.RECENT )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.BASELINE )%>&#160;</span></th>
</c:forEach>
</tr>
<%
   for ( int ii = 0; ii < percContextTimeAttrNames.length; ++ii )
   {
     final String  attrName = percContextTimeAttrNames[ii];
     final String  chartJsp = percContextTimeChartJsps[ii];
%>
<tr class='<%=( ( ii % 2 ) == 0 ) ? "o" : "e" %>'>
<th nowrap="nowrap" scope="row" class="c"><%=xmlEscape( percContextTimeLabels[ii] )%></th>
<%
     int  jj = 0;
     for ( Map.Entry<String,Map<String,Object>> msToAttrMapEntry : msToAttrMap.entrySet() )
     {
       final String  methodServerName = msToAttrMapEntry.getKey();
       final double  percTimes[] = { (Double) recentData[jj].get( attrName ), (Double) baselineData[jj].get( attrName ) };
%>
<th/>
<td class="c"><%=decimalFormat.format( percTimes[0] )%><%=percentString%></td>
<td class="c">
<a href='chartWrapper.jsp?chartPg=<%=chartJsp%>&amp;<%=msChartQueryStrings.get( methodServerName )%>'>
<%=decimalFormat.format( percTimes[1] )%><%=percentString%>
</a>
</td>
<%
       ++jj;
     }
%>
</tr>
<%
   }
%>
</tbody>
</table>
</td>
</tr>
<% } %>
</c:if>
<%-- Show any failures to obtain method server data --%>
<c:if test='<%=!msToExceptionMap.isEmpty()%>'>
<tr><td height="14"/></tr>
<tr valign="top">
<td>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<thead>
<tr valign="top">
<th nowrap="nowrap" scope="col">
<div class="frameTitle"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.METHOD_SERVER )%></span></div>
</th>
<th width="1"/>
<th nowrap="nowrap" scope="col">
<div class="frameTitle"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.ERROR )%></span></div>
</th>
</tr>
</thead>
<tbody class="tablebody">
<%
   {
     int  ii = 0;
     for ( Map.Entry<String,Throwable> msToExceptionEntry : msToExceptionMap.entrySet() )
     {
       ++ii;
%>
<tr class='<%=( ( ii % 2 ) == 0 ) ? "e" : "o"%>'>
<th nowrap="nowrap" scope="row" class="c"><%=xmlEscape( msToExceptionEntry.getKey() )%></th>
<th width="1"/>
<td class="c" style="color: red"><%=xmlEscape( msToExceptionEntry.getValue() )%></td>
</tr>
<%
     }
   }
%>
</tbody>
</table>
</td>
</tr>
</c:if>
</tbody>
</table>
</div>
<%-- Produce link back to the top of the page --%>
<a href="#" class="ppdata"><%=getXmlEscapedString( RB, serverStatusResource.BACK_TO_TOP )%></a>
</span>
</div>
</td>
</tr>
</tbody>
</table>
<%
 }
%>
<%-- Show any failures to obtain server manager data --%>
<%
 for ( Map.Entry<String,Throwable> smToExceptionEntry : smToExceptionMap.entrySet() )
 {
   final String  serverManagerName = smToExceptionEntry.getKey();
%>
<a name="<%=xmlEscape( serverManagerName )%>">
<h3 style='color: red'><%=getXmlEscapedString( RB, serverStatusResource.SERVER_MANAGER )%>: <%=xmlEscape( serverManagerName )%></h3>
</a>
<table>
<tbody>
<tr valign="top">
<th align="left" style='color: red'><%=getXmlEscapedString( RB, serverStatusResource.ERROR_EMPHASIZED )%>: </th>
<td><%=xmlEscape( smToExceptionEntry.getValue() )%></td>
</tr>
</tbody>
</table>
<%
 }
%>
<%-- Output data for WindchillDS --%>
<a name="WindchillDS"/>
<%
{  // intentionally limit scope of variables herein
%>
<c:choose>
<c:when test='<%=wcDsAttrMap != null%>'>
<table>
<tbody>
<tr valign="top">
<td>
<div class="frame, frame_outer">
<span style="width: 100%">  <%-- Necessary for MSIE to get this right --%>
<%-- WindchillDS data header --%>
<div class="frameTitle">
<table class="pp" width="100%">
<tbody>
<tr>
<td align="left" valign="top">
<table class="pp">
<tbody>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.WINDCHILL_DS )%>: </td>
<td class="ppdata">
<c:choose>
<c:when test='<%=isPrivilegedUser%>'>
<a href='mbeanDump.jsp?target=windchillDS'><%=xmlEscape( wcDsAttrMap.get("Name") )%></a>
</c:when>
<c:otherwise>
<%=xmlEscape( wcDsAttrMap.get("Name") )%>
</c:otherwise>
</c:choose>
</td>
</tr>
<c:if test='<%=dsJmxUrlString != null%>'>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.JMX_URL )%>: </td>
<td class="ppdata"><%=xmlEscape( dsJmxUrlString )%></td>
</tr>
</c:if>
</tbody>
</table>
</td>
<td align="right" valign="top">
<table class="pp">
<tbody>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.UPTIME )%>: </td>
<td class="ppdata"><%=xmlEscape( renderMillis( (Long) wcDsAttrMap.get( "Uptime" ), RB, localeObj ) )%></td>
</tr>
<%
 final boolean  dsDeadlocked = ( wcDsAttrMap.get( "Deadlocked" ) != null );
%>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.DEADLOCKED )%>: </td>
<td class="ppdata" <%=dsDeadlocked ? "style='color: red'" : ""%>><%=getXmlEscapedString( RB, dsDeadlocked ? serverStatusResource.YES : serverStatusResource.NO )%></td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
<%-- Container for all data tables for Windchill DS --%>
<div class="frameContent">
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody>
<tr valign="top">
<td>
<%-- Layout table for WindchillDS data tables --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody>
<tr valign="top">
<td>
<%-- WindchillDS GC and CPU data table --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<thead>
<tr>
<th/>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.RECENT )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.BASELINE )%>&#160;</span></th>
</tr>
</thead>
<tbody class="tablebody">
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.TIME_IN_GC )%>&#160;</th>
<%
 final double  dsPercTimeInGCLimit = (Double) wcDsAttrMap.get( "PercentTimeSpentInGCThreshold" );
 final double  dsPercTimeInGCRecent = (Double) wcDsAttrMap.get( "RecentPercentTimeSpentInGC" );
 final double  dsPercTimeInGCBaseline = (Double) wcDsAttrMap.get( "OverallPercentTimeSpentInGC" );
%>
<td class="c">
<a href='liveDSGcChart.jsp' <%=( ( dsPercTimeInGCLimit > 0 ) && ( dsPercTimeInGCRecent > dsPercTimeInGCLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( dsPercTimeInGCRecent )%><%=percentString%>
</a>
</td>
<td class="c" <%=( ( dsPercTimeInGCLimit > 0 ) && ( dsPercTimeInGCBaseline > dsPercTimeInGCLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( dsPercTimeInGCBaseline )%><%=percentString%></td>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.CPU_USED_BY_PROCESS )%>&#160;</th>
<%
 final double  dsPercCpuLimit = (Double) wcDsAttrMap.get( "ProcessPercentCpuThreshold" );
 final double  dsPercCpuUsedOverall = (Double) wcDsAttrMap.get( "AverageProcessPercentCpu" );  // using overall rather than baseline...
 final CompositeData  dsRecentCpuData = (CompositeData) wcDsAttrMap.get( "RecentCpuData" );
 final double  dsPercCpuUsedRecent = ( ( dsRecentCpuData != null ) ? (Double) dsRecentCpuData.get( "processPercentCpu" ) : dsPercCpuUsedOverall );
%>
<td class="c">
<a href="liveDSCpuChart.jsp" <%=( ( dsPercCpuLimit > 0 ) && ( dsPercCpuUsedRecent > dsPercCpuLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( dsPercCpuUsedRecent )%><%=percentString%>
</a>
</td>
<td class="c" <%=( ( dsPercCpuLimit > 0 ) && ( dsPercCpuUsedOverall > dsPercCpuLimit ) ? "style='color: red'" : "" )%>><%=decimalFormat.format( dsPercCpuUsedOverall )%><%=percentString%></td>
</tr>
</tbody>
</table>
</td>
<td>&#160;&#160;</td>
<td>
<%-- WindchillDS memory table --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody class="tablebody">
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.MEMORY_USED )%>&#160;</span>
</th>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.HEAP )%>&#160;</th>
<% final double  dsPercHeapLimit = (Double) wcDsAttrMap.get( "HeapPercentUsageThreshold" ), dsPercHeapUsed = (Double) wcDsAttrMap.get( "HeapPercentUsage" ); %>
<td class="c">
<a href="liveDSMemUsageChart.jsp" <%=( ( dsPercHeapLimit > 0 ) && ( dsPercHeapUsed > dsPercHeapLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( dsPercHeapUsed )%><%=percentString%>
</a>
</td>
</tr>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.PERM_GEN )%>&#160;</th>
<% final double  dsPercPermLimit = (Double) wcDsAttrMap.get( "PermGenPercentUsageThreshold" ), dsPercPermUsed = (Double) wcDsAttrMap.get( "PermGenPercentUsage" ); %>
<td class="c">
<a href="liveDSMemUsageChart.jsp?permGen=true" <%=( ( dsPercPermLimit > 0 ) && ( dsPercPermUsed > dsPercPermLimit ) ? "style='color: red'" : "" )%>>
<%=decimalFormat.format( dsPercPermUsed )%><%=percentString%>
</a>
</td>
</tr>
</tbody>
</table>
</td>
<%
 final String  dsPhysMemInfo = renderSysMemInfo( wcDsAttrMap, "FreePhysicalMemorySize", "TotalPhysicalMemorySize", decimalFormat, RB );
 final String  dsSwapMemInfo = renderSysMemInfo( wcDsAttrMap, "FreeSwapSpaceSize", "TotalSwapSpaceSize", decimalFormat, RB );
%>
<%-- WindchillDS system memory table --%>
<c:if test='<%=( dsPhysMemInfo != null ) || ( dsSwapMemInfo != null )%>'>
<td>&#160;&#160;</td>
<td>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody class="tablebody">
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.AVAILABLE_SYSTEM_MEMORY )%>&#160;</span>
</th>
</tr>
<c:if test='<%=dsPhysMemInfo != null%>'>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.PHYSICAL )%>&#160;</th>
<td class="c" nowrap="nowrap"><%=xmlEscape( dsPhysMemInfo )%></td>
</tr>
</c:if>
<c:if test='<%=dsSwapMemInfo != null%>'>
<tr class="e">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.SWAP )%>&#160;</th>
<td class="c" nowrap="nowrap"><%=xmlEscape( dsSwapMemInfo )%></td>
</tr>
</c:if>
</tbody>
</table>
</td>
</c:if>
<%
 final Double  dsSystemLoadAverage = (Double) wcDsAttrMap.get( "SystemLoadAverage" );
%>
<%-- WindchillDS system load average table --%>
<c:if test='<%=( dsSystemLoadAverage != null ) && ( dsSystemLoadAverage >= 0 )%>'>
<td>&#160;&#160;</td>
<td>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<tbody class="tablebody">
<tr>
<th nowrap="nowrap" scope="col" colspan="2" class="tablecolumnheaderbg">
<span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.OTHER_SYSTEM_INFO )%>&#160;</span>
</th>
</tr>
<tr class="o">
<th nowrap="nowrap" scope="row" class="c"><%=getXmlEscapedString( RB, serverStatusResource.LOAD_AVERAGE )%>&#160;</th>
<td class="c"><%=decimalFormat.format( dsSystemLoadAverage )%></td>
</tr>
</tbody>
</table>
</td>
</c:if>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
<%-- Produce link back to the top of the page --%>
<a href="#" class="ppdata"><%=getXmlEscapedString( RB, serverStatusResource.BACK_TO_TOP )%></a>
</span>
</div>
</td>
</tr>
</tbody>
</table>
</c:when>
<c:otherwise>
<h3 style='color: red'><%=getXmlEscapedString( RB, serverStatusResource.WINDCHILL_DS )%></h3>
<table>
<tbody>
<tr valign="top">
<th align="left" style='color: red'><%=getXmlEscapedString( RB, serverStatusResource.ERROR_EMPHASIZED )%>: </th>
<td><%=xmlEscape( wcDsResultRetrievalException )%></td>
</tr>
</tbody>
</table>
</c:otherwise>
</c:choose>
<%
}  // intentionally limit scope of variables herein
%>
<%-- Show vault site status data --%>
<c:if test='<%=siteStatusData != null %>'>
<a name="FileVaultSites"/>
<table>
<tbody>
<tr valign="top">
<td>
<div class="frame, frame_outer">
<span style="width: 100%">  <%-- Necessary for MSIE to get this right --%>
<%-- File vaults data header --%>
<div class="frameTitle">
<table class="pp" width="100%">
<tbody>
<tr>
<td align="left" valign="top">
<table class="pp">
<tbody>
<tr>
<td class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.FILE_VAULT_SITES )%></td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>
</div>
<%-- Container for all file vault data table --%>
<div class="frameContent">
<%-- File vault data table --%>
<table cellpadding="0" cellspacing="0" border="0" class="tablecellsepbg frameTable">
<thead>
<tr>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.SITE_URL )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.NAME )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.STATUS )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.TIME_OF_LAST_PING )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.AVAILABILITY )%>&#160;</span></th>
<th nowrap="nowrap" scope="col" class="tablecolumnheaderbg"><span class="pplabel"><%=getXmlEscapedString( RB, serverStatusResource.AVERAGE_RESPONSE_TIME )%>&#160;</span></th>
</tr>
</thead>
<tbody class="tablebody">
<%
 int  rowCount = 0;
 for ( CompositeData siteStatus : MBeanUtilities.getSortedData( siteStatusData ) )
 {
   final String  names[] = (String[]) siteStatus.get( "names" );
   final Date  lastPingTime = (Date) siteStatus.get( "lastPing" );
   final String  lastStatus = (String) siteStatus.get( "lastStatus" );
%>
<tr class='<%=( ( ++rowCount % 2 ) == 1 ? "o" : "e" )%>'>
<td class="c"><%=xmlEscape( siteStatus.get( "url" ) )%></td>
<td class="c"><%=xmlEscape( ( names != null ) ? MBeanUtilities.getStringArrayAsString( names ) : null )%></td>
<td class="c" <%=SiteMonitorMBean.OK_STATUS.equals( lastStatus ) ? "" : "style='color: red'" %>><%=xmlEscape( lastStatus )%></td>
<td class="c"><%=xmlEscape( ( lastPingTime != null ) ? dateFormat.format( lastPingTime ) : null )%></td>
<td class="c"><%=xmlEscape( decimalFormat.format( siteStatus.get( "percentageUptime" ) ) )%><%=percentString%></td>
<td class="c"><%=xmlEscape( decimalFormat.format( siteStatus.get( "averageResponseSeconds" ) ) )%></td>
</tr>
<%
   ++rowCount;
 }
%>
</tbody>
</table>
</div>
<%-- Produce link back to the top of the page --%>
<a href="#" class="ppdata"><%=getXmlEscapedString( RB, serverStatusResource.BACK_TO_TOP )%></a>
</span>
</div>
</td>
</tr>
</tbody>
</table>
</c:if>
<br />
<%-- Show time span during which data was collected --%>
<table>
<tbody>
<tr>
<td width="60"/>
<td class="ppdata">
<i>
<%= MBeanUtilities.formatMessage( RB.getString( serverStatusResource.DATA_COLLECTED_BETWEEN_MSG ),
                                  dateFormat.format( new Date( dataCollectionStart ) ),
                                  dateFormat.format( new Date( dataCollectionEnd ) ) ) %>
</i>
</td>
</tr>
</tbody>
</table>
</body>
</html>
<%-- Internal utilities --%>
<%!
 private static String  getDefaultServerManagerJvmName()
 {
   try
   {
     final JmxConnectInfo  jmxConnectInfo = (JmxConnectInfo) RemoteServerManager.getDefault().getInfo().jmxConnectInfo;
     return ( jmxConnectInfo.getJvmName() );
   }
   catch ( VirtualMachineError e )
   {
     throw e;
   }
   catch ( Throwable t )
   {
     logger.error( "Failed to retrieve JVM name of default server manager", t );
     return ( null );
   }
 }

 private static CompositeData  getVaultSiteStatusInfo()
 {
   try
   {
     // Use SelfAwareMBean.getSelfAwareMBean() and caste as this will be faster than going through MBeanServer
     return ( ((SiteMonitorMBean)SelfAwareMBean.getSelfAwareMBean( vaultSitesMBeanName )).getSiteStatusInfo() );
   }
   catch ( VirtualMachineError e )
   {
     throw e;
   }
   catch ( Throwable t )
   {
     logger.error( "Failed to retrieve vault site status info", t );
     return ( null );
   }
 }

 // collect into a more handy map form
 private static Map<String,Object>  collate( final Map<ObjectName,AttributeList> mbeanAttrMaps[] )
 {
   final Map<String,Object>  collationMap = new HashMap<>();
   for ( Map<ObjectName,AttributeList> mbeanAttrMap : mbeanAttrMaps )
     for ( Map.Entry<ObjectName,AttributeList> mbeanAttrMapEntry : mbeanAttrMap.entrySet() )
       collate( mbeanAttrMapEntry.getKey(), collationMap, mbeanAttrMapEntry.getValue() );
   return ( collationMap );
 }

 // collect attribute list into a more handy map form, ensuring uniqueness amongst keys
 //   1) places a prefix on attribute names from WHC and Solr web apps
 //   2) places a prefix on BaselineStatistics and RecentStatistics attribute names from ServletSessions' and ServletRequests'
 private static void  collate( final ObjectName objectName, final Map<String,Object> dataMap, final AttributeList attrs )
 {
   final String  webAppContextPath = objectName.getKeyPropertyList().get( MBeanRegistry.WEB_APP_CONTEXT_PROP_KEY );
   if ( webAppContextPath != null )
   {
     final boolean  isSolrWebApp = solrWebAppPath.equals( webAppContextPath );
     final boolean  isWhcWebApp = whcWebAppPath.equals( webAppContextPath );
     final String  webAppPrefix = ( isSolrWebApp ? SOLR_PREFIX : ( isWhcWebApp ? WHC_PREFIX : "" ) );
     final boolean  isSessionAttr = "ServletSessions".equals( objectName.getKeyPropertyList().get( MBeanRegistry.SERVLET_ENGINE_SUBSYSTEM_PROP_KEY ) );
     for ( Object attrObj : attrs )
     {
       final Attribute  attr = (Attribute) attrObj;
       String  attrName = attr.getName();
       if ( "BaselineStatistics".equals( attrName ) || "RecentStatistics".equals( attrName ) )
         attrName = ( isSessionAttr ? "Session" : "Request" ) + attrName;  // currently assume these attributes are either from ServletSessions or ServletRequests mbeans
       dataMap.put( webAppPrefix + attrName, attr.getValue() );
     }
   }
   else
     for ( Object attrObj : attrs )
     {
       final Attribute  attr = (Attribute) attrObj;
       dataMap.put( attr.getName(), attr.getValue() );
     }
 }

 @SuppressWarnings( "unchecked" )
 private static void  collateResultsFromServerManager( final String serverManagerName, final Map<String,Object> resultsForAllSms,
                                                       final Map<String,Map<String,Object>> jvmNameToAttrMap,
                                                       final Map<String,Throwable> jvmNameToExceptionMap )
 {
   if ( resultsForAllSms != null )
   {
     final Object smResultsObj = resultsForAllSms.get( serverManagerName );
     if ( smResultsObj instanceof Map )
     {
       final Map<String,Object>  smResults = (Map<String,Object>) smResultsObj;
       for ( Map.Entry<String,Object> smResultsEntry : smResults.entrySet() )
       {
         final String  jvmName = smResultsEntry.getKey();
         final Object  result = smResultsEntry.getValue();
         if ( result instanceof Map[] )
           jvmNameToAttrMap.put( jvmName, collate( (Map<ObjectName,AttributeList>[]) result ) );
         else if ( result instanceof Throwable )
           jvmNameToExceptionMap.put( jvmName, (Throwable) result );
       }
     }
   }
 }

 private static boolean  containsResultsForMs( final Map<String,Map<String,Map<String,Object>>> smToMsAttrMap, final String methodServerName )
 {
   if ( smToMsAttrMap != null )
     for ( Map<String,Map<String,Object>> msToAttrMap : smToMsAttrMap.values() )
       if ( msToAttrMap.containsKey( methodServerName ) )
         return ( true );
   return ( false );
 }

 private static final int  MILLIS_PER_SECOND = 1000;
 private static final int  MILLIS_PER_MINUTE = 60 * MILLIS_PER_SECOND;
 private static final int  MILLIS_PER_HOUR = 60 * MILLIS_PER_MINUTE;
 private static final int  MILLIS_PER_DAY = 24 * MILLIS_PER_HOUR;

 // render millisecond duration into days, hours, minutes, and seconds
 private static String  renderMillis( final long millis, final ResourceBundle resourceBundle, final Locale locale )
 {
   final long  days = millis / MILLIS_PER_DAY;
   long  remainder = millis % MILLIS_PER_DAY;
   final long  hours = remainder / MILLIS_PER_HOUR;
   remainder %= MILLIS_PER_HOUR;
   final long  minutes = remainder / MILLIS_PER_MINUTE;
   remainder %= MILLIS_PER_MINUTE;
   final long  seconds = remainder / MILLIS_PER_SECOND;
   remainder %= MILLIS_PER_SECOND;
   final String  msgFormat = resourceBundle.getString( ( days > 0 ) ? serverStatusResource.TIME_DURATION_FORMAT_W_DAYS
                                                                    : serverStatusResource.TIME_DURATION_FORMAT_WO_DAYS );
   final DecimalFormat  twoDigitFormat = new DecimalFormat( "00" );
   return ( MBeanUtilities.formatMessage( msgFormat,
                                          NumberFormat.getNumberInstance( locale ).format( days ),  // in case # of days goes into thousands, use proper formatting...
                                          twoDigitFormat.format( hours ),
                                          twoDigitFormat.format( minutes ),
                                          twoDigitFormat.format( seconds ),
                                          remainder ) );
 }

 private static final double  BYTES_PER_MB_AS_DBL = 1024.0 * 1024.0;

 // render free vs. total physical or swap memory; these items may be null as they're Sun-specific features
 private static String  renderSysMemInfo( final Map<String,Object> dataMap,
                                          final String freeMemItemName, final String totalMemItemName,
                                          final DecimalFormat decimalFormat, final ResourceBundle resourceBundle )
 {
   final Long  freeMem = (Long) dataMap.get( freeMemItemName );
   if ( freeMem != null )
   {
     final StringBuilder  sb = new StringBuilder();
     sb.append( decimalFormat.format( freeMem / BYTES_PER_MB_AS_DBL ) );
     sb.append( resourceBundle.getString( serverStatusResource.MB ) );
     final Long  totalMem = (Long) dataMap.get( totalMemItemName );
     if ( totalMem != null )
     {
       sb.append( " (" );
       sb.append( decimalFormat.format( 100.0 * (double)freeMem / (double)totalMem ) );
       sb.append( decimalFormat.getDecimalFormatSymbols().getPercent() );
       sb.append( ')' );
     }
     return ( sb.toString() );
   }
   else
     return ( null );
 }

 private static ObjectName  newObjectName( final String objectNameString )
 {
   try
   {
     return ( new ObjectName( objectNameString ) );
   }
   catch ( Exception e )
   {
     logger.error( "Could not create ObjectName from " + objectNameString, e );
     if ( e instanceof RuntimeException )
       throw (RuntimeException) e;
     throw new RuntimeException( e );
   }
 }

 private static String   xmlEscape( final char ch )
 {
   final String  replacement = MBeanUtilities.getXmlReplacementString( ch );
   if ( replacement != null )
     return ( replacement );
   return ( new String( new char[] { ch } ) );
 }

 private static String  xmlEscape( final String string )
 {
   return ( MBeanUtilities.xmlEscape( string ) );
 }

 private static String  xmlEscape( Object object )
 {
   // catch-all location to catch this obnoxious exception type to provide a better toString() rendering here
   // Since this exception type passes null to its super class as the causal exception, it will never be represented in getMessage()!
   // This is to fix SPR #2158634 and replaces a previous, improper fix for this same issue in this location.
   if ( object instanceof UndeclaredThrowableException )
   {
     final UndeclaredThrowableException  undeclaredThrowableException = (UndeclaredThrowableException) object;
     object = object.toString() + "; undeclared throwable: " + undeclaredThrowableException.getUndeclaredThrowable();
   }

   return ( ( object != null ) ? xmlEscape( object.toString() ) : null );
 }

 private static String  getXmlEscapedString( final ResourceBundle bundle, final String key )
 {
   return ( xmlEscape( bundle.getString( key ) ) );
 }
%>
