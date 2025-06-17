/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  poweredByHeader: false,
  reactStrictMode: true,
  // outputFileTracingRoot movido fuera de experimental para Next.js 15
  outputFileTracingRoot: process.cwd(),
  experimental: {
    // Configuraciones experimentales válidas para Next.js 15
  }
}

module.exports = nextConfig
