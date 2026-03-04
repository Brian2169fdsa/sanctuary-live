#!/bin/bash
# ============================================================================
# Extract-KPI-Sections.sh
#
# Takes full Sanctuary mockup HTML files and extracts ONLY the KPI dashboard
# and custom visualization sections, stripping out:
#   - SharePoint chrome (nav, header, footer)
#   - Document library sections
#   - List view sections
#   - Navigation menus
#
# Output: Slim HTML files suitable for iframe embedding in SharePoint
#         Embed web parts.
#
# Usage:
#   chmod +x Extract-KPI-Sections.sh
#   ./Extract-KPI-Sections.sh [input_dir] [output_dir]
#
# Defaults:
#   input_dir:  ./mockups/
#   output_dir: ./kpi-embeds/
# ============================================================================

set -euo pipefail

INPUT_DIR="${1:-./mockups}"
OUTPUT_DIR="${2:-./kpi-embeds}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} KPI Section Extractor${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Mapping of source HTML files to output KPI files
declare -A FILE_MAP=(
    ["Sanctuary_CEO_Dashboard_KPIs.html"]="CEO-KPIs.html"
    ["Sanctuary_Clinical_KPIs.html"]="Clinical-KPIs.html"
    ["Sanctuary_Admissions_KPIs.html"]="Admissions-KPIs.html"
    ["Sanctuary_Marketing_KPIs.html"]="Marketing-KPIs.html"
    ["Sanctuary_BD_KPIs.html"]="BD-KPIs.html"
    ["Sanctuary_HR_KPIs.html"]="HR-KPIs.html"
    ["Sanctuary_Admin_KPIs.html"]="Admin-KPIs.html"
    ["Sanctuary_Reentry_KPIs.html"]="Reentry-KPIs.html"
)

# Alternative source file patterns (the user may have different naming)
declare -A ALT_PATTERNS=(
    ["CEO-KPIs.html"]="*CEO*Dashboard*.html *ceo*.html"
    ["Clinical-KPIs.html"]="*Clinical*.html *clinical*.html"
    ["Admissions-KPIs.html"]="*Admissions*.html *admissions*.html"
    ["Marketing-KPIs.html"]="*Marketing*.html *marketing*.html"
    ["BD-KPIs.html"]="*Business*Development*.html *BD*.html *bd*.html"
    ["HR-KPIs.html"]="*Human*Resources*.html *HR*.html *hr*.html"
    ["Admin-KPIs.html"]="*Administration*.html *Admin*.html *admin*.html"
    ["Reentry-KPIs.html"]="*Reentry*.html *reentry*.html"
)

# Common KPI wrapper template
generate_kpi_wrapper() {
    local title="$1"
    local kpi_content="$2"
    local output_file="$3"

    cat > "$output_file" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sanctuary — ${title} KPIs</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
            background: #ffffff;
            color: #323130;
            padding: 16px;
        }
        /* Allow embedding in SharePoint iframe */
        html, body { overflow-x: hidden; }

        /* Sanctuary brand colors */
        :root {
            --primary: #e8732a;
            --accent: #4dc8e8;
            --success: #107c10;
            --warning: #f5a623;
            --danger: #d83b01;
            --neutral-bg: #faf9f8;
            --neutral-border: #edebe9;
            --text-primary: #323130;
            --text-secondary: #605e5c;
        }
    </style>
</head>
<body>
${kpi_content}
</body>
</html>
HTMLEOF
}

# Extract KPI sections from a source HTML file
extract_kpis() {
    local source_file="$1"
    local output_file="$2"
    local title="$3"

    if [ ! -f "$source_file" ]; then
        echo -e "   ${YELLOW}[WARN]${NC} Source not found: $source_file"
        return 1
    fi

    echo -e "   ${CYAN}Processing:${NC} $source_file"

    # Strategy: Extract content between KPI-related markers
    # Common patterns in dashboard HTML mockups:
    #   - <div class="kpi-*">
    #   - <div class="dashboard-*">
    #   - <div class="metrics-*">
    #   - <section id="kpi*">
    #   - Elements with data-section="kpi"

    # Step 1: Try to extract sections with kpi/dashboard/metric class names
    local kpi_content=""

    # Use sed/awk to extract relevant sections
    # First try: extract everything between <!-- KPI START --> and <!-- KPI END --> markers
    if grep -q "KPI START\|kpi-section\|dashboard-kpis\|metrics-grid" "$source_file" 2>/dev/null; then
        kpi_content=$(sed -n '/<!-- KPI START -->/,/<!-- KPI END -->/p' "$source_file" 2>/dev/null || true)
    fi

    # Second try: extract divs with kpi/dashboard/metric classes
    if [ -z "$kpi_content" ]; then
        # Extract the <style> block and KPI-related content
        local styles=""
        styles=$(sed -n '/<style/,/<\/style>/p' "$source_file" 2>/dev/null || true)

        # Extract body content, stripping nav, footer, document library, and list sections
        kpi_content=$(sed \
            -e '/<nav/,/<\/nav>/d' \
            -e '/<footer/,/<\/footer>/d' \
            -e '/class=".*sp-nav/,/<\/div>/d' \
            -e '/class=".*document-library/,/<\/section>/d' \
            -e '/class=".*list-view/,/<\/section>/d' \
            -e '/class=".*sharepoint-chrome/,/<\/div>/d' \
            -e '/<header.*class=".*site-header/,/<\/header>/d' \
            "$source_file" 2>/dev/null | \
            sed -n '/<body/,/<\/body>/p' 2>/dev/null | \
            sed '1d;$d' || true)

        # If we got styles, prepend them
        if [ -n "$styles" ]; then
            kpi_content="${styles}${kpi_content}"
        fi
    fi

    # Third try: if still empty, just copy the whole file as-is (user can trim manually)
    if [ -z "$kpi_content" ]; then
        echo -e "   ${YELLOW}[WARN]${NC} Could not isolate KPI sections — copying full content"
        cp "$source_file" "$output_file"
        return 0
    fi

    # Generate the slim wrapper
    generate_kpi_wrapper "$title" "$kpi_content" "$output_file"
    echo -e "   ${GREEN}[OK]${NC} Extracted KPIs → $output_file"
}

# ============================================================================
# MAIN
# ============================================================================

if [ ! -d "$INPUT_DIR" ]; then
    echo -e "${YELLOW}Input directory '$INPUT_DIR' not found.${NC}"
    echo ""
    echo "This script expects full mockup HTML files in $INPUT_DIR/"
    echo "Expected files:"
    for src in "${!FILE_MAP[@]}"; do
        echo "  - $src"
    done
    echo ""
    echo "If your mockup files have different names, place them in $INPUT_DIR/"
    echo "and the script will attempt to match them by department name."
    echo ""
    echo -e "${CYAN}Generating placeholder KPI embed files instead...${NC}"
    echo ""

    # Generate placeholder KPI files for each department
    declare -A DEPT_TITLES=(
        ["CEO-KPIs.html"]="CEO Dashboard"
        ["Clinical-KPIs.html"]="Clinical Department"
        ["Admissions-KPIs.html"]="Admissions Department"
        ["Marketing-KPIs.html"]="Marketing Department"
        ["BD-KPIs.html"]="Business Development"
        ["HR-KPIs.html"]="Human Resources"
        ["Admin-KPIs.html"]="Administration"
        ["Reentry-KPIs.html"]="Reentry Program"
    )

    for output in "${!DEPT_TITLES[@]}"; do
        title="${DEPT_TITLES[$output]}"
        placeholder_content="<div style='padding: 24px; text-align: center; background: var(--neutral-bg); border-radius: 8px; border: 2px dashed var(--neutral-border);'>
    <h2 style='color: var(--primary); margin-bottom: 8px;'>$title — KPI Dashboard</h2>
    <p style='color: var(--text-secondary);'>Replace this placeholder with the extracted KPI dashboard content.</p>
    <p style='color: var(--text-secondary); font-size: 13px; margin-top: 12px;'>Source your full mockup HTML into <code>$INPUT_DIR/</code> and re-run this script.</p>
</div>"
        generate_kpi_wrapper "$title" "$placeholder_content" "$OUTPUT_DIR/$output"
        echo -e "   ${GREEN}[OK]${NC} Generated placeholder: $OUTPUT_DIR/$output"
    done

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} Placeholder KPI files generated!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "   Output: $OUTPUT_DIR/"
    echo -e "   Files:  8 placeholder HTML files"
    echo ""
    echo -e "   ${YELLOW}Next: Add full mockup HTMLs to $INPUT_DIR/ and re-run.${NC}"
    exit 0
fi

# Process each expected file
echo -e "${CYAN}Input:${NC}  $INPUT_DIR/"
echo -e "${CYAN}Output:${NC} $OUTPUT_DIR/"
echo ""

processed=0
skipped=0

for src in "${!FILE_MAP[@]}"; do
    output="${FILE_MAP[$src]}"
    title="${output%.html}"
    title="${title//-/ }"

    source_path="$INPUT_DIR/$src"

    # Try exact match first
    if [ -f "$source_path" ]; then
        extract_kpis "$source_path" "$OUTPUT_DIR/$output" "$title"
        ((processed++))
        continue
    fi

    # Try alternative patterns
    found=false
    if [ -n "${ALT_PATTERNS[$output]:-}" ]; then
        for pattern in ${ALT_PATTERNS[$output]}; do
            match=$(find "$INPUT_DIR" -maxdepth 1 -name "$pattern" -print -quit 2>/dev/null || true)
            if [ -n "$match" ]; then
                extract_kpis "$match" "$OUTPUT_DIR/$output" "$title"
                ((processed++))
                found=true
                break
            fi
        done
    fi

    if [ "$found" = false ]; then
        echo -e "   ${YELLOW}[SKIP]${NC} No source found for $output"
        ((skipped++))
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Extraction Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "   Processed: $processed files"
echo -e "   Skipped:   $skipped files"
echo -e "   Output:    $OUTPUT_DIR/"
echo ""
