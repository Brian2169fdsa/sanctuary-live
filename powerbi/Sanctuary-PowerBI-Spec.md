# Sanctuary Recovery Centers — Power BI Data Model Specification

> **Version:** 1.0
> **Last Updated:** March 2026
> **Data Source:** SharePoint Online Lists
> **Site URL:** `https://sanctuaryrecoverycenters48.sharepoint.com/sites/ops-hub-dev`

---

## 1. Data Sources

Connect to the SharePoint Operations Hub using the **SharePoint Online List** connector in Power BI Desktop.

**Connection Steps:**
1. Get Data > SharePoint Online List
2. Enter site URL: `https://sanctuaryrecoverycenters48.sharepoint.com/sites/ops-hub-dev`
3. Select all 9 lists below
4. Transform data as needed (rename columns, set types)

### Source Lists

| # | List Name | Primary Key | Row Estimate |
|---|-----------|-------------|--------------|
| 1 | Facility Census Tracker | Title (Facility) | 9 |
| 2 | Compliance Audit Calendar | Title | 6+ |
| 3 | Incident Reports | IncidentID | 4+ |
| 4 | Admissions Pipeline | ReferralID | 6+ |
| 5 | Referral Partners | PartnerName | 8+ |
| 6 | Staff Credential Tracker | StaffName | 15+ |
| 7 | Revenue by Payer | Title (Payer + Month) | 7+ |
| 8 | Reentry Participants | ParticipantID | 6+ |
| 9 | Marketing Campaigns | CampaignName | 6+ |

---

## 2. Data Model

### 2.1 Calculated Tables

#### DateTable
A standard date dimension covering Jan 2025 – Dec 2026, with columns for time intelligence.

```dax
DateTable =
ADDCOLUMNS(
    CALENDAR(DATE(2025,1,1), DATE(2026,12,31)),
    "Year", YEAR([Date]),
    "Month", MONTH([Date]),
    "MonthName", FORMAT([Date], "MMMM"),
    "MonthYear", FORMAT([Date], "MMM YYYY"),
    "Quarter", "Q" & CEILING(MONTH([Date])/3, 1),
    "QuarterYear", "Q" & CEILING(MONTH([Date])/3, 1) & " " & YEAR([Date]),
    "WeekNum", WEEKNUM([Date]),
    "DayOfWeek", WEEKDAY([Date]),
    "DayName", FORMAT([Date], "dddd"),
    "IsCurrentMonth", IF(MONTH([Date]) = MONTH(TODAY()) && YEAR([Date]) = YEAR(TODAY()), TRUE, FALSE),
    "IsCurrentQuarter", IF(CEILING(MONTH([Date])/3,1) = CEILING(MONTH(TODAY())/3,1) && YEAR([Date]) = YEAR(TODAY()), TRUE, FALSE),
    "MonthSort", YEAR([Date]) * 100 + MONTH([Date])
)
```

Mark as Date Table using the `Date` column.

#### FacilityDim
Static facility dimension table with master data for all 8 facilities.

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
        {1, "Roadrunner Home", "Residential", "RES", 16, "Phoenix, AZ", "Men's"},
        {2, "Blossom House", "Residential", "RES", 16, "Phoenix, AZ", "Women's (ASU)"},
        {3, "Rose Garden", "Residential", "RES", 14, "Phoenix, AZ", "Co-Ed"},
        {4, "Rosemonte Home", "Residential", "RES", 16, "Phoenix, AZ", "Men's"},
        {5, "Charter Oak Home", "Residential", "RES", 16, "Phoenix, AZ", "Men's"},
        {6, "Mercer Home", "Residential", "RES", 16, "Phoenix, AZ", "Co-Ed"},
        {7, "Friess Home", "Residential", "RES", 12, "Phoenix, AZ", "Adolescent"},
        {8, "IOP Clinic", "Outpatient", "IOP/PHP", 999, "11645 N Cave Creek Rd", "Co-Ed"}
    }
)
```

### 2.2 Relationships

| From | To | Cardinality | Cross-filter |
|------|----|-------------|--------------|
| DateTable[Date] | Facility Census Tracker[LastUpdated] | Many-to-One | Single |
| DateTable[Date] | Admissions Pipeline[ReferralDate] | Many-to-One | Single |
| DateTable[Date] | Incident Reports[IncidentDate] | Many-to-One | Single |
| DateTable[Date] | Revenue by Payer[Month] | Many-to-One | Single |
| DateTable[Date] | Compliance Audit Calendar[AuditDate] | Many-to-One | Single |
| DateTable[Date] | Marketing Campaigns[StartDate] | Many-to-One | Single |
| DateTable[Date] | Reentry Participants[EnrollDate] | Many-to-One | Single |
| FacilityDim[FacilityName] | Facility Census Tracker[Facility] | One-to-Many | Single |
| FacilityDim[FacilityName] | Incident Reports[Facility] | One-to-Many | Single |
| Referral Partners[PartnerName] | Admissions Pipeline[SourceDetail] | One-to-Many | Single |

**Notes:**
- The FacilityDim → Admissions Pipeline relationship uses FacilityAssigned, which is a Choice field. Match on display text.
- SharePoint Person fields import as record types. Extract `.DisplayName` or `.Email` in Power Query.

---

## 3. Measures

All DAX measures are in `Sanctuary-DAX-Measures.dax`. Summary by category:

### Census & Occupancy (9 measures)
- Total Census, Total Capacity, Occupancy Rate
- Residential Census, IOP Census, PHP Census
- Avg Length of Stay, Facilities at Capacity, Available Beds

### Revenue (11 measures)
- Revenue MTD, Revenue Target, Revenue Pacing, Revenue vs Target
- Total Revenue, AHCCCS Revenue, AHCCCS Pct
- Commercial Revenue, Commercial Pct
- Clean Claim Rate, Denial Rate, Avg Revenue Per Claim, Total Claims, Total Denials

### Admissions (10 measures)
- Leads MTD, Admits MTD, Lead to Admit Rate
- Avg Days to Admit, Active Pipeline, Waitlisted Count, Lost Leads
- VOB Pending, Assessments Scheduled, Pipeline by Stage

### Compliance & Incidents (7 measures)
- Overdue Audits, Upcoming Audits 30d, Completed Audits
- Open Incidents, Critical Incidents, Incidents MTD, Avg Resolution Days

### Staff / HR (9 measures)
- Total Staff, Licensed Clinicians
- Credentials Expiring 30d, Credentials Expired
- HIPAA Compliance Rate, Credential Compliance Rate
- CPR Expiring 30d, FPC Expiring 30d, Staff Action Required

### Reentry Program (10 measures)
- Active Reentry Participants, Total Reentry Enrolled
- Housing Placement Rate, Employment Rate
- Court Compliance Rate, Court Involved Count
- Avg Days in Program, Residential Phase Count, Community Transition Count, Alumni Count

### Referral Partners (7 measures)
- Active Partners, Total Partners
- Partner Referrals MTD, Partner Admits MTD, Partner Conversion Rate
- Partners Needing Follow-Up, Partners Without Agreement, New Partners

### Marketing (8 measures)
- Marketing Spend MTD, Total Marketing Leads, Avg CPL
- Marketing Admits, Avg CPA
- Live Campaigns, Organic vs Paid Ratio, ROAS

---

## 4. Report Pages

### Page 1: Executive Overview
| Visual | Type | Data |
|--------|------|------|
| Census KPI Card | Card | [Total Census] |
| Revenue MTD KPI | Card | [Revenue MTD] |
| Occupancy Rate | Gauge | [Occupancy Rate], max=1 |
| Compliance Status | Card | [Overdue Audits] |
| Occupancy by Facility | Clustered Bar | FacilityDim[FacilityName], Census, Capacity |
| Revenue Trend | Line Chart | DateTable[MonthYear], [Total Revenue] |
| Payer Mix | Donut Chart | Revenue by Payer[Payer], [Total Revenue] |
| Open Incidents | Card | [Open Incidents] |

### Page 2: Clinical
| Visual | Type | Data |
|--------|------|------|
| Caseload by Facility | Clustered Bar | FacilityDim[FacilityName], Census |
| ALOS by Facility | Column Chart | Facility Census Tracker[Facility], [ALOS] |
| Incident Category Breakdown | Stacked Bar | Incident Reports[Category], count |
| Facility Status Matrix | Matrix | Facility, LOC, Census, Capacity, Status |

### Page 3: Admissions
| Visual | Type | Data |
|--------|------|------|
| Pipeline Funnel | Funnel | Admissions Pipeline[Stage], count |
| Leads by Source | Bar Chart | Admissions Pipeline[Source], count |
| Conversion Rate KPI | Card | [Lead to Admit Rate] |
| Time to Admit Trend | Line Chart | DateTable[MonthYear], [Avg Days to Admit] |
| Insurance Mix | Donut | Admissions Pipeline[Insurance], count |
| Active Pipeline KPI | Card | [Active Pipeline] |

### Page 4: Financial
| Visual | Type | Data |
|--------|------|------|
| Revenue MTD vs Target | Gauge | [Revenue MTD], target=[Revenue Target] |
| Revenue by Payer | Stacked Bar | Payer, Revenue |
| Clean Claim Rate | Gauge | [Clean Claim Rate], target=0.95 |
| Denial Trend | Line | DateTable[MonthYear], [Denial Rate] |
| AHCCCS vs Commercial | Donut | AHCCCS/Commercial segments |
| Revenue per Claim | Card | [Avg Revenue Per Claim] |

### Page 5: Compliance
| Visual | Type | Data |
|--------|------|------|
| Audit Calendar | Table | Title, AuditDate, AuditType, Status |
| Overdue Audits KPI | Card | [Overdue Audits] |
| Upcoming 30d KPI | Card | [Upcoming Audits 30d] |
| HIPAA Training % | Gauge | [HIPAA Compliance Rate] |
| Incident Trend | Line | DateTable[MonthYear], [Incidents MTD] |
| Credential Expiration Heatmap | Matrix | StaffName, LicenseExp, CPRExp, FPCExp |

### Page 6: HR / Workforce
| Visual | Type | Data |
|--------|------|------|
| Headcount by Role | Bar | Staff Credential Tracker[Role], count |
| Credential Compliance | Gauge | [Credential Compliance Rate] |
| Expiring 30d KPI | Card | [Credentials Expiring 30d] |
| Staff Status Breakdown | Donut | Status, count |
| Training Compliance Matrix | Matrix | StaffName, HIPAA, Cultural, Trauma, Mandated |
| License Expiration Timeline | Table | StaffName, Role, LicenseExpiration, Status |

### Page 7: Reentry Program
| Visual | Type | Data |
|--------|------|------|
| Phase Pipeline | Funnel | Phase, count |
| Housing Placement Rate | Gauge | [Housing Placement Rate] |
| Employment Rate | Gauge | [Employment Rate] |
| Court Compliance | Gauge | [Court Compliance Rate] |
| Active Participants KPI | Card | [Active Reentry Participants] |
| Participant Detail Table | Table | ParticipantID, Phase, Housing, Employment, Court |

### Page 8: Referral Network
| Visual | Type | Data |
|--------|------|------|
| Referrals by Source Type | Bar | PartnerType, ReferralsMTD |
| Conversion by Partner | Scatter | ReferralsMTD (X), ConversionPct (Y), Partner (detail) |
| Territory Coverage | Map or Bar | Territory, count |
| Active Partners KPI | Card | [Active Partners] |
| Partner Conversion Rate | KPI | [Partner Conversion Rate] |
| Partner Status Table | Table | PartnerName, Type, Referrals, Admits, Status |

---

## 5. Theme

Apply `Sanctuary-Theme-PowerBI.json` via Home > View > Themes > Browse for themes.

Brand colors:
- Primary: #e8732a (Sanctuary orange)
- Accent: #4dc8e8 (Sanctuary blue)
- Success: #107c10
- Warning: #f5a623
- Danger: #d83b01

---

## 6. Deployment

1. Publish report to Power BI Service workspace
2. Configure scheduled refresh (daily, 6 AM AZ time)
3. Set SharePoint Online List credentials (OAuth2)
4. Copy embed URL for SharePoint web parts
5. Update CEO-Dashboard.aspx and Marketing-Department.aspx Power BI web parts

---

## 7. Data Refresh

| Source | Refresh Frequency | Notes |
|--------|-------------------|-------|
| SharePoint Lists | Daily 6:00 AM MST | Gateway not required for SPO connector |
| DateTable | Static | Calculated table, regenerated on refresh |
| FacilityDim | Static | Update manually if facilities change |

---

*Sanctuary Recovery Centers — Operations Hub Power BI Specification*
*Prepared by Manage AI*
