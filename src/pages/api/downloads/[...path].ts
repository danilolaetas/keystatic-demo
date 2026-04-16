import type { APIRoute } from 'astro'
import { createReadStream, existsSync, statSync } from 'node:fs'
import { readdir } from 'node:fs/promises'
import { join, resolve } from 'node:path'
import archiver from 'archiver'
import { Readable } from 'node:stream'

const DOCS_OUTPUT_DIR = resolve(process.cwd(), 'docs/output')

const MIME_TYPES: Record<string, string> = {
  '.pdf': 'application/pdf',
  '.epub': 'application/epub+zip',
  '.zip': 'application/zip',
}

async function createHtmlZip(): Promise<ReadableStream<Uint8Array>> {
  const htmlDir = join(DOCS_OUTPUT_DIR, 'html')

  if (!existsSync(htmlDir)) {
    throw new Error('HTML documentation not found')
  }

  const archive = archiver('zip', { zlib: { level: 9 } })

  archive.directory(htmlDir, 'html')
  archive.finalize()

  return Readable.toWeb(archive) as ReadableStream<Uint8Array>
}

export const GET: APIRoute = async ({ params }) => {
  const requestedPath = params.path

  if (!requestedPath) {
    return new Response('File path required', { status: 400 })
  }

  // Handle HTML ZIP request specially
  if (requestedPath === 'html.zip') {
    try {
      const zipStream = await createHtmlZip()
      return new Response(zipStream, {
        headers: {
          'Content-Type': 'application/zip',
          'Content-Disposition': 'attachment; filename="documentation-html.zip"',
        },
      })
    } catch (error) {
      return new Response('HTML documentation not available', { status: 404 })
    }
  }

  // Sanitize path to prevent directory traversal
  const sanitizedPath = requestedPath.replace(/\.\./g, '')
  const filePath = join(DOCS_OUTPUT_DIR, sanitizedPath)

  // Ensure the resolved path is within the docs output directory
  const resolvedPath = resolve(filePath)
  if (!resolvedPath.startsWith(DOCS_OUTPUT_DIR)) {
    return new Response('Invalid path', { status: 403 })
  }

  if (!existsSync(resolvedPath)) {
    return new Response('File not found', { status: 404 })
  }

  const stat = statSync(resolvedPath)
  if (!stat.isFile()) {
    return new Response('Not a file', { status: 400 })
  }

  // Determine content type
  const ext = resolvedPath.substring(resolvedPath.lastIndexOf('.'))
  const contentType = MIME_TYPES[ext] || 'application/octet-stream'

  // Get filename for Content-Disposition
  const filename = resolvedPath.substring(resolvedPath.lastIndexOf('/') + 1)

  const fileStream = createReadStream(resolvedPath)
  const webStream = Readable.toWeb(fileStream) as ReadableStream<Uint8Array>

  return new Response(webStream, {
    headers: {
      'Content-Type': contentType,
      'Content-Length': stat.size.toString(),
      'Content-Disposition': `attachment; filename="${filename}"`,
    },
  })
}
