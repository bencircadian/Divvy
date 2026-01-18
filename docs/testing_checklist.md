# Mobile Testing Checklist

## iOS Testing

### Authentication
- [ ] Sign in with Apple works
- [ ] Google Sign-In works
- [ ] Email/password sign-in works
- [ ] Sign-out works
- [ ] Password reset flow works
- [ ] Session persists after app restart

### Push Notifications
- [ ] Permission prompt appears
- [ ] Notifications delivered when app is backgrounded
- [ ] Notifications delivered when app is killed
- [ ] Tapping notification opens correct screen
- [ ] Notification settings sync correctly

### Deep Links
- [ ] `divvy://` scheme opens app
- [ ] `io.supabase.divvy://` scheme opens app
- [ ] OAuth callback redirects work
- [ ] Invite links open correctly

### Accessibility
- [ ] VoiceOver navigation works
- [ ] Task cards announce correctly
- [ ] Buttons have proper labels
- [ ] Progress indicators announce percentage
- [ ] Dynamic type supported

### UI/UX
- [ ] Safe areas respected (notch, home indicator)
- [ ] Keyboard avoidance works
- [ ] Pull-to-refresh works
- [ ] Swipe actions work
- [ ] Dark mode displays correctly
- [ ] Animations play smoothly

### Offline Behavior
- [ ] Tasks cached locally
- [ ] Can view tasks offline
- [ ] Changes sync when online
- [ ] Offline indicator shows

---

## Android Testing

### Authentication
- [ ] Google Sign-In works
- [ ] Email/password sign-in works
- [ ] Sign-out works
- [ ] Password reset flow works
- [ ] Session persists after app restart

### Push Notifications
- [ ] Permission prompt appears (Android 13+)
- [ ] Notifications delivered when app is backgrounded
- [ ] Notifications delivered when app is killed
- [ ] Tapping notification opens correct screen
- [ ] Notification settings sync correctly

### Deep Links
- [ ] `divvy://` scheme opens app
- [ ] `io.supabase.divvy://login-callback` works
- [ ] OAuth callback redirects work
- [ ] Invite links open correctly

### Accessibility
- [ ] TalkBack navigation works
- [ ] Task cards announce correctly
- [ ] Buttons have proper labels
- [ ] Progress indicators announce percentage

### UI/UX
- [ ] Back button behavior correct
- [ ] Keyboard avoidance works
- [ ] Pull-to-refresh works
- [ ] Swipe actions work
- [ ] Dark mode displays correctly
- [ ] Material You theming (Android 12+)
- [ ] Edge-to-edge works correctly

### Offline Behavior
- [ ] Tasks cached locally
- [ ] Can view tasks offline
- [ ] Changes sync when online
- [ ] Offline indicator shows

---

## Web Testing

### Authentication
- [ ] Google OAuth redirect works
- [ ] Apple OAuth redirect works
- [ ] Email/password sign-in works
- [ ] Sign-out works
- [ ] Password reset flow works
- [ ] Session persists after page refresh

### Deep Links
- [ ] OAuth callback URLs work
- [ ] Share links open correctly

### Accessibility
- [ ] Keyboard navigation works
- [ ] Tab order logical
- [ ] Screen readers announce correctly
- [ ] Focus indicators visible

### UI/UX
- [ ] Responsive layout (mobile/tablet/desktop)
- [ ] Hover states work
- [ ] Tooltips appear
- [ ] Dark mode displays correctly

### Cross-browser
- [ ] Chrome works
- [ ] Safari works
- [ ] Firefox works
- [ ] Edge works

---

## General Testing

### Performance
- [ ] App starts in < 3 seconds
- [ ] Smooth scrolling (60fps)
- [ ] No janky animations
- [ ] Memory usage reasonable

### Error Handling
- [ ] Network errors show user-friendly message
- [ ] Invalid input shows validation error
- [ ] Sentry captures errors (when configured)

### Onboarding
- [ ] Feature tour displays
- [ ] Demo mode works
- [ ] Quick setup flow completes
- [ ] Skip options work
- [ ] Progress indicator updates

### Core Features
- [ ] Create task works
- [ ] Complete task works
- [ ] Edit task works
- [ ] Delete task works
- [ ] Recurring tasks generate correctly
- [ ] Task bundles work (if enabled)

---

## Pre-release Checklist

1. [ ] Run `flutter analyze` - no errors
2. [ ] Run `flutter test` - all pass
3. [ ] Test on physical iOS device
4. [ ] Test on physical Android device
5. [ ] Test on Chrome/Safari/Firefox
6. [ ] Check Sentry for new errors
7. [ ] Review crash reports
8. [ ] Verify production API endpoints
9. [ ] Test with slow network (Network Link Conditioner)
10. [ ] Test offline mode

---

## Supabase Database Security

### Recommended Fixes (from Supabase Linter)

1. **Function Search Path Mutable** - Set `search_path` for these functions:
   - `public.check_invite_rate_limit`
   - `public.cleanup_old_invite_attempts`
   - `public.get_weekly_task_counts`
   - `public.get_workload_distribution`

   Fix: Add `SET search_path = public` to each function definition:
   ```sql
   ALTER FUNCTION function_name() SET search_path = public;
   ```

2. **RLS Policy Always True** - Review `notifications` table INSERT policy:
   - Policy `System can insert notifications` uses `WITH CHECK (true)`
   - Consider restricting to specific roles or service role only

3. **Leaked Password Protection** - Enable in Supabase Dashboard:
   - Go to Authentication > Settings > Password Protection
   - Enable "Check passwords against HaveIBeenPwned database"
