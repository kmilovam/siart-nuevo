import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  const { user, pass } = await req.json();
  if (user === process.env.LOGIN_USER && pass === process.env.LOGIN_PASS) {
    return NextResponse.json({ success: true });
  }
  return NextResponse.json({ success: false }, { status: 401 });
}
