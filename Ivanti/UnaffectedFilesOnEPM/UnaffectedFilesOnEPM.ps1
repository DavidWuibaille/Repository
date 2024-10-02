Function CompareHttpWithBDD {
	Param
	(
		[String]$WebShare,
		[String]$FileWithPath
	)
	$inf = Get-Content ($FileWithPath)
	
	Import-Module BitsTransfer	
	$WebShare = $WebShare.replace('%20',' ')
	$SiteWeb = Invoke-WebRequest $WebShare -UseBasicParsing
	$Links = $SiteWeb.links
	foreach ($link in $Links) {
		$sublink  = $link.innerText
		$sublink2 = $link.href
		$sublink3 = $link.outerHTML
		if (($sublink3 -notlike "*Parent Directory*") -and ($sublink3 -notlike "*C=*") -and ($sublink3 -notlike "*@eaDir*"))  {
			if ($sublink2 -like "*/")  {
				if ($sublink2 -like "/*") { 
					$parentFolder = $sublink2 | split-path -parent
					$parentFolder = $parentFolder.replace("\","/")
					$parentFolder = $parentFolder+"/"
					$sublink2 = $sublink2.replace($parentFolder,"")
				}
				$sublink2 = $sublink2.replace("/","")	
				$newwebsite  = $WebShare+$sublink2+"/"
				$newwebsite = $newwebsite.replace('%20',' ')
			
				$findpath = 0		
				Foreach ( $line in $inf ) {
					if ($line -like "$newwebsite*") { 
						$findpath = 1
					} 
				}

				if ($findpath -eq 1) {
					#Write-host "OK"
				} Else {
					Write-host "Missing:$newwebsite"
				}	
			} 
		} 
	}
}


$FileWithPath = "$PSScriptRoot\PackagePath.txt"
if (test-path $FileWithPath ) { Remove-item $FileWithPath  -Force -Recurse }

#-------------------------- connecteur SQL ----------------------------------
$dataSource = "ivanr0mql01.cvojoayc2fxr.eu-west-1.rds.amazonaws.com"
$user = "read"
$PassSQL = 'Pass1!'
$database = "EPM2022"
$connectionString = "Server=$dataSource;uid=$user; pwd=$PassSQL;Database=$database;Integrated Security=False;"
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()


#------------------------ Query -----------------------------------------------------
$query = "SELECT * FROM  [dbo].[PACKAGE]"
$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$Packages = new-object System.Data.DataTable
$Packages.Load($result)

$query = "SELECT * FROM [dbo].[PACKAGE_FILES_HASH]"
$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$FilesHash = new-object System.Data.DataTable
$FilesHash.Load($result)

# Generate DB
foreach ($Package in $Packages) {
	$PackageName 		= $Package.NAME
	$PackageInstall		= $Package.INSTALL
	$PackageFileHashIDN = $Package.PACKAGE_FILES_HASH_IDN

	If ($PackageInstall -eq 1) { #Package reelle <> bundle 
		foreach ($FileHash in $FilesHash) {
			$FileHashIDN  = $FileHash.PACKAGE_FILES_HASH_IDN
			$FileHashPath = $FileHash.FULL_PATH
			
			if ($PackageFileHashIDN -eq $FileHashIDN) {
				if ($FileHashPath -ne "") { $FileHashPath | Out-File -FilePath $FileWithPath -Append }
				write-host $FileHashPath
			}
		}
	}
}


CompareHttpWithBDD -WebShare "http://EPM2021.leblogosd.lan/lan_common/" -FileWithPath "$PSScriptRoot\PackagePath.txt"
CompareHttpWithBDD -WebShare "http://EPM2021.leblogosd.lan/Lan_RetailDecathlon/" -FileWithPath "$PSScriptRoot\PackagePath.txt"









