/**
 * Bulk-add challenges from a CSV file or Google Sheet into an existing journey.
 *
 * Usage:
 *   node scripts/bulk-add-challenges.js
 * 
 * You will then be prompted for the :
 *   <journey-id>
 *   <source>
 * 
 * Alternatively, run in one step:
 *   node scripts/bulk-add-challenges.js <journey-id> <source> [--force]
 * 
 * Source can be:
 *   - A local CSV file path
 *   - A Google Sheets URL, e.g. https://docs.google.com/spreadsheets/d/SHEET_ID/edit...
 *     Two auth modes:
 *       a) Set GOOGLE_API_KEY in server/.env — sheet just needs "Anyone with the link" sharing
 *       b) No API key — sheet must be fully public ("Anyone on the internet")
 *
 * CSV columns (header row required):
 *   Name, Description, Latitude, Longitude, Location Description,
 *   Image URL, Awarding Distance, Close Distance, Points
 *
 * If the journey already has challenges with completions, the script will
 * abort unless --force is passed.
 */

const { PrismaClient } = require('../server/node_modules/@prisma/client');
const path = require('path');
const fs = require('fs');
const readline = require('readline');

function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

require('../server/node_modules/dotenv').config({
  path: path.join(__dirname, '../server/.env'),
});

const prisma = new PrismaClient();

// CSV parser (no dependencies)

function parseCsv(text) {
  const rows = [];
  let current = '';
  let inQuotes = false;
  const lines = [];

  // Split into lines respecting quoted newlines
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === '"') {
      inQuotes = !inQuotes;
      current += ch;
    } else if (ch === '\n' && !inQuotes) {
      lines.push(current);
      current = '';
    } else if (ch === '\r' && !inQuotes) {
      // skip \r
    } else {
      current += ch;
    }
  }
  if (current.length > 0) lines.push(current);

  for (const line of lines) {
    const cells = [];
    let cell = '';
    let q = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (q && line[i + 1] === '"') {
          cell += '"';
          i++;
        } else {
          q = !q;
        }
      } else if (ch === ',' && !q) {
        cells.push(cell.trim());
        cell = '';
      } else {
        cell += ch;
      }
    }
    cells.push(cell.trim());
    rows.push(cells);
  }

  return rows;
}

// Location mapping

const LOCATION_MAP = {
  'eng quad': 'ENG_QUAD',
  'engineering quad': 'ENG_QUAD',
  'arts quad': 'ARTS_QUAD',
  'ag quad': 'AG_QUAD',
  'agriculture quad': 'AG_QUAD',
  'central campus': 'CENTRAL_CAMPUS',
  'north campus': 'NORTH_CAMPUS',
  'west campus': 'WEST_CAMPUS',
  'cornell athletics': 'CORNELL_ATHLETICS',
  'athletics': 'CORNELL_ATHLETICS',
  'vet school': 'VET_SCHOOL',
  'collegetown': 'COLLEGETOWN',
  'college town': 'COLLEGETOWN',
  'ithaca commons': 'ITHACA_COMMONS',
  'commons': 'ITHACA_COMMONS',
};

function mapLocation(locationDesc) {
  if (!locationDesc) return 'ANY';
  const key = locationDesc.toLowerCase().trim();
  return LOCATION_MAP[key] || 'ANY';
}

// Validation

const REQUIRED_FIELDS = [
  'name',
  'description',
  'latitude',
  'longitude',
  'imageUrl',
  'awardingRadius',
  'closeRadius',
  'points',
];

function parseRow(headers, cells) {
  const raw = {};
  headers.forEach((h, i) => {
    raw[h] = cells[i] || '';
  });

  // Clean latitude (some cells have trailing commas/spaces)
  const latStr = raw['Latitude'].replace(/,/g, '').trim();
  const lngStr = raw['Longitude'].replace(/,/g, '').trim();

  const challenge = {
    name: raw['Name'] || '',
    description: raw['Description'] || '',
    latitude: parseFloat(latStr),
    longitude: parseFloat(lngStr),
    imageUrl: raw['Image URL'] || '',
    awardingRadius: parseFloat(raw['Awarding Distance']) || 0,
    closeRadius: parseFloat(raw['Close Distance']) || 0,
    points: parseInt(raw['Points'], 10) || 0,
    location: mapLocation(raw['Location Description']),
  };

  const missing = REQUIRED_FIELDS.filter((f) => {
    const val = challenge[f];
    if (typeof val === 'string') return !val;
    if (typeof val === 'number') return isNaN(val) || val === 0;
    return !val;
  });

  return { challenge, missing, rawName: raw['Name'] || '(unnamed)' };
}

// Google Sheets fetcher

function extractSheetId(url) {
  const match = url.match(/\/spreadsheets\/d\/([a-zA-Z0-9_-]+)/);
  return match ? match[1] : null;
}

async function fetchGoogleSheet(url) {
  const sheetId = extractSheetId(url);
  if (!sheetId) {
    throw new Error('Could not extract sheet ID from URL: ' + url);
  }

  const apiKey = process.env.GOOGLE_API_KEY;

  if (apiKey) {
    // Use Sheets API v4 with API key (works with "Anyone with the link" sharing)
    const apiUrl =
      `https://sheets.googleapis.com/v4/spreadsheets/${sheetId}/values/A:Z?key=${apiKey}`;
    console.log('Fetching Google Sheet via Sheets API...');
    const res = await fetch(apiUrl);
    if (!res.ok) {
      const body = await res.text();
      throw new Error(
        `Sheets API error (${res.status}): ${body.substring(0, 200)}`,
      );
    }
    const json = await res.json();
    const rows = json.values || [];
    // Convert to CSV format
    return rows
      .map((row) =>
        row.map((cell) => {
          const str = String(cell ?? '');
          return str.includes(',') || str.includes('"') || str.includes('\n')
            ? '"' + str.replace(/"/g, '""') + '"'
            : str;
        }).join(','),
      )
      .join('\n');
  }

  // Fallback: public CSV export (requires sheet to be fully public)
  const csvUrl = `https://docs.google.com/spreadsheets/d/${sheetId}/export?format=csv`;
  console.log('Fetching Google Sheet as CSV (public export)...');
  const res = await fetch(csvUrl, { redirect: 'follow' });
  if (!res.ok) {
    throw new Error(
      `Failed to fetch sheet (${res.status}). Either:\n` +
        `  1. Set GOOGLE_API_KEY in server/.env and share the sheet as "Anyone with the link"\n` +
        `  2. Or make the sheet fully public (File > Share > Anyone on the internet)`,
    );
  }
  return res.text();
}

function isGoogleSheetsUrl(str) {
  return str.startsWith('https://docs.google.com/spreadsheets/');
}

// Main

async function main() {
  const args = process.argv.slice(2);
  const force = args.includes('--force');
  const positional = args.filter((a) => a !== '--force');

  let journeyId = positional[0];
  let source = positional[1];

  if (!journeyId) {
    journeyId = await prompt('Journey ID: ');
    if (!journeyId) {
      console.error('Journey ID is required.');
      process.exit(1);
    }
  }
  if (!source) {
    source = await prompt('Source (CSV file path or Google Sheets URL): ');
    if (!source) {
      console.error('Source is required.');
      process.exit(1);
    }
  }

  // 1. Verify journey exists
  const journey = await prisma.eventBase.findUnique({
    where: { id: journeyId },
    include: {
      challenges: {
        include: { completions: { select: { id: true }, take: 1 } },
      },
    },
  });

  if (!journey) {
    console.error(`Journey not found: ${journeyId}`);
    process.exit(1);
  }

  console.log(`Journey: "${journey.name}" (${journey.id})`);
  console.log(`Existing challenges: ${journey.challenges.length}`);

  // 2. Check for completions if challenges exist
  if (journey.challenges.length > 0) {
    const hasCompletions = journey.challenges.some(
      (c) => c.completions.length > 0,
    );

    if (hasCompletions && !force) {
      console.error(
        '\nExisting challenges have user completions. ' +
          'Re-adding will DELETE completion records.',
      );
      console.error('Pass --force to proceed anyway.');
      process.exit(1);
    }

    if (hasCompletions) {
      console.log('\n⚠ --force passed: deleting challenges with completions');
    }

    // Delete existing challenges (cascades to PrevChallenge)
    const deleted = await prisma.challenge.deleteMany({
      where: { linkedEventId: journeyId },
    });
    console.log(`Deleted ${deleted.count} existing challenges`);
  }

  // 3. Read and parse CSV
  let csvText;
  if (isGoogleSheetsUrl(source)) {
    csvText = await fetchGoogleSheet(source);
  } else {
    csvText = fs.readFileSync(path.resolve(source), 'utf-8');
  }
  const rows = parseCsv(csvText);

  if (rows.length < 2) {
    console.error('CSV must have a header row and at least one data row.');
    process.exit(1);
  }

  const headers = rows[0];
  const dataRows = rows.slice(1);

  // 4. Parse and validate rows
  const valid = [];
  const skipped = [];

  for (let i = 0; i < dataRows.length; i++) {
    const cells = dataRows[i];
    // Skip fully empty rows
    if (cells.every((c) => !c)) continue;

    const { challenge, missing, rawName } = parseRow(headers, cells);

    if (missing.length > 0) {
      skipped.push({ row: i + 2, name: rawName, missing });
    } else {
      valid.push(challenge);
    }
  }

  if (valid.length === 0) {
    console.error('\nNo valid challenges found in CSV.');
    if (skipped.length > 0) printSkipped(skipped);
    process.exit(1);
  }

  // 5. Insert challenges
  console.log(`\nInserting ${valid.length} challenges...`);

  const data = valid.map((c, idx) => ({
    linkedEventId: journeyId,
    eventIndex: idx,
    name: c.name,
    description: c.description,
    location: c.location,
    points: c.points,
    imageUrl: c.imageUrl,
    latitude: c.latitude,
    longitude: c.longitude,
    awardingRadius: c.awardingRadius,
    closeRadius: c.closeRadius,
  }));

  const result = await prisma.challenge.createMany({ data });
  console.log(`Created ${result.count} challenges`);

  // 6. Print summary
  if (skipped.length > 0) printSkipped(skipped);

  console.log('\nDone!');
}

function printSkipped(skipped) {
  console.log(`\n--- Skipped ${skipped.length} row(s) ---`);
  for (const s of skipped) {
    console.log(`  Row ${s.row}: "${s.name}" — missing: ${s.missing.join(', ')}`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
