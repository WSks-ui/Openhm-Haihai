import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { DraftManager } from '../../utils/DraftManager';
import { LiquidGlass } from '../common/LiquidGlass';

interface Draft {
  id: string;
  content: string;
  images: string[];
  createdAt: number;
  updatedAt: number;
}

@Component
export struct MyDraftsPanel {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State draftList: Draft[] = [];
  @State isLoading: boolean = true;
  private draftManager: DraftManager = DraftManager.getInstance();

  aboutToAppear() {
    this.loadDrafts();
  }

  private async loadDrafts() {
    this.isLoading = true;
    this.draftList = await this.draftManager.getDrafts();
    this.isLoading = false;
  }

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    
    if (minutes < 1) {
      return '刚刚';
    } else if (minutes < 60) {
      return `${minutes}分钟前`;
    } else if (hours < 24) {
      return `${hours}小时前`;
    } else if (days < 7) {
      return `${days}天前`;
    } else {
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    }
  }

  private async deleteDraft(id: string) {
    try {
      const success = await this.draftManager.deleteDraft(id);
      if (success) {
        promptAction.showToast({
          message: '删除成功',
          duration: 1500
        });
        this.loadDrafts();
      }
    } catch (error) {
      promptAction.showToast({
        message: '删除失败',
        duration: 1500
      });
    }
  }

  private editDraft(draft: Draft) {
    router.pushUrl({
      url: 'pages/CreatePostPage',
      params: {
        draftId: draft.id,
        content: draft.content,
        images: draft.images
      }
    });
  }

  @Builder
  EmptyState() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.doc'))
        .fontSize(64)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#444' : '#CCC'])
      
      Text('暂无草稿')
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
      
      Text('保存的草稿将显示在这里')
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#BBB')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  DraftCard(draft: Draft) {
    Column() {
      Row({ space: 12 }) {
        if (draft.images.length > 0) {
          Image(draft.images[0].startsWith('app.media.') ? $r(draft.images[0]) : $rawfile(draft.images[0]))
            .width(80)
            .height(80)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#EEE')
        }
        
        Column({ space: 8 }) {
          Text(draft.content || '无内容')
            .fontSize(15)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(22)
            .width('100%')
          
          Text(this.formatDate(draft.updatedAt))
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Row({ space: 8 }) {
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.editDraft(draft);
            })
          
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.deleteDraft(draft.id);
            })
        }
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 4,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.05)',
      offsetY: 2
    })
    .onClick(() => {
      this.editDraft(draft);
    })
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#7B68EE')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.draftList.length === 0) {
        this.EmptyState()
      } else {
        List({ space: 12 }) {
          ForEach(this.draftList, (draft: Draft) => {
            ListItem() {
              this.DraftCard(draft)
            }
          }, (draft: Draft) => draft.id)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
