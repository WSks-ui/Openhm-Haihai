import { ConfigurationConstant } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';
import { PhotoPickerService } from '../../utils/PhotoPickerService';
import { HoldingHandStatus } from '../../utils/HoldingHandManager';

// 中间加号的发布菜单
@CustomDialog
export struct PublishMenu {
  controller: CustomDialogController;
  action: (type: string) => void = () => {};
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('holdingHandStatus') gripStatus: HoldingHandStatus = HoldingHandStatus.UNKNOWN_STATUS;
  private photoPickerService: PhotoPickerService = PhotoPickerService.getInstance();

  // 根据握持状态判断是否右手握持（菜单靠左对齐）
  private isRightHandHeld(): boolean {
    return this.gripStatus === HoldingHandStatus.RIGHT_HAND_HELD;
  }

  build() {
    Column() {
      // 顶部指示条
      Row()
        .width(40)
        .height(4)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#333' : '#E0E0E0')
        .borderRadius(2)
        .margin({ top: 12, bottom: 24 })

      Text('开始创作')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#182431')
        .margin({ bottom: 32 })
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 24 })

      Column({ space: 16 }) {
        Row() {
          this.MenuItem('发图文或分享', 'sys.symbol.picture', '#7B68EE', '分享想要交流的图片')
        }
        .onClick(async () => {
          this.controller.close();
          const imageUri = await this.photoPickerService.selectSingleImage(getContext(this) as common.UIAbilityContext);
          if (imageUri) {
            router.pushUrl({
              url: 'pages/CreatePostPage',
              params: { selectedImage: imageUri }
            });
          }
        })

        Row() {
          this.MenuItem('提问', 'sys.symbol.questionmark_circle', '#4ECDC4', '获取社区解答')
        }
        .onClick(() => {
          this.action('question');
          this.controller.close();
        })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 32 })
      // .height(160) // 移除固定高度，由内容撑开

      Button('取消')
        .width('90%')
        .height(48)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F5F5F5')
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#999' : '#666')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 }) // 底部留白，适配安全区
        .onClick(() => {
          this.controller.close();
        })
    }
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
    .borderRadius(this.currentBreakpoint === 'sm' ? { topLeft: 24, topRight: 24 } : 24)
    .width(this.currentBreakpoint === 'sm' ? '100%' : 400)
    .margin(this.currentBreakpoint === 'sm' ? 0 : { bottom: 24 })
    // 增加磨砂效果背景，提升质感（如果系统支持）
    .backdropBlur(20)
    .shadow(this.currentBreakpoint === 'sm' ? undefined : { radius: 32, color: 'rgba(0,0,0,0.2)', offsetY: 8 })
  }

  @Builder
  MenuItem(title: string, icon: string, color: string, subtitle: string) {
    Row() {
      // 图标容器 - 根据握持状态调整位置
      Column() {
        SymbolGlyph($r(icon))
          .fontSize(32)
          .fontColor([Color.White])
      }
      .width(56)
      .height(56)
      .borderRadius(18)
      .backgroundColor(color)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({ radius: 8, color: color + '66', offsetY: 4 })

      // 文字内容
      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#182431')
          .margin({ bottom: 4 })

        Text(subtitle)
          .fontSize(14)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 16 })

      // 箭头指示
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(24)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#CCC'])
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F9F9F9')
    .borderRadius(24)
    // 右手握持时反转布局，图标靠右
    .reverse(this.isRightHandHeld())
  }
}
