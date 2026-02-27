on run
	set homeDir to do shell script "/bin/bash -lc 'printf %s \"$HOME\"'"
	set projectDir to homeDir & "/longwei-dev"
	set deployScript to projectDir & "/scripts/deploy-site.sh"
	set envFile to homeDir & ".config/longwei-site/deploy.env"
	set logDir to homeDir & ".cache/longwei-site"
	
	try
		do shell script "/bin/mkdir -p " & quoted form of logDir
	on error
		display dialog "无法创建日志目录: " & logDir buttons {"好"} default button "好"
		return
	end try
	
	if (do shell script "/usr/bin/test -f " & quoted form of deployScript & " && echo ok || echo no") is "no" then
		display dialog "找不到发布脚本: " & deployScript & return & return & "请确认项目目录在: " & projectDir buttons {"好"} default button "好"
		return
	end if
	
	if (do shell script "/usr/bin/test -f " & quoted form of envFile & " && echo ok || echo no") is "no" then
		display dialog "找不到配置文件: " & envFile & return & return & "请先运行: ./scripts/setup-site-env.sh" buttons {"好"} default button "好"
		return
	end if
	
	set ts to do shell script "/bin/date +%Y%m%d-%H%M%S"
	set logFile to logDir & "/deploy-app-" & ts & ".log"
	set runCmd to "/bin/bash -lc " & quoted form of ("/bin/bash " & quoted form of deployScript & " > " & quoted form of logFile & " 2>&1")
	
	try
		do shell script runCmd
		display notification "网站发布成功" with title "longwei.org.cn"
		display dialog "发布成功" & return & "日志文件: " & logFile buttons {"好"} default button "好"
	on error errMsg number errNum
		set tailOut to ""
		try
			set tailOut to do shell script "/usr/bin/tail -n 30 " & quoted form of logFile
		end try
		display dialog "发布失败 (错误码 " & errNum & ")" & return & return & "最近日志:" & return & tailOut & return & return & "完整日志: " & logFile buttons {"好"} default button "好"
	end try
end run
