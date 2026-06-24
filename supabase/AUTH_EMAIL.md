# Email-code login (Resend)

Rinkler logs in with a **6-digit code emailed to the user** — no password, and
separate from Apple/Google sign-in. Both the iOS app and the website call
Supabase GoTrue (`/auth/v1/otp` to send, `/auth/v1/verify` to check). Supabase
sends the actual email, so making the code arrive reliably is a Supabase **Auth
email** config job, captured here in version control.

## What's in the repo

- `config.toml` — pins OTP behaviour (6 digits, 1-hour expiry), points custom
  SMTP at **Resend**, and wires the email templates.
- `templates/otp_code.html` — the email that shows `{{ .Token }}` (the code).
  Used by the `confirmation`, `magic_link`, **and** `reauthentication` templates.
- `.env.example` — where the Resend API key goes (copy to `supabase/.env`).

### The new-user gotcha (why all three templates point at the same file)

`signInWithOtp` chooses the template by whether the account already exists.
Rinkler sends `create_user: true`, so:

- **First-time user** → `confirmation` ("Confirm signup") template
- **Returning user** → `magic_link` template

Supabase's *default* "Confirm signup" template contains a confirmation **link**,
not a code — so a brand-new user on the "enter your code" screen would have
nothing to type. Pointing both at `otp_code.html` (which renders `{{ .Token }}`)
fixes that.

## One-time prerequisites in Resend

1. Add and **verify your sending domain** (e.g. `rinkler.app`) in Resend → Domains.
2. Create an API key (Resend → API Keys, "Sending access").
3. Make sure the `admin_email` in `config.toml` (`login@rinkler.app`) is on the
   verified domain.

## Apply — option A: CLI (preferred, reproducible)

```bash
# from repo root, with the Supabase CLI installed
cp supabase/.env.example supabase/.env      # then paste your Resend key
supabase link --project-ref <your-project-ref>
supabase config push                        # pushes auth/email config + templates
```

`supabase/.env` is gitignored (`.env*` rule), so the key never gets committed.

## Apply — option B: dashboard (no CLI)

In the Supabase dashboard for the project:

1. **Authentication → Emails → SMTP Settings**: enable custom SMTP and enter
   - Host `smtp.resend.com`, Port `465`, Username `resend`,
     Password = your Resend API key, Sender `login@rinkler.app`, Name `Rinkler`.
2. **Authentication → Emails → Templates**: for **Confirm signup**, **Magic
   Link**, and **Reauthentication**, paste the body of `templates/otp_code.html`
   and set the subject to `Your Rinkler code` (keep `{{ .Token }}` intact).
3. **Authentication → Providers → Email**: confirm "Confirm email" is **off** so
   the code itself signs the user in.

## Verify it works

1. From the website login page (or the app), enter a fresh email → "Send code".
2. The email should arrive from `login@rinkler.app` and show a 6-digit code
   (not a link). In Resend → Logs you should see the send.
3. Type the code → you're signed in.
4. Test a **brand-new** email too (exercises the "Confirm signup" template path).
5. Tap "Resend code" → a second code arrives (subject to the 60s `max_frequency`).
