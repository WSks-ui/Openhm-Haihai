import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { Post } from '../../model/Post';
import { LikeManager } from '../../utils/LikeManager';

@Component
export struct MyLikesPanel {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State likedList: Post[] = [];
  @State isLoading: boolean = true;
  private likeManager: LikeManager = LikeManager.getInstance();

  aboutToAppear() {
    this.loadLikedPosts();
  }

  private loadLikedPosts() {
    this.isLoading = true;
    this.likedList = this.likeManager.getLikedPosts();
    this.isLoading = false;
  }

  private formatLikes(likes: number): string {
    if (likes >= 10000) {
      return `${(likes / 10000).toFixed(1)}w`;
    } else if (likes >= 1000) {
      return `${(likes / 1000).toFixed(1)}k`;
    }
    return `${likes}`;
  }

  private viewPostDetail(post: Post) {
    router.pushUrl({
      url: 'pages/PostDetailPage',
      params: {
        postId: post.id,
        post: post
      }
    });
  }

  private unlikePost(post: Post) {
    this.likeManager.toggleLike(post);
    promptAction.showToast({
      message: '已取消点赞',
      duration: 1500
    });
    this.loadLikedPosts();
  }

  @Builder
  EmptyState() {
    Column({ space: 16 }) {
      Image($r('app.media.startIcon'))
        .width(64)
        .height(64)
      
      Text('暂无点赞')
        .fontSize(16)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
      
      Text('你点赞的帖子将显示在这里')
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#BBB')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  PostCard(post: Post) {
    Column() {
      Row({ space: 12 }) {
        if (post.images.length > 0) {
          Image(post.images[0].startsWith('app.media.') ? $r(post.images[0]) : $rawfile(post.images[0]))
            .width(80)
            .height(80)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#EEE')
        }
        
        Column({ space: 8 }) {
          Text(post.content || '无内容')
            .fontSize(15)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(22)
            .width('100%')
          
          Row({ space: 16 }) {
            Row({ space: 4 }) {
              Image($r('app.media.startIcon'))
                .width(14)
                .height(14)
              Text(this.formatLikes(post.likes))
                .fontSize(12)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
            }
            
            Row({ space: 4 }) {
              Image($r('app.media.startIcon'))
                .width(14)
                .height(14)
              Text(post.time)
                .fontSize(12)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Row({ space: 8 }) {
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.unlikePost(post);
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
      this.viewPostDetail(post);
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
      } else if (this.likedList.length === 0) {
        this.EmptyState()
      } else {
        List({ space: 12 }) {
          ForEach(this.likedList, (post: Post) => {
            ListItem() {
              this.PostCard(post)
            }
          }, (post: Post) => post.id)
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