$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Server started at http://localhost:$port/"
Write-Host "Press Ctrl+C to stop."

try {
    while ($listener.IsListening) {
        $context = $listener.GetContextAsync().Result
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath
        if ($path -eq "/") { $path = "/index.html" }
        
        # Prevent directory traversal
        $normalizedPath = $path.TrimStart('/').Replace('/', '\')
        $localPath = Join-Path $PWD $normalizedPath
        
        if ($localPath.StartsWith($PWD.Path) -and (Test-Path $localPath -PathType Leaf)) {
            $content = [System.IO.File]::ReadAllBytes($localPath)
            $response.ContentLength64 = $content.Length
            
            $ext = [System.IO.Path]::GetExtension($localPath)
            switch ($ext) {
                ".html" { $response.ContentType = "text/html" }
                ".css"  { $response.ContentType = "text/css" }
                ".js"   { $response.ContentType = "application/javascript" }
                ".jpg"  { $response.ContentType = "image/jpeg" }
                ".png"  { $response.ContentType = "image/png" }
                ".gif"  { $response.ContentType = "image/gif" }
                ".svg"  { $response.ContentType = "image/svg+xml" }
                ".mp3"  { $response.ContentType = "audio/mpeg" }
                ".mp4"  { $response.ContentType = "video/mp4" }
                ".pdf"  { $response.ContentType = "application/pdf" }
            }
            
            try {
                $response.OutputStream.Write($content, 0, $content.Length)
            } catch {}
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
}
