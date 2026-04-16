import { collection, config, fields } from '@keystatic/core'

const isProd = true

export default config({
  storage: isProd
    ? {
        kind: 'github',
        repo: 'danilolaetas/keystatic-demo',
        branchPrefix: 'content/',
      }
    : { kind: 'local' },
  collections: {
    faqs: collection({
      label: 'FAQ',
      slugField: 'title',
      path: 'src/content/docs/faqs/*',
      format: { contentField: 'content' },
      schema: {
        title: fields.slug({ name: { label: 'Title' } }),
        description: fields.text({
          label: 'Description',
          description: 'Short summary shown in listings',
        }),
        category: fields.select({
          label: 'Category',
          options: [
            { label: 'General', value: 'general' },
            { label: 'Billing', value: 'billing' },
            { label: 'Technical', value: 'technical' },
            { label: 'Account', value: 'account' },
          ],
          defaultValue: 'general',
        }),
        content: fields.mdx({ label: 'Content' }),
      },
    }),

    releases: collection({
      label: 'Release Notes',
      slugField: 'title',
      path: 'src/content/docs/releases/*',
      format: { contentField: 'content' },
      schema: {
        title: fields.slug({ name: { label: 'Title' } }),
        description: fields.text({
          label: 'Summary',
          description: 'One-line summary of this release',
        }),
        version: fields.text({
          label: 'Version',
          description: 'Semantic version (e.g. 2.4.0)',
          validation: { isRequired: true },
        }),
        releaseDate: fields.date({
          label: 'Release Date',
          validation: { isRequired: true },
          defaultValue: { kind: 'today' },
        }),
        type: fields.select({
          label: 'Release Type',
          options: [
            { label: 'Major', value: 'major' },
            { label: 'Minor', value: 'minor' },
            { label: 'Patch', value: 'patch' },
            { label: 'Hotfix', value: 'hotfix' },
          ],
          defaultValue: 'minor',
        }),
        status: fields.select({
          label: 'Status',
          options: [
            { label: 'Draft', value: 'draft' },
            { label: 'Published', value: 'published' },
          ],
          defaultValue: 'draft',
        }),
        content: fields.mdx({ label: 'Content' }),
      },
    }),
  },
})
