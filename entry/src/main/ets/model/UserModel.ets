import preferences from '@ohos.data.preferences';

/**
 * 用户数据接口
 * 定义用户的基本信息结构
 */
export interface User {
  uid: string;              // 用户唯一ID
  phoneNumber: string;      // 手机号
  nickname: string;         // 昵称
  avatar?: string;          // 头像（可选）
  bio?: string;             // 简介（可选）
  gender?: string;          // 性别（可选）：男/女/保密
  birthday?: string;        // 生日（可选）：YYYY-MM-DD
  level: number;            // 用户等级（初始为1）
  password: string;         // 密码（加密存储）
  createdAt: number;        // 账号创建时间戳
}

/**
 * 检查结果接口
 * 用于返回唯一性检查的结果
 */
export interface CheckResult {
  isValid: boolean;         // 是否有效
  message: string;          // 提示信息
}

/**
 * 用户管理类
 * 提供完整的用户数据管理功能
 */
export class UserManager {
  private static readonly PREFERENCE_NAME: string = 'user_database';
  private static readonly USERS_KEY: string = 'users';
  private static readonly UID_COUNTER_KEY: string = 'uid_counter';
  
  private static instance: UserManager | null = null;
  private preferenceStore: preferences.Preferences | null = null;
  private context: Context | null = null;

  /**
   * 获取用户管理器单例
   * @returns UserManager 单例实例
   */
  static getInstance(): UserManager {
    if (!UserManager.instance) {
      UserManager.instance = new UserManager();
    }
    return UserManager.instance;
  }

  private constructor() {}

  /**
   * 初始化用户管理器
   * @param context 应用上下文
   */
  async init(context: Context): Promise<void> {
    try {
      this.context = context;
      this.preferenceStore = await preferences.getPreferences(context, UserManager.PREFERENCE_NAME);
      console.info('用户管理器初始化成功');
    } catch (error) {
      console.error('用户管理器初始化失败：' + JSON.stringify(error));
      throw new Error('用户管理器初始化失败');
    }
  }

  /**
   * 获取所有用户
   * @returns Promise<Record<string, User>> 用户数据Map，key为手机号
   */
  private async getAllUsers(): Promise<Record<string, User>> {
    if (!this.preferenceStore) {
      return {};
    }
    const raw = await this.preferenceStore.get(UserManager.USERS_KEY, '{}') as string;
    try {
      return JSON.parse(raw) as Record<string, User>;
    } catch (_) {
      return {};
    }
  }

  /**
   * 保存所有用户
   * @param users 用户数据Map
   */
  private async saveAllUsers(users: Record<string, User>): Promise<void> {
    if (!this.preferenceStore) {
      return;
    }
    await this.preferenceStore.put(UserManager.USERS_KEY, JSON.stringify(users));
    await this.preferenceStore.flush();
  }

  /**
   * 生成唯一UID
   * @returns Promise<string> 生成的UID
   */
  private async generateUID(): Promise<string> {
    if (!this.preferenceStore) {
      throw new Error('用户管理器未初始化');
    }
    const counter = await this.preferenceStore.get(UserManager.UID_COUNTER_KEY, 10000) as number;
    const newCounter = counter + 1;
    await this.preferenceStore.put(UserManager.UID_COUNTER_KEY, newCounter);
    await this.preferenceStore.flush();
    return `U${newCounter}`;
  }

  /**
   * 检查手机号是否已注册
   * @param phoneNumber 手机号
   * @returns Promise<boolean> 是否已注册
   */
  async isPhoneRegistered(phoneNumber: string): Promise<boolean> {
    const users = await this.getAllUsers();
    return !!users[phoneNumber];
  }

  /**
   * 检查昵称是否已存在
   * @param nickname 昵称
   * @returns Promise<boolean> 是否已存在
   */
  async isNicknameExists(nickname: string): Promise<boolean> {
    const users = await this.getAllUsers();
    return Object.values(users).some(user => user.nickname === nickname);
  }

  /**
   * 检查UID是否已存在
   * @param uid UID
   * @returns Promise<boolean> 是否已存在
   */
  async isUIDExists(uid: string): Promise<boolean> {
    const users = await this.getAllUsers();
    return Object.values(users).some(user => user.uid === uid);
  }

  /**
   * 验证手机号格式并检查是否已注册
   * @param phoneNumber 手机号
   * @returns Promise<CheckResult> 检查结果
   */
  async checkPhoneNumber(phoneNumber: string): Promise<CheckResult> {
    const phoneRegex = /^1[3-9]\d{9}$/;
    if (!phoneRegex.test(phoneNumber)) {
      return { isValid: false, message: '请输入正确的手机号码' };
    }
    const isRegistered = await this.isPhoneRegistered(phoneNumber);
    if (isRegistered) {
      return { isValid: true, message: '手机号已注册，可以登录' };
    }
    return { isValid: true, message: '手机号未注册，需要注册' };
  }

  /**
   * 验证昵称格式并检查是否已存在
   * @param nickname 昵称
   * @returns Promise<CheckResult> 检查结果
   */
  async checkNickname(nickname: string): Promise<CheckResult> {
    if (!nickname || nickname.trim().length === 0) {
      return { isValid: false, message: '昵称不能为空' };
    }
    if (nickname.length < 2 || nickname.length > 20) {
      return { isValid: false, message: '昵称长度应在2-20个字符之间' };
    }
    const exists = await this.isNicknameExists(nickname);
    if (exists) {
      return { isValid: false, message: '昵称已被使用，请更换' };
    }
    return { isValid: true, message: '昵称可用' };
  }

  /**
   * 验证UID格式并检查是否已存在
   * @param uid UID
   * @returns Promise<CheckResult> 检查结果
   */
  async checkUID(uid: string): Promise<CheckResult> {
    if (!uid || uid.trim().length === 0) {
      return { isValid: false, message: 'UID不能为空' };
    }
    const uidRegex = /^[a-zA-Z0-9_]{4,16}$/;
    if (!uidRegex.test(uid)) {
      return { isValid: false, message: 'UID只能包含字母、数字和下划线，长度4-16位' };
    }
    const exists = await this.isUIDExists(uid);
    if (exists) {
      return { isValid: false, message: 'UID已被使用，请更换' };
    }
    return { isValid: true, message: 'UID可用' };
  }

  /**
   * 验证密码格式
   * @param password 密码
   * @returns CheckResult 检查结果
   */
  checkPassword(password: string): CheckResult {
    if (!password || password.trim().length === 0) {
      return { isValid: false, message: '密码不能为空' };
    }
    if (password.length < 6) {
      return { isValid: false, message: '密码长度至少6位' };
    }
    if (password.length > 20) {
      return { isValid: false, message: '密码长度不能超过20位' };
    }
    
    const hasLetter = /[a-zA-Z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    
    if (!hasLetter || !hasNumber) {
      return { isValid: false, message: '密码必须包含字母和数字' };
    }
    
    return { isValid: true, message: '密码格式正确' };
  }

  /**
   * 简单的密码加密（生产环境应使用更强的加密算法）
   * @param password 原始密码
   * @returns string 加密后的密码
   */
  private encryptPassword(password: string): string {
    let hash = 0;
    for (let i = 0; i < password.length; i++) {
      const char = password.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return 'enc_' + Math.abs(hash).toString(16);
  }

  /**
   * 验证密码是否匹配
   * @param phoneNumber 手机号
   * @param password 密码
   * @returns Promise<boolean> 密码是否匹配
   */
  async verifyPassword(phoneNumber: string, password: string): Promise<boolean> {
    const user = await this.getUserByPhone(phoneNumber);
    if (!user) {
      return false;
    }
    const encryptedPassword = this.encryptPassword(password);
    return user.password === encryptedPassword;
  }

  /**
   * 创建新用户
   * @param phoneNumber 手机号
   * @param nickname 昵称
   * @param password 密码
   * @param customUid 用户自定义UID（可选，不传则自动生成）
   * @returns Promise<User> 创建的用户对象
   */
  async createUser(phoneNumber: string, nickname: string, password: string, customUid?: string): Promise<User> {
    const users = await this.getAllUsers();
    
    let uid: string;
    if (customUid) {
      const uidCheck = await this.checkUID(customUid);
      if (!uidCheck.isValid) {
        throw new Error(uidCheck.message);
      }
      uid = customUid;
    } else {
      uid = await this.generateUID();
    }

    const encryptedPassword = this.encryptPassword(password);

    const user: User = {
      uid: uid,
      phoneNumber: phoneNumber,
      nickname: nickname,
      avatar: 'ID_Wa/20260308215703.jpg',
      bio: '记录生活，发现美好',
      gender: '保密',
      birthday: '2000-01-01',
      level: 1,
      password: encryptedPassword,
      createdAt: Date.now()
    };

    users[phoneNumber] = user;
    await this.saveAllUsers(users);
    
    console.info(`用户创建成功：${phoneNumber} - ${nickname}`);
    return user;
  }

  /**
   * 根据手机号获取用户
   * @param phoneNumber 手机号
   * @returns Promise<User | null> 用户对象或null
   */
  async getUserByPhone(phoneNumber: string): Promise<User | null> {
    const users = await this.getAllUsers();
    const user = users[phoneNumber] || null;
    if (user && user.level === undefined) {
      user.level = 1;
      await this.saveAllUsers(users);
    }
    return user;
  }

  /**
   * 根据UID获取用户
   * @param uid UID
   * @returns Promise<User | null> 用户对象或null
   */
  async getUserByUID(uid: string): Promise<User | null> {
    const users = await this.getAllUsers();
    return Object.values(users).find(user => user.uid === uid) || null;
  }

  /**
   * 更新用户信息
   * @param phoneNumber 手机号
   * @param updates 需要更新的字段
   * @returns Promise<boolean> 是否更新成功
   */
  async updateUser(phoneNumber: string, updates: Partial<User>): Promise<boolean> {
    const users = await this.getAllUsers();
    const user = users[phoneNumber];
    
    if (!user) {
      return false;
    }

    if (updates.nickname !== undefined) {
      user.nickname = updates.nickname;
    }
    if (updates.avatar !== undefined) {
      user.avatar = updates.avatar;
    }
    if (updates.bio !== undefined) {
      user.bio = updates.bio;
    }
    if (updates.gender !== undefined) {
      user.gender = updates.gender;
    }
    if (updates.birthday !== undefined) {
      user.birthday = updates.birthday;
    }
    if (updates.password !== undefined) {
      user.password = updates.password;
    }
    if (updates.level !== undefined) {
      user.level = updates.level;
    }

    await this.saveAllUsers(users);
    
    console.info(`用户信息更新成功：${phoneNumber}`);
    return true;
  }
}
