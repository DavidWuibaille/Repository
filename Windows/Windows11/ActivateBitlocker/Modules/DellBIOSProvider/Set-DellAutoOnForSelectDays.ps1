##########################################################################
# DELL PROPRIETARY INFORMATION
#
# This software is confidential.  Dell Inc., or one of its subsidiaries, has supplied this
# software to you under the terms of a license agreement,nondisclosure agreement or both.
# You may not copy, disclose, or use this software except in accordance with those terms.
#
# Copyright 2020 Dell Inc. or its subsidiaries.  All Rights Reserved.
#
# DELL INC. MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE SUITABILITY OF THE SOFTWARE,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.
# DELL SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING,
# MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES.
#
#
#
##########################################################################

function Set-DellAutoOnForSelectDays {
<#
  .Synopsis 
    Configures the system's auto-on capabilities that control individual days
  .Description
    This CmdLet sets the Auto-on to select days and enables or disables the individual days
    to automatically power on the system on a pre fixed .
	If a BIOS password (Admin or System password) is set, supply it using the -Password parameter. 
  .Example
    Set-DellAutoonForSelectDays -Sunday "Enabled" -Monday "Disabled" -password $Password
  .Example
	Set-DellAutoonForSelectDays -Tuesday "Enabled"
  .Example
    Set-DellAutoOnForSelectDays -verbose
#>
[CmdletBinding()]
param(  
    [Alias("Sun")][System.String] $Sunday,
    [Alias("Mon")][System.String] $Monday,
    [Alias("Tue")][System.String] $Tuesday,
    [Alias("Wed")][System.String] $Wednesday,
    [Alias("Thu")][System.String] $Thursday,
    [Alias("Fri")][System.String] $Friday,
    [Alias("Sat")][System.String] $Saturday,
    [Alias("pw")][Parameter(Mandatory=$false)][System.String] $Password
  
 )

 BEGIN { 
        Write-Output "Set-DellAutoOnForSelectDays"
 }
 PROCESS {
    #the process block is called for each item in the pipeline and you can reference it via $_
    #Write-Output "in process"

    $pathToPowerManagement = 'DellSmbios' + ':\' + 'PowerManagement'
    
    
    $isAdminPWSet  = Get-Item -path DellSmbios:\Security\IsAdminPasswordSet
    $issystemPWSet = Get-Item -path DellSmbios:\Security\IsSystemPasswordSet

    if (($isAdminPWSet.CurrentValue -match 'True') -or ($issystemPWSet.CurrentValue -match 'True')) 
    {
        if ([string]::IsNullOrEmpty($Password)){
        Write-Warning "Specify the password using -password."
        return
        }
    }

    
    if ($Password){
        Set-Item -path $pathToPowerManagement\AutoOn -value "SelectDays" -password $Password -ErrorVariable ev
    }
    else{   Set-Item -path $pathToPowerManagement\AutoOn -value "SelectDays" -ErrorVariable ev}

	if ($ev){
              Write-Warning "$ev Error occured in $($ev.InvocationInfo.ScriptName)"  
			  return
	}		
	
    if ($PSBoundParameters.ContainsKey('Sunday')) {
        if ($password){    
                Set-Item -path DellSmbios:\PowerManagement\AutoOnSun -value $Sunday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnSun -value $Sunday -ErrorVariable ev}
        
    }
    if ($PSBoundParameters.ContainsKey('Monday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnMon -value $Monday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnMon -value $Monday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Tuesday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnTue -value $Tuesday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnTue -value $Tuesday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Wednesday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnWed -value $Wednesday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnWed -value $Wednesday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Thursday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnThur -value $Thursday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnThur -value $Thursday -ErrorVariable ev}
    }
    if ($PSBoundParameters.ContainsKey('Friday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnFri -value $Friday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnFri -value $Friday -ErrorVariable ev}
    }
     if ($PSBoundParameters.ContainsKey('Saturday')) {
         if ($password){ 
            Set-Item -path $pathToPowerManagement\AutoOnSat -value $Saturday -password $Password -ErrorVariable ev
         }
         else {Set-Item -path DellSmbios:\PowerManagement\AutoOnSat -value $Saturday -ErrorVariable ev}
    }
    if ($ev){
              Write-Warning "$ev Error occured in $($ev.InvocationInfo.ScriptName)"    		
	}			
  }
  END{}

  }


# SIG # Begin signature block
# MIIkoAYJKoZIhvcNAQcCoIIkkTCCJI0CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD1D2K0YTXuJHDy
# U75BbgwisPDfAeiOq4I0PwKtFyrKyaCCExYwggXfMIIEx6ADAgECAhBOQOQ3VO3m
# jAAAAABR05R/MA0GCSqGSIb3DQEBCwUAMIG+MQswCQYDVQQGEwJVUzEWMBQGA1UE
# ChMNRW50cnVzdCwgSW5jLjEoMCYGA1UECxMfU2VlIHd3dy5lbnRydXN0Lm5ldC9s
# ZWdhbC10ZXJtczE5MDcGA1UECxMwKGMpIDIwMDkgRW50cnVzdCwgSW5jLiAtIGZv
# ciBhdXRob3JpemVkIHVzZSBvbmx5MTIwMAYDVQQDEylFbnRydXN0IFJvb3QgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkgLSBHMjAeFw0yMTA1MDcxNTQzNDVaFw0zMDEx
# MDcxNjEzNDVaMGkxCzAJBgNVBAYTAlVTMRYwFAYDVQQKDA1FbnRydXN0LCBJbmMu
# MUIwQAYDVQQDDDlFbnRydXN0IENvZGUgU2lnbmluZyBSb290IENlcnRpZmljYXRp
# b24gQXV0aG9yaXR5IC0gQ1NCUjEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQCngY/3FEW2YkPy2K7TJV5IT1G/xX2fUBw10dZ+YSqUGW0nRqSmGl33VFFq
# gCLGqGZ1TVSDyV5oG6v2W2Swra0gvVTvRmttAudFrnX2joq5Mi6LuHccUk15iF+l
# OhjJUCyXJy2/2gB9Y3/vMuxGh2Pbmp/DWiE2e/mb1cqgbnIs/OHxnnBNCFYVb5Cr
# +0i6udfBgniFZS5/tcnA4hS3NxFBBuKK4Kj25X62eAUBw2DtTwdBLgoTSeOQm3/d
# vfqsv2RR0VybtPVc51z/O5uloBrXfQmywrf/bhy8yH3m6Sv8crMU6UpVEoScRCV1
# HfYq8E+lID1oJethl3wP5bY9867DwRG8G47M4EcwXkIAhnHjWKwGymUfe5SmS1dn
# DH5erXhnW1XjXuvH2OxMbobL89z4n4eqclgSD32m+PhCOTs8LOQyTUmM4OEAwjig
# nPqEPkHcblauxhpb9GdoBQHNG7+uh7ydU/Yu6LZr5JnexU+HWKjSZR7IH9Vybu5Z
# HFc7CXKd18q3kMbNe0WSkUIDTH0/yvKquMIOhvMQn0YupGaGaFpoGHApOBGAYGuK
# Q6NzbOOzazf/5p1nAZKG3y9I0ftQYNVc/iHTAUJj/u9wtBfAj6ju08FLXxLq/f0u
# DodEYOOp9MIYo+P9zgyEIg3zp3jak/PbOM+5LzPG/wc8Xr5F0wIDAQABo4IBKzCC
# AScwDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQEwHQYDVR0lBBYw
# FAYIKwYBBQUHAwMGCCsGAQUFBwMIMDsGA1UdIAQ0MDIwMAYEVR0gADAoMCYGCCsG
# AQUFBwIBFhpodHRwOi8vd3d3LmVudHJ1c3QubmV0L3JwYTAzBggrBgEFBQcBAQQn
# MCUwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLmVudHJ1c3QubmV0MDAGA1UdHwQp
# MCcwJaAjoCGGH2h0dHA6Ly9jcmwuZW50cnVzdC5uZXQvZzJjYS5jcmwwHQYDVR0O
# BBYEFIK61j2Xzp/PceiSN6/9s7VpNVfPMB8GA1UdIwQYMBaAFGpyJnrQHu995ztp
# UdRsjZ+QEmarMA0GCSqGSIb3DQEBCwUAA4IBAQAfXkEEtoNwJFMsVXMdZTrA7LR7
# BJheWTgTCaRZlEJeUL9PbG4lIJCTWEAN9Rm0Yu4kXsIBWBUCHRAJb6jU+5J+Nzg+
# LxR9jx1DNmSzZhNfFMylcfdbIUvGl77clfxwfREc0yHd0CQ5KcX+Chqlz3t57jpv
# 3ty/6RHdFoMI0yyNf02oFHkvBWFSOOtg8xRofcuyiq3AlFzkJg4sit1Gw87kVlHF
# VuOFuE2bRXKLB/GK+0m4X9HyloFdaVIk8Qgj0tYjD+uL136LwZNr+vFie1jpUJuX
# bheIDeHGQ5jXgWG2hZ1H7LGerj8gO0Od2KIc4NR8CMKvdgb4YmZ6tvf6yK81MIIG
# gzCCBGugAwIBAgIQNa+3e500H2r8j4RGqzE1KzANBgkqhkiG9w0BAQ0FADBpMQsw
# CQYDVQQGEwJVUzEWMBQGA1UECgwNRW50cnVzdCwgSW5jLjFCMEAGA1UEAww5RW50
# cnVzdCBDb2RlIFNpZ25pbmcgUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAt
# IENTQlIxMB4XDTIxMDUwNzE5MTk1MloXDTQwMTIyOTIzNTkwMFowYzELMAkGA1UE
# BhMCVVMxFjAUBgNVBAoTDUVudHJ1c3QsIEluYy4xPDA6BgNVBAMTM0VudHJ1c3Qg
# RXh0ZW5kZWQgVmFsaWRhdGlvbiBDb2RlIFNpZ25pbmcgQ0EgLSBFVkNTMjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL69pznJpX3sXWXx9Cuph9DnrRrF
# GjsYzuGhUY1y+s5YH1y4JEIPRtUxl9BKTeObMMm6l6ic/kU2zyeA53u4bsEkt9+n
# dNyF8qMkWEXMlJQ7AuvEjXxG9VxmguOkwdMfrG4MUyMO1Dr62kLxg1RfNTJW8rV4
# m1cASB6pYWEnDnMDQ7bWcJL71IWaMMaz5ppeS+8dKthmqxZG/wvYD6aJSgJRV0E8
# QThOl8dRMm1njmahXk2fNSKv1Wq3f0BfaDXMafrxBfDqhabqMoXLwcHKg2lFSQbc
# CWy6SWUZjPm3NyeMZJ414+Xs5wegnahyvG+FOiymFk49nM8I5oL1RH0owL2JrWwv
# 3C94eRHXHHBL3Z0ITF4u+o29p91j9n/wUjGEbjrY2VyFRJ5jBmnQhlh4iZuHu1gc
# pChsxv5pCpwerBFgal7JaWUu7UMtafF4tzstNfKqT+If4wFvkEaq1agNBFegtKzj
# bb2dGyiAJ0bH2qpnlfHRh3vHyCXphAyPiTbSvjPhhcAz1aA8GYuvOPLlk4C/xsOr
# e5PEPZ257kV2wNRobzBePLQ2+ddFQuASBoDbpSH85wV6KI20jmB798i1SkesFGaX
# oFppcjFXa1OEzWG6cwcVcDt7AfynP4wtPYeM+wjX5S8Xg36Cq08J8inhflV3ZZQF
# HVnUCt2TfuMUXeK7AgMBAAGjggErMIIBJzASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
# A1UdDgQWBBTOiU+CUaoVooRiyjEjYdJh+/j+eDAfBgNVHSMEGDAWgBSCutY9l86f
# z3Hokjev/bO1aTVXzzAzBggrBgEFBQcBAQQnMCUwIwYIKwYBBQUHMAGGF2h0dHA6
# Ly9vY3NwLmVudHJ1c3QubmV0MDEGA1UdHwQqMCgwJqAkoCKGIGh0dHA6Ly9jcmwu
# ZW50cnVzdC5uZXQvY3NicjEuY3JsMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
# BggrBgEFBQcDAzBEBgNVHSAEPTA7MDAGBFUdIAAwKDAmBggrBgEFBQcCARYaaHR0
# cDovL3d3dy5lbnRydXN0Lm5ldC9ycGEwBwYFZ4EMAQMwDQYJKoZIhvcNAQENBQAD
# ggIBAD4AVLgq849mr2EWxFiTZPRBi2RVjRs1M6GbkdirRsqrX7y+fnDk0tcHqJYH
# 14bRVwoI0NB4Tfgq37IE85rh13zwwQB6wUCh34qMt8u0HQFh8piapt24gwXKqSwW
# 3JwtDv6nl+RQqZeVwUsqjFHjxALga3w1TVO8S5QTi1MYFl6mCqe4NMFssess5DF9
# DCzGfOGkVugtdtWyE3XqgwCuAHfGb6k97mMUgVAW/FtPEhkOWw+N6kvOBkyJS64g
# zI5HpnXWZe4vMOhdNI8fgk1cQqbyFExQIJwJonQkXDnYiTKFPK+M5Wqe5gQ6pRP/
# qh3NR0suAgW0ao/rhU+B7wrbfZ8pj6XCP1I4UkGVO7w+W1QwQiMJY95QjYk1Rfqr
# uA+Poq17ehGT8Y8ohHtoeUdq6GQpTR/0HS9tHsiUhjzTWpl6a3yrNfcrOUtPuT8W
# ku8pjI2rrAEazHFEOctAPiASzghw40f+3IDXCADRC2rqIbV5ZhfpaqpW3c0VeLED
# wBStPkcYde0KU0syk83/gLGQ1hPl5EF4Iu1BguUO37DOlSFF5osB0xn39CtVrNlW
# c2MQ4LigbctUlpigmSFRBqqmDDorY8t52kO50hLM3o9VeukJ8+Ka0yXBezaS2uDl
# UmfN4+ZUCqWd1HOj0y9dBmSFA3d/YNjCvHTJlZFot7d+YRl1MIIGqDCCBJCgAwIB
# AgIQAe4UxLGsyd7P5PzHxoWYOTANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJV
# UzEWMBQGA1UEChMNRW50cnVzdCwgSW5jLjE8MDoGA1UEAxMzRW50cnVzdCBFeHRl
# bmRlZCBWYWxpZGF0aW9uIENvZGUgU2lnbmluZyBDQSAtIEVWQ1MyMB4XDTIxMTEx
# ODIzMDczOVoXDTIyMTIxMjIzMDczOVowgdgxCzAJBgNVBAYTAlVTMQ4wDAYDVQQI
# EwVUZXhhczETMBEGA1UEBxMKUm91bmQgUm9jazETMBEGCysGAQQBgjc8AgEDEwJV
# UzEZMBcGCysGAQQBgjc8AgECEwhEZWxhd2FyZTERMA8GA1UEChMIRGVsbCBJbmMx
# HTAbBgNVBA8TFFByaXZhdGUgT3JnYW5pemF0aW9uMR0wGwYDVQQLExRDbGllbnQg
# UHJvZHVjdCBHcm91cDEQMA4GA1UEBRMHMjE0MTU0MTERMA8GA1UEAxMIRGVsbCBJ
# bmMwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCcnoY5qeZB6eKg6TA0
# u4F4EOiljq6evB9RAQVNoxAiM/LCe2DdMC6NJZ65D+NvuoqdJOwFfFF4XsDZ1Ejt
# GIKSkFWi4UrgdG/VAh8QUru2zJc7Loun9WlgixCc3+umiC+BepYwkzRwCA6fnXDd
# pn7leFV6+hfTZxLZ+3FM+apPHrCA06ediV7TTqE2D+8OiO2ltOzTMGBSIFd+6QS3
# 9yqKiEFgU6Fj/XrZ/daJ7M3Y9E1HJGcmKB5I+7tO7WMcFXElJiCkXt8MJiKZWf9v
# sQUwz95YEwFHyQq28CIqSwhzTsu1RTr2ntYztWusyggBmeRMOZbpBCPwov/uH3Qg
# p3fss43WHpTOvrrOxy/aNi3l4wiAzE76I/Ormena6Q5KeDDRspg39LMopZqujyB3
# 0n1+MLt7AT+Rn/Wo8QEWmHWTPKxNgDLLGzmUdtwfNgkkBuh9d7QM4RQVm97Q/yCI
# OrVDpGpJic3WcgiWoeBNYGHjml0FQC0Y3wkmgOgUND7xL5ECAwEAAaOCAWAwggFc
# MAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFLo0bmGFz/lpCSH/8Bb/n9HscUq3MB8G
# A1UdIwQYMBaAFM6JT4JRqhWihGLKMSNh0mH7+P54MGcGCCsGAQUFBwEBBFswWTAj
# BggrBgEFBQcwAYYXaHR0cDovL29jc3AuZW50cnVzdC5uZXQwMgYIKwYBBQUHMAKG
# Jmh0dHA6Ly9haWEuZW50cnVzdC5uZXQvZXZjczItY2hhaW4ucDdjMDEGA1UdHwQq
# MCgwJqAkoCKGIGh0dHA6Ly9jcmwuZW50cnVzdC5uZXQvZXZjczIuY3JsMA4GA1Ud
# DwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzBLBgNVHSAERDBCMDcGCmCG
# SAGG+mwKAQIwKTAnBggrBgEFBQcCARYbaHR0cHM6Ly93d3cuZW50cnVzdC5uZXQv
# cnBhMAcGBWeBDAEDMA0GCSqGSIb3DQEBCwUAA4ICAQCeCAC5jie90k3LIkOSD8lh
# F5ljcQDkp7HGkCvIVqNJ0hLHoLTubqURUWOBh0XVln6oGG80NVLVz/NqW4kGpLoC
# ntX/BGb68IbyyEh/uA2ODqRkFfnHhOqtoBlfn6A02/1GbW8Gjuc90MsK89ANVUyo
# g9l4DG+jjVjWpsRu21YypDNwnuHTzjbvl1E85zNDUJgq1P/9lxwvXr/DKQgwHsQs
# /7bflgYQsf2BS0aj1mDvnqUmFOVR6lEdbnxYo2cEmw3Uvx+Zd3oAkP+Cd8uxDn4b
# h+9DhnL+D7NNzbgAnDwB5RAiHp4yCIvHwHE+IZhUEGWLSqph81+oUUDwaeOohdMf
# NA3ZJYd8aSDgldapLuG3kfP91eMDu59AWtdFW1JZ0tGr8I24+LS4NeD6dsdb7RUj
# Z8VsK8S5VDKYyHzxQPYFI78w8wjIKZ9d1M7BrRiQMhg3U3gP9kj4GRVWIjJyxqPx
# JXahtIULNreCnfZzMi0w3QcLt1KwH4hYYQ9sO2EZYOUoZ4wWVodb5NQiM5Ksjmli
# 8262L7zhW5fb9LIzlvNf10z9Ab8nf+QN6dMWqydnHmB0kL6H1i515cE3cmBDo+b2
# QKQFbpI5d2AilrbsD3s9OD2siDrmTj+aFsZ3h/OZB2xiYkewm0QTpFDG5q715634
# kdBK9cjmdy5Y5OJ8+LSZkzGCEOAwghDcAgEBMHcwYzELMAkGA1UEBhMCVVMxFjAU
# BgNVBAoTDUVudHJ1c3QsIEluYy4xPDA6BgNVBAMTM0VudHJ1c3QgRXh0ZW5kZWQg
# VmFsaWRhdGlvbiBDb2RlIFNpZ25pbmcgQ0EgLSBFVkNTMgIQAe4UxLGsyd7P5PzH
# xoWYOTANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3
# DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEV
# MC8GCSqGSIb3DQEJBDEiBCBr0wUseAm9fQtjs5WFSewSjd32GcHUr5RVAV2c/7tC
# CTANBgkqhkiG9w0BAQEFAASCAYCOhWizla85DdxJofzy0zI0ldypjzwcWb0R1FrH
# n038WkCUr/FKnNNWteiRRJvR4AV2urQ5YlA9fiGTaaVhDvDOc9zSTy/RVJcA3RLi
# w+LjT7DKLFkJ4NvuJnb4TaUEmU8+PVtHCt+zRd/PWg41PSYAA/jJqLuFP0iDrz4R
# S/sq9SXllHn533bAd0mnsM969azU8CSq0A99m7Xf3UqGuRrw4DGXdWyPjgsw0eQ8
# 0UA9e2M4hnR/WbVPTZSusbC+/FINMAcQy343QnHw/DGR0quCgQo7uMqbu5LFRKxa
# oLTTzbUl4YzgSDozeBAQvoS9Zvzz/qoeHYDHuprOuaqQkoO3ByUtQ7JMVMt92V5G
# PzYO3lYz/xuRAJST3O945ddXfBLRKfj9EAcgVB8W3jYwxxoz202A0YszR2qtOlzB
# ca29PFOQG7ajuHMDClC2XtEwudLuL+BFEhkc+JLrKjenHmiqCd64kdS968d8OcMI
# jadcRNXIpBB9V/BZxoc3Z+cifwKhgg48MIIOOAYKKwYBBAGCNwMDATGCDigwgg4k
# BgkqhkiG9w0BBwKggg4VMIIOEQIBAzENMAsGCWCGSAFlAwQCATCCAQ4GCyqGSIb3
# DQEJEAEEoIH+BIH7MIH4AgEBBgtghkgBhvhFAQcXAzAxMA0GCWCGSAFlAwQCAQUA
# BCAv93FskkgkYjkkR4AFOYPh/fNw22OUNn/P71NGOgsePwIUcYf3AT7FhIS6rIOg
# X03BZlLYzW8YDzIwMjIwOTI5MTA0MTA0WjADAgEeoIGGpIGDMIGAMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsTFlN5
# bWFudGVjIFRydXN0IE5ldHdvcmsxMTAvBgNVBAMTKFN5bWFudGVjIFNIQTI1NiBU
# aW1lU3RhbXBpbmcgU2lnbmVyIC0gRzOgggqLMIIFODCCBCCgAwIBAgIQewWx1Elo
# UUT3yYnSnBmdEjANBgkqhkiG9w0BAQsFADCBvTELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQLExZWZXJpU2lnbiBUcnVzdCBOZXR3
# b3JrMTowOAYDVQQLEzEoYykgMjAwOCBWZXJpU2lnbiwgSW5jLiAtIEZvciBhdXRo
# b3JpemVkIHVzZSBvbmx5MTgwNgYDVQQDEy9WZXJpU2lnbiBVbml2ZXJzYWwgUm9v
# dCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNjAxMTIwMDAwMDBaFw0zMTAx
# MTEyMzU5NTlaMHcxCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jw
# b3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEoMCYGA1UE
# AxMfU3ltYW50ZWMgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALtZnVlVT52Mcl0agaLrVfOwAa08cawyjwVrhpon
# ADKXak3JZBRLKbvC2Sm5Luxjs+HPPwtWkPhiG37rpgfi3n9ebUA41JEG50F8eRzL
# y60bv9iVkfPw7mz4rZY5Ln/BJ7h4OcWEpe3tr4eOzo3HberSmLU6Hx45ncP0mqj0
# hOHE0XxxxgYptD/kgw0mw3sIPk35CrczSf/KO9T1sptL4YiZGvXA6TMU1t/HgNuR
# 7v68kldyd/TNqMz+CfWTN76ViGrF3PSxS9TO6AmRX7WEeTWKeKwZMo8jwTJBG1kO
# qT6xzPnWK++32OTVHW0ROpL2k8mc40juu1MO1DaXhnjFoTcCAwEAAaOCAXcwggFz
# MA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgEAMGYGA1UdIARfMF0w
# WwYLYIZIAYb4RQEHFwMwTDAjBggrBgEFBQcCARYXaHR0cHM6Ly9kLnN5bWNiLmNv
# bS9jcHMwJQYIKwYBBQUHAgIwGRoXaHR0cHM6Ly9kLnN5bWNiLmNvbS9ycGEwLgYI
# KwYBBQUHAQEEIjAgMB4GCCsGAQUFBzABhhJodHRwOi8vcy5zeW1jZC5jb20wNgYD
# VR0fBC8wLTAroCmgJ4YlaHR0cDovL3Muc3ltY2IuY29tL3VuaXZlcnNhbC1yb290
# LmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAoBgNVHREEITAfpB0wGzEZMBcGA1UE
# AxMQVGltZVN0YW1wLTIwNDgtMzAdBgNVHQ4EFgQUr2PWyqNOhXLgp7xB8ymiOH+A
# dWIwHwYDVR0jBBgwFoAUtnf6aUhHn1MS1cLqBzJ2B9GXBxkwDQYJKoZIhvcNAQEL
# BQADggEBAHXqsC3VNBlcMkX+DuHUT6Z4wW/X6t3cT/OhyIGI96ePFeZAKa3mXfSi
# 2VZkhHEwKt0eYRdmIFYGmBmNXXHy+Je8Cf0ckUfJ4uiNA/vMkC/WCmxOM+zWtJPI
# TJBjSDlAIcTd1m6JmDy1mJfoqQa3CcmPU1dBkC/hHk1O3MoQeGxCbvC2xfhhXFL1
# TvZrjfdKer7zzf0D19n2A6gP41P3CnXsxnUuqmaFBJm3+AZX4cYO9uiv2uybGB+q
# ueM6AL/OipTLAduexzi7D1Kr0eOUA2AKTaD+J20UMvw/l0Dhv5mJ2+Q5FL3a5NPD
# 6itas5VYVQR9x5rsIwONhSrS/66pYYEwggVLMIIEM6ADAgECAhB71OWvuswHP6EB
# IwQiQU0SMA0GCSqGSIb3DQEBCwUAMHcxCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRT
# eW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3QgTmV0
# d29yazEoMCYGA1UEAxMfU3ltYW50ZWMgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTAe
# Fw0xNzEyMjMwMDAwMDBaFw0yOTAzMjIyMzU5NTlaMIGAMQswCQYDVQQGEwJVUzEd
# MBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsTFlN5bWFudGVj
# IFRydXN0IE5ldHdvcmsxMTAvBgNVBAMTKFN5bWFudGVjIFNIQTI1NiBUaW1lU3Rh
# bXBpbmcgU2lnbmVyIC0gRzMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCvDoqq+Ny/aXtUF3FHCb2NPIH4dBV3Z5Cc/d5OAp5LdvblNj5l1SQgbTD53R2D
# 6T8nSjNObRaK5I1AjSKqvqcLG9IHtjy1GiQo+BtyUT3ICYgmCDr5+kMjdUdwDLNf
# W48IHXJIV2VNrwI8QPf03TI4kz/lLKbzWSPLgN4TTfkQyaoKGGxVYVfR8QIsxLWr
# 8mwj0p8NDxlsrYViaf1OhcGKUjGrW9jJdFLjV2wiv1V/b8oGqz9KtyJ2ZezsNvKW
# lYEmLP27mKoBONOvJUCbCVPwKVeFWF7qhUhBIYfl3rTTJrJ7QFNYeY5SMQZNlANF
# xM48A+y3API6IsW0b+XvsIqbAgMBAAGjggHHMIIBwzAMBgNVHRMBAf8EAjAAMGYG
# A1UdIARfMF0wWwYLYIZIAYb4RQEHFwMwTDAjBggrBgEFBQcCARYXaHR0cHM6Ly9k
# LnN5bWNiLmNvbS9jcHMwJQYIKwYBBQUHAgIwGRoXaHR0cHM6Ly9kLnN5bWNiLmNv
# bS9ycGEwQAYDVR0fBDkwNzA1oDOgMYYvaHR0cDovL3RzLWNybC53cy5zeW1hbnRl
# Yy5jb20vc2hhMjU2LXRzcy1jYS5jcmwwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgw
# DgYDVR0PAQH/BAQDAgeAMHcGCCsGAQUFBwEBBGswaTAqBggrBgEFBQcwAYYeaHR0
# cDovL3RzLW9jc3Aud3Muc3ltYW50ZWMuY29tMDsGCCsGAQUFBzAChi9odHRwOi8v
# dHMtYWlhLndzLnN5bWFudGVjLmNvbS9zaGEyNTYtdHNzLWNhLmNlcjAoBgNVHREE
# ITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtNjAdBgNVHQ4EFgQUpRMB
# qZ+FzBtuFh5fOzGqeTYAex0wHwYDVR0jBBgwFoAUr2PWyqNOhXLgp7xB8ymiOH+A
# dWIwDQYJKoZIhvcNAQELBQADggEBAEaer/C4ol+imUjPqCdLIc2yuaZycGMv41Up
# ezlGTud+ZQZYi7xXipINCNgQujYk+gp7+zvTYr9KlBXmgtuKVG3/KP5nz3E/5jMJ
# 2aJZEPQeSv5lzN7Ua+NSKXUASiulzMub6KlN97QXWZJBw7c/hub2wH9EPEZcF1rj
# pDvVaSbVIX3hgGd+Yqy3Ti4VmuWcI69bEepxqUH5DXk4qaENz7Sx2j6aescixXTN
# 30cJhsT8kSWyG5bphQjo3ep0YG5gpVZ6DchEWNzm+UgUnuW/3gC9d7GYFHIUJN/H
# ESwfAD/DSxTGZxzMHgajkF9cVIs+4zNbgg/Ft4YCTnGf6WZFP3YxggJaMIICVgIB
# ATCBizB3MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xHzAdBgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxKDAmBgNVBAMTH1N5
# bWFudGVjIFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEHvU5a+6zAc/oQEjBCJBTRIw
# CwYJYIZIAWUDBAIBoIGkMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAcBgkq
# hkiG9w0BCQUxDxcNMjIwOTI5MTA0MTA0WjAvBgkqhkiG9w0BCQQxIgQgTuY66V5x
# F0niWm4tTZjAvB41ruKWoD0bnJt8Zvxyaf0wNwYLKoZIhvcNAQkQAi8xKDAmMCQw
# IgQgxHTOdgB9AjlODaXk3nwUxoD54oIBPP72U+9dtx/fYfgwCwYJKoZIhvcNAQEB
# BIIBAIT1L54dlnPM940R8DVBctG26fHaGGbo5jfUmJ+cj0j3qh6Db0t7XExXNw/F
# ISiXzQZOcyESLRKp/uLAuSFMU+7Ei92N2+lQjyrfjPCXrQhDwz193hnQVfBeOBBy
# T4RwwFtgD8SoG7fjWc0Mft7xfuw9157woIkB1oHkQoPv/XPCUqYEzzAX51u4VkJ8
# hOxtOJXm799kw69MTjb6XMK883b9KoM9HAT/+yFp0V13AQwkQwgINEUp7Dwj9GWd
# nA7JySynq1pzpd7+nXnWRhbXjEB7hLBwZIoBQo2btttL1WipJYAWjLoVBgxIdo33
# 3KFS0s+gBRHt275d3In1z0KcKFU=
# SIG # End signature block
