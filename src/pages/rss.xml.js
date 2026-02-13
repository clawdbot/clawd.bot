import rss from '@astrojs/rss';
import { getPublishedBlogPosts } from '../lib/blog';

export async function GET(context) {
  const posts = await getPublishedBlogPosts();

  return rss({
    title: 'OpenClaw Blog',
    description: 'Updates and news from OpenClaw — The AI that actually does things',
    site: context.site ?? 'https://openclaw.ai',
    items: posts.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.date,
      link: `/blog/${post.slug}`,
    })),
  });
}
