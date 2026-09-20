import { createClient } from '@supabase/supabase-js';
import { previewPosts } from '../data/preview-posts.js';

const url=import.meta.env.PUBLIC_SUPABASE_URL;
const serviceKey=import.meta.env.SUPABASE_SERVICE_ROLE_KEY;
const hasSupabase=()=>Boolean(url&&serviceKey);

const readingTime=html=>Math.max(1,Math.ceil(((html||'').replace(/<[^>]+>/g,'').length||1)/500));

function normalize(row){
  const tags=(row.post_tags||[]).map(link=>link.tags).filter(Boolean);
  const author=row.profiles ? {name:row.profiles.display_name||'Field Notes'} : {name:'Field Notes'};
  return {
    slug:row.slug,
    title:row.title,
    excerpt:row.excerpt||'',
    published_at:row.published_at,
    updated_at:row.updated_at,
    feature_image:row.feature_image,
    feature_image_alt:row.feature_image_alt||'',
    html:row.html||'',
    featured:Boolean(row.featured),
    reading_time:readingTime(row.html),
    tags,
    primary_tag:tags[0]||null,
    authors:[author],
    primary_author:author
  };
}

async function getPublishedFromSupabase(){
  const supabase=createClient(url,serviceKey,{
    auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}
  });
  const {data,error}=await supabase
    .from('posts')
    .select('slug,title,excerpt,published_at,updated_at,feature_image,feature_image_alt,html,featured,profiles!posts_author_id_fkey(display_name),post_tags(tags(name,slug))')
    .eq('status','published')
    .not('published_at','is',null)
    .order('published_at',{ascending:false});
  if(error) throw new Error(`Supabase published-post build failed: ${error.message}`);
  return (data||[]).map(normalize);
}

export async function getPosts(){
  if(!hasSupabase()) return previewPosts;
  return getPublishedFromSupabase();
}

export async function getTags(){
  const posts=await getPosts();
  const map=new Map();
  for(const post of posts) for(const tag of post.tags||[]){
    if(!map.has(tag.slug)) map.set(tag.slug,{...tag,count:0});
    map.get(tag.slug).count++;
  }
  return [...map.values()].sort((a,b)=>a.name.localeCompare(b.name));
}

export async function getPostsByTag(slug){
  return (await getPosts()).filter(post=>(post.tags||[]).some(tag=>tag.slug===slug));
}

export function contentSource(){
  return hasSupabase()?'supabase':'preview';
}
