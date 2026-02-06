import { defineCollection, z } from 'astro:content';

const authorSchema = z.object({
  name: z.string(),
  handle: z.string(),
});

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.date(),
    // Single author (legacy)
    author: z.string().optional(),
    authorHandle: z.string().optional(),
    // Multiple authors
    authors: z.array(authorSchema).optional(),
    draft: z.boolean().default(false),
    tags: z.array(z.string()).default([]),
    image: z.string().optional(),
  }),
});

export const collections = { blog };
