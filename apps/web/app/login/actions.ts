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

  // Defense in depth: when a Turnstile site key is configured the client renders
  // a captcha, so a request with no token is either a misconfiguration or a bot
  // bypassing the widget. Reject it here rather than relying solely on the
  // Supabase project's captcha toggle being enabled.
  if (process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY && !captchaToken) {
    return {
      step: "email",
      email,
      error: "Captcha verification is required. Please try again.",
    };
  }

  const supabase = await createClient();

  // Waitlist gate (dark-launched behind a flag): only allow-listed emails can
  // request a code. Existing users were grandfathered into the list by migration,
  // so flipping this on never locks out a current account.
  if (process.env.ENABLE_WAITLIST_LOCK === "true") {
    const { data: allowed } = await supabase.rpc("email_can_sign_in", { p_email: email });
    if (!allowed) {
      return {
        step: "email",
        email,
        error: "You're on the waitlist — we'll email you the moment your spot opens.",
      };
    }
  }
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
  // A prefix check ("/" and not "//") is NOT enough: browsers normalize
  // backslashes, so "/\evil.com" becomes protocol-relative and escapes the
  // origin. Resolve against a sentinel origin and require the result to stay on
  // it, then return only the path — same approach as /auth/callback's safeNext.
  const base = "https://internal.invalid";
  try {
    const u = new URL(value, base);
    if (u.origin !== base) return "/";
    return `${u.pathname}${u.search}${u.hash}`;
  } catch {
    return "/";
  }
}
