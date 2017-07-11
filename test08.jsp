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
    import="java.io.PrintWriter"%><%@page
    import="java.util.Date"%><%@page
    import="java.util.Calendar"%><%@page
    import=" java.lang.Integer"%><%@page
    import=" java.lang.Runnable"%><%@page
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
    import="wt.org.OrganizationServicesHelper"%><%@page
    import="wt.org.WTGroup"%><%@page
    import="wt.org.WTPrincipal"%><%@page
    import="wt.org.WTUser"%><%@page
    import="wt.session.SessionHelper"%><%@page
    import="wt.util.WTException"%><%@page
    import="wt.util.jmx.serverStatusResource"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page errorPage="/netmarkets/jsp/util/error.jsp"%>
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


private static String wcHome;
private static int count;


%>
<% 
 String ant_home = "ANT_HOME=" + WTProperties.getLocalProperties().getProperty("wt.env.ANT_HOME");
 String ant_opts = "ANT_OPTS=" + WTProperties.getLocalProperties().getProperty("wt.env.ANT_OPTS");
 String classpath = "CLASSPATH=" + WTProperties.getLocalProperties().getProperty("wt.env.CLASSPATH");
 String java_home = "JAVA_HOME=" + WTProperties.getLocalProperties().getProperty("wt.env.JAVA_HOME");
 String lang = "LANG=en_US.UTF-8";
 String path = "PATH=" + WTProperties.getLocalProperties().getProperty("wt.env.PATH");
 String sqlpath = "SQLPATH=" + WTProperties.getLocalProperties().getProperty("wt.env.SQLPATH");
 String wt_home = "WT_HOME="  + WTProperties.getLocalProperties().getProperty("wt.home");
 String[] envp = {ant_home,ant_opts,classpath,java_home,lang,path,sqlpath,wt_home};

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
    boolean groupFlag = hasAccess("Administrators");
    if(!groupFlag){
        throw new Exception("on premission");
    }
    List<String> cmdResult = new ArrayList<>();
    String keyTemp = "";
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
      list.add(findNowAndFinish(readFile(key)));
    }

    response.setCharacterEncoding("utf-8");  
    response.setHeader("iso-8859-1","utf-8");  
    request.setCharacterEncoding("utf-8"); 
    String type = request.getParameter("type");
    session = request.getSession(true); 
    if("submit".equals(type)){
        String dir = request.getParameter("dir");
        String cmd = request.getParameter("cmd");
        if(cmd != null){
            int cmdId = getCMDId();
            String writeTime = getTime();
            cmd.replaceAll("\n","").replaceAll("\r","");
            PrimeThread pt = new PrimeThread(cmdId,cmd,envp,dir,writeTime,keyTemp);
            Thread thread = new Thread(pt);
            thread.start();
        }
    }else if(("result").equals(type)){
        String filename = request.getParameter("filename");
        if(filename != null){
            String resultfile = "result_" + filename.replace(" ","_").replace(":","_");
            String errorfile = "error_" + filename.replace(" ","_").replace(":","_");
            for(String str : readFile(resultfile)){
                cmdResult.add(str + "<br>");
            }
            for(String str : readFile(errorfile)){
                cmdResult.add(str + "<br>");
            }
            session.setAttribute("result",cmdResult);
        }
    }else if(("refresh").equals(type)){
        cmdResult = (List<String>)session.getAttribute("result");
    }else{
        cmdResult = null;
    }
    
  %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Insert title here</title>
<script>
var xmlhttp;
function loadXMLDoc(url)
{
    cmd = document.getElementById("cmd").value;
    cmd = cmd.replace(/(^\s*)|(\s*$)/g,"").replace(/\s{2,}/g," ");
    dir = document.getElementById("dir").value;
    if (window.XMLHttpRequest)
    {// IE7+, Firefox, Chrome, Opera, Safari 代码
        xmlhttp=new XMLHttpRequest();
    }
    else
    {// IE6, IE5 代码
        xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
    }
    xmlhttp.onreadystatechange=rfunc;
    xmlhttp.open("POST",url,true);
    xmlhttp.setRequestHeader("Content-type","application/x-www-form-urlencoded");
    xmlhttp.send("cmd=" + cmd + "&dir=" + dir + "&type=submit");
}
function fromSubmit()
{
    var cmd = document.getElementById("cmd").value;
    if(cmd != null && cmd != "" && cmd != undefined){
        if(cmdFilte()){
            loadXMLDoc("test08.jsp");
        }else{
            alert("no permission to execute CMD order")
        }
    }else{
        alert("命令不能为空");
    }

}

function refresh(){
    window.location.href = "test08.jsp";
}

function loadResult(url,filename){
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
    xmlhttp.send("filename=" + filename + "&type=result");
}

function show_result(filename){
    loadResult("test08.jsp",filename);
}

function cfunc()
{
    if (xmlhttp.readyState==4 && xmlhttp.status==200)
    {
        
            window.location.href = "test08.jsp?type=refresh";
    }
}

function rfunc(){
    
    if (xmlhttp.readyState==4 && xmlhttp.status==200)
    {
        
            window.location.href = "test08.jsp";
    }
}

function cmdFilte(){
    var cmd = document.getElementById("cmd").value;
    var flag = false;            
    var writeFilters = ["windchill","pwd"];
    var blackFilters = ["windchill start","winchill stop","windchill sttat"];
    var cmdSplit = cmd.replace(/(^\s*)|(\s*$)/g,"").replace(/\s{2,}/g," ").split(" ");
    
    for(var i = 0;i < writeFilters.length;i++){
        if(writeFilters[i] == cmdSplit[0]){
            flag = true;
            break;
        }
    }
   
    if(flag){
        for(var i = 0;i < blackFilters.length;i++){
            var blackFilteSplit = blackFilters[i].split(" ");

            if(cmdSplit.length < blackFilteSplit.length){
                continue;
            }else{
                for(var m = 0;m < cmdSplit.length;m++){
                    var buff = new StringBuffer();
                    for(var n = 0;n < blackFilteSplit.length;n++){
                        buff.append(cmdSplit[m+n]);
                        buff.append(" ");
                    }
                    if(blackFilters[i].replace( /^\s+|\s+$/g, "" ) == buff.toString().replace( /^\s+|\s+$/g, "" )){
                        flag = false;
                        break;
                    }
                }
            }

            if(!flag){
                break;
            }
        }
    }

    return flag;
}

function StringBuffer() {
    this._strings = new Array();
}
    StringBuffer.prototype.append = function(_string) {
    this._strings.push(_string);
};
    StringBuffer.prototype.toString = function() {
    return this._strings.join("");
};
    StringBuffer.prototype.clear = function() {
    this._strings = [];
};
</script>
<style type="text/css">
    body{
        brackground-color:black;
        font-color:write;
    }

    .cmd{
        width:100%;
    }

    .info_div{
        margin:20px 0;
        width:100%;
    }

    .contre_div{
        margin:0 10%;
        
    }
    
    .btn_input{
        height:25px;
        width:10%;
    }

    .cmd_div{
        margin:50px 0;
    }

    table{
        width:100%;
        border: 1px solid #ccc;
        border: 1px solid #ccc;
        border-collapse: collapse;
    }

    td{
        border: 1px solid black;
    }

    .td_1{
        width:5%;
    }

    .res_td{
        width:7%;
    }
   
</style>
</head>
<body id="myBody">
    <div align="center">
        <%=keyTemp %>
    </div>
    <br>
    
    <br>
    <div class="contre_div">
        <div class="cmd_div">
            目录 : <input type="text" class="cmd" id="dir" value="/apphome/ptc/Windchill_10.2/Windchill">
            <br>
            命令 : <input type="text" class="cmd" id="cmd"> 
            <br> 
            <input class="btn_input" type="button" value="submit" onclick="fromSubmit()">
            <input class="btn_input" type="button" value="refresh" onclick="refresh()"> 
        </div>
        <div id="mydiv">
            <%
                if(cmdResult != null){
            %>
            <table>
                <tbody>
            <%
                    int num = 0;
                    int buffNum = 0;
                    StringBuffer buff = new StringBuffer();
                    for(String resultStr : cmdResult){
            %>
                    <tr>
            <%
                        switch(num){
                            case 0:
            %>
                            <td>Index</td>
                            <td><%=resultStr %></td>
            <%
                            break;

                            case 1:
            %>
                            <td>Command</td>
                            <td><%=resultStr %></td>
            <%
                            break;

                            case 2:
            %>
                            <td>MethodServer</td>
                            <td><%=resultStr %></td>
            <%
                            break;

                            case 3:
            %>
                            <td>StartTime</td>
                            <td><%=resultStr %></td>
            <%
                            break;

                            default:
                                String[] resultStrS = resultStr.split(" ");
                                if("FinishedTime:".equals(resultStrS[0])){
            %>
                                    <td>Result</td>
                                    <td><textarea cols="100" rows=<%=buffNum %>><%=buff.toString() %></textarea></td>
                                    </tr>
                                    <tr>
                                    <td>FinishedTime</td>
                                    <td><%=(resultStrS[1] + " " + resultStrS[2]) %></td>
            <%
                                }else{
                                    buff.append(resultStr.substring(0,resultStr.length() - 4));
                                    buff.append("\n");
                                    buffNum++;
                                }
                        }
            %>
                        </tr>
            <%
                        num++;
                    }
            %>
                    </tbody>
                </table>
            <%
                }
             %>
        </div>
        <div class="info_div">
            <p align="center">Running</p>
            <table>
                <tbody>
                    <%
                        for(Map<String,List> fileMap : list){
                            for(Object str : fileMap.get("now")){
                                String cmdInfo = (String)str;
                                String[] strSplit = cmdInfo.split("_");
                    %>   
                    <tr>
                        <td class="td_1">
                            <%=strSplit[0] %>
                        </td>
                        <td>
                            <%=strSplit[1] %>
                        </td>
                        <td>
                            <%=strSplit[2] %>
                        </td>
                        <td>
                            <%=strSplit[3] %>
                        </td>
                        <td class="res_td">
                            <button type="button" onclick="show_result('<%=(String)str %>')">结果</button>
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
            <p align="center">Finished</p>
            <table>
                <tbody>
                    <%
                        for(Map<String,List> fileMap : list){
                            for(Object str :fileMap.get("finish")){
                                String cmdInfo = (String)str;
                                String[] strSplit = cmdInfo.split("_");
                                cmdInfo = cmdInfo.replace("\'","_");
                    %>   
                    <tr>
                       <td class="td_1">
                            <%=strSplit[0] %>
                        </td>
                        <td>
                            <%=strSplit[1] %>
                        </td>
                        <td>
                            <%=strSplit[2] %>
                        </td>
                        <td>
                            <%=strSplit[3] %>
                        </td>
                        <td class="res_td">
                            <button type="button" onclick="show_result('<%=cmdInfo %>')">结果</button>
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

  private Map<String,List> findNowAndFinish(List<String> readList){
    List<String> nowList = new ArrayList<>();
    List<String> finishList = new ArrayList<>();
    Map<String,List> map = new HashMap<>();
    List<String> RNlist = new ArrayList<>();
    List<String> RFlist = new ArrayList<>();
    for(String tempString : readList){
        if(tempString != null && tempString != ""){
            String[] str = tempString.split("~@~");
            try{
                if("Running".equals(str[2])){
                    nowList.add(str[0] + "_" + str[1] + "_" + str[3] + "_" + str[5]);
                }else if("Finished".equals(str[2])){
                    finishList.add(str[0]+ "_" + str[1] + "_" + str[3] + "_" + str[5]);
                    RFlist.add(str[0]+ "_" + str[1] + "_" + str[3] + "_" + str[5]);
                }
            }catch(Exception e){
                continue;
            }
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
            RNlist.add(nowStr);
        }
    }
    map.put("now",RNlist);
    map.put("finish",RFlist);
    return map;
  }

  private List<String> readFile(String fileName){
    File file = new File(wcHome + fileName + ".log");
    BufferedReader reader = null;
    List<String> readList = new ArrayList<>();
    try {
        reader = new BufferedReader(new FileReader(file));
        String tempString = null;
        while ((tempString = reader.readLine()) != null) {
            readList.add(tempString);
        }
    } catch (IOException e) {
        writeFile("error","readFile: " + e.getMessage(),true);
    } finally {
        if (reader != null) {
            try {
                reader.close();
            } catch (IOException e1) {
            }
        }
    }
    return readList;
  }

  private synchronized static void writeFile(String fileName,String writeStr,boolean flag){
    File dir = new File(wcHome);
    dir.mkdirs();
    File file = new File(wcHome + fileName + ".log");
    BufferedWriter writer = null;
    try{
        writer = new BufferedWriter(new FileWriter(file,flag));
        writer.write(writeStr);
        writer.newLine();
    } catch (Exception e) {
        
    } finally {
            if (writer != null) {
                try {
                    writer.close();
                } catch (IOException e1) {
                }
            }
     }

  }
  
  public class PrimeThread implements Runnable {
      private int cmdId;
      private String cmd;
      private String[] envp;
      private String dir;
      private String writeTime;
      private String keyTemp = "";
      
      
      PrimeThread(int cmdId,String cmd,String[] envp,String dir,String writeTime,String keyTemp) {
          this.cmdId = cmdId;
          this.cmd = cmd;
          this.envp = envp;
          this.dir = dir;
          this.writeTime = writeTime;
          this.keyTemp = keyTemp;
      }

      public void run() {
         excutCMD(cmdId,cmd,envp,dir,writeTime,keyTemp);
      }
    
    
        public void excutCMD(int cmdId,String cmd,String[] envp,String dir,String writeTime,String keyTemp){
            String nowDate = "";
            String cmdReplace = cmd.replace(" ","_").replace("\'","_");
            String writeTimeReplace = writeTime.replace(" ","_").replace(":","_");
            String resultFileName = "result_" + cmdId + "_" + cmdReplace + "_" + writeTimeReplace + "_" + keyTemp;
            String errorFileName = "error_" + cmdId + "_" + cmdReplace + "_" + writeTimeReplace + "_" + keyTemp;
            String runningStr = cmdId + "~@~" + cmd + "~@~Running~@~" + writeTime + "~@~" + writeTime + "~@~" + keyTemp;
            String finishedStr = cmdId + "~@~" + cmd + "~@~Finished~@~" + writeTime + "~@~";
            String cmdMaker = cmdId + "_" + cmd + "_" + keyTemp;
            try {
                writeFile(keyTemp,runningStr,true);
                Process process = Runtime.getRuntime().exec(cmd,envp,new File(dir));//执行cmd命令
                BufferedReader input = new BufferedReader(new InputStreamReader(process.getInputStream()));//获取控制台输入流
                BufferedReader error = new BufferedReader(new InputStreamReader(process.getErrorStream()));//获取控制台输入流
                String line = "";
                String[] date = getTime().split(" ");
                int errorNum = 0;
                writeFile(resultFileName,cmdId + "",true);
                writeFile(resultFileName,cmd,true);
                writeFile(resultFileName,keyTemp,true);
                writeFile(resultFileName,writeTime,true);
                while ((line = input.readLine()) != null) {
                    writeFile(resultFileName,line,true);
                }
                while ((line = error.readLine()) != null) {
                    if(errorNum == 0){
                        writeFile(errorFileName,cmdId + "",true);
                        writeFile(errorFileName,cmd,true);
                        writeFile(errorFileName,keyTemp,true);
                        writeFile(errorFileName,writeTime,true);
                        errorNum++;
                    }
                    writeFile(errorFileName,line,true);
                }
                input.close();
                error.close();
                int waitFor = process.waitFor();
                nowDate = getTime();
                finishedStr = finishedStr + nowDate + "~@~" + keyTemp; 
                writeFile(keyTemp,finishedStr,true);
                writeFile(resultFileName,"FinishedTime: " + nowDate,true);
                if(errorNum > 0){
                    writeFile(errorFileName,"FinishedTime: " + nowDate,true);
                }
            } catch (Exception e) {
                nowDate = getTime();
                finishedStr = finishedStr + nowDate + "~@~" + keyTemp; 
                writeFile(keyTemp,finishedStr,true);
                writeFile(errorFileName,cmdId + "",true);
                writeFile(errorFileName,cmd,true);
                writeFile(errorFileName,keyTemp,true);
                writeFile(errorFileName,e.getMessage(),true);
            }
        }
  }

  private String getTime(){
      SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss SSS ZZZ");
      String time = df.format(new Date());
      String[] splitTime = time.split(" ");
      int difference = (800 - Integer.valueOf(splitTime[3].substring(1))) / 100;
      
      try {  
            Calendar c = Calendar.getInstance();  
            c.setTime(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss SSS ZZZ").parse(time));  
            Long millis = c.getTimeInMillis() + (difference * 60 * 60 * 1000);
            Date date = new Date(millis);    
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");  
            time = sdf.format(date);
        } catch (java.text.ParseException e) {   
            writeFile("error","[Error]GetTime: " + e.getMessage(),true);  
        }  
        return time;
  }

  private synchronized static int getCMDId(){
      int id = ++count;
      return id;
  }

  private boolean cmdFilter(String cmd){
      boolean flag = false;            

      String[] writeFilters = {"windchill"};
      String[] blackFilters = {"windchill start"};
      String[] cmdSplit = cmd.split(" ");
      
      for(String writeFilte : writeFilters){
          if(writeFilte.equals(cmdSplit[0])){
              flag = true;
              break;
          }
      }

      if(flag){
          for(String blackFilte : blackFilters){
              String[] blackFilteSplit = blackFilte.split(" ");
              if(cmdSplit.length < blackFilteSplit.length){
                  continue;
              }else{
                for(int i = 0;i < cmdSplit.length;i++){
                    StringBuffer buff = new StringBuffer();
                    for(int n = 0;n < blackFilteSplit.length && (cmdSplit.length - i) >= blackFilteSplit.length;n++){
                        buff.append(cmdSplit[i+n]);
                        buff.append(" ");
                    }
                    if(blackFilte.equals(buff.toString())){
                        flag = false;
                        break;
                    }
                }
              }
              if(!flag){
                  break;
              }
          }
      }
      return flag;
  }

  private boolean hasAccess(String groupName) throws WTException {
		
		boolean flag = false;
		WTPrincipal principal = SessionHelper.manager.getPrincipal();
		
		if(principal!=null && principal instanceof WTUser) {
			WTUser currentUser = (WTUser)principal;
			
			WTGroup group = OrganizationServicesHelper.manager.getGroup(groupName);
			
			flag = group.isMember(currentUser);
		}
		
		return flag;
	}

  
%>
