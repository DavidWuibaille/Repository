
#-------------------------- connecteur SQL ----------------------------------
$dataSource = "sql.leblogosd.lan"
$user = "compteSQL"
$PassSQL = 'Password'
$database = "EPM2021"
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


$PackageError = 0

foreach ($Package in $Packages) {
	$PackageName 		= $Package.NAME
	$PackageInstall		= $Package.INSTALL
	$PackageFileHashIDN = $Package.PACKAGE_FILES_HASH_IDN

		foreach ($FileHash in $FilesHash) {
			$FileHashIDN  = $FileHash.PACKAGE_FILES_HASH_IDN
			$FileHashPath = $FileHash.FULL_PATH
			
			if ($PackageFileHashIDN -eq $FileHashIDN) {
				If ($FileHashPath -like "http*") {
					try {
						$Request = Invoke-WebRequest -uri $FileHashPath
					} Catch {
						$PackageError = $PackageError+1
						If ($PackageInstall -eq 1) { #Package reelle <> bundle 
						write-host "MISSING : $PackageName => $FileHashPath"
					}
				}
				
				If ($FileHashPath -like "\\*") {
					If (Test-path $FileHashPath) {
					} Else {
						$PackageError = $PackageError+1
						write-host "MISSING : $PackageName => $FileHashPath"
					}
				}
			}
		}
		
	}
}




