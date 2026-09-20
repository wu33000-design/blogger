import { previewPosts } from '../data/preview-posts.js';

const fields = 'slug,title,excerpt,published_at,feature_image,html,reading_time,featured,tags,primary_tag,authors,primary_author';

function normalize(post) {
  return {
    ...post,
    reading_time: post.reading_time ?? Math.max(1, Math.ceil(((post.html || '').replace(/<[^>]+>/g, '').length || 1) / 500)),
    tags: post.tags ?? [],
    authors: post.authors ?? [],
  };
}

export async function getPosts() {
  const GHOST_URL = import.meta.env.GHOST_URL;
  const GHOST_KEY = import.meta.env.GHOST_KEY;
  if (!GHOST_URL || !GHOST_KEY) return previewPosts.map(normalize);

  const endpoint = new URL('/ghost/api/content/posts/', GHOST_URL);
  endpoint.searchParams.set('key', GHOST_KEY);
  endpoint.searchParams.set('fields', fields);
  endpoint.searchParams.set('include', 'tags,authors');
  endpoint.searchParams.set('limit', 'all');
  endpoint.searchParams.set('order', 'published_at DESC');
  const response = await fetch(endpoint);
  if (!response.ok) throw new Error(`Ghost Content API request failed: ${response.status} ${response.statusText}`);
  const { posts = [] } = await response.json();
  return posts.map(normalize);
}

export async function getTags() {
  const posts = await getPosts();
  const map = new Map();
  for (const post of posts) for (const tag of post.tags || []) {
    if (!map.has(tag.slug)) map.set(tag.slug, { ...tag, count: 0 });
    map.get(tag.slug).count++;
  }
  return [...map.values()].sort((a,b)=>a.name.localeCompare(b.name));
}

export async function getPostsByTag(slug) {
  return (await getPosts()).filter(post => (post.tags || []).some(tag => tag.slug === slug));
}
