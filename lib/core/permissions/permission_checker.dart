import 'permission_manager.dart';

/// Helper class for checking permissions.
///
/// Uses role-based RBAC (via PermissionManager) to determine access.
/// ADMIN always gets full access. EMPLOYEE access is controlled by RbacConfig.
class PermissionChecker {
  static final PermissionManager _manager = PermissionManager();

  // ========== General Permission Checks ==========

  static bool hasPermission(String permission) {
    return _manager.hasPermission(permission);
  }

  static bool hasAnyPermission(List<String> permissions) {
    return _manager.hasAnyPermission(permissions);
  }

  static bool hasAllPermissions(List<String> permissions) {
    return _manager.hasAllPermissions(permissions);
  }

  static bool get isAdmin => _manager.isAdmin;
  static bool get isEmployee => _manager.isEmployee;
  static String get userId => _manager.userId;

  // ========== Entity-level helpers ==========

  /// Check if entity is view-only for current role
  static bool isViewOnly(String entity) => _manager.isViewOnly(entity);

  /// Check if current user can edit a specific record (ownership check)
  static bool canEditRecord(String entity, {String? createdById}) {
    return _manager.canEditEntity(entity, createdById: createdById);
  }

  /// Check if current user can delete a specific record (ownership check)
  static bool canDeleteRecord(String entity, {String? createdById}) {
    return _manager.canDeleteEntity(entity, createdById: createdById);
  }

  // ========== Resource-specific CRUD Checks ==========

  // Brands (view-only for EMPLOYEE)
  static bool get canCreateBrand => _manager.canCreate('brands');
  static bool get canReadBrand => _manager.canRead('brands');
  static bool get canUpdateBrand => _manager.canUpdate('brands');
  static bool get canDeleteBrand => _manager.canDelete('brands');
  static bool get hasAnyBrandAccess => _manager.hasAnyAccessTo('brands');

  // Categories (view-only for EMPLOYEE)
  static bool get canCreateCategory => _manager.canCreate('categories');
  static bool get canReadCategory => _manager.canRead('categories');
  static bool get canUpdateCategory => _manager.canUpdate('categories');
  static bool get canDeleteCategory => _manager.canDelete('categories');
  static bool get hasAnyCategoryAccess => _manager.hasAnyAccessTo('categories');

  // Themes (view-only for EMPLOYEE)
  static bool get canCreateTheme => _manager.canCreate('themes');
  static bool get canReadTheme => _manager.canRead('themes');
  static bool get canUpdateTheme => _manager.canUpdate('themes');
  static bool get canDeleteTheme => _manager.canDelete('themes');
  static bool get hasAnyThemeAccess => _manager.hasAnyAccessTo('themes');

  // Tags (full access for EMPLOYEE)
  static bool get canCreateTag => _manager.canCreate('tags');
  static bool get canReadTag => _manager.canRead('tags');
  static bool get canUpdateTag => _manager.canUpdate('tags');
  static bool get canDeleteTag => _manager.canDelete('tags');
  static bool get hasAnyTagAccess => _manager.hasAnyAccessTo('tags');

  // Products (view-only for EMPLOYEE)
  static bool get canCreateProduct => _manager.canCreate('products');
  static bool get canReadProduct => _manager.canRead('products');
  static bool get canUpdateProduct => _manager.canUpdate('products');
  static bool get canDeleteProduct => _manager.canDelete('products');
  static bool get hasAnyProductAccess => _manager.hasAnyAccessTo('products');

  // Activities (filtered for EMPLOYEE — own records only)
  static bool get canCreateActivity => _manager.canCreate('activities');
  static bool get canReadActivity => _manager.canRead('activities');
  static bool get canUpdateActivity => _manager.canUpdate('activities');
  static bool get canDeleteActivity => _manager.canDelete('activities');
  static bool get hasAnyActivityAccess => _manager.hasAnyAccessTo('activities');

  // Activity Types (hidden for EMPLOYEE — admin only)
  static bool get canCreateActivityType => _manager.canCreate('activity-types');
  static bool get canReadActivityType => _manager.canRead('activity-types');
  static bool get canUpdateActivityType => _manager.canUpdate('activity-types');
  static bool get canDeleteActivityType => _manager.canDelete('activity-types');
  static bool get hasAnyActivityTypeAccess => _manager.hasAnyAccessTo('activity-types');

  // Inquiries (filtered for EMPLOYEE — own records only)
  static bool get canCreateInquiry => _manager.canCreate('inquiries');
  static bool get canReadInquiry => _manager.canRead('inquiries');
  static bool get canUpdateInquiry => _manager.canUpdate('inquiries');
  static bool get canDeleteInquiry => _manager.canDelete('inquiries');
  static bool get hasAnyInquiryAccess => _manager.hasAnyAccessTo('inquiries');

  // Groups (full access for EMPLOYEE)
  static bool get canCreateGroup => _manager.canCreate('groups');
  static bool get canReadGroup => _manager.canRead('groups');
  static bool get canUpdateGroup => _manager.canUpdate('groups');
  static bool get canDeleteGroup => _manager.canDelete('groups');
  static bool get hasAnyGroupAccess => _manager.hasAnyAccessTo('groups');

  // Users (filtered for EMPLOYEE — can create CUSTOMER only)
  static bool get canCreateUser => _manager.canCreate('users');
  static bool get canReadUser => _manager.canRead('users');
  static bool get canUpdateUser => _manager.canUpdate('users');
  static bool get canDeleteUser => _manager.canDelete('users');
  static bool get hasAnyUserAccess => _manager.hasAnyAccessTo('users');
  static List<String>? get userCreateRoleFilter => _manager.getCreateRoleFilter('users');

  // Companies (view-only for EMPLOYEE)
  static bool get canCreateCompany => _manager.canCreate('companies');
  static bool get canReadCompany => _manager.canRead('companies');
  static bool get canUpdateCompany => _manager.canUpdate('companies');
  static bool get canDeleteCompany => _manager.canDelete('companies');
  static bool get hasAnyCompanyAccess => _manager.hasAnyAccessTo('companies');

  // Files
  static bool get canCreateFile => _manager.canCreate('files');
  static bool get canReadFile => _manager.canRead('files');
  static bool get canDeleteFile => _manager.canDelete('files');
  static bool get hasAnyFileAccess => _manager.hasAnyAccessTo('files');

  // WhatsApp Messages (full access for EMPLOYEE)
  static bool get canReadWhatsApp => _manager.hasPermission('whatsapp.read');
  static bool get canSendWhatsApp => _manager.hasPermission('whatsapp.send');
  static bool get canUpdateWhatsApp => _manager.hasPermission('whatsapp.update');
  static bool get canDeleteWhatsApp => _manager.hasPermission('whatsapp.delete');

  // WhatsApp Campaigns (view-only for EMPLOYEE — separate from messages)
  static bool get canCreateCampaign => _manager.canCreateEntity('whatsapp-campaign');
  static bool get canEditCampaign => _manager.canEditEntity('whatsapp-campaign');
  static bool get canDeleteCampaign => _manager.canDeleteEntity('whatsapp-campaign');
  static bool get canExecuteCampaign => _manager.canExecuteEntity('whatsapp-campaign');

  // Prompts
  static bool get canCreatePrompt => _manager.canCreate('prompts');
  static bool get canReadPrompt => _manager.canRead('prompts');
  static bool get canUpdatePrompt => _manager.canUpdate('prompts');
  static bool get canDeletePrompt => _manager.canDelete('prompts');
}
