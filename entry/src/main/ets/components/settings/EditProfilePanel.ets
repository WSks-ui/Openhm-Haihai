import { ConfigurationConstant } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';
import { UserManager } from '../../model/UserModel';

@Component
export struct EditProfilePanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageLink('userName') userName: string = '我的名字';
  @StorageLink('userAvatar') userAvatar: string = 'ID_Wa/20260308215703.jpg';
  @StorageLink('userUid') userUid: string = 'U10001';
  @StorageLink('userBio') userBio: string = '记录生活，发现美好';
  @StorageLink('userGender') userGender: string = '保密';
  @StorageLink('userBirthday') userBirthday: string = '2000-01-01';
  @StorageLink('userPhone') userPhone: string = '';

  private userManager: UserManager = UserManager.getInstance();

  private async saveUserInfo(): Promise<void> {
    if (!this.userPhone) {
      promptAction.showToast({ message: '用户信息异常，请重新登录' });
      return;
    }

    const success = await this.userManager.updateUser(this.userPhone, {
      nickname: this.userName,
      avatar: this.userAvatar,
      bio: this.userBio,
      gender: this.userGender,
      birthday: this.userBirthday
    });

    if (success) {
      promptAction.showToast({ message: '保存成功' });
    } else {
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  @Builder
  EditProfileInputItem(title: string, value: string, onChange: (val: string) => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      TextInput({ text: value })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .textAlign(TextAlign.End)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
        .maxLines(1)
        .onChange(onChange)
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  EditProfileInfoItem(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      Text(value)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  EditProfileSelectItem(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      Text(value)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#98989D' : '#8E8E93')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#636366' : '#C7C7CC'])
        .margin({ left: 8 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  EditProfileArrowItem(title: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#EBEBF5' : '#1C1C1E')
        .fontWeight(FontWeight.Medium)
      Blank()
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#636366' : '#C7C7CC'])
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  EditProfileContent() {
    Column() {
      Row() {
        Blank()
        Text('保存')
          .fontSize(16)
          .fontColor('#7B68EE')
          .onClick(() => this.saveUserInfo())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 0, bottom: 16 })

      Scroll() {
        Column({ space: 16 }) {
          Column() {
            Column() {
              Stack() {
                if (this.userAvatar.startsWith('app.media.')) {
                  Image($r(this.userAvatar))
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                } else {
                  Image($rawfile(this.userAvatar))
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                }
                Column() {
                  SymbolGlyph($r('sys.symbol.camera_fill'))
                    .fontSize(20)
                    .fontColor([Color.White])
                }
                .width(100)
                .height(100)
                .borderRadius(50)
                .backgroundColor('rgba(0,0,0,0.4)')
                .justifyContent(FlexAlign.Center)
              }
              .width(100)
              .height(100)
              .margin({ top: 24, bottom: 12 })

              Text('点击更换头像')
                .fontSize(14)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
          .borderRadius(16)
          .padding({ bottom: 24 })

          Column({ space: 0 }) {
            this.EditProfileInputItem('昵称', this.userName, (val) => { this.userName = val; })
            Divider()
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
              .margin({ left: 20 })
            this.EditProfileInfoItem('ID', this.userUid)
            Divider()
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
              .margin({ left: 20 })
            this.EditProfileInputItem('简介', this.userBio, (val) => { this.userBio = val; })
            Divider()
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
              .margin({ left: 20 })
            this.EditProfileSelectItem('性别', this.userGender, () => {
              promptAction.showActionMenu({
                title: '选择性别',
                buttons: [
                  { text: '男', color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333' },
                  { text: '女', color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333' },
                  { text: '保密', color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333' }
                ]
              }, (err, data) => {
                if (data.index === 0) this.userGender = '男';
                if (data.index === 1) this.userGender = '女';
                if (data.index === 2) this.userGender = '保密';
              });
            })
            Divider()
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)')
              .margin({ left: 20 })
            this.EditProfileSelectItem('生日', this.userBirthday, () => {
              DatePickerDialog.show({
                start: new Date('1900-01-01'),
                end: new Date('2100-12-31'),
                selected: new Date(this.userBirthday),
                onAccept: (value: DatePickerResult) => {
                  const year = value.year;
                  const month = (value.month ?? 0) + 1;
                  const day = value.day ?? 1;
                  const monthStr = month < 10 ? `0${month}` : `${month}`;
                  const dayStr = day < 10 ? `0${day}` : `${day}`;
                  this.userBirthday = `${year}-${monthStr}-${dayStr}`;
                }
              });
            })
          }
          .width('100%')
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
          .borderRadius(16)

          Column({ space: 0 }) {
            this.EditProfileArrowItem('管理自己的主页', () => {
              promptAction.showToast({ message: '管理主页设置' });
            })
          }
          .width('100%')
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
          .borderRadius(16)

        }
        .padding({ left: 16, right: 16, top: 0, bottom: 32 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }

  build() {
    this.EditProfileContent()
  }
}
