require('dotenv').config();

async function testToken() {
  const accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
  const apiToken = process.env.CLOUDFLARE_API_TOKEN;

  console.log('🔍 Testing Cloudflare credentials...');
  console.log('Account ID:', accountId);
  console.log('Token prefix:', apiToken?.substring(0, 10) + '...');

  // Test 1: Verify token is valid
  const verifyUrl = `https://api.cloudflare.com/client/v4/user/tokens/verify`;
  const verifyResponse = await fetch(verifyUrl, {
    headers: {
      Authorization: `Bearer ${apiToken}`,
      'Content-Type': 'application/json',
    },
  });

  const verifyResult = await verifyResponse.json();
  console.log('\n📋 Token Verification:');
  console.log(JSON.stringify(verifyResult, null, 2));

  // Test 2: List images (requires Images permission)
  const listUrl = `https://api.cloudflare.com/client/v4/accounts/${accountId}/images/v1`;
  const listResponse = await fetch(listUrl, {
    headers: {
      Authorization: `Bearer ${apiToken}`,
      'Content-Type': 'application/json',
    },
  });

  const listResult = await listResponse.json();
  console.log('\n📸 Images List Test:');
  console.log(JSON.stringify(listResult, null, 2));
}

testToken().catch(console.error);
