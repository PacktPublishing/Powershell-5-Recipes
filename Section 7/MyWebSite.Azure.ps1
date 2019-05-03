Configuration MyWebSite {
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xWebAdministration'

    Node WebServer {
        File HelloWorldHtml {
            DestinationPath = 'c:\inetpub\wwwroot\index.html'
            Ensure = 'Present'
            Type = 'File'
            Contents = '<html><head></head><body><h1>Hello from DSC</h1></body></html>'
        }

        WindowsFeature IIS {
            Ensure = 'Present'
            Name = 'Web-Server'
        }
    }

    Node NotAWebServer {
        WindowsFeature IIS {
            Ensure = 'Absent'
            Name = 'Web-Server'
        }
    }
}