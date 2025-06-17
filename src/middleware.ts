import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(req: NextRequest) {
  const publicPaths = ['/login','/api/auth/login'];
  if (publicPaths.includes(req.nextUrl.pathname)) return NextResponse.next();
  const isLoggedIn = req.cookies.get('loggedIn')?.value === 'true';
  return isLoggedIn
    ? NextResponse.next()
    : NextResponse.redirect(new URL('/login', req.url));
}
