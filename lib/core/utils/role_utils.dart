String normalizeRole(String? role) => (role ?? '').trim().toLowerCase();

bool isAdminRole(String? role) => normalizeRole(role) == 'admin';

bool isManagerRole(String? role) => normalizeRole(role) == 'manager';

bool isSuperadminRole(String? role) => normalizeRole(role) == 'superadmin';

bool hasManagerPrivileges(String? role) =>
    isManagerRole(role) || isAdminRole(role) || isSuperadminRole(role);

bool canManageNotices(String? role) =>
    hasManagerPrivileges(role) || normalizeRole(role) == 'coach';

bool canEditRosterPosition(String? role) =>
    hasManagerPrivileges(role) || normalizeRole(role) == 'coach';
