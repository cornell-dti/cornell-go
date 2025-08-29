#!/usr/bin/env node

const { execSync } = require("child_process");
const { chdir } = require("process");

// Get database URL from command line argument or environment variable
const dbUrl = process.argv[2] || process.env.CUSTOM_DATABASE_URL;

if (!dbUrl) {
  console.log("❌ No database URL provided!");
  console.log("\nUsage:");
  console.log("  node scripts/inspect-db.js <DATABASE_URL>");
  console.log("  or set CUSTOM_DATABASE_URL environment variable");
  console.log("\nExample:");
  console.log('  node scripts/inspect-db.js "postgres://user:pass@host:port/db"');
  process.exit(1);
}

async function main() {
  console.log("🔍 Inspecting database...");
  console.log(`📊 Database: ${dbUrl.replace(/:[^:@]*@/, ':***@')}`); // Hide password in logs
  console.log("📍 Navigating to server directory...");
  
  // Change to server directory
  chdir("./server");
  
  console.log("🚀 Starting Prisma Studio...");
  console.log("   This will open in your browser at http://localhost:5555");
  console.log("   Press Ctrl+C to stop when you're done inspecting.");
  
  try {
    // Run prisma studio with the provided DATABASE_URL
    execSync(`DATABASE_URL="${dbUrl}" npx prisma studio`, {
      stdio: "inherit",
      env: {
        ...process.env,
        DATABASE_URL: dbUrl
      }
    });
  } catch (error) {
    console.log("\n✅ Prisma Studio stopped.");
  }
}

main().catch(error => {
  console.error("❌ Error:", error.message);
  process.exit(1);
});
