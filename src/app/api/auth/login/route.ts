import { NextResponse } from 'next/server';

const USERS = [
  { user: process.env.USER1, pass: process.env.PASS1 },
  { user: process.env.USER2, pass: process.env.PASS2 },
  { user: process.env.USER3, pass: process.env.PASS3 },
  { user: process.env.USER4, pass: process.env.PASS4 }
];

export async function POST(req: Request) {
  const { user, pass } = await req.json();
  const valid = USERS.some(u=>u.user===user&&u.pass===pass);
  if (valid) return NextResponse.json({ success: true });
  return NextResponse.json({ success: false }, { status: 401 });
}
