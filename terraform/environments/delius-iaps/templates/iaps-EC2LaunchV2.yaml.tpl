version: 1.0
tasks:
- task: writeFile
  inputs:
  - frequency: always
    destination: C:\tools\nginx.conf
    content: |-
      worker_processes auto;

      error_log  logs/error.log;

      events {
        worker_connections  1024;
      }

      http {
        include              mime.types;
        default_type         application/octet-stream;
        sendfile             on;
        client_max_body_size 10M;
        keepalive_timeout    65;

        server {
          listen 80;
          server_name localhost;

          allow 127.0.0.1;
          deny  all;

          # Proxy requests to the NDelius Interface
          location ^~ /NDeliusIAPS {
            proxy_pass        https://${ndelius_interface_url}$request_uri;
            proxy_ssl_ciphers ALL:!aNULL:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
          }

          # Proxy all other requests IM servers
          location / {
            proxy_pass                    https://${im_interface_url};
            proxy_ssl_verify_depth        2;
            proxy_ssl_verify              on;
            proxy_ssl_server_name         on;
            proxy_ssl_protocols           TLSv1.3;
            proxy_ssl_ciphers             EECDH+CHACHA20:EECDH+AESGCM:EECDH+AES;
            proxy_http_version            1.1;
            client_max_body_size          10m;
          }
        }
      }

- task: executeScript
  inputs:
  - frequency: always
    type: powershell
    runAs: admin
    content: |-
      # Move previously templated config file to correct location
      Move-Item -Path 'C:\tools\nginx.conf' -Destination (Resolve-Path 'C:\tools\nginx-*\conf\nginx.conf').Path -Force
      Restart-Service -Name nginx
  - frequency: once
    type: powershell
    runAs: localSystem
    content: |-
      $ConfirmPreference="none"
      $ErrorActionPreference="Stop"
      $VerbosePreference="Continue"
      Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force # Needed for PS module installs
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
      Install-Module -Name AWSPowerShell -MinimumVersion 4.1.196 # Current latest version as of 3/1/23 is 4.1.196
  - frequency: always
    type: powershell
    runAs: admin
    content: |-
      # Join computer to domain if not already joined
      if (! ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) ) {
        # Server is not joined to the domain
        $secretName = "${delius_iaps_ad_password_secret_name}"
        $domainJoinUserName = "Admin"
        $domainJoinPassword = ConvertTo-SecureString((Get-SECSecretValue -SecretId $secretName).SecretString) -AsPlainText -Force
        $domainJoinCredential = New-Object System.Management.Automation.PSCredential($domainJoinUserName, $domainJoinPassword)
        $token = invoke-restmethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds"=3600} -Method PUT -Uri http://169.254.169.254/latest/api/token
        $instanceId = invoke-restmethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -uri http://169.254.169.254/latest/meta-data/instance-id
        Add-Computer -DomainName "${delius_iaps_ad_domain_name}" -Credential $domainJoinCredential -NewName $instanceId -Force
        exit 3010 # Reboot instance, see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2launch-v2-settings.html#ec2launch-v2-exit-codes-reboots
      }
  - frequency: once
    type: powershell
    runAs: admin
    content: |-
      # Configure IM Interface
      $ErrorActionPreference = "Stop"
      $VerbosePreference = "Continue"

      $IMConfigFile = "C:\Program Files (x86)\I2N\IapsIMInterface\Config\IMIAPS.xml"
      $configXML = [xml](Get-Content $IMConfigFile)
      $configXML.DLLDEF.IAPSORACLE.USER = (Get-SSMParameter -Name "/IMInterface/IAPSOracle/user" -WithDecryption $true).Value
      $configXML.DLLDEF.IAPSORACLE.PASSWORD = (Get-SSMParameter -Name "/IMInterface/IAPSOracle/password" -WithDecryption $true).Value
      $configXML.save($IMConfigFile)

      $service = Restart-Service -Name IMIapsInterfaceWinService -Force -PassThru
      if ($service.Status -match "Running") {
          Write-Host('Restart of IMIapsInterfaceWinService successful')
      } else {
          Write-Host('Error - Failed to restart IMIapsInterfaceWinService - see logs')
          Exit 1
      }