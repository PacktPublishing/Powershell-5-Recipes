Configuration MyWebSite01 {

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node WebServer01 {
        
        File HelloWorldHtml {
            DestinationPath = 'c:\inetpub\wwwroot\index.html'
            Ensure = 'Present'
            Type = 'File'
            Contents = '<html><head></head><body><h1>Hello from DSC</h1></body></html>'
        }
    }
}