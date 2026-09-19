export const previewPosts = [
  {
    slug: 'welcome',
    title: '內部預覽：第一篇文章',
    excerpt: '這是尚未連接正式 Ghost CMS 前使用的預覽內容，用來確認 Astro 靜態網站的資訊架構與發布流程。',
    published_at: '2026-09-20T00:00:00.000Z',
    feature_image: null,
    html: '<p>這是一個內部檢視版本。</p><p>正式部署連接 Ghost Content API 後，這裡會顯示 Ghost 編輯器輸出的文章內容。</p>'
  },
  {
    slug: 'architecture-preview',
    title: '系統架構預覽',
    excerpt: 'Astro 在建置階段讀取 Ghost，產生完全靜態 HTML，再由 Cloudflare Pages 發布。',
    published_at: '2026-09-19T00:00:00.000Z',
    feature_image: null,
    html: '<h2>目前架構</h2><p>Astro SSG → static HTML → CDN。Ghost 作為 Headless CMS，圖片預計儲存在 Cloudflare R2。</p>'
  }
];
