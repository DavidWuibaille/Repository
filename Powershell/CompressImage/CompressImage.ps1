# Path of the folder to analyze
$folderPath = "\\192.168.0.3\web\blog\wp-content\uploads-webpc"

# Function to compress images for web use
function Compress-Image {
    param (
        [string]$imagePath
    )

    # Create a temporary path for the compressed version
    $tempImagePath = "$($imagePath).temp"

    # Compress the image based on its type
    if ($imagePath -match "\.png$") {
        # PNG compression via ImageMagick (adjusting for better web performance)
        & magick $imagePath -strip -quality 85 -define png:compression-level=9 $tempImagePath
    } elseif ($imagePath -match "\.webp$") {
        # WebP lossy compression for web (adjusting quality for web use)
        & magick $imagePath -strip -quality 75 $tempImagePath
    } else {
        Write-Host "Unsupported format: $imagePath"
        return
    }

    # Compare the file sizes
    $originalSize = (Get-Item $imagePath).Length
    $compressedSize = (Get-Item $tempImagePath).Length

    if ($compressedSize -lt $originalSize) {
        # Replace the original image with the compressed version if it's smaller
        Move-Item $tempImagePath $imagePath -Force
        Write-Host "Compression successful: $imagePath ($originalSize -> $compressedSize bytes)"
    } else {
        # Delete the temporary image if it's not smaller
        Remove-Item $tempImagePath
        Write-Host "No size reduction: $imagePath"
    }
}

# Get all PNG and WebP files in the folder and subfolders
$images = Get-ChildItem -Path $folderPath -Recurse -Include *.png, *.webp

# Loop to compress each image
foreach ($image in $images) {
    Compress-Image -imagePath $image.FullName
}

Write-Host "Compression completed."
