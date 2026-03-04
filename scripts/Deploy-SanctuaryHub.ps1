<#
.SYNOPSIS
    Deploys the Sanctuary Recovery Centers Operations Hub SharePoint site.

.DESCRIPTION
    PnP PowerShell provisioning script that creates:
    - Communication Site "Sanctuary Operations Hub"
    - Sanctuary brand theme
    - Hub navigation (9 pages)
    - 8 Document Libraries with full folder structures and placeholder files
    - 9 SharePoint Lists with typed columns

    This script is idempotent — safe to re-run without duplicating resources.

.PARAMETER TenantUrl
    SharePoint tenant URL, e.g. "https://sanctuaryrecoverycenters48.sharepoint.com"

.PARAMETER SiteAlias
    Site alias for the URL path, e.g. "ops-hub-dev"

.PARAMETER SiteTitle
    Display name for the site. Defaults to "Sanctuary Operations Hub"

.PARAMETER SkipSiteCreation
    Skip site creation if it already exists.

.EXAMPLE
    .\Deploy-SanctuaryHub.ps1 -TenantUrl "https://sanctuaryrecoverycenters48.sharepoint.com" -SiteAlias "ops-hub-dev"

.NOTES
    Required: PnP.PowerShell module (Install-Module -Name PnP.PowerShell -Scope CurrentUser)
    Required: SharePoint Admin or Site Collection Admin permissions
    Required: PowerShell 7+
    Admin: breinhart@sanctuaryrecoverycenters.com
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TenantUrl = "https://sanctuaryrecoverycenters48.sharepoint.com",

    [Parameter(Mandatory = $false)]
    [string]$SiteAlias = "ops-hub-dev",

    [string]$SiteTitle = "Sanctuary Operations Hub",

    [switch]$SkipSiteCreation
)

$ErrorActionPreference = "Stop"
$SiteUrl = "$TenantUrl/sites/$SiteAlias"

# ============================================================================
# PREREQUISITES CHECK
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Sanctuary Operations Hub — Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Write-Error "PnP.PowerShell module is not installed. Run: Install-Module -Name PnP.PowerShell -Scope CurrentUser"
    exit 1
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "PowerShell 7+ is recommended. Current version: $($PSVersionTable.PSVersion)"
}

# ============================================================================
# HELPER FUNCTIONS
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

function Ensure-List {
    <#
    .SYNOPSIS
        Creates a SharePoint list if it doesn't already exist.
    #>
    param(
        [string]$ListName,
        [string]$Template = "GenericList"
    )
    $existing = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Skip "List '$ListName' already exists"
        return $existing
    }
    $list = New-PnPList -Title $ListName -Template $Template -ErrorAction Stop
    Write-OK "Created list '$ListName'"
    return $list
}

function Ensure-Field {
    <#
    .SYNOPSIS
        Adds a field to a list if it doesn't already exist.
    #>
    param(
        [string]$ListName,
        [string]$FieldName,
        [string]$FieldType,
        [string[]]$Choices = @(),
        [string]$Formula = "",
        [switch]$Required
    )

    $internalName = $FieldName -replace '[^a-zA-Z0-9]', ''
    $existing = Get-PnPField -List $ListName -Identity $internalName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Skip "Field '$FieldName' on '$ListName' already exists"
        return
    }

    $params = @{
        List         = $ListName
        DisplayName  = $FieldName
        InternalName = $internalName
        Type         = $FieldType
        AddToDefaultView = $true
    }

    if ($Required) { $params.Required = $true }

    switch ($FieldType) {
        "Choice" {
            $params.Choices = $Choices
            Add-PnPField @params | Out-Null
        }
        "Calculated" {
            # Calculated fields need XML
            $choiceXml = ""
            $resultType = "Number"
            $fieldXml = "<Field Type='Calculated' DisplayName='$FieldName' ResultType='$resultType' ReadOnly='TRUE'><Formula>$Formula</Formula></Field>"
            Add-PnPFieldFromXml -List $ListName -FieldXml $fieldXml | Out-Null
        }
        "Note" {
            $params.Type = "Note"
            Add-PnPField @params | Out-Null
        }
        "DateTime" {
            Add-PnPField @params | Out-Null
        }
        "Currency" {
            Add-PnPField @params | Out-Null
        }
        "Boolean" {
            Add-PnPField @params | Out-Null
        }
        "User" {
            Add-PnPField @params | Out-Null
        }
        "Number" {
            Add-PnPField @params | Out-Null
        }
        default {
            Add-PnPField @params | Out-Null
        }
    }
    Write-OK "Added field '$FieldName' ($FieldType) to '$ListName'"
}

function Ensure-Library {
    <#
    .SYNOPSIS
        Creates a document library if it doesn't already exist.
    #>
    param([string]$LibraryName)

    $existing = Get-PnPList -Identity $LibraryName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Skip "Library '$LibraryName' already exists"
        return $existing
    }
    $lib = New-PnPList -Title $LibraryName -Template DocumentLibrary -ErrorAction Stop
    Write-OK "Created library '$LibraryName'"
    return $lib
}

function Ensure-Folder {
    <#
    .SYNOPSIS
        Creates a folder in a document library if it doesn't already exist.
    #>
    param(
        [string]$LibraryName,
        [string]$FolderPath
    )

    $fullPath = "$LibraryName/$FolderPath"
    try {
        $existing = Get-PnPFolder -Url $fullPath -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Skip "Folder '$fullPath' already exists"
            return
        }
    } catch {
        # Folder doesn't exist, proceed to create
    }
    Add-PnPFolder -Name (Split-Path $FolderPath -Leaf) -Folder ($LibraryName + "/" + (Split-Path $FolderPath -Parent)).TrimEnd("/\") -ErrorAction SilentlyContinue | Out-Null
    Write-OK "Created folder '$fullPath'"
}

function Ensure-PlaceholderFile {
    <#
    .SYNOPSIS
        Creates a placeholder .txt file in a library folder.
    #>
    param(
        [string]$LibraryName,
        [string]$FolderPath,
        [string]$FileName
    )

    $targetFolder = "$LibraryName/$FolderPath"
    # Create a placeholder text file
    $txtFileName = $FileName + ".txt"
    $content = "Placeholder for: $FileName`nUpload the real document here and delete this placeholder.`nSanctuary Recovery Centers — Operations Hub"
    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $content

    try {
        $existing = Get-PnPFile -Url "$targetFolder/$txtFileName" -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Skip "Placeholder '$txtFileName' already exists"
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            return
        }
    } catch {
        # File doesn't exist, proceed
    }

    Add-PnPFile -Path $tempFile -Folder $targetFolder -NewFileName $txtFileName -ErrorAction SilentlyContinue | Out-Null
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    Write-OK "Created placeholder '$txtFileName'"
}

# ============================================================================
# 1.1 — SITE CREATION
# ============================================================================
Write-Step "1.1 — Site Creation"

if ($SkipSiteCreation) {
    Write-Skip "Site creation skipped (-SkipSiteCreation)"
    Connect-PnPOnline -Url $SiteUrl -Interactive
} else {
    # Connect to tenant admin for site creation
    Connect-PnPOnline -Url $TenantUrl -Interactive

    $existingSite = $null
    try {
        $existingSite = Get-PnPTenantSite -Url $SiteUrl -ErrorAction SilentlyContinue
    } catch {
        # Site doesn't exist
    }

    if ($existingSite) {
        Write-Skip "Site '$SiteUrl' already exists"
    } else {
        Write-Host "   Creating Communication Site '$SiteTitle' at $SiteUrl ..." -ForegroundColor White
        New-PnPSite -Type CommunicationSite `
            -Title $SiteTitle `
            -Url $SiteUrl `
            -Lcid 1033 `
            -Owner "breinhart@sanctuaryrecoverycenters.com" | Out-Null
        Write-OK "Created site '$SiteTitle'"

        # Wait for site provisioning
        Write-Host "   Waiting for site provisioning..." -ForegroundColor White
        Start-Sleep -Seconds 15
    }

    # Reconnect to the new site
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
    Connect-PnPOnline -Url $SiteUrl -Interactive
}

# Set time zone to Arizona (ID 15 — no DST)
Set-PnPWeb -TimeZone 15 | Out-Null
Write-OK "Set time zone to Arizona (no DST)"

# ============================================================================
# 1.2 — BRANDING / THEMING
# ============================================================================
Write-Step "1.2 — Branding & Theming"

$themePalette = @{
    "themePrimary"        = "#e8732a"
    "themeLighterAlt"     = "#fef7f2"
    "themeLighter"        = "#fbe0cc"
    "themeLight"          = "#f7c5a3"
    "themeTertiary"       = "#ef8f52"
    "themeSecondary"      = "#e97e35"
    "themeDarkAlt"        = "#d16826"
    "themeDark"           = "#b05820"
    "themeDarker"         = "#824118"
    "neutralLighterAlt"   = "#faf9f8"
    "neutralLighter"      = "#f3f2f1"
    "neutralLight"        = "#edebe9"
    "neutralQuaternaryAlt"= "#e1dfdd"
    "neutralQuaternary"   = "#d2d0ce"
    "neutralTertiaryAlt"  = "#c8c6c4"
    "neutralTertiary"     = "#a19f9d"
    "neutralSecondary"    = "#605e5c"
    "neutralPrimaryAlt"   = "#3b3a39"
    "neutralPrimary"      = "#323130"
    "neutralDark"         = "#201f1e"
    "black"               = "#000000"
    "white"               = "#ffffff"
    "primaryBackground"   = "#ffffff"
    "primaryText"         = "#323130"
    "accent"              = "#4dc8e8"
}

try {
    Add-PnPTenantTheme -Identity "Sanctuary Recovery Centers" -Palette $themePalette -IsInverted:$false -Overwrite
    Write-OK "Registered tenant theme 'Sanctuary Recovery Centers'"
} catch {
    Write-Warning "Could not register tenant theme (may require tenant admin). Skipping."
}

try {
    Set-PnPWebTheme -Theme "Sanctuary Recovery Centers"
    Write-OK "Applied theme to site"
} catch {
    Write-Warning "Could not apply theme to site. Apply manually via Site Settings > Change the look."
}

# Upload logo if available
$logoPath = Join-Path $PSScriptRoot "..\assets\sanctuary-logo.png"
if (Test-Path $logoPath) {
    Set-PnPSite -LogoFilePath $logoPath
    Write-OK "Uploaded site logo"
} else {
    Write-Warning "Logo file not found at $logoPath — upload manually later."
}

# ============================================================================
# 1.3 — HUB NAVIGATION
# ============================================================================
Write-Step "1.3 — Hub Navigation"

$navLinks = @(
    @{ Title = "Home";                  Url = "$SiteUrl/SitePages/Home.aspx" },
    @{ Title = "CEO";                   Url = "$SiteUrl/SitePages/CEO-Dashboard.aspx" },
    @{ Title = "Clinical";              Url = "$SiteUrl/SitePages/Clinical-Department.aspx" },
    @{ Title = "Admissions";            Url = "$SiteUrl/SitePages/Admissions-Department.aspx" },
    @{ Title = "Marketing";             Url = "$SiteUrl/SitePages/Marketing-Department.aspx" },
    @{ Title = "Business Development";  Url = "$SiteUrl/SitePages/Business-Development.aspx" },
    @{ Title = "Human Resources";       Url = "$SiteUrl/SitePages/Human-Resources.aspx" },
    @{ Title = "Administration";        Url = "$SiteUrl/SitePages/Administration.aspx" },
    @{ Title = "Reentry Program";       Url = "$SiteUrl/SitePages/Reentry-Program.aspx" }
)

# Get existing nav nodes to avoid duplicates
$existingNav = Get-PnPNavigationNode -Location TopNavigationBar -ErrorAction SilentlyContinue
$existingTitles = @()
if ($existingNav) {
    $existingTitles = $existingNav | ForEach-Object { $_.Title }
}

foreach ($link in $navLinks) {
    if ($existingTitles -contains $link.Title) {
        Write-Skip "Nav link '$($link.Title)' already exists"
    } else {
        Add-PnPNavigationNode -Location TopNavigationBar -Title $link.Title -Url $link.Url | Out-Null
        Write-OK "Added nav link '$($link.Title)'"
    }
}

# ============================================================================
# 1.4 — DOCUMENT LIBRARIES
# ============================================================================
Write-Step "1.4 — Document Libraries"

# --- Facility choices (reused across lists) ---
$facilityChoices = @(
    "Roadrunner Home",
    "Blossom House",
    "Rose Garden",
    "Rosemonte Home",
    "Charter Oak Home",
    "Mercer Home",
    "Friess Home",
    "IOP Clinic"
)

# Define all libraries, folders, and placeholder files
$libraries = @{
    "CEO-Documents" = @{
        "Licensing-and-Accreditation" = @(
            "Joint Commission Certificate of Accreditation.pdf",
            "AZDHS BH License - Roadrunner Home.pdf",
            "AZDHS BH License - Blossom House.pdf",
            "AZDHS BH License - Rosemonte Home.pdf",
            "DEA Registration - All Facilities.pdf",
            "LegitScript Certification.pdf",
            "ASU Partnership Agreement - Blossom House.pdf"
        )
        "Payer-Contracts" = @(
            "AHCCCS - Mercy Care Contract.pdf",
            "AHCCCS - UHCCP Agreement.pdf",
            "Cigna Evernorth Provider Agreement.pdf",
            "Aetna Behavioral Health Agreement.pdf",
            "Humana Provider Contract.pdf",
            "Single Case Agreement SCA Template.docx"
        )
        "Strategic-Planning-Board-Reports" = @(
            "2026 Strategic Growth Plan.pdf",
            "Board Report - Feb 2026.pptx",
            "Board Report - Jan 2026.pptx",
            "Expansion Feasibility - Tempe Mesa Market.pdf",
            "Financial Summary Q4 2025.xlsx"
        )
        "Risk-Management-Insurance" = @(
            "Professional Liability Policy 2026.pdf",
            "General Liability Certificate All Properties.pdf",
            "Risk Assessment Matrix Q1 2026.xlsx",
            "Emergency Preparedness Plan All Sites.pdf",
            "Workers Comp Policy.pdf"
        )
        "CORE-Team-Community-Programs" = @(
            "CORE Team Charter and Outreach Plan.pdf",
            "Reentry Program SOP.docx",
            "ASU Womens Trauma Research MOU.pdf"
        )
    }

    "Clinical-Documents" = @{
        "SOPs-and-Protocols" = @(
            "Suicide Risk Assessment Protocol QPR.pdf",
            "ASAM Criteria Level of Care Guidelines.pdf",
            "Treatment Plan Standards AHCCCS Requirements.pdf",
            "Progress Note Documentation Guide.pdf",
            "Group Facilitation Manual.pdf",
            "Medication Management Protocol.pdf",
            "AMA Discharge Safety Planning SOP.pdf"
        )
        "Therapeutic-Modality-Guides" = @(
            "CBT Implementation Guide.pdf",
            "DBT Skills Training Manual.pdf",
            "EMDR Protocol Trauma Processing.pdf",
            "ART Accelerated Resolution Therapy Guide.pdf",
            "Equine Therapy Session Protocol.pdf",
            "Sand Tray Expressive Arts Therapy Guide.pdf"
        )
    }

    "Admissions-Documents" = @{
        "Intake-Forms-Assessments" = @(
            "Biopsychosocial Assessment Template.docx",
            "ASAM Level of Care Determination Guide.pdf",
            "Client Consent Rights Packet.pdf",
            "PHQ9 GAD7 AUDITC Screening Tools.pdf",
            "Adolescent Intake Packet Friess Home.pdf",
            "Reentry Program Eligibility Checklist.pdf"
        )
        "Insurance-VOB-Resources" = @(
            "VOB Process SOP Phone Scripts.pdf",
            "Mercy Care Prior Auth Requirements.pdf",
            "UHCCP Authorization Procedures.pdf",
            "Single Case Agreement SCA Template.docx",
            "Out of Network Benefits Guide.pdf"
        )
    }

    "Marketing-Documents" = @{
        "Brand-Assets" = @(
            "Sanctuary Brand Guidelines v3.pdf",
            "Logo Pack Phoenix Lotus.zip",
            "Photography Library Facilities.zip",
            "Color Typography Spec.pdf",
            "Email Signature Templates.html",
            "Presentation Template Sanctuary.pptx"
        )
        "Website-Content-SEO" = @(
            "Service Page Copy All Programs.docx",
            "SEO Keyword Research Q1 2026.xlsx",
            "Blog Post Calendar Assignments.xlsx",
            "Facility Page Photography Shot List.docx"
        )
        "Compliance-Ad-Review" = @(
            "Ad Copy Compliance Checklist Anti-Inducement.pdf",
            "LegitScript Certification Requirements.pdf",
            "Client Testimonial Release HIPAA Consent.pdf"
        )
    }

    "BD-Documents" = @{
        "Referral-Agreements-MOUs" = @(
            "Banner Health Referral Agreement.pdf",
            "HonorHealth MOU.pdf",
            "Standard Referral Agreement Template.docx",
            "Anti-Kickback Compliance Addendum.pdf",
            "Maricopa County Court Liaison Agreement.pdf"
        )
        "Outreach-Materials" = @(
            "Facility Presentation Deck.pptx",
            "One-Pager Sanctuary Services Overview.pdf",
            "Cold Outreach Script Hospital EDs.pdf",
            "Follow-Up Email Templates.docx"
        )
    }

    "HR-Documents" = @{
        "Employee-Handbook-Policies" = @(
            "Employee Handbook v5.1.pdf",
            "Trauma-Informed Workplace Policy.pdf",
            "Dual Relationships Boundary Policy.pdf",
            "Staff Wellness Burnout Prevention Plan.pdf",
            "Drug-Free Workplace Policy.pdf",
            "Social Media HIPAA Confidentiality Policy.pdf"
        )
        "Job-Descriptions-BH-Roles" = @(
            "Licensed Professional Counselor LPC.docx",
            "Licensed Independent Substance Abuse Counselor LISAC.docx",
            "Licensed Clinical Social Worker LCSW.docx",
            "Behavioral Health Technician BHT.docx",
            "Peer Support Specialist CPSS.docx",
            "Reentry Program Coordinator.docx"
        )
    }

    "Admin-Documents" = @{
        "AHCCCS-Billing-Guides" = @(
            "AHCCCS Residential Billing Manual 2026.pdf",
            "Mercy Care Provider Manual.pdf",
            "CPT Code Quick Reference BH Services.pdf",
            "Denial Appeal Process SOP.pdf"
        )
        "Corporate-Compliance" = @(
            "Corporate Compliance Plan 2026.pdf",
            "HIPAA Privacy Security Policies.pdf",
            "Fraud Waste Abuse Prevention Plan.pdf",
            "Emergency Preparedness Plan All Sites.pdf"
        )
    }

    "Reentry-Documents" = @{
        "Program-SOPs-Protocols" = @(
            "Reentry Program Manual v2.0.pdf",
            "Phase Transition Criteria Assessment.pdf",
            "Housing Readiness Checklist.pdf",
            "Employment Readiness Assessment.pdf",
            "Court Compliance Reporting Template.docx"
        )
        "CORE-Team-Resources" = @(
            "CORE Team Charter Mission.pdf",
            "Community Partner Directory.xlsx",
            "Partner Onboarding Guide.pdf",
            "ASU Partnership Womens Trauma Research MOU.pdf"
        )
    }
}

foreach ($libName in $libraries.Keys) {
    Write-Host "`n   --- Library: $libName ---" -ForegroundColor Magenta
    Ensure-Library -LibraryName $libName

    foreach ($folder in $libraries[$libName].Keys) {
        # Create the folder
        try {
            Resolve-PnPFolder -SiteRelativePath "$libName/$folder" | Out-Null
            Write-Skip "Folder '$libName/$folder' already exists"
        } catch {
            Resolve-PnPFolder -SiteRelativePath "$libName/$folder" | Out-Null
            Write-OK "Created folder '$libName/$folder'"
        }

        # Create placeholder files
        foreach ($file in $libraries[$libName][$folder]) {
            Ensure-PlaceholderFile -LibraryName $libName -FolderPath $folder -FileName $file
        }
    }
}

# ============================================================================
# 1.5 — SHAREPOINT LISTS
# ============================================================================
Write-Step "1.5 — SharePoint Lists"

# ---------- LIST 1: Facility Census Tracker ----------
Write-Host "`n   --- List: Facility Census Tracker ---" -ForegroundColor Magenta
Ensure-List -ListName "Facility Census Tracker"

Ensure-Field -ListName "Facility Census Tracker" -FieldName "Facility" -FieldType "Choice" `
    -Choices $facilityChoices

Ensure-Field -ListName "Facility Census Tracker" -FieldName "LOC" -FieldType "Choice" `
    -Choices @("Residential", "PHP", "IOP")

Ensure-Field -ListName "Facility Census Tracker" -FieldName "Census" -FieldType "Number"

Ensure-Field -ListName "Facility Census Tracker" -FieldName "Capacity" -FieldType "Number"

Ensure-Field -ListName "Facility Census Tracker" -FieldName "OccupancyPct" -FieldType "Calculated" `
    -Formula "=Census/Capacity"

Ensure-Field -ListName "Facility Census Tracker" -FieldName "ALOS" -FieldType "Number"

Ensure-Field -ListName "Facility Census Tracker" -FieldName "LeadClinician" -FieldType "User"

Ensure-Field -ListName "Facility Census Tracker" -FieldName "Status" -FieldType "Choice" `
    -Choices @("Current", "Waitlisted", "CAP Open", "License Due", "Fire Drill Gap", "Fire Insp Overdue", "At Capacity")

Ensure-Field -ListName "Facility Census Tracker" -FieldName "Notes" -FieldType "Note"

Ensure-Field -ListName "Facility Census Tracker" -FieldName "LastUpdated" -FieldType "DateTime"


# ---------- LIST 2: Compliance Audit Calendar ----------
Write-Host "`n   --- List: Compliance Audit Calendar ---" -ForegroundColor Magenta
Ensure-List -ListName "Compliance Audit Calendar"

# Title field exists by default on GenericList

Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "AuditDate" -FieldType "DateTime"

Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "AuditType" -FieldType "Choice" `
    -Choices @("Joint Commission", "AZDHS", "Fire Marshal", "Internal", "HIPAA", "Chart Audit")

Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Scope" -FieldType "Text"

Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Owner" -FieldType "User"

Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Status" -FieldType "Choice" `
    -Choices @("Scheduled", "Preparing", "Complete", "Overdue", "Window Open")

Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "DaysRemaining" -FieldType "Calculated" `
    -Formula "=AuditDate-Today"

Ensure-Field -ListName "Compliance Audit Calendar" -FieldName "Notes" -FieldType "Note"


# ---------- LIST 3: Incident Reports ----------
Write-Host "`n   --- List: Incident Reports ---" -ForegroundColor Magenta
Ensure-List -ListName "Incident Reports"

Ensure-Field -ListName "Incident Reports" -FieldName "IncidentID" -FieldType "Text"

Ensure-Field -ListName "Incident Reports" -FieldName "IncidentDate" -FieldType "DateTime"

Ensure-Field -ListName "Incident Reports" -FieldName "Facility" -FieldType "Choice" `
    -Choices $facilityChoices

Ensure-Field -ListName "Incident Reports" -FieldName "Category" -FieldType "Choice" `
    -Choices @("Client Fall", "Med Discrepancy", "AMA Discharge", "Behavioral Escalation", "Property Damage", "Other")

Ensure-Field -ListName "Incident Reports" -FieldName "Severity" -FieldType "Choice" `
    -Choices @("Critical", "High", "Medium", "Low")

Ensure-Field -ListName "Incident Reports" -FieldName "Description" -FieldType "Note"

Ensure-Field -ListName "Incident Reports" -FieldName "Status" -FieldType "Choice" `
    -Choices @("Open", "Under Review", "Investigating", "Resolved", "Closed")

Ensure-Field -ListName "Incident Reports" -FieldName "AssignedTo" -FieldType "User"

Ensure-Field -ListName "Incident Reports" -FieldName "ResolutionDate" -FieldType "DateTime"

Ensure-Field -ListName "Incident Reports" -FieldName "CorrectiveAction" -FieldType "Note"


# ---------- LIST 4: Admissions Pipeline ----------
Write-Host "`n   --- List: Admissions Pipeline ---" -ForegroundColor Magenta
Ensure-List -ListName "Admissions Pipeline"

Ensure-Field -ListName "Admissions Pipeline" -FieldName "ReferralID" -FieldType "Text"

Ensure-Field -ListName "Admissions Pipeline" -FieldName "ReferralDate" -FieldType "DateTime"

Ensure-Field -ListName "Admissions Pipeline" -FieldName "Source" -FieldType "Choice" `
    -Choices @("Hospital ED", "Self-Referral", "Private Therapist", "Probation Officer", "Alumni Referral", "Sober Living", "Community Outreach", "Crisis Line")

Ensure-Field -ListName "Admissions Pipeline" -FieldName "SourceDetail" -FieldType "Text"

Ensure-Field -ListName "Admissions Pipeline" -FieldName "PrimaryDx" -FieldType "Text"

Ensure-Field -ListName "Admissions Pipeline" -FieldName "Insurance" -FieldType "Choice" `
    -Choices @("Mercy Care", "UHCCP", "Cigna", "Aetna", "Humana", "Private Pay", "Other/SCA")

Ensure-Field -ListName "Admissions Pipeline" -FieldName "LOCRequested" -FieldType "Choice" `
    -Choices @("Residential", "PHP", "IOP")

Ensure-Field -ListName "Admissions Pipeline" -FieldName "FacilityAssigned" -FieldType "Choice" `
    -Choices $facilityChoices

Ensure-Field -ListName "Admissions Pipeline" -FieldName "Stage" -FieldType "Choice" `
    -Choices @("Lead", "Screened", "VOB In Progress", "VOB Complete", "Assessment Scheduled", "Assessment Complete", "Admitted", "Waitlisted", "Lost")

Ensure-Field -ListName "Admissions Pipeline" -FieldName "Status" -FieldType "Choice" `
    -Choices @("Active", "Admitted", "Waitlisted", "No-Show", "Lost to Follow-Up", "Declined")

Ensure-Field -ListName "Admissions Pipeline" -FieldName "AssessmentDate" -FieldType "DateTime"

Ensure-Field -ListName "Admissions Pipeline" -FieldName "AdmitDate" -FieldType "DateTime"

Ensure-Field -ListName "Admissions Pipeline" -FieldName "AssignedTo" -FieldType "User"

Ensure-Field -ListName "Admissions Pipeline" -FieldName "Notes" -FieldType "Note"


# ---------- LIST 5: Referral Partners ----------
Write-Host "`n   --- List: Referral Partners ---" -ForegroundColor Magenta
Ensure-List -ListName "Referral Partners"

Ensure-Field -ListName "Referral Partners" -FieldName "PartnerName" -FieldType "Text"

Ensure-Field -ListName "Referral Partners" -FieldName "PartnerType" -FieldType "Choice" `
    -Choices @("Hospital ED", "Crisis Services", "Courts", "Outpatient MDs", "Sober Living", "Therapist", "Community Org")

Ensure-Field -ListName "Referral Partners" -FieldName "Territory" -FieldType "Choice" `
    -Choices @("North Phoenix", "Scottsdale", "East Valley", "Tempe", "West Valley", "County-Wide", "Metro PHX")

Ensure-Field -ListName "Referral Partners" -FieldName "ContactName" -FieldType "Text"

Ensure-Field -ListName "Referral Partners" -FieldName "ContactEmail" -FieldType "Text"

Ensure-Field -ListName "Referral Partners" -FieldName "ContactPhone" -FieldType "Text"

Ensure-Field -ListName "Referral Partners" -FieldName "ReferralsMTD" -FieldType "Number"

Ensure-Field -ListName "Referral Partners" -FieldName "AdmitsMTD" -FieldType "Number"

Ensure-Field -ListName "Referral Partners" -FieldName "ConversionPct" -FieldType "Calculated" `
    -Formula "=AdmitsMTD/ReferralsMTD"

Ensure-Field -ListName "Referral Partners" -FieldName "LastContact" -FieldType "DateTime"

Ensure-Field -ListName "Referral Partners" -FieldName "AgreementOnFile" -FieldType "Boolean"

Ensure-Field -ListName "Referral Partners" -FieldName "Status" -FieldType "Choice" `
    -Choices @("Active", "Follow-Up", "New Partner", "Inactive")

Ensure-Field -ListName "Referral Partners" -FieldName "Notes" -FieldType "Note"


# ---------- LIST 6: Staff Credential Tracker ----------
Write-Host "`n   --- List: Staff Credential Tracker ---" -ForegroundColor Magenta
Ensure-List -ListName "Staff Credential Tracker"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "StaffName" -FieldType "Text"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Role" -FieldType "Choice" `
    -Choices @("LPC", "LISAC", "LCSW", "LAC", "BHT", "CPSS", "Admin", "Admissions", "Operations")

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Facility" -FieldType "Choice" `
    -Choices ($facilityChoices + @("Corporate"))

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "LicenseNumber" -FieldType "Text"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "LicenseExpiration" -FieldType "DateTime"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "FingerprintClearance" -FieldType "DateTime"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "CPRExpiration" -FieldType "DateTime"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "HIPAATrainingDate" -FieldType "DateTime"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "HIPAADueDate" -FieldType "DateTime"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "CulturalCompDate" -FieldType "DateTime"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "TraumaInformedDate" -FieldType "DateTime"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "MandatedReporterDate" -FieldType "DateTime"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "SupervisionCurrent" -FieldType "Boolean"

Ensure-Field -ListName "Staff Credential Tracker" -FieldName "Status" -FieldType "Choice" `
    -Choices @("Current", "Expiring Soon", "Expired", "Action Required")


# ---------- LIST 7: Revenue by Payer ----------
Write-Host "`n   --- List: Revenue by Payer ---" -ForegroundColor Magenta
Ensure-List -ListName "Revenue by Payer"

Ensure-Field -ListName "Revenue by Payer" -FieldName "Month" -FieldType "DateTime"

Ensure-Field -ListName "Revenue by Payer" -FieldName "Payer" -FieldType "Choice" `
    -Choices @("Mercy Care", "UHCCP", "Cigna", "Aetna", "Humana", "Private Pay", "SCA/Other")

Ensure-Field -ListName "Revenue by Payer" -FieldName "Revenue" -FieldType "Currency"

Ensure-Field -ListName "Revenue by Payer" -FieldName "ClaimCount" -FieldType "Number"

Ensure-Field -ListName "Revenue by Payer" -FieldName "DenialCount" -FieldType "Number"

Ensure-Field -ListName "Revenue by Payer" -FieldName "CleanClaimPct" -FieldType "Number"

Ensure-Field -ListName "Revenue by Payer" -FieldName "Notes" -FieldType "Note"


# ---------- LIST 8: Reentry Participants ----------
Write-Host "`n   --- List: Reentry Participants ---" -ForegroundColor Magenta
Ensure-List -ListName "Reentry Participants"

Ensure-Field -ListName "Reentry Participants" -FieldName "ParticipantID" -FieldType "Text"

Ensure-Field -ListName "Reentry Participants" -FieldName "EnrollDate" -FieldType "DateTime"

Ensure-Field -ListName "Reentry Participants" -FieldName "Phase" -FieldType "Choice" `
    -Choices @("Residential Stabilization", "PHP Step-Down", "IOP + Housing Search", "Community Transition", "Alumni/Aftercare")

Ensure-Field -ListName "Reentry Participants" -FieldName "Facility" -FieldType "Text"

Ensure-Field -ListName "Reentry Participants" -FieldName "DaysInProgram" -FieldType "Calculated" `
    -Formula "=Today-EnrollDate"

Ensure-Field -ListName "Reentry Participants" -FieldName "HousingStatus" -FieldType "Choice" `
    -Choices @("Future", "Pending", "Searching", "Placed (Sober Living)", "Placed (Independent)", "Lost")

Ensure-Field -ListName "Reentry Participants" -FieldName "EmploymentStatus" -FieldType "Choice" `
    -Choices @("Not Yet", "Job Training", "Job Search", "Interviewing", "Employed (PT)", "Employed (FT)", "Lost")

Ensure-Field -ListName "Reentry Participants" -FieldName "CourtInvolved" -FieldType "Boolean"

Ensure-Field -ListName "Reentry Participants" -FieldName "CourtCompliance" -FieldType "Choice" `
    -Choices @("Compliant", "Check-In Due", "Non-Compliant", "N/A")

Ensure-Field -ListName "Reentry Participants" -FieldName "CaseManager" -FieldType "User"

Ensure-Field -ListName "Reentry Participants" -FieldName "NextStep" -FieldType "Text"

Ensure-Field -ListName "Reentry Participants" -FieldName "Notes" -FieldType "Note"


# ---------- LIST 9: Marketing Campaigns ----------
Write-Host "`n   --- List: Marketing Campaigns ---" -ForegroundColor Magenta
Ensure-List -ListName "Marketing Campaigns"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "CampaignName" -FieldType "Text"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "Channel" -FieldType "Choice" `
    -Choices @("Google Ads", "SEO/Organic", "Facebook/Instagram", "Referral Partners", "Community Events", "LegitScript/Directories")

Ensure-Field -ListName "Marketing Campaigns" -FieldName "SpendMTD" -FieldType "Currency"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "Leads" -FieldType "Number"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "CPL" -FieldType "Currency"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "Admits" -FieldType "Number"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "CPA" -FieldType "Currency"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "Status" -FieldType "Choice" `
    -Choices @("Live", "Building", "Paused", "Completed")

Ensure-Field -ListName "Marketing Campaigns" -FieldName "StartDate" -FieldType "DateTime"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "EndDate" -FieldType "DateTime"

Ensure-Field -ListName "Marketing Campaigns" -FieldName "Notes" -FieldType "Note"


# ============================================================================
# DONE
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host " Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`n   Site URL:  $SiteUrl" -ForegroundColor Cyan
Write-Host "   Lists:     9 created" -ForegroundColor Cyan
Write-Host "   Libraries: 8 created with folder structures" -ForegroundColor Cyan
Write-Host "   Theme:     Sanctuary Recovery Centers applied" -ForegroundColor Cyan
Write-Host "   Nav:       9 top-nav links configured" -ForegroundColor Cyan
Write-Host "`n   Next step: Run Seed-ListData.ps1 to populate sample data." -ForegroundColor Yellow
Write-Host ""
