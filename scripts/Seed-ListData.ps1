<#
.SYNOPSIS
    Seeds all SharePoint lists in the Sanctuary Operations Hub with sample data.

.DESCRIPTION
    Pre-populates every list created by Deploy-SanctuaryHub.ps1 with representative
    sample data for demonstration and testing. This script is idempotent — it checks
    for existing items by key fields before inserting.

    Lists seeded:
    1. Facility Census Tracker (9 rows)
    2. Compliance Audit Calendar (6 rows)
    3. Incident Reports (4 rows)
    4. Admissions Pipeline (6 rows)
    5. Referral Partners (8 rows)
    6. Staff Credential Tracker (15 rows)
    7. Revenue by Payer (7 rows)
    8. Reentry Participants (6 rows)
    9. Marketing Campaigns (6 rows)

.PARAMETER SiteUrl
    Full URL to the Sanctuary Operations Hub site.

.EXAMPLE
    .\Seed-ListData.ps1 -SiteUrl "https://sanctuaryrecoverycenters48.sharepoint.com/sites/ops-hub-dev"

.NOTES
    Run Deploy-SanctuaryHub.ps1 first to create all lists and columns.
    Person/User fields are populated with display names as text where the field
    type does not support lookup. Adjust AssignedTo/Owner fields after deployment
    to map to real tenant users.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl = "https://sanctuaryrecoverycenters48.sharepoint.com/sites/ops-hub-dev"
)

$ErrorActionPreference = "Stop"

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

function Add-ListItemSafe {
    <#
    .SYNOPSIS
        Adds a list item if a matching item doesn't already exist.
    .PARAMETER ListName
        The SharePoint list name.
    .PARAMETER Values
        Hashtable of field values to set.
    .PARAMETER KeyField
        Field name to check for duplicates.
    .PARAMETER KeyValue
        Value to match against for duplicate check.
    #>
    param(
        [string]$ListName,
        [hashtable]$Values,
        [string]$KeyField = "Title",
        [string]$KeyValue
    )

    if (-not $KeyValue) {
        if ($Values.ContainsKey($KeyField)) {
            $KeyValue = $Values[$KeyField]
        } elseif ($Values.ContainsKey("Title")) {
            $KeyValue = $Values["Title"]
            $KeyField = "Title"
        }
    }

    # Check for existing item
    if ($KeyValue) {
        $existing = Get-PnPListItem -List $ListName -Query "<View><Query><Where><Eq><FieldRef Name='$KeyField'/><Value Type='Text'>$KeyValue</Value></Eq></Where></Query></View>" -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Skip "$ListName — '$KeyValue' already exists"
            return
        }
    }

    Add-PnPListItem -List $ListName -Values $Values | Out-Null
    Write-OK "$ListName — Added '$KeyValue'"
}

# ============================================================================
# CONNECT
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Sanctuary Operations Hub — Seed Data" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Connect-PnPOnline -Url $SiteUrl -Interactive

# ============================================================================
# LIST 1: Facility Census Tracker (9 rows)
# ============================================================================
Write-Step "Seeding: Facility Census Tracker"

$censusData = @(
    @{
        Title = "Roadrunner Home"
        Facility = "Roadrunner Home"; LOC = "Residential"
        Census = 16; Capacity = 16; ALOS = 58
        Status = "Waitlisted"
        LastUpdated = (Get-Date "2026-03-03")
    },
    @{
        Title = "Blossom House"
        Facility = "Blossom House"; LOC = "Residential"
        Census = 14; Capacity = 16; ALOS = 72
        Status = "CAP Open"
        LastUpdated = (Get-Date "2026-03-03")
    },
    @{
        Title = "Rose Garden"
        Facility = "Rose Garden"; LOC = "Residential"
        Census = 12; Capacity = 14; ALOS = 45
        Status = "Current"
        LastUpdated = (Get-Date "2026-03-03")
    },
    @{
        Title = "Rosemonte Home"
        Facility = "Rosemonte Home"; LOC = "Residential"
        Census = 14; Capacity = 16; ALOS = 60
        Status = "License Due"
        LastUpdated = (Get-Date "2026-03-03")
    },
    @{
        Title = "Charter Oak Home"
        Facility = "Charter Oak Home"; LOC = "Residential"
        Census = 15; Capacity = 16; ALOS = 55
        Status = "Fire Drill Gap"
        LastUpdated = (Get-Date "2026-03-03")
    },
    @{
        Title = "Mercer Home"
        Facility = "Mercer Home"; LOC = "Residential"
        Census = 12; Capacity = 16; ALOS = 68
        Status = "Fire Insp Overdue"
        LastUpdated = (Get-Date "2026-03-03")
    },
    @{
        Title = "Friess Home"
        Facility = "Friess Home"; LOC = "Residential"
        Census = 10; Capacity = 12; ALOS = 90
        Status = "Current"
        LastUpdated = (Get-Date "2026-03-03")
    },
    @{
        Title = "IOP Clinic (AM)"
        Facility = "IOP Clinic"; LOC = "IOP"
        Census = 47
        Status = "Current"
        LastUpdated = (Get-Date "2026-03-03")
    },
    @{
        Title = "IOP Clinic (PHP)"
        Facility = "IOP Clinic"; LOC = "PHP"
        Census = 18
        Status = "Current"
        LastUpdated = (Get-Date "2026-03-03")
    }
)

foreach ($row in $censusData) {
    Add-ListItemSafe -ListName "Facility Census Tracker" -Values $row -KeyField "Title" -KeyValue $row.Title
}

# ============================================================================
# LIST 2: Compliance Audit Calendar (6 rows)
# ============================================================================
Write-Step "Seeding: Compliance Audit Calendar"

$auditData = @(
    @{
        Title     = "Fire Drill All Sites"
        AuditDate = (Get-Date "2026-03-10")
        AuditType = "Internal"
        Scope     = "All 7 homes + clinic"
        Status    = "Scheduled"
    },
    @{
        Title     = "Mock JC Survey"
        AuditDate = (Get-Date "2026-03-18")
        AuditType = "Joint Commission"
        Scope     = "Organization-wide"
        Status    = "Preparing"
    },
    @{
        Title     = "Internal Chart Audit"
        AuditDate = (Get-Date "2026-03-25")
        AuditType = "Internal"
        Scope     = "20 random charts"
        Status    = "Scheduled"
    },
    @{
        Title     = "JC Annual Survey Window"
        AuditDate = (Get-Date "2026-04-01")
        AuditType = "Joint Commission"
        Scope     = "Organization-wide"
        Status    = "Window Open"
    },
    @{
        Title     = "AZDHS License Rosemonte"
        AuditDate = (Get-Date "2026-04-15")
        AuditType = "AZDHS"
        Scope     = "Rosemonte Home"
        Status    = "Scheduled"
    },
    @{
        Title     = "Fire Marshal Mercer"
        AuditDate = (Get-Date "2026-02-25")
        AuditType = "Fire Marshal"
        Scope     = "Mercer Home"
        Status    = "Overdue"
        Notes     = "Overdue — was due Feb 25, 2026. Follow up with Mercer Home operations."
    }
)

foreach ($row in $auditData) {
    Add-ListItemSafe -ListName "Compliance Audit Calendar" -Values $row -KeyField "Title" -KeyValue $row.Title
}

# ============================================================================
# LIST 3: Incident Reports (4 rows)
# ============================================================================
Write-Step "Seeding: Incident Reports"

$incidentData = @(
    @{
        Title        = "IR-2026-042"
        IncidentID   = "IR-2026-042"
        IncidentDate = (Get-Date "2026-03-01")
        Facility     = "Blossom House"
        Category     = "Client Fall"
        Severity     = "Medium"
        Description  = "Client slipped in bathroom area at approximately 7:15 AM. No head injury. Vitals taken, nurse notified. Ice applied to left knee."
        Status       = "Under Review"
    },
    @{
        Title        = "IR-2026-041"
        IncidentID   = "IR-2026-041"
        IncidentDate = (Get-Date "2026-02-28")
        Facility     = "Charter Oak Home"
        Category     = "Med Discrepancy"
        Severity     = "Medium"
        Description  = "Medication count off by 1 unit for Suboxone during shift change count. Investigated — documentation error confirmed. No diversion."
        Status       = "Open"
    },
    @{
        Title        = "IR-2026-040"
        IncidentID   = "IR-2026-040"
        IncidentDate = (Get-Date "2026-02-25")
        Facility     = "Mercer Home"
        Category     = "AMA Discharge"
        Severity     = "Low"
        Description  = "Client left AMA after 12 days in residential. Safety plan completed. Community resources provided. Family contacted."
        Status       = "Closed"
        ResolutionDate    = (Get-Date "2026-02-26")
        CorrectiveAction  = "Safety plan documented. Follow-up call scheduled at 48 hours and 7 days. Alumni outreach assigned."
    },
    @{
        Title        = "IR-2026-039"
        IncidentID   = "IR-2026-039"
        IncidentDate = (Get-Date "2026-02-22")
        Facility     = "Rose Garden"
        Category     = "Property Damage"
        Severity     = "Low"
        Description  = "Window screen damaged during cleaning. No safety concern. Maintenance work order submitted."
        Status       = "Closed"
        ResolutionDate    = (Get-Date "2026-02-24")
        CorrectiveAction  = "Screen replaced by maintenance on 2/24. No further action required."
    }
)

foreach ($row in $incidentData) {
    Add-ListItemSafe -ListName "Incident Reports" -Values $row -KeyField "IncidentID" -KeyValue $row.IncidentID
}

# ============================================================================
# LIST 4: Admissions Pipeline (6 rows — REF-0337 through REF-0342)
# ============================================================================
Write-Step "Seeding: Admissions Pipeline"

$admissionsData = @(
    @{
        Title           = "REF-0337"
        ReferralID      = "REF-0337"
        ReferralDate    = (Get-Date "2026-03-03")
        Source          = "Hospital ED"
        SourceDetail    = "Banner Desert Medical Center"
        PrimaryDx       = "Alcohol Use Disorder, Severe"
        Insurance       = "Mercy Care"
        LOCRequested    = "Residential"
        FacilityAssigned = "Roadrunner Home"
        Stage           = "Assessment Scheduled"
        Status          = "Active"
        AssessmentDate  = (Get-Date "2026-03-05")
        Notes           = "ED referral, medically cleared. ASAM suggests 3.5 residential. Assessment scheduled for 3/5."
    },
    @{
        Title           = "REF-0338"
        ReferralID      = "REF-0338"
        ReferralDate    = (Get-Date "2026-03-02")
        Source          = "Self-Referral"
        SourceDetail    = "Website contact form"
        PrimaryDx       = "Opioid Use Disorder"
        Insurance       = "Cigna"
        LOCRequested    = "Residential"
        FacilityAssigned = "Blossom House"
        Stage           = "VOB In Progress"
        Status          = "Active"
        Notes           = "Self-referral via website. Cigna VOB in progress. History of prior treatment x2."
    },
    @{
        Title           = "REF-0339"
        ReferralID      = "REF-0339"
        ReferralDate    = (Get-Date "2026-03-01")
        Source          = "Probation Officer"
        SourceDetail    = "Maricopa County Adult Probation"
        PrimaryDx       = "Stimulant Use Disorder, Co-occurring MDD"
        Insurance       = "UHCCP"
        LOCRequested    = "Residential"
        FacilityAssigned = "Charter Oak Home"
        Stage           = "VOB Complete"
        Status          = "Active"
        Notes           = "Court-ordered treatment. Probation officer contact: J. Hernandez. VOB approved for 30 days residential."
    },
    @{
        Title           = "REF-0340"
        ReferralID      = "REF-0340"
        ReferralDate    = (Get-Date "2026-02-28")
        Source          = "Private Therapist"
        SourceDetail    = "Dr. Sarah Kim, PsyD"
        PrimaryDx       = "PTSD, Alcohol Use Disorder"
        Insurance       = "Aetna"
        LOCRequested    = "IOP"
        FacilityAssigned = "IOP Clinic"
        Stage           = "Admitted"
        Status          = "Admitted"
        AssessmentDate  = (Get-Date "2026-03-01")
        AdmitDate       = (Get-Date "2026-03-03")
        Notes           = "Step-down from prior residential. Therapist referral for IOP + trauma processing. Admitted 3/3."
    },
    @{
        Title           = "REF-0341"
        ReferralID      = "REF-0341"
        ReferralDate    = (Get-Date "2026-02-27")
        Source          = "Crisis Line"
        SourceDetail    = "Solari Crisis Line"
        PrimaryDx       = "Polysubstance Use Disorder"
        Insurance       = "Mercy Care"
        LOCRequested    = "Residential"
        FacilityAssigned = "Rose Garden"
        Stage           = "Waitlisted"
        Status          = "Waitlisted"
        AssessmentDate  = (Get-Date "2026-02-28")
        Notes           = "Crisis line warm handoff. Assessment complete. Waitlisted — Rose Garden next available bed ~3/6."
    },
    @{
        Title           = "REF-0342"
        ReferralID      = "REF-0342"
        ReferralDate    = (Get-Date "2026-02-25")
        Source          = "Alumni Referral"
        SourceDetail    = "Alumni — M. Torres"
        PrimaryDx       = "Alcohol Use Disorder, GAD"
        Insurance       = "Humana"
        LOCRequested    = "PHP"
        FacilityAssigned = "IOP Clinic"
        Stage           = "Screened"
        Status          = "Active"
        Notes           = "Alumni referral. Screened by phone. Needs PHP-level care. Scheduling VOB and intake assessment."
    }
)

foreach ($row in $admissionsData) {
    Add-ListItemSafe -ListName "Admissions Pipeline" -Values $row -KeyField "ReferralID" -KeyValue $row.ReferralID
}

# ============================================================================
# LIST 5: Referral Partners (8 rows)
# ============================================================================
Write-Step "Seeding: Referral Partners"

$partnerData = @(
    @{
        Title          = "Banner Desert Medical Center"
        PartnerName    = "Banner Desert Medical Center"
        PartnerType    = "Hospital ED"
        Territory      = "East Valley"
        ContactName    = "Lisa Moreno, LCSW"
        ContactEmail   = "lisa.moreno@bannerhealth.com"
        ContactPhone   = "(480) 412-3700"
        ReferralsMTD   = 12
        AdmitsMTD      = 5
        LastContact    = (Get-Date "2026-03-01")
        AgreementOnFile = $true
        Status         = "Active"
    },
    @{
        Title          = "HonorHealth Scottsdale Osborn"
        PartnerName    = "HonorHealth Scottsdale Osborn"
        PartnerType    = "Hospital ED"
        Territory      = "Scottsdale"
        ContactName    = "James Park, RN"
        ContactEmail   = "jpark@honorhealth.com"
        ContactPhone   = "(480) 882-4000"
        ReferralsMTD   = 8
        AdmitsMTD      = 3
        LastContact    = (Get-Date "2026-02-28")
        AgreementOnFile = $true
        Status         = "Active"
    },
    @{
        Title          = "Maricopa County Adult Probation"
        PartnerName    = "Maricopa County Adult Probation"
        PartnerType    = "Courts"
        Territory      = "County-Wide"
        ContactName    = "Jorge Hernandez"
        ContactEmail   = "jhernandez@maricopa.gov"
        ContactPhone   = "(602) 506-3411"
        ReferralsMTD   = 6
        AdmitsMTD      = 4
        LastContact    = (Get-Date "2026-03-02")
        AgreementOnFile = $true
        Status         = "Active"
    },
    @{
        Title          = "Solari Crisis Services"
        PartnerName    = "Solari Crisis Services"
        PartnerType    = "Crisis Services"
        Territory      = "Metro PHX"
        ContactName    = "Andrea Simms"
        ContactEmail   = "asimms@solaricrisis.org"
        ContactPhone   = "(602) 222-9444"
        ReferralsMTD   = 9
        AdmitsMTD      = 3
        LastContact    = (Get-Date "2026-02-27")
        AgreementOnFile = $true
        Status         = "Active"
    },
    @{
        Title          = "Dr. Sarah Kim, PsyD"
        PartnerName    = "Dr. Sarah Kim, PsyD"
        PartnerType    = "Therapist"
        Territory      = "North Phoenix"
        ContactName    = "Sarah Kim"
        ContactEmail   = "drkim@phoenixtherapy.com"
        ContactPhone   = "(602) 555-0147"
        ReferralsMTD   = 3
        AdmitsMTD      = 2
        LastContact    = (Get-Date "2026-03-01")
        AgreementOnFile = $false
        Status         = "Follow-Up"
        Notes          = "High conversion rate. Need to get referral agreement signed."
    },
    @{
        Title          = "Oxford House Phoenix North"
        PartnerName    = "Oxford House Phoenix North"
        PartnerType    = "Sober Living"
        Territory      = "North Phoenix"
        ContactName    = "Mike Daniels"
        ContactEmail   = "mdaniels@oxfordhouse.org"
        ContactPhone   = "(602) 555-0233"
        ReferralsMTD   = 4
        AdmitsMTD      = 1
        LastContact    = (Get-Date "2026-02-20")
        AgreementOnFile = $true
        Status         = "Active"
        Notes          = "Good step-down partner for clients completing residential."
    },
    @{
        Title          = "Terros Health"
        PartnerName    = "Terros Health"
        PartnerType    = "Community Org"
        Territory      = "Metro PHX"
        ContactName    = "Rachel Nguyen"
        ContactEmail   = "rnguyen@terroshealth.org"
        ContactPhone   = "(602) 685-6000"
        ReferralsMTD   = 5
        AdmitsMTD      = 2
        LastContact    = (Get-Date "2026-02-25")
        AgreementOnFile = $true
        Status         = "Active"
    },
    @{
        Title          = "Dignity Health Chandler Regional"
        PartnerName    = "Dignity Health Chandler Regional"
        PartnerType    = "Hospital ED"
        Territory      = "East Valley"
        ContactName    = "Tom Walsh, SW"
        ContactEmail   = "twalsh@dignityhealth.org"
        ContactPhone   = "(480) 728-3000"
        ReferralsMTD   = 2
        AdmitsMTD      = 0
        LastContact    = (Get-Date "2026-02-15")
        AgreementOnFile = $false
        Status         = "New Partner"
        Notes          = "Initial outreach meeting completed. MOU under review. Promising volume potential."
    }
)

foreach ($row in $partnerData) {
    Add-ListItemSafe -ListName "Referral Partners" -Values $row -KeyField "PartnerName" -KeyValue $row.PartnerName
}

# ============================================================================
# LIST 6: Staff Credential Tracker (15 rows)
# ============================================================================
Write-Step "Seeding: Staff Credential Tracker"

$staffData = @(
    @{
        Title = "Dr. Maria Reyes"
        StaffName = "Dr. Maria Reyes"; Role = "LPC"
        Facility = "Roadrunner Home"; LicenseNumber = "LPC-14892"
        LicenseExpiration     = (Get-Date "2027-06-30")
        FingerprintClearance  = (Get-Date "2027-01-15")
        CPRExpiration         = (Get-Date "2026-09-01")
        HIPAATrainingDate     = (Get-Date "2026-01-10")
        HIPAADueDate          = (Get-Date "2027-01-10")
        CulturalCompDate      = (Get-Date "2025-11-15")
        TraumaInformedDate    = (Get-Date "2025-12-01")
        MandatedReporterDate  = (Get-Date "2026-02-01")
        Status = "Current"
    },
    @{
        Title = "Sarah Thompson"
        StaffName = "Sarah Thompson"; Role = "LISAC"
        Facility = "Blossom House"; LicenseNumber = "LISAC-20145"
        LicenseExpiration     = (Get-Date "2026-04-15")
        FingerprintClearance  = (Get-Date "2027-03-20")
        CPRExpiration         = (Get-Date "2026-05-01")
        HIPAATrainingDate     = (Get-Date "2025-12-15")
        HIPAADueDate          = (Get-Date "2026-12-15")
        CulturalCompDate      = (Get-Date "2025-10-01")
        TraumaInformedDate    = (Get-Date "2025-11-01")
        MandatedReporterDate  = (Get-Date "2025-09-15")
        Status = "Expiring Soon"
    },
    @{
        Title = "Kevin Patel"
        StaffName = "Kevin Patel"; Role = "LCSW"
        Facility = "Rose Garden"; LicenseNumber = "LCSW-08773"
        LicenseExpiration     = (Get-Date "2027-08-31")
        FingerprintClearance  = (Get-Date "2026-12-01")
        CPRExpiration         = (Get-Date "2026-07-15")
        HIPAATrainingDate     = (Get-Date "2026-02-01")
        HIPAADueDate          = (Get-Date "2027-02-01")
        CulturalCompDate      = (Get-Date "2026-01-15")
        TraumaInformedDate    = (Get-Date "2026-01-15")
        MandatedReporterDate  = (Get-Date "2026-01-15")
        Status = "Current"
    },
    @{
        Title = "Juan Martinez"
        StaffName = "Juan Martinez"; Role = "LPC"
        Facility = "Rosemonte Home"; LicenseNumber = "LPC-16210"
        LicenseExpiration     = (Get-Date "2026-03-20")
        FingerprintClearance  = (Get-Date "2026-11-30")
        CPRExpiration         = (Get-Date "2026-04-01")
        HIPAATrainingDate     = (Get-Date "2025-11-01")
        HIPAADueDate          = (Get-Date "2026-11-01")
        CulturalCompDate      = (Get-Date "2025-09-01")
        TraumaInformedDate    = (Get-Date "2025-10-01")
        MandatedReporterDate  = (Get-Date "2025-08-01")
        Status = "Expiring Soon"
    },
    @{
        Title = "Rachel Davis"
        StaffName = "Rachel Davis"; Role = "LISAC"
        Facility = "Charter Oak Home"; LicenseNumber = "LISAC-18934"
        LicenseExpiration     = (Get-Date "2027-02-28")
        FingerprintClearance  = (Get-Date "2027-05-15")
        CPRExpiration         = (Get-Date "2026-08-01")
        HIPAATrainingDate     = (Get-Date "2026-01-20")
        HIPAADueDate          = (Get-Date "2027-01-20")
        CulturalCompDate      = (Get-Date "2025-12-10")
        TraumaInformedDate    = (Get-Date "2026-02-15")
        MandatedReporterDate  = (Get-Date "2026-02-15")
        Status = "Current"
    },
    @{
        Title = "Lisa Chen"
        StaffName = "Lisa Chen"; Role = "LPC"
        Facility = "Mercer Home"; LicenseNumber = "LPC-15567"
        LicenseExpiration     = (Get-Date "2027-09-30")
        FingerprintClearance  = (Get-Date "2027-02-28")
        CPRExpiration         = (Get-Date "2026-06-15")
        HIPAATrainingDate     = (Get-Date "2026-02-10")
        HIPAADueDate          = (Get-Date "2027-02-10")
        CulturalCompDate      = (Get-Date "2026-01-01")
        TraumaInformedDate    = (Get-Date "2026-01-01")
        MandatedReporterDate  = (Get-Date "2026-01-01")
        Status = "Current"
    },
    @{
        Title = "Amanda Brooks"
        StaffName = "Amanda Brooks"; Role = "LCSW"
        Facility = "Friess Home"; LicenseNumber = "LCSW-09102"
        LicenseExpiration     = (Get-Date "2027-04-30")
        FingerprintClearance  = (Get-Date "2026-08-15")
        CPRExpiration         = (Get-Date "2026-10-01")
        HIPAATrainingDate     = (Get-Date "2025-10-15")
        HIPAADueDate          = (Get-Date "2026-10-15")
        CulturalCompDate      = (Get-Date "2025-08-01")
        TraumaInformedDate    = (Get-Date "2025-09-01")
        MandatedReporterDate  = (Get-Date "2025-07-01")
        Status = "Current"
    },
    @{
        Title = "Dr. Nicole Voss"
        StaffName = "Dr. Nicole Voss"; Role = "LPC"
        Facility = "IOP Clinic"; LicenseNumber = "LPC-12004"
        LicenseExpiration     = (Get-Date "2028-01-31")
        FingerprintClearance  = (Get-Date "2027-06-30")
        CPRExpiration         = (Get-Date "2026-11-01")
        HIPAATrainingDate     = (Get-Date "2026-02-20")
        HIPAADueDate          = (Get-Date "2027-02-20")
        CulturalCompDate      = (Get-Date "2026-02-01")
        TraumaInformedDate    = (Get-Date "2026-02-01")
        MandatedReporterDate  = (Get-Date "2026-02-01")
        Status = "Current"
    },
    @{
        Title = "Marcus Johnson"
        StaffName = "Marcus Johnson"; Role = "LAC"
        Facility = "Roadrunner Home"; LicenseNumber = "LAC-30221"
        LicenseExpiration     = (Get-Date "2026-07-31")
        FingerprintClearance  = (Get-Date "2027-04-10")
        CPRExpiration         = (Get-Date "2026-03-15")
        HIPAATrainingDate     = (Get-Date "2025-08-01")
        HIPAADueDate          = (Get-Date "2026-08-01")
        CulturalCompDate      = (Get-Date "2025-06-01")
        TraumaInformedDate    = (Get-Date "2025-07-01")
        MandatedReporterDate  = (Get-Date "2025-06-15")
        SupervisionCurrent    = $true
        Status = "Action Required"
    },
    @{
        Title = "Destiny Morales"
        StaffName = "Destiny Morales"; Role = "BHT"
        Facility = "Blossom House"; LicenseNumber = "BHT-N/A"
        FingerprintClearance  = (Get-Date "2027-08-01")
        CPRExpiration         = (Get-Date "2026-02-15")
        HIPAATrainingDate     = (Get-Date "2025-12-01")
        HIPAADueDate          = (Get-Date "2026-12-01")
        CulturalCompDate      = (Get-Date "2025-11-01")
        TraumaInformedDate    = (Get-Date "2025-11-15")
        MandatedReporterDate  = (Get-Date "2025-11-01")
        SupervisionCurrent    = $true
        Status = "Expired"
    },
    @{
        Title = "Chris Blackwell"
        StaffName = "Chris Blackwell"; Role = "BHT"
        Facility = "Charter Oak Home"; LicenseNumber = "BHT-N/A"
        FingerprintClearance  = (Get-Date "2026-05-30")
        CPRExpiration         = (Get-Date "2026-06-01")
        HIPAATrainingDate     = (Get-Date "2026-01-15")
        HIPAADueDate          = (Get-Date "2027-01-15")
        CulturalCompDate      = (Get-Date "2025-12-15")
        TraumaInformedDate    = (Get-Date "2026-01-01")
        MandatedReporterDate  = (Get-Date "2026-01-01")
        SupervisionCurrent    = $true
        Status = "Current"
    },
    @{
        Title = "Alicia Ruiz"
        StaffName = "Alicia Ruiz"; Role = "CPSS"
        Facility = "Rose Garden"; LicenseNumber = "CPSS-4418"
        LicenseExpiration     = (Get-Date "2026-12-31")
        FingerprintClearance  = (Get-Date "2027-03-01")
        CPRExpiration         = (Get-Date "2026-04-15")
        HIPAATrainingDate     = (Get-Date "2025-09-01")
        HIPAADueDate          = (Get-Date "2026-09-01")
        CulturalCompDate      = (Get-Date "2025-08-15")
        TraumaInformedDate    = (Get-Date "2025-09-01")
        MandatedReporterDate  = (Get-Date "2025-08-15")
        SupervisionCurrent    = $true
        Status = "Current"
    },
    @{
        Title = "Brian Reinhart"
        StaffName = "Brian Reinhart"; Role = "Admin"
        Facility = "Corporate"; LicenseNumber = "N/A"
        FingerprintClearance  = (Get-Date "2027-07-01")
        CPRExpiration         = (Get-Date "2026-12-01")
        HIPAATrainingDate     = (Get-Date "2026-02-15")
        HIPAADueDate          = (Get-Date "2027-02-15")
        CulturalCompDate      = (Get-Date "2026-01-15")
        TraumaInformedDate    = (Get-Date "2026-01-15")
        MandatedReporterDate  = (Get-Date "2026-01-15")
        Status = "Current"
    },
    @{
        Title = "Priya Sharma"
        StaffName = "Priya Sharma"; Role = "Admissions"
        Facility = "IOP Clinic"; LicenseNumber = "N/A"
        FingerprintClearance  = (Get-Date "2026-06-15")
        CPRExpiration         = (Get-Date "2026-05-01")
        HIPAATrainingDate     = (Get-Date "2025-07-01")
        HIPAADueDate          = (Get-Date "2026-07-01")
        CulturalCompDate      = (Get-Date "2025-06-01")
        TraumaInformedDate    = (Get-Date "2025-06-15")
        MandatedReporterDate  = (Get-Date "2025-06-01")
        Status = "Action Required"
    },
    @{
        Title = "Derek Washington"
        StaffName = "Derek Washington"; Role = "Operations"
        Facility = "Corporate"; LicenseNumber = "N/A"
        FingerprintClearance  = (Get-Date "2027-09-01")
        CPRExpiration         = (Get-Date "2026-08-15")
        HIPAATrainingDate     = (Get-Date "2026-01-01")
        HIPAADueDate          = (Get-Date "2027-01-01")
        CulturalCompDate      = (Get-Date "2025-12-01")
        TraumaInformedDate    = (Get-Date "2025-12-15")
        MandatedReporterDate  = (Get-Date "2025-12-01")
        Status = "Current"
    }
)

foreach ($row in $staffData) {
    Add-ListItemSafe -ListName "Staff Credential Tracker" -Values $row -KeyField "StaffName" -KeyValue $row.StaffName
}

# ============================================================================
# LIST 7: Revenue by Payer (7 rows — Feb 2026)
# ============================================================================
Write-Step "Seeding: Revenue by Payer"

$revenueData = @(
    @{
        Title         = "Mercy Care — Feb 2026"
        Month         = (Get-Date "2026-02-01")
        Payer         = "Mercy Care"
        Revenue       = 485000
        ClaimCount    = 312
        DenialCount   = 12
        CleanClaimPct = 96.2
        Notes         = "Largest AHCCCS payer. Residential + IOP claims."
    },
    @{
        Title         = "UHCCP — Feb 2026"
        Month         = (Get-Date "2026-02-01")
        Payer         = "UHCCP"
        Revenue       = 380000
        ClaimCount    = 245
        DenialCount   = 8
        CleanClaimPct = 96.7
    },
    @{
        Title         = "Cigna — Feb 2026"
        Month         = (Get-Date "2026-02-01")
        Payer         = "Cigna"
        Revenue       = 310000
        ClaimCount    = 178
        DenialCount   = 14
        CleanClaimPct = 92.1
        Notes         = "Higher denial rate — prior auth issues. Follow up with rep."
    },
    @{
        Title         = "Aetna — Feb 2026"
        Month         = (Get-Date "2026-02-01")
        Payer         = "Aetna"
        Revenue       = 195000
        ClaimCount    = 124
        DenialCount   = 6
        CleanClaimPct = 95.2
    },
    @{
        Title         = "Humana — Feb 2026"
        Month         = (Get-Date "2026-02-01")
        Payer         = "Humana"
        Revenue       = 145000
        ClaimCount    = 95
        DenialCount   = 4
        CleanClaimPct = 95.8
    },
    @{
        Title         = "Private Pay — Feb 2026"
        Month         = (Get-Date "2026-02-01")
        Payer         = "Private Pay"
        Revenue       = 85000
        ClaimCount    = 18
        DenialCount   = 0
        CleanClaimPct = 100
        Notes         = "Self-pay and out-of-network reimbursement."
    },
    @{
        Title         = "SCA/Other — Feb 2026"
        Month         = (Get-Date "2026-02-01")
        Payer         = "SCA/Other"
        Revenue       = 52000
        ClaimCount    = 34
        DenialCount   = 5
        CleanClaimPct = 85.3
        Notes         = "Single case agreements. Higher admin burden, lower clean claim rate."
    }
)

foreach ($row in $revenueData) {
    Add-ListItemSafe -ListName "Revenue by Payer" -Values $row -KeyField "Title" -KeyValue $row.Title
}

# ============================================================================
# LIST 8: Reentry Participants (6 rows)
# ============================================================================
Write-Step "Seeding: Reentry Participants"

$reentryData = @(
    @{
        Title            = "RE-001"
        ParticipantID    = "RE-001"
        EnrollDate       = (Get-Date "2025-11-15")
        Phase            = "Community Transition"
        Facility         = "IOP Clinic"
        HousingStatus    = "Placed (Sober Living)"
        EmploymentStatus = "Employed (PT)"
        CourtInvolved    = $true
        CourtCompliance  = "Compliant"
        NextStep         = "Full-time employment search; lease application by April"
        Notes            = "Strong progress. 109 days in program. Oxford House placement stable. Part-time warehouse work since Jan."
    },
    @{
        Title            = "RE-002"
        ParticipantID    = "RE-002"
        EnrollDate       = (Get-Date "2025-12-20")
        Phase            = "IOP + Housing Search"
        Facility         = "IOP Clinic"
        HousingStatus    = "Searching"
        EmploymentStatus = "Job Training"
        CourtInvolved    = $true
        CourtCompliance  = "Check-In Due"
        NextStep         = "Complete OSHA-10 cert; housing application for Homeward Bound"
        Notes            = "74 days in program. In job training through Goodwill. Court check-in due 3/10."
    },
    @{
        Title            = "RE-003"
        ParticipantID    = "RE-003"
        EnrollDate       = (Get-Date "2026-01-10")
        Phase            = "PHP Step-Down"
        Facility         = "Rose Garden"
        HousingStatus    = "Pending"
        EmploymentStatus = "Not Yet"
        CourtInvolved    = $false
        CourtCompliance  = "N/A"
        NextStep         = "Transition to IOP by mid-March; begin housing assessment"
        Notes            = "53 days in program. Stepped down from residential to PHP. Good clinical engagement."
    },
    @{
        Title            = "RE-004"
        ParticipantID    = "RE-004"
        EnrollDate       = (Get-Date "2026-01-28")
        Phase            = "Residential Stabilization"
        Facility         = "Charter Oak Home"
        HousingStatus    = "Future"
        EmploymentStatus = "Not Yet"
        CourtInvolved    = $true
        CourtCompliance  = "Compliant"
        NextStep         = "Complete residential phase; begin PHP transition planning"
        Notes            = "35 days in program. Court-ordered 90-day minimum. Stabilizing well. Probation officer engaged."
    },
    @{
        Title            = "RE-005"
        ParticipantID    = "RE-005"
        EnrollDate       = (Get-Date "2025-09-01")
        Phase            = "Alumni/Aftercare"
        Facility         = "Community"
        HousingStatus    = "Placed (Independent)"
        EmploymentStatus = "Employed (FT)"
        CourtInvolved    = $true
        CourtCompliance  = "Compliant"
        NextStep         = "Monthly alumni check-in; court compliance reporting"
        Notes            = "185 days. Program graduate. Independent housing secured. FT employment at distribution center. Mentor to RE-001."
    },
    @{
        Title            = "RE-006"
        ParticipantID    = "RE-006"
        EnrollDate       = (Get-Date "2026-02-14")
        Phase            = "Residential Stabilization"
        Facility         = "Roadrunner Home"
        HousingStatus    = "Future"
        EmploymentStatus = "Not Yet"
        CourtInvolved    = $false
        CourtCompliance  = "N/A"
        NextStep         = "Engage in treatment planning; assess vocational interests"
        Notes            = "18 days in program. Self-referred. History of chronic homelessness. Early stabilization phase."
    }
)

foreach ($row in $reentryData) {
    Add-ListItemSafe -ListName "Reentry Participants" -Values $row -KeyField "ParticipantID" -KeyValue $row.ParticipantID
}

# ============================================================================
# LIST 9: Marketing Campaigns (6 rows)
# ============================================================================
Write-Step "Seeding: Marketing Campaigns"

$marketingData = @(
    @{
        Title        = "Google Ads — Phoenix BH"
        CampaignName = "Google Ads — Phoenix BH"
        Channel      = "Google Ads"
        SpendMTD     = 12500
        Leads        = 89
        CPL          = 140
        Admits       = 8
        CPA          = 1563
        Status       = "Live"
        StartDate    = (Get-Date "2026-01-01")
        Notes        = "Primary paid channel. Targeting 'drug rehab Phoenix', 'alcohol treatment Arizona', 'IOP near me'. CTR 4.2%."
    },
    @{
        Title        = "SEO / Organic Traffic"
        CampaignName = "SEO / Organic Traffic"
        Channel      = "SEO/Organic"
        SpendMTD     = 4500
        Leads        = 124
        CPL          = 36
        Admits       = 11
        CPA          = 409
        Status       = "Live"
        StartDate    = (Get-Date "2025-06-01")
        Notes        = "Best ROI channel. Blog content + service pages driving organic leads. Ranking page 1 for 14 target keywords."
    },
    @{
        Title        = "Facebook / Instagram Ads"
        CampaignName = "Facebook / Instagram Ads"
        Channel      = "Facebook/Instagram"
        SpendMTD     = 6800
        Leads        = 52
        CPL          = 131
        Admits       = 3
        CPA          = 2267
        Status       = "Live"
        StartDate    = (Get-Date "2026-01-15")
        Notes        = "Awareness + retargeting campaigns. Lower intent but building brand pipeline. Testing new creative Q1."
    },
    @{
        Title        = "Referral Partner Outreach"
        CampaignName = "Referral Partner Outreach"
        Channel      = "Referral Partners"
        SpendMTD     = 2200
        Leads        = 49
        CPL          = 45
        Admits       = 18
        CPA          = 122
        Status       = "Live"
        StartDate    = (Get-Date "2025-01-01")
        Notes        = "Highest conversion channel. Includes hospital ED liaison, court referrals, and therapist network. Spend is BD team costs."
    },
    @{
        Title        = "Community Events — Q1"
        CampaignName = "Community Events — Q1"
        Channel      = "Community Events"
        SpendMTD     = 1800
        Leads        = 15
        CPL          = 120
        Admits       = 2
        CPA          = 900
        Status       = "Live"
        StartDate    = (Get-Date "2026-01-01")
        EndDate      = (Get-Date "2026-03-31")
        Notes        = "CORE Team outreach events. Narcan training, community talks, recovery month. Brand awareness + pipeline."
    },
    @{
        Title        = "LegitScript / Directory Listings"
        CampaignName = "LegitScript / Directory Listings"
        Channel      = "LegitScript/Directories"
        SpendMTD     = 1500
        Leads        = 31
        CPL          = 48
        Admits       = 4
        CPA          = 375
        Status       = "Live"
        StartDate    = (Get-Date "2025-09-01")
        Notes        = "LegitScript certified. Listed on SAMHSA, Psychology Today, Rehabs.com. Steady baseline leads."
    }
)

foreach ($row in $marketingData) {
    Add-ListItemSafe -ListName "Marketing Campaigns" -Values $row -KeyField "CampaignName" -KeyValue $row.CampaignName
}

# ============================================================================
# DONE
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host " Seed Data Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`n   Facility Census Tracker:   9 rows" -ForegroundColor Cyan
Write-Host "   Compliance Audit Calendar: 6 rows" -ForegroundColor Cyan
Write-Host "   Incident Reports:          4 rows" -ForegroundColor Cyan
Write-Host "   Admissions Pipeline:       6 rows" -ForegroundColor Cyan
Write-Host "   Referral Partners:         8 rows" -ForegroundColor Cyan
Write-Host "   Staff Credential Tracker:  15 rows" -ForegroundColor Cyan
Write-Host "   Revenue by Payer:          7 rows" -ForegroundColor Cyan
Write-Host "   Reentry Participants:      6 rows" -ForegroundColor Cyan
Write-Host "   Marketing Campaigns:       6 rows" -ForegroundColor Cyan
Write-Host "`n   Total: 67 sample records across 9 lists" -ForegroundColor Yellow
Write-Host ""
