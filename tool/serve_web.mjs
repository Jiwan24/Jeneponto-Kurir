import { createServer } from 'node:http';
import { promises as fs } from 'node:fs';
import path from 'node:path';

const root = path.resolve('build/web');
const port = Number(process.env.PORT ?? 5000);

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json; charset=utf-8',
};

async function resolveFile(pathname) {
  const clean = pathname === '/' ? '/index.html' : pathname;
  const file = path.join(root, path.normalize(clean));
  if (!file.startsWith(root)) return null;

  try {
    const stats = await fs.stat(file);
    if (stats.isFile()) return file;
    if (stats.isDirectory()) {
      const index = path.join(file, 'index.html');
      const indexStats = await fs.stat(index);
      if (indexStats.isFile()) return index;
    }
  } catch (_) {
    // File tidak ada.
  }
  return null;
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url ?? '/', `http://${request.headers.host}`);
  let file = await resolveFile(decodeURIComponent(url.pathname));

  if (!file && (request.headers.accept ?? '').includes('text/html')) {
    file = path.join(root, 'index.html');
  }

  if (!file) {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Not found');
    return;
  }

  try {
    const data = await fs.readFile(file);
    response.writeHead(200, {
      'Content-Type': mime[path.extname(file).toLowerCase()] ?? 'application/octet-stream',
      'Cache-Control': 'no-store',
      'Service-Worker-Allowed': '/',
    });
    response.end(data);
  } catch (error) {
    response.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end(String(error));
  }
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Jeneponto Kurir demo: http://127.0.0.1:${port}`);
});
