import { previewPosts } from '../data/preview-posts.js';

const fields='slug,title,excerpt,published_at,updated_at,feature_image,feature_image_alt,html,reading_time,featured';
const hasGhost=()=>Boolean(import.meta.env.GHOST_URL&&import.meta.env.GHOST_KEY);
const normalize=post=>({...post,reading_time:post.reading_time??Math.max(1,Math.ceil(((post.html||'').replace(/<[^>]+>/g,'').length||1)/500)),tags:post.tags??[],authors:post.authors??[]});

async function ghost(path,params={}){
 const endpoint=new URL(`/ghost/api/content/${path}/`,import.meta.env.GHOST_URL);
 endpoint.searchParams.set('key',import.meta.env.GHOST_KEY);
 Object.entries(params).forEach(([k,v])=>endpoint.searchParams.set(k,v));
 const response=await fetch(endpoint);
 if(!response.ok) throw new Error(`Ghost Content API ${path} request failed: ${response.status} ${response.statusText}`);
 return response.json();
}

export async function getPosts(){
 if(!hasGhost()) return previewPosts.map(normalize);
 const {posts=[]}=await ghost('posts',{fields,include:'tags,authors',limit:'all',order:'published_at DESC'});
 return posts.map(normalize);
}
export async function getTags(){const posts=await getPosts();const map=new Map();for(const post of posts)for(const tag of post.tags||[]){if(!map.has(tag.slug))map.set(tag.slug,{...tag,count:0});map.get(tag.slug).count++;}return [...map.values()].sort((a,b)=>a.name.localeCompare(b.name));}
export async function getPostsByTag(slug){return (await getPosts()).filter(post=>(post.tags||[]).some(tag=>tag.slug===slug));}
export function contentSource(){return hasGhost()?'ghost':'preview';}
