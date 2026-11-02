$ErrorActionPreference = "Stop"
$tar = Join-Path $env:TEMP "worker-web.tgz"
$hostName = "root@187.127.175.116"

Write-Host "Packing Flutter web build..." -ForegroundColor Cyan
if (Test-Path $tar) { Remove-Item $tar -Force }
tar -czf $tar -C "e:\SIH\Worker\build" web

Write-Host "Enter the VPS password when asked." -ForegroundColor Yellow
scp $tar "${hostName}:~/worker-web.tgz"
ssh $hostName @'
set -e
mkdir -p /root/worker-web
rm -rf /tmp/worker-web-extract
mkdir /tmp/worker-web-extract
tar -xzf /root/worker-web.tgz -C /tmp/worker-web-extract
rm -rf /root/worker-web
mv /tmp/worker-web-extract/web /root/worker-web
rm -f /root/worker-web.tgz
rmdir /tmp/worker-web-extract 2>/dev/null || true
docker rm -f worker-web >/dev/null 2>&1 || true
docker run -d --name worker-web --restart unless-stopped -p 8080:80 -v /root/worker-web:/usr/share/nginx/html:ro nginx:alpine
ufw allow 8080/tcp >/dev/null 2>&1 || true
echo "Worker preview: http://187.127.175.116:8080"
'@

Write-Host "Done. Open http://187.127.175.116:8080" -ForegroundColor Green
Read-Host "Press Enter to close"
