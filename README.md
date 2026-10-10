# JSP Court Booking · UiTM Kuala Terengganu

Flutter (web, Android, iOS, desktop) + Supabase. Dark, futuristic sports UI (Poppins + orange accent,
taken from the AFA reference design). Responsive: sidebar layout on desktop, bottom navigation on mobile.

## Features
- Login (Supabase email + password) for JSP committee members
- Two courts: **Court Kolej** and **Court Kampus**
- Hourly booking, 8:00 AM – 12:00 AM (e.g. 9 PM → 12 AM = 3 hours)
- Live availability: free / booked / selected hours (shown with colour + icon + text)
- Booking form: name, phone, sport, optional note
- Double-booking is blocked by the database itself (not only by the app)
- Weekly and monthly timetable per court, with **PNG** and **PDF** download
- Tap a booking to see details or cancel it (with confirmation)

## Setup (5 steps)
1. **Create the project folders** (this zip only has the Dart code). In the unzipped folder run:
   ```
   flutter create . --platforms=web,android,ios --project-name court_booking_uitmkt
   flutter pub get
   ```
   (`flutter create .` will not overwrite `lib/` or `pubspec.yaml`.)
2. **Supabase**: create a free project at https://supabase.com, open **SQL Editor**, paste and run `supabase/schema.sql`.
3. **Create JSP accounts**: Supabase > Authentication > Users > *Add user* (email + password, tick "Auto Confirm").
   Then Authentication > Sign In / Providers > Email: turn **off** "Allow new users to sign up" so only your accounts can log in.
4. **Add your keys**: open `lib/config.dart` and paste the *Project URL* and *anon public key*
   (Supabase > Project Settings > API). Or run with:
   `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
5. **Run**: `flutter run -d chrome`

## Free deployment
```
flutter build web --release
```
Upload the `build/web` folder to **Netlify Drop**, **Vercel**, **Cloudflare Pages** or **Firebase Hosting** (all have free plans).
A custom domain such as courtbookinguitmkt.com is a paid extra; the free hosts give you a free `*.netlify.app` / `*.pages.dev` address.

## Notes
- Poppins is loaded through the `google_fonts` package (needs internet the first time).
- Change opening hours or the sport list in `lib/config.dart`.
- Tap an empty cell in the weekly timetable, or a free hour chip on the dashboard, to jump to the booking form with it pre-filled.
