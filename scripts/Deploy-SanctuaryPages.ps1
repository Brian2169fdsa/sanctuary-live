<#
.SYNOPSIS
    Deploys all 9 SharePoint pages for the Sanctuary Operations Hub with web parts.

.DESCRIPTION
    Creates 9 modern SharePoint pages using Add-PnPPage and places web parts
    (List, Document Library, Embed, Text, Quick Links, Hero, Power BI) on each
    page according to the Sanctuary Operations Hub spec.

    Pages created:
    1. Home.aspx
    2. CEO-Dashboard.aspx
    3. Clinical-Department.aspx
    4. Admissions-Department.aspx
    5. Marketing-Department.aspx
    6. Business-Development.aspx
    7. Human-Resources.aspx
    8. Administration.aspx
    9. Reentry-Program.aspx

    This script is idempotent — existing pages are skipped unless -Force is set.

.PARAMETER SiteUrl
    Full URL to the Sanctuary Operations Hub site.

.PARAMETER EmbedUrlsFile
    Path to embed-urls.json with KPI dashboard URLs.

.PARAMETER Force
    If set, recreates pages that already exist.

.EXAMPLE
    .\Deploy-SanctuaryPages.ps1 -SiteUrl "https://sanctuaryrecoverycenters48.sharepoint.com/sites/ops-hub-dev"

.NOTES
    Run Deploy-SanctuaryHub.ps1 first to create lists and libraries.
    Required: PnP.PowerShell module, PowerShell 7+
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://sanctuaryrecoverycenters48.sharepoint.com/sites/ops-hub-dev",

    [Parameter(Mandatory = $false)]
    [string]$EmbedUrlsFile = (Join-Path $PSScriptRoot "embed-urls.json"),

    [string]$PowerBIReportUrl = "{POWER_BI_REPORT_URL}",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ============================================================================
# HELPERS
# ============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Yellow
}

function Write-OK {
    param([string]$Message)
    Write-Host "   [OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "   [SKIP] $Message" -ForegroundColor DarkGray
}

function Get-ListId {
    param([string]$ListName)
    $list = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
    if ($list) { return $list.Id.ToString() }
    Write-Warning "List '$ListName' not found — web part will need manual configuration."
    return $null
}

function Ensure-Page {
    <#
    .SYNOPSIS
        Creates a modern page if it doesn't exist. Returns $true if page was created or exists.
    #>
    param(
        [string]$PageName,
        [string]$Title,
        [string]$LayoutType = "Article"
    )

    $existing = Get-PnPPage -Identity $PageName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        Write-Skip "Page '$PageName' already exists (use -Force to recreate)"
        return $existing
    }

    if ($existing -and $Force) {
        Remove-PnPPage -Identity $PageName -Force
        Write-Host "   [DEL] Removed existing page '$PageName'" -ForegroundColor DarkYellow
    }

    $page = Add-PnPPage -Name $PageName -Title $Title -LayoutType $LayoutType -HeaderLayoutType NoImage
    Write-OK "Created page '$PageName'"
    return $page
}

function Add-TextSection {
    <#
    .SYNOPSIS
        Adds a text web part with HTML content to a page section.
    #>
    param(
        [string]$PageName,
        [int]$Section,
        [int]$Column = 1,
        [string]$Html
    )

    Add-PnPPageTextPart -Page $PageName -Section $Section -Column $Column -Text $Html
    Write-OK "Added text web part to $PageName (Section $Section, Column $Column)"
}

function Add-ListWebPart {
    <#
    .SYNOPSIS
        Adds a List web part to a page.
    #>
    param(
        [string]$PageName,
        [int]$Section,
        [int]$Column = 1,
        [string]$ListName
    )

    $listId = Get-ListId -ListName $ListName
    if (-not $listId) { return }

    $webPartProps = @{
        selectedListId   = $listId
        selectedListUrl  = ""
        webRelativeListUrl = "Lists/$($ListName -replace ' ', '%20')"
        isDocumentLibrary = $false
    }

    Add-PnPPageWebPart -Page $PageName -Section $Section -Column $Column `
        -DefaultWebPartType List -WebPartProperties $webPartProps
    Write-OK "Added List web part '$ListName' to $PageName (Section $Section, Column $Column)"
}

function Add-DocLibWebPart {
    <#
    .SYNOPSIS
        Adds a Document Library web part to a page.
    #>
    param(
        [string]$PageName,
        [int]$Section,
        [int]$Column = 1,
        [string]$LibraryName
    )

    $listId = Get-ListId -ListName $LibraryName
    if (-not $listId) { return }

    $webPartProps = @{
        selectedListId     = $listId
        selectedListUrl    = ""
        webRelativeListUrl = $LibraryName
        isDocumentLibrary  = $true
    }

    Add-PnPPageWebPart -Page $PageName -Section $Section -Column $Column `
        -DefaultWebPartType List -WebPartProperties $webPartProps
    Write-OK "Added DocLib web part '$LibraryName' to $PageName (Section $Section, Column $Column)"
}

function Add-EmbedWebPart {
    <#
    .SYNOPSIS
        Adds an Embed web part with an iframe URL.
    #>
    param(
        [string]$PageName,
        [int]$Section,
        [int]$Column = 1,
        [string]$EmbedUrl,
        [string]$Description = ""
    )

    # Embed web part ID
    $embedWebPartId = "490d7c76-1824-45b2-9de3-676421c997fa"

    $jsonProps = @"
{
    "embedCode": "<iframe src='$EmbedUrl' width='100%' height='600' frameborder='0' style='border:0'></iframe>",
    "websiteUrl": "$EmbedUrl",
    "cachedEmbedCode": "",
    "shouldScaleWidth": true,
    "tempState": null
}
"@

    Add-PnPPageWebPart -Page $PageName -Section $Section -Column $Column `
        -Component $embedWebPartId -WebPartProperties ($jsonProps | ConvertFrom-Json -AsHashtable)
    Write-OK "Added Embed web part to $PageName (Section $Section, Column $Column) — $Description"
}

function Add-PowerBIWebPart {
    <#
    .SYNOPSIS
        Adds a Power BI web part with a report URL placeholder.
    #>
    param(
        [string]$PageName,
        [int]$Section,
        [int]$Column = 1,
        [string]$ReportUrl
    )

    $pbiWebPartId = "544dd15b-cf3c-441b-96da-004d5a8cea1d"

    $jsonProps = @"
{
    "reportUrl": "$ReportUrl",
    "reportType": 0
}
"@

    Add-PnPPageWebPart -Page $PageName -Section $Section -Column $Column `
        -Component $pbiWebPartId -WebPartProperties ($jsonProps | ConvertFrom-Json -AsHashtable)
    Write-OK "Added Power BI web part to $PageName (Section $Section)"
}

# ============================================================================
# CONNECT & LOAD EMBED URLS
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Sanctuary Operations Hub — Page Deploy" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Connect-PnPOnline -Url $SiteUrl -Interactive

# Load embed URLs
$embedUrls = @{
    ceo_dashboard       = "https://{GITHUB_PAGES_URL}/CEO-KPIs.html"
    clinical_dashboard  = "https://{GITHUB_PAGES_URL}/Clinical-KPIs.html"
    admissions_dashboard = "https://{GITHUB_PAGES_URL}/Admissions-KPIs.html"
    marketing_dashboard = "https://{GITHUB_PAGES_URL}/Marketing-KPIs.html"
    bd_dashboard        = "https://{GITHUB_PAGES_URL}/BD-KPIs.html"
    hr_dashboard        = "https://{GITHUB_PAGES_URL}/HR-KPIs.html"
    admin_dashboard     = "https://{GITHUB_PAGES_URL}/Admin-KPIs.html"
    reentry_dashboard   = "https://{GITHUB_PAGES_URL}/Reentry-KPIs.html"
}

if (Test-Path $EmbedUrlsFile) {
    $embedUrls = Get-Content $EmbedUrlsFile -Raw | ConvertFrom-Json -AsHashtable
    Write-OK "Loaded embed URLs from $EmbedUrlsFile"
} else {
    Write-Warning "embed-urls.json not found at $EmbedUrlsFile — using placeholder URLs."
}

# ============================================================================
# PAGE 1: HOME
# ============================================================================
Write-Step "Page 1/9: Home"

$page = Ensure-Page -PageName "Home" -Title "Sanctuary Operations Hub"
if ($page) {
    # Section 1: Hero-style branded header
    $heroHtml = @"
<div style="background: linear-gradient(135deg, #e8732a 0%, #d16826 100%); color: white; padding: 40px; border-radius: 8px; text-align: center; margin-bottom: 20px;">
    <h1 style="color: white; font-size: 32px; margin-bottom: 8px;">Sanctuary Recovery Centers</h1>
    <p style="color: #fbe0cc; font-size: 18px; margin-bottom: 4px;">Operations Hub</p>
    <p style="color: #f7c5a3; font-size: 14px; font-style: italic;">True Healing &amp; Continued Care&trade;</p>
</div>
"@
    Add-PnPPageSection -Page "Home" -SectionTemplate OneColumn -Order 1
    Add-TextSection -PageName "Home" -Section 1 -Html $heroHtml

    # Section 2: Quick Links to departments
    $quickLinksHtml = @"
<div style="padding: 20px;">
    <h2 style="color: #323130; margin-bottom: 16px;">Department Pages</h2>
    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px;">
        <a href="CEO-Dashboard.aspx" style="display: block; padding: 16px; background: #fef7f2; border-left: 4px solid #e8732a; border-radius: 4px; text-decoration: none; color: #323130; font-weight: 600;">CEO Dashboard</a>
        <a href="Clinical-Department.aspx" style="display: block; padding: 16px; background: #fef7f2; border-left: 4px solid #e8732a; border-radius: 4px; text-decoration: none; color: #323130; font-weight: 600;">Clinical</a>
        <a href="Admissions-Department.aspx" style="display: block; padding: 16px; background: #fef7f2; border-left: 4px solid #e8732a; border-radius: 4px; text-decoration: none; color: #323130; font-weight: 600;">Admissions</a>
        <a href="Marketing-Department.aspx" style="display: block; padding: 16px; background: #fef7f2; border-left: 4px solid #e8732a; border-radius: 4px; text-decoration: none; color: #323130; font-weight: 600;">Marketing</a>
        <a href="Business-Development.aspx" style="display: block; padding: 16px; background: #fef7f2; border-left: 4px solid #e8732a; border-radius: 4px; text-decoration: none; color: #323130; font-weight: 600;">Business Development</a>
        <a href="Human-Resources.aspx" style="display: block; padding: 16px; background: #fef7f2; border-left: 4px solid #e8732a; border-radius: 4px; text-decoration: none; color: #323130; font-weight: 600;">Human Resources</a>
        <a href="Administration.aspx" style="display: block; padding: 16px; background: #fef7f2; border-left: 4px solid #e8732a; border-radius: 4px; text-decoration: none; color: #323130; font-weight: 600;">Administration</a>
        <a href="Reentry-Program.aspx" style="display: block; padding: 16px; background: #fef7f2; border-left: 4px solid #e8732a; border-radius: 4px; text-decoration: none; color: #323130; font-weight: 600;">Reentry Program</a>
    </div>
</div>
"@
    Add-PnPPageSection -Page "Home" -SectionTemplate OneColumn -Order 2
    Add-TextSection -PageName "Home" -Section 2 -Html $quickLinksHtml

    # Section 3: Welcome message
    $welcomeHtml = @"
<div style="padding: 20px; background: #f3f2f1; border-radius: 8px;">
    <h2 style="color: #323130;">Welcome to the Sanctuary Operations Hub</h2>
    <p>This is the central operations portal for Sanctuary Recovery Centers. Use the navigation above or department links to access dashboards, documents, compliance tracking, and operational data across all facilities.</p>
    <p><strong>Facilities:</strong> 7 residential homes + outpatient clinic serving the greater Phoenix metro area.</p>
    <p><strong>Programs:</strong> Residential, PHP, IOP, Adolescent, Women's Trauma (ASU Partnership), Reentry/Transitional Living</p>
    <p style="color: #605e5c; font-size: 13px; margin-top: 16px;">11645 N Cave Creek Rd, Phoenix, AZ 85020 &bull; sanctuaryrecoverycenters.com</p>
</div>
"@
    Add-PnPPageSection -Page "Home" -SectionTemplate OneColumn -Order 3
    Add-TextSection -PageName "Home" -Section 3 -Html $welcomeHtml

    Set-PnPPage -Identity "Home" -Publish
    Write-OK "Published Home.aspx"
}

# ============================================================================
# PAGE 2: CEO DASHBOARD
# ============================================================================
Write-Step "Page 2/9: CEO Dashboard"

$page = Ensure-Page -PageName "CEO-Dashboard" -Title "CEO Dashboard"
if ($page) {
    # Section 1: KPI Dashboard embed
    Add-PnPPageSection -Page "CEO-Dashboard" -SectionTemplate OneColumn -Order 1
    Add-EmbedWebPart -PageName "CEO-Dashboard" -Section 1 -EmbedUrl $embedUrls.ceo_dashboard -Description "CEO KPI Dashboard"

    # Section 2: Power BI
    Add-PnPPageSection -Page "CEO-Dashboard" -SectionTemplate OneColumn -Order 2
    Add-PowerBIWebPart -PageName "CEO-Dashboard" -Section 2 -ReportUrl $PowerBIReportUrl

    # Section 3: Two columns — Census + Compliance
    Add-PnPPageSection -Page "CEO-Dashboard" -SectionTemplate TwoColumn -Order 3
    Add-ListWebPart -PageName "CEO-Dashboard" -Section 3 -Column 1 -ListName "Facility Census Tracker"
    Add-ListWebPart -PageName "CEO-Dashboard" -Section 3 -Column 2 -ListName "Compliance Audit Calendar"

    # Section 4: CEO Documents
    Add-PnPPageSection -Page "CEO-Dashboard" -SectionTemplate OneColumn -Order 4
    Add-DocLibWebPart -PageName "CEO-Dashboard" -Section 4 -LibraryName "CEO-Documents"

    # Section 5: Two columns — Incidents + Revenue
    Add-PnPPageSection -Page "CEO-Dashboard" -SectionTemplate TwoColumn -Order 5
    Add-ListWebPart -PageName "CEO-Dashboard" -Section 5 -Column 1 -ListName "Incident Reports"
    Add-ListWebPart -PageName "CEO-Dashboard" -Section 5 -Column 2 -ListName "Revenue by Payer"

    Set-PnPPage -Identity "CEO-Dashboard" -Publish
    Write-OK "Published CEO-Dashboard.aspx"
}

# ============================================================================
# PAGE 3: CLINICAL DEPARTMENT
# ============================================================================
Write-Step "Page 3/9: Clinical Department"

$page = Ensure-Page -PageName "Clinical-Department" -Title "Clinical Department"
if ($page) {
    # Section 1: KPI embed
    Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate OneColumn -Order 1
    Add-EmbedWebPart -PageName "Clinical-Department" -Section 1 -EmbedUrl $embedUrls.clinical_dashboard -Description "Clinical KPI Dashboard"

    # Section 2: Census
    Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate OneColumn -Order 2
    Add-ListWebPart -PageName "Clinical-Department" -Section 2 -ListName "Facility Census Tracker"

    # Section 3: Clinical Documents
    Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate OneColumn -Order 3
    Add-DocLibWebPart -PageName "Clinical-Department" -Section 3 -LibraryName "Clinical-Documents"

    # Section 4: Two columns — Incidents + Group Schedule placeholder
    Add-PnPPageSection -Page "Clinical-Department" -SectionTemplate TwoColumn -Order 4
    Add-ListWebPart -PageName "Clinical-Department" -Section 4 -Column 1 -ListName "Incident Reports"

    $groupScheduleHtml = @"
<div style="padding: 16px; background: #fef7f2; border-radius: 8px; border-left: 4px solid #e8732a;">
    <h3 style="color: #323130;">Group Schedule</h3>
    <p style="color: #605e5c;">Embed the group therapy schedule here once hosted. This section will display the weekly group schedule across all facilities.</p>
    <p style="color: #a19f9d; font-size: 12px;">Configure: Replace with Embed web part pointing to hosted Group Schedule HTML.</p>
</div>
"@
    Add-TextSection -PageName "Clinical-Department" -Section 4 -Column 2 -Html $groupScheduleHtml

    Set-PnPPage -Identity "Clinical-Department" -Publish
    Write-OK "Published Clinical-Department.aspx"
}

# ============================================================================
# PAGE 4: ADMISSIONS DEPARTMENT
# ============================================================================
Write-Step "Page 4/9: Admissions Department"

$page = Ensure-Page -PageName "Admissions-Department" -Title "Admissions Department"
if ($page) {
    # Section 1: KPI embed
    Add-PnPPageSection -Page "Admissions-Department" -SectionTemplate OneColumn -Order 1
    Add-EmbedWebPart -PageName "Admissions-Department" -Section 1 -EmbedUrl $embedUrls.admissions_dashboard -Description "Admissions KPI + Funnel"

    # Section 2: Pipeline
    Add-PnPPageSection -Page "Admissions-Department" -SectionTemplate OneColumn -Order 2
    Add-ListWebPart -PageName "Admissions-Department" -Section 2 -ListName "Admissions Pipeline"

    # Section 3: Admissions Documents
    Add-PnPPageSection -Page "Admissions-Department" -SectionTemplate OneColumn -Order 3
    Add-DocLibWebPart -PageName "Admissions-Department" -Section 3 -LibraryName "Admissions-Documents"

    # Section 4: Two columns — Partners + Census
    Add-PnPPageSection -Page "Admissions-Department" -SectionTemplate TwoColumn -Order 4
    Add-ListWebPart -PageName "Admissions-Department" -Section 4 -Column 1 -ListName "Referral Partners"
    Add-ListWebPart -PageName "Admissions-Department" -Section 4 -Column 2 -ListName "Facility Census Tracker"

    Set-PnPPage -Identity "Admissions-Department" -Publish
    Write-OK "Published Admissions-Department.aspx"
}

# ============================================================================
# PAGE 5: MARKETING DEPARTMENT
# ============================================================================
Write-Step "Page 5/9: Marketing Department"

$page = Ensure-Page -PageName "Marketing-Department" -Title "Marketing Department"
if ($page) {
    # Section 1: KPI embed
    Add-PnPPageSection -Page "Marketing-Department" -SectionTemplate OneColumn -Order 1
    Add-EmbedWebPart -PageName "Marketing-Department" -Section 1 -EmbedUrl $embedUrls.marketing_dashboard -Description "Marketing KPI Dashboard"

    # Section 2: Campaigns
    Add-PnPPageSection -Page "Marketing-Department" -SectionTemplate OneColumn -Order 2
    Add-ListWebPart -PageName "Marketing-Department" -Section 2 -ListName "Marketing Campaigns"

    # Section 3: Marketing Documents
    Add-PnPPageSection -Page "Marketing-Department" -SectionTemplate OneColumn -Order 3
    Add-DocLibWebPart -PageName "Marketing-Department" -Section 3 -LibraryName "Marketing-Documents"

    # Section 4: Power BI analytics placeholder
    Add-PnPPageSection -Page "Marketing-Department" -SectionTemplate OneColumn -Order 4
    Add-PowerBIWebPart -PageName "Marketing-Department" -Section 4 -ReportUrl $PowerBIReportUrl

    Set-PnPPage -Identity "Marketing-Department" -Publish
    Write-OK "Published Marketing-Department.aspx"
}

# ============================================================================
# PAGE 6: BUSINESS DEVELOPMENT
# ============================================================================
Write-Step "Page 6/9: Business Development"

$page = Ensure-Page -PageName "Business-Development" -Title "Business Development"
if ($page) {
    # Section 1: KPI embed
    Add-PnPPageSection -Page "Business-Development" -SectionTemplate OneColumn -Order 1
    Add-EmbedWebPart -PageName "Business-Development" -Section 1 -EmbedUrl $embedUrls.bd_dashboard -Description "BD KPI Dashboard"

    # Section 2: Referral Partners
    Add-PnPPageSection -Page "Business-Development" -SectionTemplate OneColumn -Order 2
    Add-ListWebPart -PageName "Business-Development" -Section 2 -ListName "Referral Partners"

    # Section 3: BD Documents
    Add-PnPPageSection -Page "Business-Development" -SectionTemplate OneColumn -Order 3
    Add-DocLibWebPart -PageName "Business-Development" -Section 3 -LibraryName "BD-Documents"

    # Section 4: Marketing Campaigns (filtered view for referral + community)
    Add-PnPPageSection -Page "Business-Development" -SectionTemplate OneColumn -Order 4
    Add-ListWebPart -PageName "Business-Development" -Section 4 -ListName "Marketing Campaigns"

    Set-PnPPage -Identity "Business-Development" -Publish
    Write-OK "Published Business-Development.aspx"
}

# ============================================================================
# PAGE 7: HUMAN RESOURCES
# ============================================================================
Write-Step "Page 7/9: Human Resources"

$page = Ensure-Page -PageName "Human-Resources" -Title "Human Resources"
if ($page) {
    # Section 1: KPI embed
    Add-PnPPageSection -Page "Human-Resources" -SectionTemplate OneColumn -Order 1
    Add-EmbedWebPart -PageName "Human-Resources" -Section 1 -EmbedUrl $embedUrls.hr_dashboard -Description "HR KPI Dashboard"

    # Section 2: Staff Credentials
    Add-PnPPageSection -Page "Human-Resources" -SectionTemplate OneColumn -Order 2
    Add-ListWebPart -PageName "Human-Resources" -Section 2 -ListName "Staff Credential Tracker"

    # Section 3: HR Documents
    Add-PnPPageSection -Page "Human-Resources" -SectionTemplate OneColumn -Order 3
    Add-DocLibWebPart -PageName "Human-Resources" -Section 3 -LibraryName "HR-Documents"

    # Section 4: Training Matrix placeholder
    Add-PnPPageSection -Page "Human-Resources" -SectionTemplate OneColumn -Order 4
    $trainingHtml = @"
<div style="padding: 16px; background: #fef7f2; border-radius: 8px; border-left: 4px solid #4dc8e8;">
    <h3 style="color: #323130;">BH Training Compliance Matrix</h3>
    <p style="color: #605e5c;">Embed the behavioral health training matrix here once hosted. Tracks HIPAA, Cultural Competency, Trauma-Informed Care, Mandated Reporter, and CPR/First Aid across all staff.</p>
    <p style="color: #a19f9d; font-size: 12px;">Configure: Replace with Embed web part pointing to hosted Training Matrix HTML.</p>
</div>
"@
    Add-TextSection -PageName "Human-Resources" -Section 4 -Html $trainingHtml

    Set-PnPPage -Identity "Human-Resources" -Publish
    Write-OK "Published Human-Resources.aspx"
}

# ============================================================================
# PAGE 8: ADMINISTRATION
# ============================================================================
Write-Step "Page 8/9: Administration"

$page = Ensure-Page -PageName "Administration" -Title "Administration"
if ($page) {
    # Section 1: KPI embed
    Add-PnPPageSection -Page "Administration" -SectionTemplate OneColumn -Order 1
    Add-EmbedWebPart -PageName "Administration" -Section 1 -EmbedUrl $embedUrls.admin_dashboard -Description "Admin KPI Dashboard (Billing/Compliance/Facilities)"

    # Section 2: Revenue by Payer
    Add-PnPPageSection -Page "Administration" -SectionTemplate OneColumn -Order 2
    Add-ListWebPart -PageName "Administration" -Section 2 -ListName "Revenue by Payer"

    # Section 3: Compliance Audit Calendar
    Add-PnPPageSection -Page "Administration" -SectionTemplate OneColumn -Order 3
    Add-ListWebPart -PageName "Administration" -Section 3 -ListName "Compliance Audit Calendar"

    # Section 4: Admin Documents
    Add-PnPPageSection -Page "Administration" -SectionTemplate OneColumn -Order 4
    Add-DocLibWebPart -PageName "Administration" -Section 4 -LibraryName "Admin-Documents"

    Set-PnPPage -Identity "Administration" -Publish
    Write-OK "Published Administration.aspx"
}

# ============================================================================
# PAGE 9: REENTRY PROGRAM
# ============================================================================
Write-Step "Page 9/9: Reentry Program"

$page = Ensure-Page -PageName "Reentry-Program" -Title "Reentry Program"
if ($page) {
    # Section 1: KPI embed
    Add-PnPPageSection -Page "Reentry-Program" -SectionTemplate OneColumn -Order 1
    Add-EmbedWebPart -PageName "Reentry-Program" -Section 1 -EmbedUrl $embedUrls.reentry_dashboard -Description "Reentry KPI + Pipeline"

    # Section 2: Participants
    Add-PnPPageSection -Page "Reentry-Program" -SectionTemplate OneColumn -Order 2
    Add-ListWebPart -PageName "Reentry-Program" -Section 2 -ListName "Reentry Participants"

    # Section 3: Reentry Documents
    Add-PnPPageSection -Page "Reentry-Program" -SectionTemplate OneColumn -Order 3
    Add-DocLibWebPart -PageName "Reentry-Program" -Section 3 -LibraryName "Reentry-Documents"

    # Section 4: Referral Partners (court/community focus)
    Add-PnPPageSection -Page "Reentry-Program" -SectionTemplate OneColumn -Order 4
    Add-ListWebPart -PageName "Reentry-Program" -Section 4 -ListName "Referral Partners"

    Set-PnPPage -Identity "Reentry-Program" -Publish
    Write-OK "Published Reentry-Program.aspx"
}

# ============================================================================
# SET HOME PAGE
# ============================================================================
Write-Step "Setting Home.aspx as site home page"

try {
    Set-PnPHomePage -RootFolderRelativeUrl "SitePages/Home.aspx"
    Write-OK "Set Home.aspx as site home page"
} catch {
    Write-Warning "Could not set home page. Set manually via Site Settings."
}

# ============================================================================
# DONE
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host " Page Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`n   Pages created: 9" -ForegroundColor Cyan
Write-Host "   Web parts placed: Lists, Doc Libraries, Embeds, Power BI, Text" -ForegroundColor Cyan
Write-Host "`n   Next steps:" -ForegroundColor Yellow
Write-Host "   1. Host KPI HTML files on GitHub Pages or Azure Blob" -ForegroundColor Yellow
Write-Host "   2. Update embed-urls.json with real URLs" -ForegroundColor Yellow
Write-Host "   3. Re-run this script with -Force to update embeds" -ForegroundColor Yellow
Write-Host "   4. Publish Power BI report and update report URL" -ForegroundColor Yellow
Write-Host ""
