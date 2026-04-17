import router from '@ohos.router';
import { Post, mockPosts, Comment, currentKeplerPost } from '../model/Post';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { LikeManager } from '../utils/LikeManager';
import { HistoryManager } from '../utils/HistoryManager';
import { currentUser } from '../model/User';
import { ANIM_INSTANT, ANIM_FAST, ANIM_NORMAL, CURVE_TRANSITION } from '../constants/ThemeTokens';

/**
 * PostDetailPage - 帖子详情页面
 * 
 * 沉浸式效果实现：
 * 1. 使用全局安全区域高度避开状态栏
 * 2. expandSafeArea 扩展页面到安全区域
 */

@Entry
@Component
struct PostDetailPage {
  @State postId: string = '1';
  @State post: Post | undefined = undefined;
  @State isLiked: boolean = false;
  @State likeScale: number = 1;
  @State commentText: string = '';
  @State comments: Comment[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageProp('currentGrayscaleMode') isGrayscaleMode: boolean = false;
  
  private likeManager: LikeManager = LikeManager.getInstance();
  private historyManager: HistoryManager = HistoryManager.getInstance();
  
  // 沉浸式效果：安全区域高度
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;

  private formatLikes(likes: number): string {
    if (likes >= 10000) {
      return `${(likes / 10000).toFixed(1)}w`;
    } else if (likes >= 1000) {
      return `${(likes / 1000).toFixed(1)}k`;
    }
    return `${likes}`;
  }

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['id']) {
      this.postId = params['id'];
      // Try finding in mockPosts first, then check currentKeplerPost
      this.post = mockPosts.find(p => p.id === this.postId);
      
      if (!this.post && currentKeplerPost && currentKeplerPost.id === this.postId) {
        this.post = currentKeplerPost;
      }

      if (this.post) {
        this.isLiked = this.likeManager.isPostLiked(this.postId);
        this.comments = this.post.commentList || [];
        this.historyManager.addToHistory(this.postId);
      }
    }
  }

  @Builder
  CommentItem(comment: Comment) {
    Row() {
      Image(comment.userAvatar.startsWith('app.media.') ? $r(comment.userAvatar) : $rawfile(comment.userAvatar))
        .width(32)
        .height(32)
        .borderRadius(16)
        .margin({ right: 12 })
        .objectFit(ImageFit.Cover)
      
      Column() {
        Text(comment.userName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
          .margin({ bottom: 4 })
        
        Text(comment.content)
          .fontSize(14)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#BBBBBB' : '#555')
          .margin({ bottom: 4 })
        
        Text(comment.time)
          .fontSize(12)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column() {
        SymbolGlyph($r('sys.symbol.heart'))
          .fontSize(16)
          .fontColor([this.likeManager.isCommentLiked(comment.id) ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')])
        Text(comment.likes.toString())
          .fontSize(12)
          .fontColor(this.likeManager.isCommentLiked(comment.id) ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'))
          .margin({ top: 2 })
      }
      .onClick(() => {
        this.likeManager.toggleCommentLike(comment);
      })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  build() {
    Stack() {
      Column() {
        // Top Bar (Overlay style)
        Row() {
          Image($r('app.media.icon_home'))
            .width(24)
            .height(24)
            .onClick(() => {
              router.back();
            })
            .fillColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#000000')
          
          Blank()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
        .zIndex(10)

        if (this.post) {
          if (['lg', 'xl'].includes(this.currentBreakpoint)) {
            // Large Screen Layout
            if (this.post.images.length > 0) {
              // Split View for posts with images
              Row() {
                 // Left: Image
                 Column() {
                   Image(this.post.images[0].startsWith('app.media.') ? $r(this.post.images[0]) : $rawfile(this.post.images[0]))
                     .width('100%')
                     .height('100%')
                     .objectFit(ImageFit.Cover)
                     .sharedTransition(this.post.id, { duration: ANIM_NORMAL, curve: Curve.EaseInOut })
                 }
                 .width('60%')
                 .height('100%')
                 .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F5F5F5')
                 .justifyContent(FlexAlign.Center)

                 // Right: Content
                 Scroll() {
                   this.PostContent()
                 }
                 .width('40%')
                 .height('100%')
                 .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
                 .scrollBar(BarState.Off)
              }
              .width('100%')
              .layoutWeight(1) // Occupy remaining space
            } else {
              // Single Column for text-only posts (Split View: Left 2/3 Content, Right 1/3 Comments)
              Row() {
                 Scroll() {
                    this.PostInfo()
                 }
                 .width('66%')
                 .height('100%')
                 .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
                 .padding({ right: 20 })
                 .scrollBar(BarState.Off)

                 Divider()
                   .vertical(true)
                   .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F0F0F0')
                   .strokeWidth(1)
                   .height('100%')

                 Column() {
                    this.CommentList()
                 }
                 .width('34%')
                 .alignItems(HorizontalAlign.Start)
                 .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
              .layoutWeight(1) // Occupy remaining space
            }
          } else {
            // Mobile Layout (Vertical)
            Scroll() {
              Column() {
                if (this.post.images.length > 0) {
                  Image(this.post.images[0].startsWith('app.media.') ? $r(this.post.images[0]) : $rawfile(this.post.images[0]))
                    .width('100%')
                    .height(400)
                    .objectFit(ImageFit.Cover)
                    .sharedTransition(this.post.id, { duration: ANIM_NORMAL, curve: Curve.EaseInOut })
                }
                this.PostContent()
              }
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
        } else {
          Column() {
            Text('Post not found')
          }.width('100%').height('100%').justifyContent(FlexAlign.Center)
        }

        // Bottom Comment Bar
        Row() {
          TextInput({ placeholder: '写下你的评论...', text: this.commentText })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F5F5F5')
            .borderRadius(20)
            .padding({ left: 16 })
            .onChange((value: string) => {
              this.commentText = value;
            })
          
          if (this.commentText.length > 0) {
            Text('发送')
              .fontColor('#FFD700')
              .fontWeight(FontWeight.Bold)
              .margin({ left: 12 })
              .onClick(() => {
                if (this.post) {
                  const newComment = new Comment(`nc_${Date.now()}`, currentUser.username, currentUser.avatar, this.commentText, '刚刚', 0);
                  this.comments.unshift(newComment);
                  this.post.commentsCount += 1;
                  this.commentText = '';
                }
              })
          } else {
             Row() {
               Column() {
                  SymbolGlyph($r('sys.symbol.heart'))
                    .fontSize(22)
                    .fontColor([this.isLiked ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')])
                    .scale({ x: this.likeScale, y: this.likeScale })
                  Text(this.post ? this.formatLikes(this.post.likes) : '0')
                    .fontSize(11)
                    .fontColor(this.isLiked ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'))
                    .margin({ top: 2 })
               }
               .onClick(() => {
                 if (this.post) {
                   this.likeScale = 1.3;
                   animateTo({ duration: ANIM_INSTANT, curve: Curve.EaseOut }, () => {
                     this.likeScale = 1.3;
                   });
                   animateTo({ duration: ANIM_FAST, curve: Curve.EaseIn, delay: 100 }, () => {
                     this.likeScale = 0.9;
                   });
                   animateTo({ duration: ANIM_INSTANT, curve: Curve.EaseOut, delay: 250 }, () => {
                     this.likeScale = 1;
                   });
                   
                   this.isLiked = this.likeManager.toggleLike(this.post);
                 }
               })
               .margin({ left: 16 })

               Column() {
                  SymbolGlyph($r('sys.symbol.message'))
                    .fontSize(22)
                    .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'])
                  Text(this.post ? this.formatLikes(this.post.commentsCount) : '0')
                    .fontSize(11)
                    .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
                    .margin({ top: 2 })
               }
               .margin({ left: 20 })
             }
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 + this.safeAreaBottom })
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : Color.White)
        .shadow({ radius: 10, color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : '#0D000000', offsetY: -2 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : Color.White)
      // 沉浸式效果：扩展整个页面到顶部和底部安全区域
      .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 灰色模式滤镜层
      if (this.isGrayscaleMode) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#808080')
          .blendMode(BlendMode.SATURATION)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CommentList() {
    Column() {
      // Comments Section
      Text(`共 ${this.comments.length} 条评论`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
        .padding(16)
      
      List() {
        ForEach(this.comments, (comment: Comment) => {
          ListItem() {
            this.CommentItem(comment)
          }
        }, (item: Comment) => item.id)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 20 })
      .layoutWeight(1)
      .divider({
        strokeWidth: 1,
        color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F0F0F0',
        startMargin: 60
      })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%') // Ensure width is 100% of parent container
    .height('100%')
  }

  @Builder
  PostInfo() {
    Column() {
      // User Info
      Row() {
        Image(this.post!.userAvatar.startsWith('app.media.') ? $r(this.post!.userAvatar) : $rawfile(this.post!.userAvatar))
          .width(40)
          .height(40)
          .borderRadius(20)
          .margin({ right: 12 })
        
        Column() {
          Text(this.post!.userName)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333')
          Text(this.post!.time)
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('关注')
          .fontSize(12)
          .height(28)
          .backgroundColor('#FFD700')
          .fontColor(Color.White)
          .borderRadius(14)
      }
      .width('100%')
      .padding(16)

      // Post Text
      if (this.post!.title) {
         Text(this.post!.title)
           .fontSize(18)
           .fontWeight(FontWeight.Bold)
           .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333')
           .padding({ left: 16, right: 16, bottom: 8 })
      }
      
      Text(this.post!.content)
        .fontSize(16)
        .lineHeight(24)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#555')
        .padding({ left: 16, right: 16, bottom: 20 })
    }
    .width('100%') // Ensure width is 100% of parent container
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PostContent() {
    Column() {
      this.PostInfo()

      Divider()
        .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#F0F0F0')
        .strokeWidth(8)

      this.CommentList()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
