param(
    [Parameter(Mandatory=$true)]
    [string]$InputPath,

    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

$source = Get-Content -Raw -LiteralPath $InputPath

# Find the start of the fixed STID payload in mergeelx.c.
# Don't depend on whitespace or the exact fprintf formatting.
$marker = '#ifdef STID'
$markerPos = $source.IndexOf($marker)

if ($markerPos -lt 0) {
    throw "Could not locate '#ifdef STID' payload in $InputPath"
}

# Start a little before the marker so that we capture the fprintf statement
# containing it.
$searchStart = [Math]::Max(0, $markerPos - 200)
$section = $source.Substring($searchStart)

# Extract every fprintf(pfile, "..."); literal from this point onward.
$matches = [regex]::Matches(
    $section,
    'fprintf\s*\(\s*pfile\s*,\s*"((?:\\.|[^"\\])*)"\s*\)\s*;'
)

$output = New-Object System.Text.StringBuilder
$insideStid = $false

foreach ($m in $matches) {

    $text = $m.Groups[1].Value

    $text = $text.Replace('\r', "`r")
    $text = $text.Replace('\n', "`n")
    $text = $text.Replace('\t', "`t")
    $text = $text.Replace('\"', '"')
    $text = $text.Replace('\\', '\')

    if (-not $insideStid) {
        if ($text.Contains('#ifdef STID')) {
            $insideStid = $true

            $pos = $text.IndexOf('#ifdef STID')
            $text = $text.Substring($pos)
        }
        else {
            continue
        }
    }

    [void]$output.Append($text)

    # The STID payload ends at its #endif.
    # Do not collect later fprintf() output from mergeelx.c.
    if ($text.Contains('#endif')) {
        break
    }
}

if (-not $insideStid) {
    throw "Found '#ifdef STID' in source but failed to extract its fprintf payload"
}

# The original generated ELXINFO.H also contains an ELDI section.
# The repository explicitly says the historical Dialog Editor stage is
# unavailable, so supply the intended inert boundary.
$prefix = @'
#ifdef elkAppMac

/*
 * Compatibility ELDI record for the x64 port.
 * The original generated dialog table is unavailable.
 */
typedef struct _ELDI_COMPAT
{
    HID hid;
    CABI cabi;
    unsigned celfd;
    ELFD rgelfd[1];
} ELDI_COMPAT;

csconst ELDI_COMPAT rgeldi_compat[] =
{
    { hidNil, 0, 0, {{0}} }
};

#define rgeldi ((ELDI *)rgeldi_compat)

csconst unsigned rgichName[] = { 0 };
csconst unsigned char rgchElkNames[] = { 0 };
csconst unsigned mpelkistName[] = { 0 };

#endif

'@

$final = $prefix + $output.ToString()

# The original generator used the historical StringMap/P-code mechanism
# for this global initializer. Modern MSVC requires a compile-time
# constant here.
$final = $final.Replace(
    'csconst char rgksp [] = StringMap("SUPO", 0, 1);',
    'csconst char rgksp [] = "SUPO";'
)

$outDir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force $outDir | Out-Null

[System.IO.File]::WriteAllText(
    $OutputPath,
    $final,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Generated $OutputPath"