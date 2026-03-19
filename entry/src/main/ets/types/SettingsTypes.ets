export type SubPageType = 'none' | 'liquidGlass' | 'darkMode' | 'account' | 'privacy' | 'offline' | 'push' | 'message' | 'storage' | 'editProfile' |
  'changePassword' | 'changePhone' | 'realNameAuth' | 'addEmail' | 'securityQuestion';

export interface SettingItem {
  title: string;
  hasArrow?: boolean;
  onClick?: () => void;
}

export interface EditProfileInfo {
  userName: string;
  userAvatar: string;
  userUid: string;
  userBio: string;
  userGender: string;
  userBirthday: string;
  userPhone: string;
}

export interface PrivacySettingsState {
  oldPassword: string;
  newPassword: string;
  confirmPassword: string;
  passwordStrength: string;
  newPhone: string;
  verifyCode: string;
  realName: string;
  idCard: string;
  email: string;
  emailVerifyCode: string;
  securityQuestion: string;
  securityAnswer: string;
  countdown: number;
  isVerified: boolean;
}

export interface NotificationSettingsState {
  privacyEnabled: boolean;
  offlineMode: boolean;
  pushEnabled: boolean;
  messageNotification: boolean;
  messageSound: boolean;
}

export interface LiquidGlassSettingsState {
  glassOpacity: number;
  previewOpacity: number;
  selectedPresetIndex: number;
}

export class SettingsConstants {
  static readonly PASSWORD_MIN_LENGTH = 8;
  static readonly PASSWORD_MAX_LENGTH = 20;
  static readonly VERIFY_CODE_LENGTH = 6;
  static readonly PHONE_REGEX = /^1[3-9]\d{9}$/;
  static readonly ID_CARD_REGEX = /^\d{17}[\dXx]$/;
  static readonly EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  static readonly UID_REGEX = /^[a-zA-Z0-9_]{4,16}$/;

  static readonly SECURITY_QUESTIONS: string[] = [
    '您的出生地是？',
    '您母亲的姓名是？',
    '您最喜欢的颜色是？',
    '您第一只宠物的名字是？',
    '您小学的名称是？'
  ];
}

export function getSubPageTitle(subPage: SubPageType): string {
  switch (subPage) {
    case 'liquidGlass':
      return '液态玻璃设置';
    case 'darkMode':
      return '深色设置';
    case 'account':
      return '账号资料';
    case 'privacy':
      return '账号安全中心';
    case 'changePassword':
      return '修改密码';
    case 'changePhone':
      return '更换手机号';
    case 'realNameAuth':
      return '实名认证';
    case 'addEmail':
      return '邮箱添加';
    case 'securityQuestion':
      return '密保问题';
    case 'offline':
      return '离线设置';
    case 'push':
      return '推送设置';
    case 'message':
      return '消息设置';
    case 'storage':
      return '清理储存空间';
    case 'editProfile':
      return '编辑资料';
    default:
      return '设置';
  }
}
