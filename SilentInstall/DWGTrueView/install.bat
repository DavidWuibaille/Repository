IF not exist C:\exploit\package MD C:\exploit\package
rd /S /Q C:\exploit\package\DWGTrueView_2018_FRA
rd /S /Q C:\exploit\package\DWGTrueView_2022_FRA
"C:\Program Files\7-Zip\7z.exe" x "%~dp0DWGTrueView_2022_French_64bit_dlm.7z" -oC:\exploit\package\DWGTrueView_2022_FRA
"C:\exploit\package\DWGTrueView_2022_FRA\setup.exe" -q

