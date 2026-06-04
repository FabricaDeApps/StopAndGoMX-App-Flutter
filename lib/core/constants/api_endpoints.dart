class ApiEndpoints {
  // Base sections
  static const public = '/public';
  static const auth = '/auth';
  static const manager = '/manager';
  static const admin = '/admin';
  static const parent = '/player';

  // ---- PUBLIC ----
  static const publicOrganizations = '$public/organizations';
  static const organization = '$public/organization';

  // ---- AUTH ----
  static const authLogin = '$auth/login';
  static const authLogout = '$auth/logout';
  static const authMe = '$auth/me';
  static const authRefresh = '$auth/refresh';
  static const authPasswordForgot = '$auth/password/forgot';
  static const accountPhoto = '/account/photo';

  // ---- MANAGER ----
  static const managerPlayers = '$manager/players';
  static const adminPlayers = '$admin/players';
  static const managerPayments = '$manager/payments';
  static const markPaymentPaid = '$manager/payments/{id}/mark-paid';

  // ---- PARENT ----
  static const parentPlayers = '$parent/players';

  // ---- NOTICES ----
  static const getNotices = '/notices';
  static const createNotice = '$manager/notices';

  // ---- NEWS ----
  static const newsFeed = '/news/feed';
  static const newsPreferences = '/news/preferences';

  // ---- CLUB LEAGUE ----
  static const clubLeague = '/club/league';
  static const clubLeagueOverview = '$clubLeague/overview';

  // ---- APP USAGE ----
  static const appUsageSessions = '/app-usage/sessions';
  static const appUsageSessionsStart = '$appUsageSessions/start';
  static const appUsageSessionsHeartbeat = '$appUsageSessions/heartbeat';
  static const appUsageSessionsEnd = '$appUsageSessions/end';
}
