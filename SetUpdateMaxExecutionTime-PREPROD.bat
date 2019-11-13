PowerShell.exe "E:\ScheduledTaskScripts\SetUpdateMaxExecutionTime\Set-UpdateMaxExecutionTime.PS1" -SiteServer XSNW10W142C -SiteCode PP0 -TitleCriteria """"Security Monthly Quality Rollup"""" -Minutes 180 -InstanceName SetUpdateMaxExecutionTime 
PowerShell.exe "E:\ScheduledTaskScripts\SetUpdateMaxExecutionTime\Set-UpdateMaxExecutionTime.PS1" -SiteServer XSNW10W142C -SiteCode PP0 -TitleCriteria """"Feature update to Windows 10 (business editions)"""" -Minutes 360 -InstanceName SetUpdateMaxExecutionTime 
PowerShell.exe "E:\ScheduledTaskScripts\SetUpdateMaxExecutionTime\Set-UpdateMaxExecutionTime.PS1" -SiteServer XSNW10W142C -SiteCode PP0 -TitleCriteria """"Cumulative Update for Windows Server 2016"""" -Minutes 180 -InstanceName SetUpdateMaxExecutionTime 
PowerShell.exe "E:\ScheduledTaskScripts\SetUpdateMaxExecutionTime\Set-UpdateMaxExecutionTime.PS1" -SiteServer XSNW10W142C -SiteCode PP0 -TitleCriteria """"Cumulative Security Update for Internet Explorer"""" -Minutes 180 -InstanceName SetUpdateMaxExecutionTime 



