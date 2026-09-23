import { createClient } from '@supabase/supabase-js';
import { previewPosts } from '../data/preview-posts.js';

const url=import.meta.env.PUBLIC_SUPABASE_URL;
const serviceKey=import.meta.env.SUPABASE_SERVICE_ROLE_KEY;
const hasSupabase=()=>Boolean(url&&serviceKey);
const readingTime=html=>Math.max(1,Math.ceil(((html||'').replace(/<[^>]+>/g,'').length||1)/500));

function normalize(row){
  const tags=(row.post_tags||[]).map(link=>link.tags).filter(Boolean);
  const author=row.profiles ? {name:row.profiles.display_name||'BACK MOUNTAIN'} : {name:'BACK MOUNTAIN'};
  return {slug:row.slug,title:row.title,excerpt:row.excerpt||'',published_at:row.published_at,updated_at:row.updated_at,feature_image:row.feature_image,feature_image_alt:row.feature_image_alt||'',html:row.html||'',featured:Boolean(row.featured),reading_time:readingTime(row.html),tags,primary_tag:tags[0]||null,authors:[author],primary_author:author,
    en:row.title_en?.trim()&&row.html_en?.trim()?{title:row.title_en,excerpt:row.excerpt_en||'',html:row.html_en,feature_image_alt:row.feature_image_alt_en||row.feature_image_alt||''}:null};
}
async function getPublishedFromSupabase(){
 const supabase=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}});
 const {data,error}=await supabase.from('posts').select('slug,title,excerpt,published_at,updated_at,feature_image,feature_image_alt,html,featured,title_en,excerpt_en,html_en,feature_image_alt_en,profiles!posts_author_id_fkey(display_name),post_tags(tags(name,slug,name_en,description,description_en))').eq('status','published').not('published_at','is',null).order('published_at',{ascending:false});
 if(error) throw new Error(`Supabase published-post build failed: ${error.message}`);
 return (data||[]).map(normalize);
}
export async function getPosts(){if(!hasSupabase()) return previewPosts;return getPublishedFromSupabase();}
export async function getEnglishPosts(){return (await getPosts()).filter(p=>p.en).map(p=>({...p,title:p.en.title,excerpt:p.en.excerpt,html:p.en.html,feature_image_alt:p.en.feature_image_alt,tags:(p.tags||[]).map(t=>({...t,name:t.name_en||t.name,description:t.description_en||t.description})),primary_tag:p.primary_tag?{...p.primary_tag,name:p.primary_tag.name_en||p.primary_tag.name}:null,reading_time:readingTime(p.en.html)}));}
export function contentSource(){return hasSupabase()?'supabase':'preview';}
