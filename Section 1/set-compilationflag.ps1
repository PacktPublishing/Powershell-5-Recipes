$content = [xml](get-content -Path .\Web.config)
$content.configuration.'system.web'.compilation.debug = "false"
$content.Save('web.config')
