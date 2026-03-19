import { ConfigurationConstant } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';

interface StorageItem {
  id: string;
  title: string;
  size: string;
  icon: Resource;
  color: string;
}

@Component
export struct StorageCleanPanel {
  @StorageLink('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State isClearing: boolean = false;
  @State totalCache: string = '128.5 MB';
  @State chatRecordSize: string = '256.8 MB';
  @State imageCacheSize: string = '64.2 MB';
  @State videoCacheSize: string = '45.3 MB';
  @State otherCacheSize: string = '22.2 MB';

  private storageItems: StorageItem[] = [
    { id: 'chat', title: '聊天记录', size: '256.8 MB', icon: $r('sys.symbol.message'), color: '#007AFF' },
    { id: 'image', title: '图片缓存', size: '64.2 MB', icon: $r('sys.symbol.heart'), color: '#34C759' },
    { id: 'video', title: '视频缓存', size: '45.3 MB', icon: $r('sys.symbol.checkmark_circle_fill'), color: '#FF9500' },
    { id: 'other', title: '其他缓存', size: '22.2 MB', icon: $r('sys.symbol.gearshape'), color: '#5856D6' }
  ];

  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    }
  }

  private clearAllCache(): void {
    AlertDialog.show({
      title: '确认清空',
      message: '确定要清空所有缓存数据吗？这将删除图片缓存、视频缓存和其他临时文件，不会影响聊天记录。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清空',
        fontColor: '#FF3B30',
        action: () => {
          this.performClearCache(['image', 'video', 'other']);
        }
      }
    });
  }

  private clearChatRecords(): void {
    AlertDialog.show({
      title: '清空聊天记录',
      message: '确定要清空本地聊天记录吗？此操作不可恢复，请谨慎操作。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清空',
        fontColor: '#FF3B30',
        action: () => {
          this.performClearCache(['chat']);
        }
      }
    });
  }

  private performClearCache(types: string[]): void {
    this.isClearing = true;

    setTimeout(() => {
      if (types.includes('chat')) {
        this.chatRecordSize = '0 B';
      }
      if (types.includes('image')) {
        this.imageCacheSize = '0 B';
      }
      if (types.includes('video')) {
        this.videoCacheSize = '0 B';
      }
      if (types.includes('other')) {
        this.otherCacheSize = '0 B';
      }

      this.updateTotalCache();
      this.isClearing = false;
      promptAction.showToast({
        message: '清理完成',
        duration: 2000
      });
    }, 1500);
  }

  private updateTotalCache(): void {
    const sizes = [
      this.parseSize(this.chatRecordSize),
      this.parseSize(this.imageCacheSize),
      this.parseSize(this.videoCacheSize),
      this.parseSize(this.otherCacheSize)
    ];
    const total = sizes.reduce((sum, size) => sum + size, 0);
    this.totalCache = this.formatSize(total);
  }

  private parseSize(sizeStr: string): number {
    if (sizeStr === '0 B') return 0;
    const match = sizeStr.match(/^([\d.]+)\s*(B|KB|MB|GB)$/);
    if (!match) return 0;
    const value = parseFloat(match[1]);
    const unit = match[2];
    switch (unit) {
      case 'B': return value;
      case 'KB': return value * 1024;
      case 'MB': return value * 1024 * 1024;
      case 'GB': return value * 1024 * 1024 * 1024;
      default: return 0;
    }
  }

  @Builder
  StorageItemRow(item: StorageItem) {
    Row() {
      SymbolGlyph(item.icon)
        .fontSize(24)
        .fontColor([item.color])
        .margin({ right: 16 })

      Column() {
        Text(item.title)
          .fontSize(16)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
          .margin({ bottom: 4 })

        Text(item.id === 'chat' ? this.chatRecordSize :
             item.id === 'image' ? this.imageCacheSize :
             item.id === 'video' ? this.videoCacheSize : this.otherCacheSize)
          .fontSize(14)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (item.id === 'chat') {
        Button('清空')
          .fontSize(14)
          .height(32)
          .backgroundColor('#FF3B30')
          .fontColor(Color.White)
          .onClick(() => {
            this.clearChatRecords();
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  TotalStorageCard() {
    Column() {
      Row() {
        Column() {
          Text('总占用空间')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
            .margin({ bottom: 8 })

          Text(this.totalCache)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Stack() {
            Progress({ value: 65, total: 100, type: ProgressType.Ring })
              .width(60)
              .height(60)
              .color('#007AFF')
              .style({ strokeWidth: 6 })

            Text('65%')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
          }
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  ClearAllButton() {
    Button() {
      if (this.isClearing) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(Color.White)
            .margin({ right: 8 })

          Text('清理中...')
            .fontSize(16)
            .fontColor(Color.White)
        }
      } else {
        Text('清空缓存')
          .fontSize(16)
          .fontColor(Color.White)
      }
    }
    .width('100%')
    .height(50)
    .backgroundColor(this.isClearing ? '#CCCCCC' : '#007AFF')
    .borderRadius(12)
    .enabled(!this.isClearing)
    .onClick(() => {
      this.clearAllCache();
    })
  }

  @Builder
  WarningCard() {
    Row() {
      SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
        .fontSize(20)
        .fontColor(['#FF9500'])
        .margin({ right: 12 })

      Column() {
        Text('温馨提示')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
          .margin({ bottom: 4 })

        Text('清空聊天记录将删除所有本地聊天数据，此操作不可恢复。图片、视频缓存清理后不影响正常使用。')
          .fontSize(12)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
          .lineHeight(18)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,149,0,0.1)' : 'rgba(255,149,0,0.05)')
    .borderRadius(12)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.TotalStorageCard()

        Column({ space: 12 }) {
          Text('存储详情')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
            .width('100%')
            .margin({ top: 8 })

          ForEach(this.storageItems, (item: StorageItem) => {
            this.StorageItemRow(item)
          }, (item: StorageItem) => item.id)
        }

        this.WarningCard()

        this.ClearAllButton()

        Text('清理缓存可以释放设备存储空间，提升应用运行速度')
          .fontSize(12)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 8 })
      }
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F2F2F7')
  }
}