// src/redis/test-upstash.ts
import { Redis } from '@upstash/redis';

async function testConnection() {
  // Your Upstash URL from .env
  const fullUrl =
    'rediss://default:gQAAAAAAAlXIAAIgcDFmYWZmNjMyM2VlMTA0ZWUzODVhZjRhNTZhNWQ3YTNlOA@mature-flamingo-153032.upstash.io:6379';

  console.log('🔗 Testing Upstash Redis connection...');

  try {
    // Parse the URL to extract components
    const parsedUrl = new URL(fullUrl);
    const token = parsedUrl.password;
    const restUrl = `https://${parsedUrl.hostname}`;

    console.log('Host:', parsedUrl.hostname);
    console.log('Token:', token ? '****' + token.slice(-4) : 'missing');
    console.log('REST URL:', restUrl);

    // Initialize with both url and token
    const redis = new Redis({
      url: restUrl,
      token: token || '',
    });

    // Test ping
    console.log('\n📡 Testing ping...');
    const ping = await redis.ping();
    console.log('✅ Ping:', ping);

    // Test set/get
    console.log('\n📝 Testing set/get...');
    await redis.set('test-key', 'test-value');
    const value = await redis.get('test-key');
    console.log('✅ Set/Get result:', value);

    // Test delete
    console.log('\n🗑️  Testing delete...');
    await redis.del('test-key');
    const deletedValue = await redis.get('test-key');
    console.log(
      '✅ Delete result:',
      deletedValue === null ? 'null (deleted)' : deletedValue,
    );

    // Test increment
    console.log('\n📊 Testing counter...');
    await redis.set('counter', '0');
    await redis.incr('counter');
    await redis.incr('counter');
    const counter = await redis.get('counter');
    console.log('✅ Counter value:', counter);
    await redis.del('counter');

    // Test pipeline
    console.log('\n🔧 Testing pipeline...');
    const pipeline = redis.pipeline();
    pipeline.incr('pipe-test');
    pipeline.incr('pipe-test');
    pipeline.incr('pipe-test');
    const results = await pipeline.exec();
    console.log('✅ Pipeline results:', results);
    await redis.del('pipe-test');

    console.log('\n🎉 All tests passed! Upstash Redis is working correctly.');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Redis test failed:', error);
    process.exit(1);
  }
}

testConnection();
