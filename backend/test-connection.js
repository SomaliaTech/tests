const { Pool } = require('pg');

// Test different connection string formats
const testUrls = [
  {
    name: 'Standard Domain - Session Pooler',
    url: 'postgresql://postgres:KHxUR8QPeP6QOeLC@db.leqauklkigctaukoxnwc.supabase.co:6543/postgres'
  },
  {
    name: 'Standard Domain - Transaction Pooler',
    url: 'postgresql://postgres:KHxUR8QPeP6QOeLC@db.leqauklkigctaukoxnwc.supabase.co:5432/postgres'
  },
  {
    name: 'Pooler Domain with Project ID',
    url: 'postgresql://postgres:KHxUR8QPeP6QOeLC@leqauklkigctaukoxnwc.pooler.supabase.com:6543/postgres'
  },
  {
    name: 'AWS Pooler Domain (Current - Failing)',
    url: 'postgresql://postgres:KHxUR8QPeP6QOeLC@aws-0-eu-west-1.pooler.supabase.com:6543/postgres'
  },
  {
    name: 'Direct Connection (No Pooler)',
    url: 'postgresql://postgres:KHxUR8QPeP6QOeLC@db.leqauklkigctaukoxnwc.supabase.co:5432/postgres?sslmode=require'
  }
];

async function testConnection(testUrl) {
  console.log(`\n🔍 Testing: ${testUrl.name}`);
  const masked = testUrl.url.replace(/:[^:@]*@/, ':****@');
  console.log(`📝 URL: ${masked}`);
  
  const pool = new Pool({
    connectionString: testUrl.url,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 10000,
  });

  try {
    const client = await pool.connect();
    const result = await client.query('SELECT current_database(), current_user, version()');
    console.log('✅ SUCCESS! Connected!');
    console.log('📊 Database:', result.rows[0]);
    client.release();
    await pool.end();
    return true;
  } catch (err) {
    console.log(`❌ Failed: ${err.message}`);
    await pool.end().catch(() => {});
    return false;
  }
}

async function main() {
  console.log('🚀 Testing Supabase connection strings...\n');
  console.log(`Project ID: leqauklkigctaukoxnwc`);
  console.log(`Region: eu-west-1 (Ireland)`);
  console.log(`Password: KHxUR8QPeP6QOeLC\n`);
  
  let workingUrl = null;
  
  for (const test of testUrls) {
    const success = await testConnection(test);
    if (success) {
      workingUrl = test.url;
      console.log(`\n✅ WORKING CONNECTION FOUND!`);
      console.log(`📌 Use this in your .env file:\nDATABASE_URL="${test.url}"`);
      break;
    }
    // Small delay between tests
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  if (!workingUrl) {
    console.log('\n❌ No working connection found. Please check:');
    console.log('1. Your password is correct');
    console.log('2. Your Supabase project is active');
    console.log('3. Network restrictions in Supabase settings');
    console.log('4. You have the correct project ID');
  }
}

main().catch(console.error);
