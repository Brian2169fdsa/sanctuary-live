# Sanctuary Recovery Centers — SharePoint Operations Hub
## Complete Deployment Package for Claude Code

> **Project:** Sanctuary Recovery Centers IOP/Residential Operations Hub
> **Client:** Sanctuary Recovery Centers — 11645 N Cave Creek Rd, Phoenix, AZ 85020
> **Prepared by:** Manage AI (brian@manageai.io)
> **Date:** March 2026

---

## HOW TO USE THIS DOCUMENT

This is a Claude Code prompt. Open a terminal, run `claude`, paste or reference this file, and Claude Code will generate three deliverables:

1. **PnP PowerShell provisioning script** — creates the entire SharePoint site, pages, lists, document libraries, navigation, and theming
2. **PnP page templates with web parts pre-placed** — deploys all 9 pages with document library, list, Power BI, and embed web parts already wired up
3. **Power BI data model specification** — table schemas, relationships, DAX measures, and sample data for a connected dashboard

---

## PART 1: PnP POWERSHELL PROVISIONING SCRIPT

### Instructions for Claude Code

Generate a single PowerShell script called `Deploy-SanctuaryHub.ps1` that uses PnP PowerShell (PnP.PowerShell module) to provision the entire SharePoint site. The script should be idempotent (safe to re-run). Include error handling and progress output.

### Prerequisites Block

The script should start with a prerequisites check:

```
# Required: PnP.PowerShell module
# Install-Module -Name PnP.PowerShell -Scope CurrentUser
# Required: SharePoint Admin or Site Collection Admin permissions
# Required: PowerShell 7+
```

### Connection

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$TenantUrl,       # e.g., "https://sanctuary.sharepoint.com"
    [Parameter(Mandatory=$true)]
    [string]$SiteAlias,       # e.g., "ops-hub"
    [string]$SiteTitle = "Sanctuary Operations Hub",
    [switch]$SkipSiteCreation  # if site already exists
)

Connect-PnPOnline -Url $TenantUrl -Interactive
```

### 1.1 Site Creation

- Create a Communication Site (not Team Site — better for dashboards)
- Site name: "Sanctuary Operations Hub"
- Site alias: `ops-hub` (or parameterized)
- Template: `STS#3` (Communication Site)
- Locale: 1033 (English US)
- Time zone: 15 (Arizona — no DST)

### 1.2 Branding / Theming

Apply a custom theme matching Sanctuary brand:

```json
{
    "name": "Sanctuary Recovery Centers",
    "isInverted": false,
    "palette": {
        "themePrimary": "#e8732a",
        "themeLighterAlt": "#fef7f2",
        "themeLighter": "#fbe0cc",
        "themeLight": "#f7c5a3",
        "themeTertiary": "#ef8f52",
        "themeSecondary": "#e97e35",
        "themeDarkAlt": "#d16826",
        "themeDark": "#b05820",
        "themeDarker": "#824118",
        "neutralLighterAlt": "#faf9f8",
        "neutralLighter": "#f3f2f1",
        "neutralLight": "#edebe9",
        "neutralQuaternaryAlt": "#e1dfdd",
        "neutralQuaternary": "#d2d0ce",
        "neutralTertiaryAlt": "#c8c6c4",
        "neutralTertiary": "#a19f9d",
        "neutralSecondary": "#605e5c",
        "neutralPrimaryAlt": "#3b3a39",
        "neutralPrimary": "#323130",
        "neutralDark": "#201f1e",
        "black": "#000000",
        "white": "#ffffff",
        "primaryBackground": "#ffffff",
        "primaryText": "#323130",
        "accent": "#4dc8e8"
    }
}
```

Upload the Sanctuary logo (from `./assets/sanctuary-logo.png`) as the site logo.

### 1.3 Hub Navigation

Create top navigation with 9 links. The nav labels and target pages:

| Order | Label | Target Page |
|-------|-------|-------------|
| 1 | Home | SitePages/Home.aspx |
| 2 | CEO | SitePages/CEO-Dashboard.aspx |
| 3 | Clinical | SitePages/Clinical-Department.aspx |
| 4 | Admissions | SitePages/Admissions-Department.aspx |
| 5 | Marketing | SitePages/Marketing-Department.aspx |
| 6 | Business Development | SitePages/Business-Development.aspx |
| 7 | Human Resources | SitePages/Human-Resources.aspx |
| 8 | Administration | SitePages/Administration.aspx |
| 9 | Reentry Program | SitePages/Reentry-Program.aspx |

### 1.4 Document Libraries

Create these document libraries with folder structures. Each library maps to a department page:

#### CEO Documents
```
CEO-Documents/
├── Licensing-and-Accreditation/
│   ├── (placeholder: Joint Commission Certificate of Accreditation.pdf)
│   ├── (placeholder: AZDHS BH License – Roadrunner Home.pdf)
│   ├── (placeholder: AZDHS BH License – Blossom House.pdf)
│   ├── (placeholder: AZDHS BH License – Rosemonte Home.pdf)
│   ├── (placeholder: DEA Registration – All Facilities.pdf)
│   ├── (placeholder: LegitScript Certification.pdf)
│   └── (placeholder: ASU Partnership Agreement – Blossom House.pdf)
├── Payer-Contracts/
│   ├── (placeholder: AHCCCS – Mercy Care Contract.pdf)
│   ├── (placeholder: AHCCCS – UHCCP Agreement.pdf)
│   ├── (placeholder: Cigna Evernorth Provider Agreement.pdf)
│   ├── (placeholder: Aetna Behavioral Health Agreement.pdf)
│   ├── (placeholder: Humana Provider Contract.pdf)
│   └── (placeholder: Single Case Agreement SCA Template.docx)
├── Strategic-Planning-Board-Reports/
│   ├── (placeholder: 2026 Strategic Growth Plan.pdf)
│   ├── (placeholder: Board Report – Feb 2026.pptx)
│   ├── (placeholder: Board Report – Jan 2026.pptx)
│   ├── (placeholder: Expansion Feasibility – Tempe Mesa Market.pdf)
│   └── (placeholder: Financial Summary Q4 2025.xlsx)
├── Risk-Management-Insurance/
│   ├── (placeholder: Professional Liability Policy 2026.pdf)
│   ├── (placeholder: General Liability Certificate All Properties.pdf)
│   ├── (placeholder: Risk Assessment Matrix Q1 2026.xlsx)
│   ├── (placeholder: Emergency Preparedness Plan All Sites.pdf)
│   └── (placeholder: Workers Comp Policy.pdf)
└── CORE-Team-Community-Programs/
    ├── (placeholder: CORE Team Charter and Outreach Plan.pdf)
    ├── (placeholder: Reentry Program SOP.docx)
    └── (placeholder: ASU Womens Trauma Research MOU.pdf)
```

#### Clinical Documents
```
Clinical-Documents/
├── SOPs-and-Protocols/
│   ├── (placeholder: Suicide Risk Assessment Protocol QPR.pdf)
│   ├── (placeholder: ASAM Criteria Level of Care Guidelines.pdf)
│   ├── (placeholder: Treatment Plan Standards AHCCCS Requirements.pdf)
│   ├── (placeholder: Progress Note Documentation Guide.pdf)
│   ├── (placeholder: Group Facilitation Manual.pdf)
│   ├── (placeholder: Medication Management Protocol.pdf)
│   └── (placeholder: AMA Discharge Safety Planning SOP.pdf)
└── Therapeutic-Modality-Guides/
    ├── (placeholder: CBT Implementation Guide.pdf)
    ├── (placeholder: DBT Skills Training Manual.pdf)
    ├── (placeholder: EMDR Protocol Trauma Processing.pdf)
    ├── (placeholder: ART Accelerated Resolution Therapy Guide.pdf)
    ├── (placeholder: Equine Therapy Session Protocol.pdf)
    └── (placeholder: Sand Tray Expressive Arts Therapy Guide.pdf)
```

#### Admissions Documents
```
Admissions-Documents/
├── Intake-Forms-Assessments/
│   ├── (placeholder: Biopsychosocial Assessment Template.docx)
│   ├── (placeholder: ASAM Level of Care Determination Guide.pdf)
│   ├── (placeholder: Client Consent Rights Packet.pdf)
│   ├── (placeholder: PHQ9 GAD7 AUDITC Screening Tools.pdf)
│   ├── (placeholder: Adolescent Intake Packet Friess Home.pdf)
│   └── (placeholder: Reentry Program Eligibility Checklist.pdf)
└── Insurance-VOB-Resources/
    ├── (placeholder: VOB Process SOP Phone Scripts.pdf)
    ├── (placeholder: Mercy Care Prior Auth Requirements.pdf)
    ├── (placeholder: UHCCP Authorization Procedures.pdf)
    ├── (placeholder: Single Case Agreement SCA Template.docx)
    └── (placeholder: Out of Network Benefits Guide.pdf)
```

#### Marketing Documents
```
Marketing-Documents/
├── Brand-Assets/
│   ├── (placeholder: Sanctuary Brand Guidelines v3.pdf)
│   ├── (placeholder: Logo Pack Phoenix Lotus.zip)
│   ├── (placeholder: Photography Library Facilities.zip)
│   ├── (placeholder: Color Typography Spec.pdf)
│   ├── (placeholder: Email Signature Templates.html)
│   └── (placeholder: Presentation Template Sanctuary.pptx)
├── Website-Content-SEO/
│   ├── (placeholder: Service Page Copy All Programs.docx)
│   ├── (placeholder: SEO Keyword Research Q1 2026.xlsx)
│   ├── (placeholder: Blog Post Calendar Assignments.xlsx)
│   └── (placeholder: Facility Page Photography Shot List.docx)
└── Compliance-Ad-Review/
    ├── (placeholder: Ad Copy Compliance Checklist Anti-Inducement.pdf)
    ├── (placeholder: LegitScript Certification Requirements.pdf)
    └── (placeholder: Client Testimonial Release HIPAA Consent.pdf)
```

#### BD Documents
```
BD-Documents/
├── Referral-Agreements-MOUs/
│   ├── (placeholder: Banner Health Referral Agreement.pdf)
│   ├── (placeholder: HonorHealth MOU.pdf)
│   ├── (placeholder: Standard Referral Agreement Template.docx)
│   ├── (placeholder: Anti-Kickback Compliance Addendum.pdf)
│   └── (placeholder: Maricopa County Court Liaison Agreement.pdf)
└── Outreach-Materials/
    ├── (placeholder: Facility Presentation Deck.pptx)
    ├── (placeholder: One-Pager Sanctuary Services Overview.pdf)
    ├── (placeholder: Cold Outreach Script Hospital EDs.pdf)
    └── (placeholder: Follow-Up Email Templates.docx)
```

#### HR Documents
```
HR-Documents/
├── Employee-Handbook-Policies/
│   ├── (placeholder: Employee Handbook v5.1.pdf)
│   ├── (placeholder: Trauma-Informed Workplace Policy.pdf)
│   ├── (placeholder: Dual Relationships Boundary Policy.pdf)
│   ├── (placeholder: Staff Wellness Burnout Prevention Plan.pdf)
│   ├── (placeholder: Drug-Free Workplace Policy.pdf)
│   └── (placeholder: Social Media HIPAA Confidentiality Policy.pdf)
└── Job-Descriptions-BH-Roles/
    ├── (placeholder: Licensed Professional Counselor LPC.docx)
    ├── (placeholder: Licensed Independent Substance Abuse Counselor LISAC.docx)
    ├── (placeholder: Licensed Clinical Social Worker LCSW.docx)
    ├── (placeholder: Behavioral Health Technician BHT.docx)
    ├── (placeholder: Peer Support Specialist CPSS.docx)
    └── (placeholder: Reentry Program Coordinator.docx)
```

#### Administration Documents
```
Admin-Documents/
├── AHCCCS-Billing-Guides/
│   ├── (placeholder: AHCCCS Residential Billing Manual 2026.pdf)
│   ├── (placeholder: Mercy Care Provider Manual.pdf)
│   ├── (placeholder: CPT Code Quick Reference BH Services.pdf)
│   └── (placeholder: Denial Appeal Process SOP.pdf)
└── Corporate-Compliance/
    ├── (placeholder: Corporate Compliance Plan 2026.pdf)
    ├── (placeholder: HIPAA Privacy Security Policies.pdf)
    ├── (placeholder: Fraud Waste Abuse Prevention Plan.pdf)
    └── (placeholder: Emergency Preparedness Plan All Sites.pdf)
```

#### Reentry Program Documents
```
Reentry-Documents/
├── Program-SOPs-Protocols/
│   ├── (placeholder: Reentry Program Manual v2.0.pdf)
│   ├── (placeholder: Phase Transition Criteria Assessment.pdf)
│   ├── (placeholder: Housing Readiness Checklist.pdf)
│   ├── (placeholder: Employment Readiness Assessment.pdf)
│   └── (placeholder: Court Compliance Reporting Template.docx)
└── CORE-Team-Resources/
    ├── (placeholder: CORE Team Charter Mission.pdf)
    ├── (placeholder: Community Partner Directory.xlsx)
    ├── (placeholder: Partner Onboarding Guide.pdf)
    └── (placeholder: ASU Partnership Womens Trauma Research MOU.pdf)
```

For placeholder files: create a tiny .txt file in each location named with the placeholder name so the folder structure is visible. The client will replace with real docs later.

### 1.5 SharePoint Lists

Create these SharePoint lists with typed columns. Claude Code should generate the `Add-PnPList` and `Add-PnPField` commands for each.

#### List: Facility Census Tracker
Used by: CEO, Clinical, Admissions pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| Facility | Choice | Roadrunner Home, Blossom House, Rose Garden, Rosemonte Home, Charter Oak Home, Mercer Home, Friess Home, IOP Clinic |
| LOC | Choice | Residential, PHP, IOP |
| Census | Number | Current client count |
| Capacity | Number | Max beds/slots |
| OccupancyPct | Calculated | =Census/Capacity |
| ALOS | Number | Avg length of stay in days |
| LeadClinician | Person | Primary clinician |
| Status | Choice | Current, Waitlisted, CAP Open, License Due, Fire Drill Gap, Fire Insp Overdue, At Capacity |
| Notes | Multi-line text | |
| LastUpdated | DateTime | |

**Seed data (9 rows):**
Roadrunner Home, Residential, 16, 16, 58, "Dr. M. Reyes", Waitlisted
Blossom House, Residential, 14, 16, 72, "S. Thompson", CAP Open
Rose Garden, Residential, 12, 14, 45, "K. Patel", Current
Rosemonte Home, Residential, 14, 16, 60, "J. Martinez", License Due
Charter Oak Home, Residential, 15, 16, 55, "R. Davis", Fire Drill Gap
Mercer Home, Residential, 12, 16, 68, "L. Chen", Fire Insp Overdue
Friess Home, Residential, 10, 12, 90, "A. Brooks", Current
IOP Clinic (AM), IOP, 47, -, -, "Dr. N. Voss", Current
IOP Clinic (PHP), PHP, 18, -, -, "Dr. N. Voss", Current

#### List: Compliance Audit Calendar
Used by: CEO, Administration pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| Title | Text | Event name |
| AuditDate | DateTime | |
| AuditType | Choice | Joint Commission, AZDHS, Fire Marshal, Internal, HIPAA, Chart Audit |
| Scope | Text | Which facility or org-wide |
| Owner | Person | |
| Status | Choice | Scheduled, Preparing, Complete, Overdue, Window Open |
| DaysRemaining | Calculated | =AuditDate-Today() |
| Notes | Multi-line text | |

**Seed data (6 rows):**
Fire Drill All Sites, Mar 10 2026, Internal, All 7 homes + clinic, Operations, Scheduled
Mock JC Survey, Mar 18 2026, Joint Commission, Organization-wide, Compliance, Preparing
Internal Chart Audit, Mar 25 2026, Internal, 20 random charts, QA, Scheduled
JC Annual Survey Window, Apr 1 2026, Joint Commission, Organization-wide, Compliance, Window Open
AZDHS License Rosemonte, Apr 15 2026, AZDHS, Rosemonte Home, Operations, Scheduled
Fire Marshal Mercer, Feb 25 2026 (overdue), Fire Marshal, Mercer Home, Operations, Overdue

#### List: Incident Reports
Used by: CEO, Clinical pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| IncidentID | Text | Format: IR-2026-XXX |
| IncidentDate | DateTime | |
| Facility | Choice | (same 8 facilities) |
| Category | Choice | Client Fall, Med Discrepancy, AMA Discharge, Behavioral Escalation, Property Damage, Other |
| Severity | Choice | Critical, High, Medium, Low |
| Description | Multi-line text | |
| Status | Choice | Open, Under Review, Investigating, Resolved, Closed |
| AssignedTo | Person | |
| ResolutionDate | DateTime | |
| CorrectiveAction | Multi-line text | |

**Seed data (4 rows):**
IR-2026-042, Mar 1, Blossom House, Client Fall, Medium, Under Review
IR-2026-041, Feb 28, Charter Oak, Med Discrepancy, Medium, Open
IR-2026-040, Feb 25, Mercer Home, AMA Discharge, Low, Closed
IR-2026-039, Feb 22, Rose Garden, Property Damage, Low, Closed

#### List: Admissions Pipeline
Used by: Admissions page

| Column | Type | Values/Notes |
|--------|------|-------------|
| ReferralID | Text | Format: REF-XXXX |
| ReferralDate | DateTime | |
| Source | Choice | Hospital ED, Self-Referral, Private Therapist, Probation Officer, Alumni Referral, Sober Living, Community Outreach, Crisis Line |
| SourceDetail | Text | Specific partner name |
| PrimaryDx | Text | |
| Insurance | Choice | Mercy Care, UHCCP, Cigna, Aetna, Humana, Private Pay, Other/SCA |
| LOCRequested | Choice | Residential, PHP, IOP |
| FacilityAssigned | Choice | (same 8 facilities) |
| Stage | Choice | Lead, Screened, VOB In Progress, VOB Complete, Assessment Scheduled, Assessment Complete, Admitted, Waitlisted, Lost |
| Status | Choice | Active, Admitted, Waitlisted, No-Show, Lost to Follow-Up, Declined |
| AssessmentDate | DateTime | |
| AdmitDate | DateTime | |
| AssignedTo | Person | |
| Notes | Multi-line text | |

**Seed data (6 rows):** Use the referral table data from the Admissions mockup (REF-0337 through REF-0342).

#### List: Referral Partners
Used by: BD, Admissions pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| PartnerName | Text | |
| PartnerType | Choice | Hospital ED, Crisis Services, Courts, Outpatient MDs, Sober Living, Therapist, Community Org |
| Territory | Choice | North Phoenix, Scottsdale, East Valley, Tempe, West Valley, County-Wide, Metro PHX |
| ContactName | Text | |
| ContactEmail | Text | |
| ContactPhone | Text | |
| ReferralsMTD | Number | |
| AdmitsMTD | Number | |
| ConversionPct | Calculated | =AdmitsMTD/ReferralsMTD |
| LastContact | DateTime | |
| AgreementOnFile | Yes/No | |
| Status | Choice | Active, Follow-Up, New Partner, Inactive |
| Notes | Multi-line text | |

**Seed data (8 rows):** Use the partner CRM data from the BD mockup.

#### List: Staff Credential Tracker
Used by: HR page

| Column | Type | Values/Notes |
|--------|------|-------------|
| StaffName | Text | |
| Role | Choice | LPC, LISAC, LCSW, LAC, BHT, CPSS, Admin, Admissions, Operations |
| Facility | Choice | (same 8 facilities + Corporate) |
| LicenseNumber | Text | |
| LicenseExpiration | DateTime | |
| FingerprintClearance | DateTime | FPC Level 1 expiration |
| CPRExpiration | DateTime | |
| HIPAATrainingDate | DateTime | Last completion |
| HIPAADueDate | DateTime | |
| CulturalCompDate | DateTime | |
| TraumaInformedDate | DateTime | |
| MandatedReporterDate | DateTime | |
| SupervisionCurrent | Yes/No | Only for LAC/BHT/CPSS |
| Status | Choice | Current, Expiring Soon, Expired, Action Required |

**Seed data:** Generate 12-15 representative rows covering different roles and expiration scenarios.

#### List: Revenue by Payer
Used by: CEO, Administration pages

| Column | Type | Values/Notes |
|--------|------|-------------|
| Month | DateTime | |
| Payer | Choice | Mercy Care, UHCCP, Cigna, Aetna, Humana, Private Pay, SCA/Other |
| Revenue | Currency | |
| ClaimCount | Number | |
| DenialCount | Number | |
| CleanClaimPct | Number (%) | |
| Notes | Multi-line text | |

**Seed data:** Use the payer mix data from the Administration mockup for Feb 2026.

#### List: Reentry Participants
Used by: Reentry Program page

| Column | Type | Values/Notes |
|--------|------|-------------|
| ParticipantID | Text | Format: RE-XXX |
| EnrollDate | DateTime | |
| Phase | Choice | Residential Stabilization, PHP Step-Down, IOP + Housing Search, Community Transition, Alumni/Aftercare |
| Facility | Text | Current location |
| DaysInProgram | Calculated | =Today()-EnrollDate |
| HousingStatus | Choice | Future, Pending, Searching, Placed (Sober Living), Placed (Independent), Lost |
| EmploymentStatus | Choice | Not Yet, Job Training, Job Search, Interviewing, Employed (PT), Employed (FT), Lost |
| CourtInvolved | Yes/No | |
| CourtCompliance | Choice | Compliant, Check-In Due, Non-Compliant, N/A |
| CaseManager | Person | |
| NextStep | Text | |
| Notes | Multi-line text | |

**Seed data (6 rows):** Use the participant data from the Reentry mockup.

#### List: Marketing Campaigns
Used by: Marketing page

| Column | Type | Values/Notes |
|--------|------|-------------|
| CampaignName | Text | |
| Channel | Choice | Google Ads, SEO/Organic, Facebook/Instagram, Referral Partners, Community Events, LegitScript/Directories |
| SpendMTD | Currency | |
| Leads | Number | |
| CPL | Currency | Calculated or manual |
| Admits | Number | |
| CPA | Currency | |
| Status | Choice | Live, Building, Paused, Completed |
| StartDate | DateTime | |
| EndDate | DateTime | |
| Notes | Multi-line text | |

**Seed data:** Use the channel performance data from the Marketing mockup.

---

## PART 2: PAGE TEMPLATES WITH WEB PARTS

### Instructions for Claude Code

Generate a PnP PowerShell script called `Deploy-SanctuaryPages.ps1` that creates all 9 SharePoint pages using `Add-PnPPage` and adds web parts using `Add-PnPPageWebPart`.

For each page, the layout is:

1. **Top section:** Text web part with branded HTML header (page title, tagline) — or Embed web part iframing the KPI dashboard section from hosted HTML
2. **Middle sections:** Native SharePoint web parts
3. **Bottom sections:** Document Library web parts

### Web Part Reference

Use these web part IDs for `Add-PnPPageWebPart`:

| Web Part | Internal Name / ID |
|----------|-------------------|
| Document Library | `DocumentLibrary` — property: `libraryId` |
| List | `List` — property: `listId` |
| Power BI | `544dd15b-cf3c-441b-96da-004d5a8cea1d` — property: `reportUrl` |
| Embed | `490d7c76-1824-45b2-9de3-676421c997fa` — property: `embedCode` or `websiteUrl` |
| Text / Markdown | `Text` — property: `innerHTML` |
| Quick Links | `QuickLinks` |
| Hero | `Hero` |

### Page Definitions

#### Home Page (Home.aspx)
- Hero web part with Sanctuary branding image
- Quick Links web part → links to all 8 department pages
- Text web part with welcome message and "True Healing & Continued Care™"

#### CEO Dashboard (CEO-Dashboard.aspx)
- **Section 1 (Full width):** Embed web part → iframe to hosted CEO KPI dashboard HTML
- **Section 2 (Full width):** Power BI web part → `{POWER_BI_REPORT_URL}` placeholder
- **Section 3 (Two columns):**
  - Left: List web part → Facility Census Tracker
  - Right: List web part → Compliance Audit Calendar
- **Section 4 (Full width):** Document Library web part → CEO-Documents
- **Section 5 (Two columns):**
  - Left: List web part → Incident Reports
  - Right: List web part → Revenue by Payer

#### Clinical Department (Clinical-Department.aspx)
- **Section 1:** Embed web part → iframe to hosted Clinical KPI dashboard HTML
- **Section 2:** List web part → Facility Census Tracker (filtered view: all facilities)
- **Section 3:** Document Library web part → Clinical-Documents
- **Section 4 (Two columns):**
  - Left: List web part → Incident Reports (filtered: clinical categories)
  - Right: Embed web part → Group Schedule HTML section

#### Admissions Department (Admissions-Department.aspx)
- **Section 1:** Embed web part → iframe to hosted Admissions KPI + Funnel HTML
- **Section 2:** List web part → Admissions Pipeline
- **Section 3:** Document Library web part → Admissions-Documents
- **Section 4 (Two columns):**
  - Left: List web part → Referral Partners
  - Right: List web part → Facility Census Tracker (bed availability view)

#### Marketing Department (Marketing-Department.aspx)
- **Section 1:** Embed web part → iframe to hosted Marketing KPI dashboard HTML
- **Section 2:** List web part → Marketing Campaigns
- **Section 3:** Document Library web part → Marketing-Documents
- **Section 4:** Power BI web part → Marketing analytics report placeholder

#### Business Development (Business-Development.aspx)
- **Section 1:** Embed web part → iframe to hosted BD KPI dashboard HTML
- **Section 2:** List web part → Referral Partners
- **Section 3:** Document Library web part → BD-Documents
- **Section 4:** List web part → Marketing Campaigns (filtered: Referral Partners, Community Events)

#### Human Resources (Human-Resources.aspx)
- **Section 1:** Embed web part → iframe to hosted HR KPI dashboard HTML
- **Section 2:** List web part → Staff Credential Tracker
- **Section 3:** Document Library web part → HR-Documents
- **Section 4:** Embed web part → BH Training Matrix HTML section

#### Administration (Administration.aspx)
- **Section 1:** Embed web part → iframe to hosted Admin KPI dashboard HTML (tabbed billing/compliance/facilities)
- **Section 2:** List web part → Revenue by Payer
- **Section 3:** List web part → Compliance Audit Calendar
- **Section 4:** Document Library web part → Admin-Documents

#### Reentry Program (Reentry-Program.aspx)
- **Section 1:** Embed web part → iframe to hosted Reentry KPI + Pipeline HTML
- **Section 2:** List web part → Reentry Participants
- **Section 3:** Document Library web part → Reentry-Documents
- **Section 4:** List web part → Referral Partners (filtered: Courts, Employment, Housing, Support)

### Embed URLs

The embed web parts will reference hosted HTML files. Generate a mapping file (`embed-urls.json`) with placeholders:

```json
{
    "ceo_dashboard": "https://{GITHUB_PAGES_URL}/Sanctuary_CEO_Dashboard_KPIs.html",
    "clinical_dashboard": "https://{GITHUB_PAGES_URL}/Sanctuary_Clinical_KPIs.html",
    "admissions_dashboard": "https://{GITHUB_PAGES_URL}/Sanctuary_Admissions_KPIs.html",
    "marketing_dashboard": "https://{GITHUB_PAGES_URL}/Sanctuary_Marketing_KPIs.html",
    "bd_dashboard": "https://{GITHUB_PAGES_URL}/Sanctuary_BD_KPIs.html",
    "hr_dashboard": "https://{GITHUB_PAGES_URL}/Sanctuary_HR_KPIs.html",
    "admin_dashboard": "https://{GITHUB_PAGES_URL}/Sanctuary_Admin_KPIs.html",
    "reentry_dashboard": "https://{GITHUB_PAGES_URL}/Sanctuary_Reentry_KPIs.html"
}
```

Also generate a script `Extract-KPI-Sections.sh` that takes each full mockup HTML file and extracts ONLY the KPI dashboard + custom visualization sections (not the SharePoint chrome, nav, doc libraries, or lists — those will be native), outputting slim HTML files suitable for iframe embedding.

---

## PART 3: POWER BI DATA MODEL SPECIFICATION

### Instructions for Claude Code

Generate a Power BI data model specification file (`Sanctuary-PowerBI-Spec.md`) AND a Power BI template starter (`Sanctuary-DataModel.pbix` generation script using Tabular Editor CLI or DAX Studio, or alternatively a well-documented `.bim` model file).

### 3.1 Data Sources

The Power BI model should connect to the SharePoint lists created in Part 1 as its primary data source. Connection method: SharePoint Online List connector.

**SharePoint Site URL:** `https://{TENANT}.sharepoint.com/sites/ops-hub`

**Lists to connect:**
1. Facility Census Tracker
2. Compliance Audit Calendar
3. Incident Reports
4. Admissions Pipeline
5. Referral Partners
6. Staff Credential Tracker
7. Revenue by Payer
8. Reentry Participants
9. Marketing Campaigns

### 3.2 Calculated Tables

#### Date Table (required for time intelligence)
```dax
DateTable =
ADDCOLUMNS(
    CALENDAR(DATE(2025,1,1), DATE(2026,12,31)),
    "Year", YEAR([Date]),
    "Month", MONTH([Date]),
    "MonthName", FORMAT([Date], "MMMM"),
    "Quarter", "Q" & CEILING(MONTH([Date])/3, 1),
    "WeekNum", WEEKNUM([Date]),
    "DayOfWeek", WEEKDAY([Date]),
    "IsCurrentMonth", IF(MONTH([Date]) = MONTH(TODAY()) && YEAR([Date]) = YEAR(TODAY()), TRUE, FALSE)
)
```

#### Facility Dimension
```dax
FacilityDim =
DATATABLE(
    "FacilityKey", INTEGER,
    "FacilityName", STRING,
    "FacilityType", STRING,
    "LOC", STRING,
    "MaxCapacity", INTEGER,
    "Address", STRING,
    "Gender", STRING,
    {
        {1, "The Roadrunner Home", "Residential", "RES", 16, "Phoenix, AZ", "Men's"},
        {2, "The Blossom House", "Residential", "RES", 16, "Phoenix, AZ", "Women's (ASU)"},
        {3, "The Rose Garden", "Residential", "RES", 14, "Phoenix, AZ", "Co-Ed"},
        {4, "The Rosemonte Home", "Residential", "RES", 16, "Phoenix, AZ", "Men's"},
        {5, "The Charter Oak Home", "Residential", "RES", 16, "Phoenix, AZ", "Men's"},
        {6, "The Mercer Home", "Residential", "RES", 16, "Phoenix, AZ", "Co-Ed"},
        {7, "The Friess Home", "Residential", "RES", 12, "Phoenix, AZ", "Adolescent"},
        {8, "Outpatient Clinic", "Outpatient", "IOP/PHP", 999, "11645 N Cave Creek Rd", "Co-Ed"}
    }
)
```

### 3.3 Relationships

```
DateTable[Date] → FacilityCensusTracker[LastUpdated] (many-to-one)
DateTable[Date] → AdmissionsPipeline[ReferralDate] (many-to-one)
DateTable[Date] → IncidentReports[IncidentDate] (many-to-one)
DateTable[Date] → RevenueByPayer[Month] (many-to-one)
FacilityDim[FacilityName] → FacilityCensusTracker[Facility] (one-to-many)
FacilityDim[FacilityName] → IncidentReports[Facility] (one-to-many)
ReferralPartners[PartnerName] → AdmissionsPipeline[SourceDetail] (one-to-many)
```

### 3.4 Key DAX Measures

```dax
// ===== CENSUS & OCCUPANCY =====
Total Census = SUM(FacilityCensusTracker[Census])
Total Capacity = SUM(FacilityDim[MaxCapacity])
Occupancy Rate = DIVIDE([Total Census], [Total Capacity], 0)
Residential Census = CALCULATE([Total Census], FacilityDim[LOC] = "RES")
IOP Census = CALCULATE([Total Census], FacilityDim[LOC] = "IOP/PHP")

// ===== REVENUE =====
Revenue MTD = CALCULATE(SUM(RevenueByPayer[Revenue]), DateTable[IsCurrentMonth] = TRUE)
Revenue Target = 1650000  // $1.65M monthly target
Revenue Pacing = DIVIDE([Revenue MTD], [Revenue Target], 0)
AHCCCS Revenue = CALCULATE([Revenue MTD], RevenueByPayer[Payer] IN {"Mercy Care", "UHCCP"})
AHCCCS Pct = DIVIDE([AHCCCS Revenue], [Revenue MTD], 0)
Clean Claim Rate = DIVIDE(
    SUM(RevenueByPayer[ClaimCount]) - SUM(RevenueByPayer[DenialCount]),
    SUM(RevenueByPayer[ClaimCount]), 0
)

// ===== ADMISSIONS =====
Leads MTD = CALCULATE(
    COUNTROWS(AdmissionsPipeline),
    DateTable[IsCurrentMonth] = TRUE
)
Admits MTD = CALCULATE(
    COUNTROWS(AdmissionsPipeline),
    AdmissionsPipeline[Status] = "Admitted",
    DateTable[IsCurrentMonth] = TRUE
)
Lead to Admit Rate = DIVIDE([Admits MTD], [Leads MTD], 0)
Avg Days to Admit = AVERAGEX(
    FILTER(AdmissionsPipeline, AdmissionsPipeline[Status] = "Admitted"),
    DATEDIFF(AdmissionsPipeline[ReferralDate], AdmissionsPipeline[AdmitDate], DAY)
)

// ===== COMPLIANCE =====
Overdue Audits = CALCULATE(
    COUNTROWS(ComplianceAuditCalendar),
    ComplianceAuditCalendar[Status] = "Overdue"
)
Upcoming Audits 30d = CALCULATE(
    COUNTROWS(ComplianceAuditCalendar),
    ComplianceAuditCalendar[AuditDate] <= TODAY() + 30,
    ComplianceAuditCalendar[AuditDate] >= TODAY(),
    ComplianceAuditCalendar[Status] <> "Complete"
)

// ===== STAFF / HR =====
Total Staff = COUNTROWS(StaffCredentialTracker)
Credentials Expiring 30d = CALCULATE(
    COUNTROWS(StaffCredentialTracker),
    StaffCredentialTracker[LicenseExpiration] <= TODAY() + 30,
    StaffCredentialTracker[LicenseExpiration] >= TODAY()
)
HIPAA Compliance Rate = DIVIDE(
    CALCULATE(COUNTROWS(StaffCredentialTracker), StaffCredentialTracker[HIPAADueDate] >= TODAY()),
    [Total Staff], 0
)
Credential Compliance Rate = DIVIDE(
    CALCULATE(COUNTROWS(StaffCredentialTracker), StaffCredentialTracker[Status] = "Current"),
    [Total Staff], 0
)

// ===== REENTRY =====
Active Reentry Participants = CALCULATE(
    COUNTROWS(ReentryParticipants),
    ReentryParticipants[Phase] <> "Alumni/Aftercare"
)
Housing Placement Rate = DIVIDE(
    CALCULATE(COUNTROWS(ReentryParticipants),
        ReentryParticipants[HousingStatus] IN {"Placed (Sober Living)", "Placed (Independent)"}),
    COUNTROWS(ReentryParticipants), 0
)
Employment Rate = DIVIDE(
    CALCULATE(COUNTROWS(ReentryParticipants),
        ReentryParticipants[EmploymentStatus] IN {"Employed (PT)", "Employed (FT)"}),
    COUNTROWS(ReentryParticipants), 0
)
Court Compliance Rate = DIVIDE(
    CALCULATE(COUNTROWS(ReentryParticipants),
        ReentryParticipants[CourtCompliance] = "Compliant",
        ReentryParticipants[CourtInvolved] = TRUE),
    CALCULATE(COUNTROWS(ReentryParticipants),
        ReentryParticipants[CourtInvolved] = TRUE), 0
)

// ===== REFERRAL PARTNERS =====
Active Partners = CALCULATE(COUNTROWS(ReferralPartners), ReferralPartners[Status] = "Active")
Partner Conversion Rate = DIVIDE(
    SUM(ReferralPartners[AdmitsMTD]),
    SUM(ReferralPartners[ReferralsMTD]), 0
)
```

### 3.5 Report Pages

The Power BI report should have these pages (tabs), each matching a department:

| Page | Key Visuals |
|------|-------------|
| **Executive Overview** | KPI cards (Census, Revenue, Compliance, Satisfaction), Occupancy gauge by facility, Revenue trend line, Payer mix donut chart |
| **Clinical** | Caseload by facility bar chart, Note completion %, PHQ-9 improvement trend, Treatment completion funnel |
| **Admissions** | Pipeline funnel visual, Leads by source bar, Conversion rate KPI, Time-to-admit trend, Insurance mix |
| **Financial** | Revenue MTD vs target, Revenue by payer stacked bar, Clean claim rate gauge, Denial trend, Days in A/R |
| **Compliance** | Audit calendar timeline, Open CAPs count, HIPAA training completion %, Credential expiration heatmap |
| **HR / Workforce** | Headcount by role, Turnover rate trend, License expiration timeline, Training compliance matrix |
| **Reentry Program** | Phase pipeline visual, Housing placement rate, Employment rate, Recidivism rate, Court compliance |
| **Referral Network** | Partner map (if geo data), Referrals by source, Conversion by partner, Territory coverage |

### 3.6 Theme File

Generate a Power BI theme JSON (`Sanctuary-Theme.json`) matching the brand:

```json
{
    "name": "Sanctuary Recovery Centers",
    "dataColors": [
        "#e8732a", "#4dc8e8", "#f5a623", "#107c10",
        "#d83b01", "#3aa8c8", "#986f0b", "#605e5c"
    ],
    "background": "#ffffff",
    "foreground": "#323130",
    "tableAccent": "#e8732a",
    "visualStyles": {
        "*": {
            "*": {
                "title": [{
                    "fontFamily": "Segoe UI",
                    "fontSize": 12,
                    "color": {"solid": {"color": "#2b2b2b"}}
                }]
            }
        }
    }
}
```

---

## PART 4: DEPLOYMENT RUNBOOK

### Step-by-Step for Brian / Manage AI

#### Day 1: Provision (2-3 hours)

1. Open PowerShell 7 terminal
2. Run `Install-Module -Name PnP.PowerShell -Scope CurrentUser` (if not installed)
3. Edit `Deploy-SanctuaryHub.ps1` — set `$TenantUrl` and `$SiteAlias`
4. Run `.\Deploy-SanctuaryHub.ps1` — creates site, theme, lists, doc libraries
5. Run `.\Deploy-SanctuaryPages.ps1` — creates 9 pages with web parts
6. Verify: open `https://{tenant}.sharepoint.com/sites/ops-hub` in browser

#### Day 2: KPI Dashboards (2 hours)

1. Host the 8 KPI-only HTML files on GitHub Pages (or Azure Blob with CORS)
2. Update `embed-urls.json` with real URLs
3. Re-run page deployment or manually paste URLs into Embed web parts
4. Test each page — KPI sections should render inside SharePoint

#### Day 3: Power BI (3-4 hours)

1. Open Power BI Desktop
2. Connect to SharePoint Online lists (Get Data → SharePoint Online List → site URL)
3. Import all 9 lists
4. Apply the data model (relationships, calculated tables, DAX measures)
5. Build report pages per spec
6. Apply `Sanctuary-Theme.json`
7. Publish to Power BI Service
8. Copy report embed URL
9. Update Power BI web parts on CEO and Marketing pages with real URL

#### Day 4: Polish & Handoff (2 hours)

1. Upload real documents to libraries (replace placeholders)
2. Populate lists with actual Sanctuary data
3. Set SharePoint permissions (CEO page restricted, dept pages by department)
4. Test navigation end-to-end
5. Walk Sanctuary team through the hub

### Total LOE: ~3-4 days from mockup to production SharePoint
### Required Access: SharePoint Admin or Global Admin on Sanctuary's M365 tenant
### Required Tools: PowerShell 7, PnP.PowerShell module, Power BI Desktop, GitHub account

---

## FILES THIS PROMPT SHOULD GENERATE

Claude Code should produce these files in the project directory:

```
sanctuary-ops-hub/
├── scripts/
│   ├── Deploy-SanctuaryHub.ps1         # Site, theme, lists, doc libraries
│   ├── Deploy-SanctuaryPages.ps1       # Pages with web parts
│   ├── Seed-ListData.ps1               # Pre-populate lists with sample data
│   ├── Extract-KPI-Sections.sh         # Strip KPI dashboards from full HTML
│   └── embed-urls.json                 # URL mapping for embed web parts
├── theme/
│   ├── sanctuary-theme.json            # SharePoint theme
│   └── Sanctuary-Theme-PowerBI.json    # Power BI theme
├── powerbi/
│   ├── Sanctuary-PowerBI-Spec.md       # Full data model documentation
│   ├── Sanctuary-DAX-Measures.dax      # All DAX measures in one file
│   └── Sanctuary-DataModel.bim         # Tabular model (if possible)
├── assets/
│   └── sanctuary-logo.png              # Logo for site branding
├── kpi-embeds/                         # Extracted KPI-only HTML files
│   ├── CEO-KPIs.html
│   ├── Clinical-KPIs.html
│   ├── Admissions-KPIs.html
│   ├── Marketing-KPIs.html
│   ├── BD-KPIs.html
│   ├── HR-KPIs.html
│   ├── Admin-KPIs.html
│   └── Reentry-KPIs.html
└── README.md                           # Setup instructions
```

---

*Generated by Manage AI for Sanctuary Recovery Centers SharePoint Operations Hub deployment.*
