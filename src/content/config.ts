import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.date(),
    author: z.string(),
    authorHandle: z.string(),
    draft: z.boolean().default(false),
    tags: z.array(z.string()).default([]),
    image: z.string().optional(),
  }),
});

export const collections = { blog };
