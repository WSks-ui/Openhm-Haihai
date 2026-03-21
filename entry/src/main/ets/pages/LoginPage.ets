import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import preferences from '@ohos.data.preferences';
import display from '@ohos.display';
import { VerifyCodeManager } from '../utils/VerifyCodeManager';
import { UserManager } from '../model/UserModel';
import { AgreementDialog } from '../components/dialogs/AgreementDialog';
import { PreferencesStorage } from '../utils/PreferencesStorage';

// ==================== 开发者模式入口 ====================
// 设置为 true 启用开发者模式，可直接进入应用无需登录
// 设置为 false 或注释掉以下代码来禁用开发者模式
const DEV_MODE_ENABLED = true;
const DEV_MODE_HIDDEN_PASSWORD = '114514';
// =====================================================

@Entry
@Component
struct LoginPage {
  @State phoneNumber: string = '';
  @State verifyCode: string = '';
  @State password: string = '';
  @State errorMsg: string = '';
  @State agreeTerms: boolean = false;
  @State pageOpacity: number = 0;
  @State titleScale: number = 0.8;
  @State phoneFocused: boolean = false;
  @State codeFocused: boolean = false;
  @State passwordFocused: boolean = false;
  @State continueBtnPressed: boolean = false;
  @State sendCodeBtnPressed: boolean = false;
  @State countdown: number = 0;
  @State isSending: boolean = false;
  @State isPhoneRegistered: boolean = true;
  @State loginMode: 'code' | 'password' = 'code';
  @State screenWidth: number = 0;
  @State isLargeScreen: boolean = false;
  private countdownTimer: number = -1;
  private userDatabase: Record<string, string> = {};
  private verifyCodeManager: VerifyCodeManager = VerifyCodeManager.getInstance();
  private userManager: UserManager = UserManager.getInstance();
  private agreementDialogController: CustomDialogController | null = null;

  private readonly USER_AGREEMENT = `用户协议

版本更新日期：2026年3月8日
版本生效日期：2026年3月8日

欢迎使用我们的应用（以下简称“本应用”）。本用户协议（以下简称“本协议”）是您与本应用运营者（以下简称“我们”或“平台”）之间关于使用本应用服务所订立的协议。
**请您在开始使用前，务必仔细阅读并充分理解本协议的全部内容，特别是以粗体/下划线标识的涉及免除或者限制责任、法律适用和争议解决的条款。如果您不同意本协议的任何内容，或者无法准确理解条款含义，请立即停止使用本应用。**

1. 服务内容与变更
1.1 本应用提供的服务包括但不限于：用户注册与登录、内容浏览与发布、社交互动、个性化推荐、在线交易（如有）等功能。具体服务内容以实际应用提供的功能为准。
1.2 我们有权根据业务发展需要，随时调整、增加、减少或中断部分或全部服务。对于付费服务的中断或终止，我们将提前通知并提供合理的解决方案。
1.3 本应用可能包含指向第三方网站或资源的链接。我们无法控制第三方的内容，不对第三方的合法性、准确性负责，访问风险由您自行承担。

2. 账号注册与管理
2.1 您可能需要提供真实的手机号码、电子邮箱或其他信息进行注册。您承诺提供的信息真实、准确、完整、有效。
2.2 您的账号所有权归平台所有，您仅拥有使用权。禁止赠与、借用、租用、转让或售卖账号。
2.3 您有责任妥善保管账号及密码（包括验证码、生物识别信息等）。因您保管不善导致的损失（如被盗用、数据泄露），由您自行承担。
2.4 如发现账号被非法使用，应立即通知平台。平台将在核实后采取冻结、找回等措施，但不承担由此产生的间接损失。

3. 用户行为规范
3.1 您在使用本应用时，必须遵守中华人民共和国相关法律法规，不得利用本应用制作、复制、发布、传播含有下列内容的信息：
   (1) 反对宪法所确定的基本原则的；
   (2) 危害国家安全，泄露国家秘密，颠覆国家政权，破坏国家统一的；
   (3) 损害国家荣誉和利益的；
   (4) 煽动民族仇恨、民族歧视，破坏民族团结的；
   (5) 破坏国家宗教政策，宣扬邪教和封建迷信的；
   (6) 散布谣言，扰乱社会秩序，破坏社会稳定的；
   (7) 散布淫秽、色情、赌博、暴力、凶杀、恐怖或者教唆犯罪的；
   (8) 侮辱或者诽谤他人，侵害他人合法权益的；
   (9) 含有法律、行政法规禁止的其他内容的。
3.2 禁止进行以下技术攻击行为：
   (1) 对本应用进行反向工程、反汇编、反编译；
   (2) 利用漏洞、外挂、脚本等非正常手段获取利益或干扰服务；
   (3) 批量注册、恶意刷量、爬取数据等破坏系统稳定性的行为。
3.3 违约处理：如您违反上述规范，我们有权视情节轻重，采取警告、限制功能、暂停服务、封禁账号、删除违规内容等措施，并保留追究法律责任的权利。

4. 知识产权声明
4.1 本应用包含的所有内容（包括但不限于文字、图片、音频、视频、软件、代码、界面设计、Logo等）的知识产权均归平台或相关权利人所有。
4.2 未经书面许可，您不得为商业目的复制、修改、出租、传播本应用的任何内容。
4.3 您在平台发布的内容，您应保证拥有合法知识产权或已获授权。您发布内容即视为授予平台在全球范围内、免费的、非独家的使用权，用于服务的展示、推广和优化。

5. 隐私与数据保护
5.1 我们高度重视您的隐私保护。关于我们如何收集、使用、存储、共享和保护您的个人信息，请详细阅读《隐私政策》。《隐私政策》是本协议不可分割的一部分。
5.2 您同意我们按照《隐私政策》的规定处理您的个人信息。

6. 费用与支付（如适用）
6.1 本应用部分服务可能收费。收费标准将在您购买前明确展示。
6.2 一旦支付成功，除法律法规另有规定或服务另有约定外，不支持退款。
6.3 您应通过官方认可的渠道进行支付，切勿向个人或非官方账户转账。

7. 免责声明
7.1 本应用按“现状”和“可用”状态提供。我们不保证服务一定能满足您的要求，也不保证服务不会中断、无错误、无病毒或完全安全。
7.2 因不可抗力（如自然灾害、政府行为、黑客攻击、电信部门技术调整等）导致的服务中断或数据丢失，我们不承担责任，但将尽力减少损失。
7.3 您因使用本应用而引发的任何直接或间接损失（包括利润损失、数据丢失、商业中断等），我们在法律允许的最大范围内不承担赔偿责任。

8. 协议的修改与通知
8.1 我们有权根据法律法规变化或业务调整修改本协议。
8.2 修改后的协议将通过应用内公告、弹窗、站内信等方式通知您。
8.3 如您继续使用本应用，视为接受修改后的协议；如不同意，请停止使用并注销账号。

9. 法律适用与争议解决
9.1 本协议的订立、执行、解释及争议解决均适用中华人民共和国大陆地区法律。
9.2 如双方发生争议，应友好协商解决；协商不成的，任何一方均有权向**平台所在地有管辖权的人民法院**提起诉讼。

10. 其他
10.1 本协议中的标题仅为方便阅读而设，不影响条款含义。
10.2 如本协议某一条款被认定无效，不影响其他条款的效力。
10.3 联系方式：如您对本协议有任何疑问，请通过应用内“帮助与反馈”或邮箱 'chr114514chr@gmail.com' 与我们联系。

感谢您的理解与支持！
`;

  private readonly PRIVACY_POLICY = `隐私政策

版本更新日期：2026年3月8日
版本生效日期：2026年3月8日

引言
我们（[含章队开发团队]）非常重视您的隐私保护。本隐私政策（以下简称“本政策”）旨在向您说明在您使用我们的应用（以下简称“本应用”）时，我们如何收集、使用、存储、共享、转让、公开披露和保护您的个人信息，以及您享有的权利。
**请您在使用本应用前，仔细阅读并了解本政策。一旦您开始使用本应用，即表示您已充分理解并同意本政策。**

一、我们如何收集和使用您的个人信息
我们遵循“合法、正当、必要”和“最小化”原则，仅在实现产品功能所必需的范围内收集您的信息。

1. 账号注册与登录
   - 收集信息：手机号码、验证码、昵称、头像（可选）、密码（加密存储）。
   - 使用目的：创建账号、身份验证、保障账号安全。
   - 必要性：不提供手机号码将无法完成注册，但您可以使用游客模式浏览部分内容（如支持）。

2. 核心业务功能
   - 内容发布：当您发布图文、视频时，我们会收集您上传的内容及相关的元数据（如拍摄时间、设备型号）。
   - 社交互动：当您评论、点赞、分享时，我们会记录您的操作日志及互动内容。
   - 搜索服务：我们会收集您的搜索关键词、历史记录，以便为您提供更精准的搜索结果。

3. 设备信息与日志信息（用于安全保障与服务优化）
   - 收集信息：设备型号、操作系统版本、唯一设备标识符（如OAID/IMEI，仅限安卓且经用户授权）、IP地址、网络状态、应用崩溃日志、启动时长。
   - 使用目的：保障服务安全（防止作弊、欺诈）、优化应用性能、统计分析。

4. 权限调用说明
   我们可能会申请以下系统权限，您可以随时在系统设置中关闭：
   - 相机权限：用于拍摄照片/视频进行发布。
   - 相册/存储权限：用于上传图片/视频或保存内容到本地。
   - 麦克风权限：用于录制视频音频或语音输入。
   - 位置权限（可选）：用于推荐同城内容或标记地理位置。拒绝授权不影响其他功能使用。
   - 通知权限：用于向您发送重要服务通知。

5. 个性化推荐
   - 我们可能利用您的浏览记录、兴趣标签进行算法分析，向您推荐感兴趣的内容。
   - **您有权关闭个性化推荐**：您可以在“设置” > “隐私设置” > “个性化推荐管理”中一键关闭。关闭后，您将看到随机推荐内容。

二、我们如何共享、转让、公开披露您的个人信息
1. 共享
   我们不会向任何无关第三方出售您的个人信息。仅在以下情形下，我们可能会与第三方共享必要的信息：
   - **获得您的明确同意**：例如您授权第三方登录。
   - **法定情形**：根据法律法规、诉讼争议解决需要，或按行政、司法机关依法提出的要求。
   - **授权合作伙伴**：仅为实现本政策中声明的目的，我们的某些服务将由授权合作伙伴提供（如短信服务商、云存储服务商、第三方支付机构）。我们会与其签署严格的保密协定，要求其仅按照我们的指示和本政策处理信息。
   - **SDK使用情况**：本应用接入了以下第三方SDK，它们可能会收集您的设备信息：
     * @kit.ArkUI 核心 UI 框架 页面构建、动画、路由、窗口管理
     * @kit.AbilityKit 应用能力框架 UIAbility 生命周期、权限控制、配置管理
     * @kit.BasicServicesKit 基础服务 统一错误处理 (BusinessError)
     * @kit.PerformanceAnalysisKit 性能分析 日志输出 (hilog)
     * @kit.MultimodalAwarenessKit 多模态感知 手势/运动检测
     * @kit.CoreSpeechKit 语音识别 语音转文字
     * @kit.ScanKit 扫码服务 条码/二维码扫描
     * @kit.CoreFileKit 文件管理 数据备份/恢复

2. 转让与公开披露
   我们不会将您的个人信息转让给任何公司、组织和个人，也不会公开披露，除非获得您的明确同意或基于法律规定。

三、我们如何保护您的个人信息
1. 技术措施：我们采用行业标准的加密技术（如SSL/TLS、AES-256）保护数据传输和存储安全；建立严格的数据访问权限控制机制。
2. 管理措施：我们建立了专门的安全管理部门，对员工进行隐私保护培训，并定期进行安全审计。
3. 风险提示：尽管我们采取了合理措施，但互联网环境并非100%安全。如发生个人信息泄露等安全事件，我们将按照法律法规要求，及时启动应急预案，并在72小时内向您告知相关情况（包括事件概况、处置措施、补救建议等）。

四、您的权利
按照中国法律法规，我们保障您对自己的个人信息行使以下权利：
1. 查阅与复制：您可以在“个人中心”查看您的基本信息。如需导出副本，请联系客服。
2. 更正与补充：发现信息有误时，您可自行修改或联系我们更正。
3. 删除：在以下情形下，您可以向我们提出删除个人信息的请求：
   - 我们处理行为违反法律法规；
   - 我们收集、使用您的个人信息，却未征得您的同意；
   - 您不再使用我们的产品或服务，或您注销了账号。
4. 撤回同意：您可以通过关闭权限、注销账号或联系客服撤回之前给予的授权。撤回后，我们将不再处理相应的个人信息，但不会影响撤回前基于您的授权已开展的业务。
5. 注销账号：您可以在“设置” > “账号安全” > “注销账号”中申请注销。注销后，我们将删除或匿名化处理您的个人信息（法律法规另有规定的除外）。

五、未成年人保护
1. 我们非常重视未成年人的个人信息保护。
2. 若您是14周岁以下的儿童，请在监护人的陪同和指导下阅读本政策，并由监护人同意后使用本应用。
3. 若您是监护人，发现被监护人未经授权向我们提供个人信息，请联系我们，我们将尽快删除相关数据。

六、政策的更新
1. 随着法律法规的更新或业务变化，我们可能会修订本政策。
2. 对于重大变更（如处理目的、类型、共享方式的改变），我们将在应用内通过弹窗等显著方式通知您。
3. 若您继续使用服务，视为同意更新后的政策。

七、联系我们
1. 如您对本政策有任何疑问、意见或投诉，请通过以下方式联系我们：
   - 联系邮箱：[chr114514chr@gmail.com]
   - 联系电话：[17530383888]
   - 联系地址：[郑州西亚斯学院产业学院]
2. 我们将在15个工作日内回复您的请求。

八、附则
本政策未尽事宜，遵照国家有关法律法规及行业标准执行。

感谢您的信任！
`;
  async aboutToAppear() {
    const ctx = getContext(this);
    await this.verifyCodeManager.init(ctx);
    await this.userManager.init(ctx);

    this.screenWidth = px2vp(display.getDefaultDisplaySync().width);
    this.isLargeScreen = this.screenWidth >= 600;

    const store = await preferences.getPreferences(ctx, 'users');
    const raw = await store.get('userDatabase', '{}') as string;
    try {
      this.userDatabase = JSON.parse(raw);
    } catch (_) {
      this.userDatabase = {};
    }

    const params = router.getParams() as Record<string, string>;
    if (params && params['phoneNumber']) {
      this.phoneNumber = params['phoneNumber'];
      this.checkPhoneNumberRegistration();
    }

    animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
      this.pageOpacity = 1;
      this.titleScale = 1;
    });
  }

  aboutToDisappear() {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
    }
  }

  private async bypassToMainPage() {
    AppStorage.setOrCreate('userName', '开发者');
    AppStorage.setOrCreate('userAvatar', 'app.media.startIcon');
    AppStorage.setOrCreate('userUid', 'DEV_USER_001');
    AppStorage.setOrCreate('userBio', '开发者模式用户');
    AppStorage.setOrCreate('userGender', '保密');
    AppStorage.setOrCreate('userBirthday', '2000-01-01');
    AppStorage.setOrCreate('userPhone', '13800138000');
    AppStorage.setOrCreate('userLevel', 99);
    AppStorage.setOrCreate('devModeSession', true);

    promptAction.showToast({ message: '开发者模式已激活，直接进入应用' });
    router.replaceUrl({ url: 'pages/Index' });
  }

  async saveUserMap() {
    const ctx = getContext(this);
    const store = await preferences.getPreferences(ctx, 'users');
    await store.put('userDatabase', JSON.stringify(this.userDatabase));
    await store.flush();
  }

  validatePhoneNumber(phone: string): boolean {
    const phoneRegex = /^1[3-9]\d{9}$/;
    return phoneRegex.test(phone);
  }

  async checkPhoneNumberRegistration() {
    if (!this.validatePhoneNumber(this.phoneNumber)) {
      this.isPhoneRegistered = true;
      return;
    }
    this.isPhoneRegistered = await this.userManager.isPhoneRegistered(this.phoneNumber);
  }

  async sendVerifyCode() {
    if (this.isSending || this.countdown > 0) {
      return;
    }

    if (!this.validatePhoneNumber(this.phoneNumber)) {
      this.errorMsg = '请输入正确的手机号码';
      return;
    }

    await this.checkPhoneNumberRegistration();

    if (!this.isPhoneRegistered) {
      this.errorMsg = '该手机号未注册，请先注册账号';
      promptAction.showToast({ message: '该手机号未注册，请先注册账号', duration: 2000 });
      return;
    }

    this.isSending = true;
    this.errorMsg = '';

    try {
      const result = await this.verifyCodeManager.sendVerifyCode(this.phoneNumber);

      if (result.success) {
        promptAction.showToast({ message: '验证码已发送' });

        this.countdown = 60;
        this.countdownTimer = setInterval(() => {
          this.countdown--;
          if (this.countdown <= 0) {
            clearInterval(this.countdownTimer);
            this.countdownTimer = -1;
          }
        }, 1000);
      } else {
        this.errorMsg = result.message || '发送验证码失败';
      }
    } catch (error) {
      this.errorMsg = '发送验证码异常，请稍后重试';
    } finally {
      this.isSending = false;
    }
  }

  private openUserAgreement() {
    this.agreementDialogController = new CustomDialogController({
      builder: AgreementDialog({
        title: '用户协议',
        content: this.USER_AGREEMENT
      }),
      autoCancel: false,
      customStyle: true
    });
    this.agreementDialogController.open();
  }

  private openPrivacyPolicy() {
    this.agreementDialogController = new CustomDialogController({
      builder: AgreementDialog({
        title: '隐私政策',
        content: this.PRIVACY_POLICY
      }),
      autoCancel: false,
      customStyle: true
    });
    this.agreementDialogController.open();
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#1A1A1E');

      if (this.isLargeScreen) {
        Row() {
          Blank();

          Column() {
            Column({ space: 12 }) {
              Text('欢迎登录')
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .scale({ x: this.titleScale, y: this.titleScale })
                .animation({
                  duration: 800,
                  curve: Curve.Friction,
                  playMode: PlayMode.Normal
                });

              Text('请使用手机号登录或注册')
                .fontSize(18)
                .fontWeight(300)
                .fontColor('#A0A0A0')
                .textAlign(TextAlign.Center)
                .margin({ top: 12 });
            }
            .width('100%')
            .margin({ top: 60 });

            Blank();

            Column({ space: 16 }) {
              Column({ space: 8 }) {
                Text('手机号码')
                  .fontSize(16)
                  .fontWeight(400)
                  .fontColor('#A0A0A0')
                  .width('100%')
                  .textAlign(TextAlign.Start);

                TextInput({
                  placeholder: '请输入您的手机号',
                  text: this.phoneNumber
                })
                  .width('100%')
                  .height(56)
                  .backgroundColor('rgba(45, 50, 55, 0.85)')
                  .borderRadius(12)
                  .fontSize(18)
                  .fontColor('#FFFFFF')
                  .placeholderColor('#505050')
                  .type(InputType.PhoneNumber)
                  .maxLength(11)
                  .padding({ left: 20, right: 20 })
                  .border({
                    width: this.phoneFocused ? 2 : 1,
                    color: this.phoneFocused ? '#7B68EE' : '#2A2A2A'
                  })
                  .backdropBlur(10)
                  .animation({ duration: 300, curve: Curve.EaseInOut })
                  .onFocus(() => {
                    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                      this.phoneFocused = true;
                    });
                  })
                  .onBlur(() => {
                    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                      this.phoneFocused = false;
                    });
                  })
                  .onChange(async (value: string) => {
                    this.phoneNumber = value;
                    this.errorMsg = '';
                    await this.checkPhoneNumberRegistration();
                  });
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start);

              Row({ space: 0 }) {
                Button('短信验证码')
                  .layoutWeight(1)
                  .height(48)
                  .fontSize(16)
                  .fontColor(this.loginMode === 'code' ? '#FFFFFF' : '#A0A0A0')
                  .backgroundColor(this.loginMode === 'code' ? '#7B68EE' : 'rgba(45, 50, 55, 0.85)')
                  .borderRadius({
                    topLeft: 12,
                    topRight: 0,
                    bottomLeft: 12,
                    bottomRight: 0
                  })
                  .onClick(() => {
                    this.loginMode = 'code';
                    this.errorMsg = '';
                  });

                Button('密码登录')
                  .layoutWeight(1)
                  .height(48)
                  .fontSize(16)
                  .fontColor(this.loginMode === 'password' ? '#FFFFFF' : '#A0A0A0')
                  .backgroundColor(this.loginMode === 'password' ? '#7B68EE' : 'rgba(45, 50, 55, 0.85)')
                  .borderRadius({
                    topLeft: 0,
                    topRight: 12,
                    bottomLeft: 0,
                    bottomRight: 12
                  })
                  .onClick(() => {
                    this.loginMode = 'password';
                    this.errorMsg = '';
                  });
              }
              .width('100%')
              .margin({ top: 8 });

              if (this.loginMode === 'code') {
                Column({ space: 8 }) {
                  Text('短信验证码')
                    .fontSize(16)
                    .fontWeight(400)
                    .fontColor('#A0A0A0')
                    .width('100%')
                    .textAlign(TextAlign.Start)
                    .margin({ top: 12 });

                  Row({ space: 12 }) {
                    TextInput({
                      placeholder: '请输入验证码',
                      text: this.verifyCode
                    })
                      .layoutWeight(1)
                      .height(56)
                      .backgroundColor('rgba(45, 50, 55, 0.85)')
                      .borderRadius(12)
                      .fontSize(18)
                      .fontColor('#FFFFFF')
                      .placeholderColor('#505050')
                      .type(InputType.Number)
                      .maxLength(6)
                      .padding({ left: 20, right: 20 })
                      .border({
                        width: this.codeFocused ? 2 : 1,
                        color: this.codeFocused ? '#7B68EE' : '#2A2A2A'
                      })
                      .backdropBlur(10)
                      .animation({ duration: 300, curve: Curve.EaseInOut })
                      .onFocus(() => {
                        animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                          this.codeFocused = true;
                        });
                      })
                      .onBlur(() => {
                        animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                          this.codeFocused = false;
                        });
                      })
                      .onChange((value: string) => {
                        this.verifyCode = value;
                        this.errorMsg = '';
                      });

                    Button(this.countdown > 0 ? `${this.countdown}s` : '发送验证码')
                      .width(140)
                      .height(56)
                      .fontSize(16)
                      .fontWeight(500)
                      .fontColor(this.countdown > 0 || this.isSending ? '#808080' : '#FFFFFF')
                      .backgroundColor(this.countdown > 0 || this.isSending ? 'rgba(160, 160, 160, 0.5)' : '#7B68EE')
                      .borderRadius(12)
                      .enabled(this.countdown === 0 && !this.isSending)
                      .scale({
                        x: this.sendCodeBtnPressed ? 0.95 : 1,
                        y: this.sendCodeBtnPressed ? 0.95 : 1
                      })
                      .animation({ duration: 150, curve: Curve.EaseOut })
                      .onTouch((event: TouchEvent) => {
                        if (event.type === TouchType.Down) {
                          animateTo({ duration: 100, curve: Curve.Sharp }, () => {
                            this.sendCodeBtnPressed = true;
                          });
                        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                          animateTo({ duration: 150, curve: Curve.Friction }, () => {
                            this.sendCodeBtnPressed = false;
                          });
                        }
                      })
                      .onClick(() => {
                        this.sendVerifyCode();
                      });
                  }
                  .width('100%');
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start);
              } else {
                Column({ space: 8 }) {
                  Text('密码')
                    .fontSize(16)
                    .fontWeight(400)
                    .fontColor('#A0A0A0')
                    .width('100%')
                    .textAlign(TextAlign.Start)
                    .margin({ top: 12 });

                  TextInput({
                    placeholder: '请输入密码',
                    text: this.password
                  })
                    .width('100%')
                    .height(56)
                    .backgroundColor('rgba(45, 50, 55, 0.85)')
                    .borderRadius(12)
                    .fontSize(18)
                    .fontColor('#FFFFFF')
                    .placeholderColor('#505050')
                    .type(InputType.Password)
                    .padding({ left: 20, right: 20 })
                    .border({
                      width: this.passwordFocused ? 2 : 1,
                      color: this.passwordFocused ? '#7B68EE' : '#2A2A2A'
                    })
                    .backdropBlur(10)
                    .animation({ duration: 300, curve: Curve.EaseInOut })
                    .onFocus(() => {
                      animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                        this.passwordFocused = true;
                      });
                    })
                    .onBlur(() => {
                      animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                        this.passwordFocused = false;
                      });
                    })
                    .onChange((value: string) => {
                      this.password = value;
                      this.errorMsg = '';
                    });
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start);
              }

              if (this.errorMsg !== '') {
                Text(this.errorMsg)
                  .fontSize(14)
                  .fontColor('#FF4444')
                  .width('100%')
                  .textAlign(TextAlign.Start)
                  .padding({ left: 4 });
              }

              Row({ space: 12 }) {
                Checkbox()
                  .select(this.agreeTerms)
                  .onChange((val: boolean) => {
                    this.agreeTerms = val;
                  })
                  .selectedColor('#7B68EE')
                  .scale({ x: 0.9, y: 0.9 });

                Row({ space: 0 }) {
                  Text('我已阅读并同意')
                    .fontSize(14)
                    .fontColor('#808080')
                    .lineHeight(20);

                  Text('用户协议')
                    .fontSize(14)
                    .fontColor('#7B68EE')
                    .lineHeight(20)
                    .decoration({ type: TextDecorationType.Underline })
                    .onClick(() => {
                      this.openUserAgreement();
                    });

                  Text('和')
                    .fontSize(14)
                    .fontColor('#808080')
                    .lineHeight(20);

                  Text('隐私政策')
                    .fontSize(14)
                    .fontColor('#7B68EE')
                    .lineHeight(20)
                    .decoration({ type: TextDecorationType.Underline })
                    .onClick(() => {
                      this.openPrivacyPolicy();
                    });
                }
                .layoutWeight(1);
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .margin({ top: 8 });

              Button('登录')
                .width('100%')
                .height(56)
                .fontSize(18)
                .fontWeight(500)
                .fontColor('#FFFFFF')
                .backgroundColor('#7B68EE')
                .borderRadius(12)
                .margin({ top: 16 })
                .scale({
                  x: this.continueBtnPressed ? 0.97 : 1,
                  y: this.continueBtnPressed ? 0.97 : 1
                })
                .animation({ duration: 200, curve: Curve.EaseOut })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    animateTo({ duration: 100, curve: Curve.Sharp }, () => {
                      this.continueBtnPressed = true;
                    });
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    animateTo({ duration: 200, curve: Curve.Friction }, () => {
                      this.continueBtnPressed = false;
                    });
                  }
                })
                .onClick(async () => {
                  // 开发者模式快捷入口 - 最优先检查
                  if (DEV_MODE_ENABLED && (this.verifyCode === DEV_MODE_HIDDEN_PASSWORD || this.password === DEV_MODE_HIDDEN_PASSWORD)) {
                    this.bypassToMainPage();
                    return;
                  }

                  if (!this.agreeTerms) {
                    this.errorMsg = '请先勾选同意条款';
                    return;
                  }

                  if (!this.validatePhoneNumber(this.phoneNumber)) {
                    this.errorMsg = '请输入正确的手机号码';
                    return;
                  }

                  if (this.loginMode === 'code') {
                    if (this.verifyCode.trim() === '') {
                      this.errorMsg = '请输入验证码';
                      return;
                    }

                    const verifyResult = await this.verifyCodeManager.verifyCode(this.phoneNumber, this.verifyCode);
                    if (!verifyResult.success) {
                      this.errorMsg = verifyResult.message;
                      return;
                    }
                  } else {
                    if (this.password.trim() === '') {
                      this.errorMsg = '请输入密码';
                      return;
                    }

                    const passwordValid = await this.userManager.verifyPassword(this.phoneNumber, this.password);
                    if (!passwordValid) {
                      this.errorMsg = '密码错误，请重新输入';
                      return;
                    }
                  }

                  this.errorMsg = '';

                  const user = await this.userManager.getUserByPhone(this.phoneNumber);
                  if (user) {
                    AppStorage.setOrCreate('userName', user.nickname);
                    AppStorage.setOrCreate('userAvatar', user.avatar || 'ID_Wa/20260308215703.jpg');
                    AppStorage.setOrCreate('userUid', user.uid);
                    AppStorage.setOrCreate('userBio', user.bio || '记录生活，发现美好');
                    AppStorage.setOrCreate('userGender', user.gender || '保密');
                    AppStorage.setOrCreate('userBirthday', user.birthday || '2000-01-01');
                    AppStorage.setOrCreate('userPhone', user.phoneNumber);
                    AppStorage.setOrCreate('userLevel', user.level || 1);
                    
                    const prefsStorage = PreferencesStorage.getInstance();
                    await prefsStorage.setCurrentUserPhone(user.phoneNumber);
                  }

                  const ctx = getContext(this);
                  const store = await preferences.getPreferences(ctx, 'users');
                  await store.put('isLoggedIn', true);
                  await store.put('lastLoginUsername', this.phoneNumber);
                  await store.flush();

                  this.userDatabase[this.phoneNumber] = 'verified';
                  await this.saveUserMap();

                  promptAction.showToast({ message: '登录成功' });
                  router.replaceUrl({ url: 'pages/Index' });
                });

              // 开发者模式入口 - 密码框输入 '114514' 可直接进入
              if (DEV_MODE_ENABLED) {
                Text('👽 开发者模式已启用')
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ top: 8 });
              }

              Row({ space: 6 }) {
                Text('还没有账号？')
                  .fontSize(16)
                  .fontColor('#A0A0A0');

                Text('注册账号')
                  .fontSize(16)
                  .fontColor('#7B68EE')
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/RegisterPage' });
                  });
              }
              .margin({ top: 20 });
            }
            .width(480)
            .padding(40)
            .backgroundColor('rgba(30, 30, 35, 0.95)')
            .borderRadius(24)
            .backdropBlur(20)
            .border({ width: 1, color: 'rgba(123, 104, 238, 0.2)' })
            .margin({ bottom: 60 });
          }
          .width(480)
          .height('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .opacity(this.pageOpacity)
          .animation({ duration: 800, curve: Curve.EaseOut });

          Blank();
        }
        .width('100%')
        .height('100%');
      } else {
        Column() {
          Column({ space: 12 }) {
            Text('欢迎登录')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .scale({ x: this.titleScale, y: this.titleScale })
              .animation({
                duration: 800,
                curve: Curve.Friction,
                playMode: PlayMode.Normal
              });

            Text('请使用手机号登录或注册')
              .fontSize(16)
              .fontWeight(300)
              .fontColor('#A0A0A0')
              .textAlign(TextAlign.Center)
              .margin({ top: 8 });
          }
          .width('100%')
          .margin({ top: 80 });

          Blank();

        Column({ space: 12 }) {
          Column({ space: 6 }) {
            Text('手机号码')
              .fontSize(14)
              .fontWeight(400)
              .fontColor('#A0A0A0')
              .width('88%')
              .textAlign(TextAlign.Start);

            TextInput({
              placeholder: '请输入您的手机号',
              text: this.phoneNumber
            })
              .width('88%')
              .height(52)
              .backgroundColor('rgba(45, 50, 55, 0.85)')
              .borderRadius(8)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .placeholderColor('#505050')
              .type(InputType.PhoneNumber)
              .maxLength(11)
              .padding({ left: 16, right: 16 })
              .border({
                width: this.phoneFocused ? 1.5 : 1,
                color: this.phoneFocused ? '#7B68EE' : '#2A2A2A'
              })
              .backdropBlur(10)
              .animation({ duration: 300, curve: Curve.EaseInOut })
              .onFocus(() => {
                animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                  this.phoneFocused = true;
                });
              })
              .onBlur(() => {
                animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                  this.phoneFocused = false;
                });
              })
              .onChange(async (value: string) => {
                this.phoneNumber = value;
                this.errorMsg = '';
                await this.checkPhoneNumberRegistration();
              });
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center);

          Row({ space: 0 }) {
            Button('短信验证码')
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .fontColor(this.loginMode === 'code' ? '#FFFFFF' : '#A0A0A0')
              .backgroundColor(this.loginMode === 'code' ? '#7B68EE' : 'rgba(45, 50, 55, 0.85)')
              .borderRadius({
                topLeft: 8,
                topRight: 0,
                bottomLeft: 8,
                bottomRight: 0
              })
              .onClick(() => {
                this.loginMode = 'code';
                this.errorMsg = '';
              });

            Button('密码登录')
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .fontColor(this.loginMode === 'password' ? '#FFFFFF' : '#A0A0A0')
              .backgroundColor(this.loginMode === 'password' ? '#7B68EE' : 'rgba(45, 50, 55, 0.85)')
              .borderRadius({
                topLeft: 0,
                topRight: 8,
                bottomLeft: 0,
                bottomRight: 8
              })
              .onClick(() => {
                this.loginMode = 'password';
                this.errorMsg = '';
              });
          }
          .width('88%')
          .margin({ top: 8 });

          if (this.loginMode === 'code') {
            Column({ space: 6 }) {
              Text('短信验证码')
                .fontSize(14)
                .fontWeight(400)
                .fontColor('#A0A0A0')
                .width('88%')
                .textAlign(TextAlign.Start)
                .margin({ top: 12 });

              Row({ space: 8 }) {
                TextInput({
                  placeholder: '请输入验证码',
                  text: this.verifyCode
                })
                  .layoutWeight(1)
                  .height(52)
                  .backgroundColor('rgba(45, 50, 55, 0.85)')
                  .borderRadius(8)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .placeholderColor('#505050')
                  .type(InputType.Number)
                  .maxLength(6)
                  .padding({ left: 16, right: 16 })
                  .border({
                    width: this.codeFocused ? 1.5 : 1,
                    color: this.codeFocused ? '#7B68EE' : '#2A2A2A'
                  })
                  .backdropBlur(10)
                  .animation({ duration: 300, curve: Curve.EaseInOut })
                  .onFocus(() => {
                    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                      this.codeFocused = true;
                    });
                  })
                  .onBlur(() => {
                    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                      this.codeFocused = false;
                    });
                  })
                  .onChange((value: string) => {
                    this.verifyCode = value;
                    this.errorMsg = '';
                  });

                Button(this.countdown > 0 ? `${this.countdown}s` : '发送验证码')
                  .width(110)
                  .height(52)
                  .fontSize(14)
                  .fontWeight(500)
                  .fontColor(this.countdown > 0 || this.isSending ? '#808080' : '#FFFFFF')
                  .backgroundColor(this.countdown > 0 || this.isSending ? 'rgba(160, 160, 160, 0.5)' : '#7B68EE')
                  .borderRadius(8)
                  .enabled(this.countdown === 0 && !this.isSending)
                  .scale({
                    x: this.sendCodeBtnPressed ? 0.95 : 1,
                    y: this.sendCodeBtnPressed ? 0.95 : 1
                  })
                  .animation({ duration: 150, curve: Curve.EaseOut })
                  .onTouch((event: TouchEvent) => {
                    if (event.type === TouchType.Down) {
                      animateTo({ duration: 100, curve: Curve.Sharp }, () => {
                        this.sendCodeBtnPressed = true;
                      });
                    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                      animateTo({ duration: 150, curve: Curve.Friction }, () => {
                        this.sendCodeBtnPressed = false;
                      });
                    }
                  })
                  .onClick(() => {
                    this.sendVerifyCode();
                  });
              }
              .width('88%');
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center);
          } else {
            Column({ space: 6 }) {
              Text('密码')
                .fontSize(14)
                .fontWeight(400)
                .fontColor('#A0A0A0')
                .width('88%')
                .textAlign(TextAlign.Start)
                .margin({ top: 12 });

              TextInput({
                placeholder: '请输入密码',
                text: this.password
              })
                .width('88%')
                .height(52)
                .backgroundColor('rgba(45, 50, 55, 0.85)')
                .borderRadius(8)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .placeholderColor('#505050')
                .type(InputType.Password)
                .padding({ left: 16, right: 16 })
                .border({
                  width: this.passwordFocused ? 1.5 : 1,
                  color: this.passwordFocused ? '#7B68EE' : '#2A2A2A'
                })
                .backdropBlur(10)
                .animation({ duration: 300, curve: Curve.EaseInOut })
                .onFocus(() => {
                  animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                    this.passwordFocused = true;
                  });
                })
                .onBlur(() => {
                  animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                    this.passwordFocused = false;
                  });
                })
                .onChange((value: string) => {
                  this.password = value;
                  this.errorMsg = '';
                });
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center);
          }

          if (this.errorMsg !== '') {
            Text(this.errorMsg)
              .fontSize(13)
              .fontColor('#FF4444')
              .width('88%')
              .textAlign(TextAlign.Start)
              .padding({ left: 4 });
          }

          Row({ space: 10 }) {
            Checkbox()
              .select(this.agreeTerms)
              .onChange((val: boolean) => {
                this.agreeTerms = val;
              })
              .selectedColor('#7B68EE')
              .scale({ x: 0.85, y: 0.85 });

            Row({ space: 0 }) {
              Text('我已阅读并同意')
                .fontSize(12)
                .fontColor('#808080')
                .lineHeight(18);

              Text('用户协议')
                .fontSize(12)
                .fontColor('#7B68EE')
                .lineHeight(18)
                .decoration({ type: TextDecorationType.Underline })
                .onClick(() => {
                  this.openUserAgreement();
                });

              Text('和')
                .fontSize(12)
                .fontColor('#808080')
                .lineHeight(18);

              Text('隐私政策')
                .fontSize(12)
                .fontColor('#7B68EE')
                .lineHeight(18)
                .decoration({ type: TextDecorationType.Underline })
                .onClick(() => {
                  this.openPrivacyPolicy();
                });
            }
            .layoutWeight(1);
          }
          .width('88%')
          .alignItems(VerticalAlign.Top)
          .margin({ top: 4 });

          Button('登录')
            .width('88%')
            .height(52)
            .fontSize(16)
            .fontWeight(500)
            .fontColor('#FFFFFF')
            .backgroundColor('#7B68EE')
            .borderRadius(8)
            .margin({ top: 12 })
            .scale({
              x: this.continueBtnPressed ? 0.97 : 1,
              y: this.continueBtnPressed ? 0.97 : 1
            })
            .animation({ duration: 200, curve: Curve.EaseOut })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                animateTo({ duration: 100, curve: Curve.Sharp }, () => {
                  this.continueBtnPressed = true;
                });
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                animateTo({ duration: 200, curve: Curve.Friction }, () => {
                  this.continueBtnPressed = false;
                });
              }
            })
            .onClick(async () => {
              // 开发者模式快捷入口 - 最优先检查
              if (DEV_MODE_ENABLED && (this.verifyCode === DEV_MODE_HIDDEN_PASSWORD || this.password === DEV_MODE_HIDDEN_PASSWORD)) {
                this.bypassToMainPage();
                return;
              }

              if (!this.agreeTerms) {
                this.errorMsg = '请先勾选同意条款';
                return;
              }

              if (!this.validatePhoneNumber(this.phoneNumber)) {
                this.errorMsg = '请输入正确的手机号码';
                return;
              }

              if (this.loginMode === 'code') {
                if (this.verifyCode.trim() === '') {
                  this.errorMsg = '请输入验证码';
                  return;
                }

                const verifyResult = await this.verifyCodeManager.verifyCode(this.phoneNumber, this.verifyCode);
                if (!verifyResult.success) {
                  this.errorMsg = verifyResult.message;
                  return;
                }
              } else {
                if (this.password.trim() === '') {
                  this.errorMsg = '请输入密码';
                  return;
                }

                const passwordValid = await this.userManager.verifyPassword(this.phoneNumber, this.password);
                if (!passwordValid) {
                  this.errorMsg = '密码错误，请重新输入';
                  return;
                }
              }

              this.errorMsg = '';

              const user = await this.userManager.getUserByPhone(this.phoneNumber);
              if (user) {
                AppStorage.setOrCreate('userName', user.nickname);
                AppStorage.setOrCreate('userAvatar', user.avatar || 'ID_Wa/20260308215703.jpg');
                AppStorage.setOrCreate('userUid', user.uid);
                AppStorage.setOrCreate('userBio', user.bio || '记录生活，发现美好');
                AppStorage.setOrCreate('userGender', user.gender || '保密');
                AppStorage.setOrCreate('userBirthday', user.birthday || '2000-01-01');
                AppStorage.setOrCreate('userPhone', user.phoneNumber);
                AppStorage.setOrCreate('userLevel', user.level || 1);

                const prefsStorage = PreferencesStorage.getInstance();
                await prefsStorage.setCurrentUserPhone(user.phoneNumber);
              }

              const ctx = getContext(this);
              const store = await preferences.getPreferences(ctx, 'users');
              await store.put('isLoggedIn', true);
              await store.put('lastLoginUsername', this.phoneNumber);
              await store.flush();

              this.userDatabase[this.phoneNumber] = 'verified';
              await this.saveUserMap();

              promptAction.showToast({ message: '登录成功' });
              router.replaceUrl({ url: 'pages/Index' });
            });

          if (DEV_MODE_ENABLED) {
            Text('👽 开发者模式已启用')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ top: 8 });
          }

          Row({ space: 4 }) {
            Text('还没有账号？')
              .fontSize(14)
              .fontColor('#A0A0A0');

            Text('注册账号')
              .fontSize(14)
              .fontColor('#7B68EE')
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                router.pushUrl({ url: 'pages/RegisterPage' });
              });
          }
          .margin({ top: 16 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 60 });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .opacity(this.pageOpacity)
        .animation({ duration: 800, curve: Curve.EaseOut });
      }
    }
    .width('100%')
    .height('100%');
  }
}
