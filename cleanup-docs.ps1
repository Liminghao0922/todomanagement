# Clean up redundant markdown files
# Remove files with duplicate content to keep the project clean

Write-Host "Starting cleanup of redundant markdown documents..." -ForegroundColor Yellow
Write-Host ""

$filesToDelete = @(
    ".github/WORKFLOW_SUMMARY.md",
    ".github/README.md",
    "PROJECT_SUMMARY.md",
    "infra/QUICK_REFERENCE.md",
    "infra/DEPLOYMENT_SUMMARY.md",
    "infra/ACR_GITHUB_INTEGRATION.md",
    "infra/POSTGRESQL_ENTRA_ID_AUTH.md"
)

$deletedCount = 0
$skippedCount = 0

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force
        Write-Host "[DELETED] $file" -ForegroundColor Green
        $deletedCount++
    } else {
        Write-Host "[SKIPPED] $file (not found)" -ForegroundColor Gray
        $skippedCount++
    }
}

Write-Host ""
Write-Host "[DONE] Cleanup completed!" -ForegroundColor Green
Write-Host "Deleted: $deletedCount files" -ForegroundColor Green
Write-Host "Skipped: $skippedCount files" -ForegroundColor Gray
Write-Host ""
Write-Host "RETAINED DOCUMENTATION:" -ForegroundColor Cyan
Write-Host "  README.md (main entry)"
Write-Host "  docs/"
Write-Host "    - ARCHITECTURE_GUIDE.md"
Write-Host "    - GITHUB_CONFIG_SETUP.md"
Write-Host "    - ENTRA_ID_SETUP.md"
Write-Host "  .github/"
Write-Host "    - WORKFLOW_SETUP.md"
Write-Host "    - WORKFLOW_QUICK_REFERENCE.md"
Write-Host "  infra/"
Write-Host "    - README.md"
Write-Host "    - DEPLOYMENT_CHECKLIST.md"
Write-Host "  src/web/README.md"
