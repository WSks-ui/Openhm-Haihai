import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { SidebarItemModel } from '../model/SidebarItemModel';

@Component
export struct MineSidebar {
  // 控制侧边栏是否显示（可以从父组件传入，这里先内部管理）
  @State isSidebarVisible: boolean = true;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @Builder
  SidebarItem(title: string, icon: string, hasCount?: boolean, count?: number) {
    Row() {
      Image($r(icon))
        .width(24)
        .height(24)
        .margin({ right: 12 })
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      if (hasCount) {
        Text(count?.toString())
          .fontSize(12)
          .fontColor('#999')
      }
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
  }

  @Builder
  SidebarGroup(items: SidebarItemModel[]) {
    Column() {
      ForEach(items, (item: SidebarItemModel) => {
        this.SidebarItem(item.title, item.icon, item.hasCount, item.count)
      })
    }
    .width('90%')
    .backgroundColor(Color.White)
    .borderRadius(16)
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 12 })
    .animation({
      duration: 300,
      curve: Curve.EaseInOut // 慢 快 慢
    })
  }

  build() {
    Column() {
      // 侧边栏内容（根据状态显示/隐藏）
        Scroll() {
          Column() {
            this.SidebarGroup([
              new SidebarItemModel('添加好友', 'app.media.startIcon'),
            ])

            this.SidebarGroup([
              new SidebarItemModel('我的草稿', 'app.media.startIcon', true, 1),
              new SidebarItemModel('浏览记录', 'app.media.startIcon'),
            ])


          }
          .padding({ top: 60, bottom: 100 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')


      // 底部按钮区（始终显示）
      Row() {
        Column() {
          Image($r('app.media.startIcon'))
            .width(24)
            .height(24)
            .margin({ bottom: 4 })
          Text('扫一扫')
            .fontSize(12)
            .fontColor('#666')
        }
        .onClick(() => {
          try {
            // 处理异常(下面的‘帮助与客服’，‘设置’同理)-------------------------------------------------------==========
            promptAction.showToast({ message: '扫一扫' });
          } catch (error) {
            console.error('Toast failed:', error.message);
          }
        })

        Column() {
          Image($r('app.media.startIcon'))
            .width(24)
            .height(24)
            .margin({ bottom: 4 })
          Text('帮助与客服')
            .fontSize(12)
            .fontColor('#666')
        }
        .onClick(() => {
          try {
            // --------------------------------------------------------------------------------=========
            promptAction
              .showToast({ message: '帮助与客服' });
          } catch (error) {
            console.error('Toast failed:', error.message);
          }
        })

        Column() {
          SymbolGlyph($r('sys.symbol.gearshape'))
            .fontSize(24)
            .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#666666'])
            .margin({ bottom: 4 })
          Text('设置')
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#666666')
        }
        .onClick(() => {
          try {
            router.pushUrl({ url: 'pages/SettingsPage' });
          } catch (error) {
            console.error('Navigation failed:', error.message);
          }
        })

      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ top: 16, bottom: 32 })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff4f4f4')
  }
}