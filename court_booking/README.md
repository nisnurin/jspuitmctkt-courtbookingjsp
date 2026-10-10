# JSP Court Booking (UiTM Terengganu)
1. Supabase: create project -> SQL Editor -> run supabase/schema.sql.
   Authentication -> Users -> Add user (email+password) for each JSP committee member.
   Authentication -> Sign In / Providers -> turn OFF "Allow new users to sign up".
2. Edit supaUrl and supaKey (anon key) at the top of lib/main.dart.
3. In this folder: flutter create . --platforms=web,android   (generates web/android folders)
4. flutter pub get && flutter run -d chrome
5. Deploy: flutter build web --release  -> upload build/web (see chat for Cloudflare Pages steps)
