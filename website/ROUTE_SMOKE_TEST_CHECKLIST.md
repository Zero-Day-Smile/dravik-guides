# Route-Specific Smoke Test Checklist (Website)

Run this checklist in the live environment after deploying to Cloudflare Pages to validate all core features work correctly.

**Time to complete:** ~5-10 minutes

---

## 1. Core Pages & Navigation

- [ ] **Home page** (`/`)
  - [ ] Loads without errors
  - [ ] Hero section renders
  - [ ] Call-to-action buttons are visible
  - [ ] Browser console has no errors
  
- [ ] **Explore page** (`/explore`)
  - [ ] Loads list of destinations
  - [ ] Destinations display: name, image, difficulty, rating
  - [ ] Search/filter controls work
  - [ ] Click on destination → navigates to detail page
  - [ ] No "404 destination not found" on initial load

- [ ] **Map page** (`/map`)
  - [ ] Map renders
  - [ ] Destination pins appear on map
  - [ ] Clicking pin shows destination info popup
  - [ ] No console errors about map library

---

## 2. Authentication Flow

- [ ] **Auth page** (`/auth`)
  - [ ] Sign-in form loads
  - [ ] Sign-up form loads (toggle between sign-in/sign-up works)
  - [ ] Email/password inputs accept text
  - [ ] Disable password visibility toggle works

- [ ] **Sign-up flow**
  - [ ] Fill email + password + confirm password
  - [ ] Click "Create account" → activity indicator appears
  - [ ] After ~3-5 seconds → redirects to verification page (email confirmation)
  - [ ] No auth errors in console

- [ ] **Sign-in flow**
  - [ ] Fill email + password (use test account created above)
  - [ ] Click "Sign in" → activity indicator appears
  - [ ] After ~3-5 seconds → redirects to dashboard
  - [ ] No auth errors in console

- [ ] **Authenticated state**
  - [ ] User name appears in nav bar
  - [ ] "Sign out" link appears in menu
  - [ ] Click "Sign out" → user is logged out
  - [ ] Redirects back to auth page or home
  - [ ] Nav bar no longer shows user name

---

## 3. Data Loading & API Calls

- [ ] **Destinations data** (tested via Explore page)
  - [ ] GET `/destinations` succeeds (check Network tab)
  - [ ] Destinations show actual data (not empty state)
  - [ ] Images load (check for 404 image errors)
  - [ ] Ratings > 0 if reviews exist

- [ ] **Categories data** (tested via Explore page filters)
  - [ ] Categories load in sidebar
  - [ ] Clicking category filters destinations
  - [ ] Filtered results update in real time

- [ ] **Reviews** (on destination detail page)
  - [ ] Reviews section appears
  - [ ] Shows review count, avg rating
  - [ ] Individual review cards display correctly
  - [ ] No broken review data

---

## 4. Authenticated User Features

- [ ] **Dashboard** (`/dashboard`, requires login)
  - [ ] Page loads after sign-in
  - [ ] Displays welcome message with user's name
  - [ ] Shows user stats (trips, saved destinations, etc.)
  - [ ] No RLS errors in console

- [ ] **Trip Planner** (`/trips`)
  - [ ] Loads trip list (or empty state if no trips)
  - [ ] Can create new trip (form works)
  - [ ] Can select destination for trip
  - [ ] Can set trip dates
  - [ ] Trip appears in list after creation
  - [ ] Can edit/delete trip (if implemented)

- [ ] **Saved Destinations** (if accessible from dashboard or explore)
  - [ ] Heart icon on destination cards toggles "saved" state
  - [ ] Saved destinations persist after page reload
  - [ ] Saved destinations appear in user dashboard

---

## 5. Content Pages

- [ ] **Guides page** (`/guides`)
  - [ ] Loads list of guides
  - [ ] Click on guide → navigates to detail page (`/guides/:slug`)
  - [ ] Guide detail displays full content
  - [ ] No 404 errors for valid guide slugs

- [ ] **Safety page** (`/safety`)
  - [ ] Loads without errors
  - [ ] Safety tips/content displays
  - [ ] Images and formatting render correctly

- [ ] **Emergency Guides** (`/emergency-guides`)
  - [ ] Loads emergency guide content
  - [ ] Emergency contacts visible (if populated)
  - [ ] SOS messaging clear and visible

- [ ] **Weather page** (`/weather`)
  - [ ] Loads weather widget/data (if live)
  - [ ] Shows current conditions
  - [ ] Forecast displays correctly

- [ ] **Analytics page** (`/analytics`)
  - [ ] Loads charts/graphs
  - [ ] Charts render data (not empty)
  - [ ] No console errors

- [ ] **Activities page** (`/activity`)
  - [ ] Loads activity feed
  - [ ] Activities display user info + timestamps
  - [ ] No pagination/loading errors

- [ ] **Countries page** (`/countries`)
  - [ ] Loads country list
  - [ ] Filtering/searching works if applicable
  - [ ] Clicking country shows associated destinations

---

## 6. Admin Features

- [ ] **Admin Import** (`/admin/import`)
  - [ ] Only accessible if logged in as admin
  - [ ] If not admin, shows access denied (or redirects)
  - [ ] If admin:
    - [ ] Import form loads
    - [ ] Can upload/paste destination data
    - [ ] Submit button processes import
    - [ ] Confirmation message on success
    - [ ] No service-role key errors in console

---

## 7. Error Handling & Edge Cases

- [ ] **Non-existent destination** (`/destination/invalid-slug`)
  - [ ] Shows 404 or error message (not crash)
  - [ ] Can navigate back to explore

- [ ] **Non-existent guide** (`/guides/invalid-slug`)
  - [ ] Shows 404 or error message
  - [ ] Can navigate back to guides

- [ ] **404 route** (`/this-does-not-exist`)
  - [ ] Shows 404 page
  - [ ] "Go Home" link works

- [ ] **Network errors** (simulate offline)
  - [ ] App shows error message (not blank page)
  - [ ] Retry button works

- [ ] **Slow API** (throttle network in DevTools)
  - [ ] Loading indicators appear
  - [ ] Page doesn't hang or timeout
  - [ ] Data loads after ~3-5 seconds

---

## 8. Browser & Environment Validation

- [ ] **Console logs**
  - [ ] No `[ERROR]` or red errors in console
  - [ ] No missing env var warnings
  - [ ] No auth/RLS errors like "policy violation" or "failed to fetch"

- [ ] **Network tab**
  - [ ] All API calls to Supabase succeed (200, 201 status)
  - [ ] No 403 "forbidden" for user data endpoints
  - [ ] No 400 "bad request" for valid queries
  - [ ] No 500 server errors

- [ ] **Performance**
  - [ ] Home page loads in < 3 seconds (on desktop)
  - [ ] Explore page with destination list loads in < 5 seconds
  - [ ] No visual jank or layout shifts on interaction
  - [ ] Buttons respond immediately to clicks

- [ ] **Responsive design**
  - [ ] Test on mobile (DevTools device emulation)
    - [ ] Home page responsive
    - [ ] Explore page readable
    - [ ] Auth form accessible
    - [ ] Nav menu mobile-friendly
  - [ ] Test on tablet
  - [ ] Test on desktop

---

## 9. Security Spot Checks

- [ ] **No sensitive data in localStorage**
  - [ ] Right-click → Inspect → Application → Local Storage
  - [ ] No raw passwords, API keys, or service roles visible
  - [ ] Only JWT token (expires) and non-sensitive settings

- [ ] **No service-role key in Network tab**
  - [ ] Network tab → filter to XHR/Fetch
  - [ ] No `Supabase-Authorization: Bearer sk_service_...` headers

- [ ] **HTTPS enforced**
  - [ ] All requests use `https://`, not `http://`
  - [ ] No "insecure content" warnings

---

## 10. Go-Live Sign-Off

- [ ] All tests above passed ✅
- [ ] No critical bugs found in explore/dashboard/auth flows
- [ ] No RLS or permission errors in console
- [ ] No missing env var warnings
- [ ] Performance is acceptable (pages load in < 5 seconds)
- [ ] Mobile is responsive and usable
- [ ] Ready to share public URL with team/stakeholders

**If any test fails:** Do not mark as complete. Investigate error in console, check Network tab, and refer to `SECURITY_CHECKLIST.md` or `DEPLOYMENT.md` for troubleshooting.
