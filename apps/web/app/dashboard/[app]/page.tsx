import { redirect } from "next/navigation";
import { connection } from "next/server";
import { createClient } from "@/lib/supabase/server";
import AppDetailClient from "./client";

interface Props {
  params: Promise<{ app: string }>;
}

export default async function AppDetailPage({ params }: Props) {
  await connection();

  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();

  if (!data?.claims) {
    redirect("/login");
  }

  const { app } = await params;
  return <AppDetailClient slug={app} />;
}
