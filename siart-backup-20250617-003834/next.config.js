/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  eslint: {
    // Ignora errores de ESLint durante builds de producción
    ignoreDuringBuilds: true,
  },
  typescript: {
    // Ignora errores de TypeScript durante builds de producción
    ignoreBuildErrors: true,
  },
}

module.exports = nextConfig
