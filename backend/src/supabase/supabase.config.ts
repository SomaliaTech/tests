export const configureSupabase = () => {
  return {
    url: process.env.SUPABASE_URL!,
    anonKey: process.env.SUPABASE_ANON_KEY!,
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY!,
    bucketName: process.env.SUPABASE_BUCKET_NAME || 'products',
  };
};
