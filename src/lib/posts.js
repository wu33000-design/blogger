import { previewPosts } from '../data/preview-posts.js';

export async function getPosts() {
  const GHOST_URL = import.meta.env.GHOST_URL;
  const GHOST_KEY = import.meta.env.GHOST_KEY;

  if (!GHOST_URL || !GHOST_KEY) {
    return previewPosts;
  }

  const endpoint = new URL('/ghost/api/content/posts/', GHOST_URL);
  endpoint.searchParams.set('key', GHOST_KEY);
  endpoint.searchParams.set('fields', 'slug,title,excerpt,published_at,feature_image,html');
  endpoint.searchParams.set('limit', 'all');
  endpoint.searchParams.set('order', 'published_at DESC');

  const response = await fetch(endpoint);
  if (!response.ok) {
    throw new Error(`Ghost Content API request failed: ${response.status} ${response.statusText}`);
  }

  const { posts = [] } = await response.json();
  return posts;
}
