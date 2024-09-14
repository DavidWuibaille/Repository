[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="titre" Height="573.975" Width="668.135">
    <Grid>
        <Button Name="Run" Content="Run" HorizontalAlignment="Left" Margin="12,489,0,0" VerticalAlignment="Top" Width="632" Background="#FF0DAC2C" FontWeight="Bold" BorderBrush="#FFFDBABA" OpacityMask="Black" Height="39"/>
    </Grid>
</Window>

    

    
'@
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}




$Run.add_Click({


})

# Display UI object
$Form.ShowDialog() | out-null