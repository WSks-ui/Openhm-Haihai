
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { Post, mockPosts } from '../model/Post';
import { PhotoPickerService } from '../utils/PhotoPickerService';
import { DraftManager } from '../utils/DraftManager';

interface PageParams {
  selectedImage?: string;
  draftId?: string;
  content?: string;
  images?: string[];
}

/**
 * CreatePostPage - 创建帖子页面
 * 
 * 沉浸式效果实现：
 * 1. 使用全局安全区域高度避开状态栏
 * 2. expandSafeArea 扩展页面到安全区域
 */

@Entry
@Component
struct CreatePostPage {
  @State content: string = '';
  @State images: string[] = [];
  @State maxImages: number = 1;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  private photoPickerService: PhotoPickerService = PhotoPickerService.getInstance();
  private draftManager: DraftManager = DraftManager.getInstance();
  @State draftId: string = '';
  
  // 沉浸式效果：安全区域高度
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;

  aboutToAppear() {
    this.draftManager.init(getContext(this));
    const params = router.getParams() as PageParams | undefined;
    if (params && params.selectedImage) {
      this.images = [params.selectedImage];
    }
    if (params && params.draftId) {
      this.draftId = params.draftId;
      this.content = params.content || '';
      this.images = params.images || [];
    }
  }

  private async saveDraft() {
    if (this.content.length === 0 && this.images.length === 0) {
      promptAction.showToast({
        message: '请输入内容或添加图片',
        duration: 2000
      });
      return;
    }

    try {
      if (this.draftId) {
        await this.draftManager.updateDraft(this.draftId, this.content, this.images);
        promptAction.showToast({
          message: '草稿已更新',
          duration: 1500
        });
      } else {
        const newDraft = await this.draftManager.saveDraft(this.content, this.images);
        this.draftId = newDraft.id;
        promptAction.showToast({
          message: '草稿已保存',
          duration: 1500
        });
      }
    } catch (error) {
      promptAction.showToast({
        message: '保存失败',
        duration: 1500
      });
    }
  }

  private async publishPost() {
    if (this.content.length === 0 && this.images.length === 0) {
      promptAction.showToast({
        message: '请输入内容或添加图片',
        duration: 2000
      });
      return;
    }

    const newId = `new_${Date.now()}`;
    const newPost = new Post(
      newId,
      '我',
      'ID_Wa/20260308215510.jpg',
      this.content,
      [...this.images],
      0,
      0,
      '刚刚'
    );

    mockPosts.unshift(newPost);

    AppStorage.setOrCreate('refreshHomeData', Date.now());

    if (this.draftId) {
      await this.draftManager.deleteDraft(this.draftId);
    }

    promptAction.showToast({
      message: '发布成功！你的声音已被世界收到',
      duration: 2000
    });

    setTimeout(() => {
      router.back();
    }, 1000);
  }

  build() {
    Column() {
      // Navigation Bar
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor('#666')
          .onClick(() => {
            router.back();
          })

        Text('发布帖子')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row({ space: 8 }) {
          Button('保存草稿')
            .fontSize(14)
            .height(32)
            .backgroundColor('#F0F0F0')
            .fontColor('#666')
            .borderRadius(16)
            .onClick(() => {
              this.saveDraft();
            })

          Button('发布')
            .fontSize(14)
            .height(32)
            .backgroundColor((this.content.length > 0 || this.images.length > 0) ? '#FFD700' : '#F0F0F0')
            .fontColor((this.content.length > 0 || this.images.length > 0) ? Color.White : '#999')
            .borderRadius(16)
            .enabled(this.content.length > 0 || this.images.length > 0)
            .onClick(() => {
              this.publishPost();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: '#0D000000', offsetY: 1 })

      // Content Area
      Column() {
        TextArea({ placeholder: '分享你的新鲜事...', text: this.content })
          .width('100%')
          .height(150)
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .margin({ top: 16 })
          .onChange((value: string) => {
            this.content = value;
          })

        // Image Area (Single Image Only)
        if (this.images.length > 0) {
          Stack() {
            Image(this.images[0])
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)
              .borderRadius(12)
            Column() {
              SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
                .fontSize(28)
                .fontColor(['#FF3B30'])
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.End)
            .alignItems(HorizontalAlign.End)
            .padding({ right: 8, bottom: 8 })
            .onClick(() => {
              this.images = [];
            })
          }
          .width('100%')
          .height(200)
          .margin({ top: 16 })
        } else {
          Column() {
            Image($r('app.media.startIcon'))
              .width(40)
              .height(40)
              .margin({ bottom: 8 })
            Text('添加图片')
              .fontSize(14)
              .fontColor('#999')
          }
          .width('100%')
          .height(200)
          .backgroundColor('#F5F5F5')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .margin({ top: 16 })
          .onClick(async () => {
            const imageUri = await this.photoPickerService.selectSingleImage(getContext(this) as common.UIAbilityContext);
            if (imageUri) {
              this.images = [imageUri];
            }
          })
        }

        // Bottom Tools
        Row() {
          Row() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .margin({ right: 6 })
            Text('添加话题')
              .fontSize(14)
              .fontColor('#666')
          }
          .backgroundColor('#F5F5F5')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .padding(16)
      .layoutWeight(1)
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : Color.White)
    // 沉浸式效果：扩展整个页面到顶部和底部安全区域
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
