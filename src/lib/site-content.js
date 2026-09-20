import { createClient } from '@supabase/supabase-js';
const defaults={
 'home.eyebrow':{zh:'田野筆記 / 001',en:'FIELD NOTES / EN'},
 'home.headline':{zh:'留下足夠的空白，讓問題自己出現。',en:'Independent notes on technology, design, research, and human agency.'},
 'home.subjects':{zh:'科技 · 設計 · 研究',en:'Technology · Design · Research'},
 'home.intro':{zh:'關於系統、實踐與人類能動性的獨立筆記。',en:'Independent notes on systems, practice and human agency.'},
 'home.about':{zh:'關於技術、設計與研究的獨立筆記。不是追逐更多資訊，而是保留足夠空間，辨認什麼值得被看見。',en:'Independent notes on technology, design, research, systems, practice, and human agency.'},
 'site.footer':{zh:'獨立數位刊物',en:'Independent digital publication'}
};
export async function getSiteContent(locale='zh'){
 const out=Object.fromEntries(Object.entries(defaults).map(([k,v])=>[k,v[locale]||v.zh]));
 const url=import.meta.env.PUBLIC_SUPABASE_URL,key=import.meta.env.SUPABASE_SERVICE_ROLE_KEY;if(!url||!key)return out;
 const supabase=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
 const {data,error}=await supabase.from('site_content').select('key,value_zh_hant,value_en');if(error)throw new Error(`Supabase site-content build failed: ${error.message}`);
 for(const row of data||[])out[row.key]=(locale==='en'?row.value_en:row.value_zh_hant)||out[row.key]||'';
 return out;
}