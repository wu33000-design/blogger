import { createClient } from '@supabase/supabase-js';

const url=import.meta.env.PUBLIC_SUPABASE_URL;
const key=import.meta.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY;

export const supabaseConfigured=Boolean(url&&key);
let client;

export function getSupabaseClient(){
 if(!supabaseConfigured) throw new Error('Supabase is not configured. Set PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_PUBLISHABLE_KEY.');
 client??=createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
 return client;
}
