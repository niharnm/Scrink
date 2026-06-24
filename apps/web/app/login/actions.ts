"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  getSupabasePublicConfig,
  missingSupabaseConfigMessage,
} from "@/lib/supabase/config";

function normalizeEmail(formData: FormData) {
  return String(formData.get("email") || "").trim().toLowerCase();
}

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export async function requestEmailCode(prevState: unknown, formData: FormData) {
  const email = normalizeEmail(formData);

  if (!isValidEmail(email)) {
    return {
      step: "email",
      email,
      error: "Enter a valid email address.",
    };
  }

  if (!getSupabasePublicConfig()) {
    return {
      step: "email",
      email,
      error: missingSupabaseConfigMessage,
    };
  }

  const captchaToken = String(formData.get("captchaToken") || "") || undefined;
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      shouldCreateUser: true,
      captchaToken,
    },
  });

  if (error) {
    return {
      step: "email",
      email,
      error: error.message,
    };
  }

  return {
    step: "code",
    email,
    message: "We sent a 6-digit code to your email.",
  };
}

export async function verifyEmailCode(prevState: unknown, formData: FormData) {
  const email = normalizeEmail(formData);
  const token = String(formData.get("code") || "").replace(/\D/g, "");

  if (!isValidEmail(email)) {
    return {
      step: "email",
      email,
      error: "Enter a valid email address.",
    };
  }

  if (token.length !== 6) {
    return {
      step: "code",
      email,
      error: "Enter the 6-digit code from your email.",
    };
  }

  if (!getSupabasePublicConfig()) {
    return {
      step: "code",
      email,
      error: missingSupabaseConfigMessage,
    };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.verifyOtp({
    email,
    token,
    type: "email",
  });

  if (error) {
    return {
      step: "code",
      email,
      error: error.message,
    };
  }

  revalidatePath("/", "layout");
  redirect(safeNextPath(formData.get("next")));
}

/**
 * Where to land after sign-in. Only an internal absolute path is allowed
 * (e.g. "/friend"); anything protocol-relative or cross-origin falls back to "/"
 * so the `next` param can't be abused as an open redirect.
 */
function safeNextPath(raw: FormDataEntryValue | null): string {
  const value = typeof raw === "string" ? raw : "";
  return value.startsWith("/") && !value.startsWith("//") ? value : "/";
}
