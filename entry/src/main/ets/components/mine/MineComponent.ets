import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { BreakpointSystem } from '../../utils/BreakpointSystem';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { AppStatistics } from '../../model/AppStatistics';
import { LiquidGlass } from '../common/LiquidGlass';
import { LikeManager } from '../../utils/LikeManager';
import { HistoryManager } from '../../utils/HistoryManager';
import { Post } from '../../model/Post';
import { MyDraftsPanel } from './MyDraftsPanel';
import { MyLikesPanel } from './MyLikesPanel';
import { MyHistoryPanel } from './MyHistoryPanel';
import { DraftManager } from '../../utils/DraftManager';

interface PostItem {
  id: number;
  title: string;
  cover: string;
  author?: string;
  likes: number;
  views: number;
}

interface UserItem {
  id: number;
  name: string;
  avatar: string;
}

@Component
export struct MineComponent {
  @StorageLink('userName') userName: string = '我的名字';
  @StorageLink('userAvatar') userAvatar: string = 'ID_Wa/20260308215703.jpg';
  @StorageLink('userUid') userUid: string = 'U10001';
  @StorageLink('userBio') userBio: string = '记录生活，发现美好';
  @StorageLink('userBg') userBg: string = 'app.media.background';
  @StorageLink('userLevel') userLevel: number = 1;
  @State selectedTab: number = 0;
  @StorageLink('isSidebarOpen') isSidebarOpen: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State statisticsUpdated: number = 0;
  @StorageLink('refreshMineData') @Watch('onRefreshSignal') refreshMineData: number = 0; // 监听刷新信号
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  private appStatistics: AppStatistics = AppStatistics.getInstance();
  private likeManager: LikeManager = LikeManager.getInstance();
  private historyManager: HistoryManager = HistoryManager.getInstance();
  private draftManager: DraftManager = DraftManager.getInstance();
  @State showDraftsPanel: boolean = false;
  @State draftsPanelOffsetX: number = 500;
  @State draftsPanelScale: number = 0.8;
  @State draftsPanelOpacity: number = 0;
  @State showLikesPanel: boolean = false;
  @State likesPanelOffsetX: number = 500;
  @State likesPanelScale: number = 0.8;
  @State likesPanelOpacity: number = 0;
  @State showHistoryPanel: boolean = false;
  @State historyPanelOffsetX: number = 500;
  @State historyPanelScale: number = 0.8;
  @State historyPanelOpacity: number = 0;
  @State backgroundDimOpacity: number = 0;
  @State historyList: Post[] = [];
  @State followList: UserItem[] = [
    { id: 1, name: '设计美学', avatar: 'app.media.startIcon' },
    { id: 2, name: '极简生活', avatar: 'app.media.startIcon' },
    { id: 3, name: '摄影笔记', avatar: 'app.media.startIcon' },
    { id: 4, name: '读书会', avatar: 'app.media.startIcon' },
    { id: 5, name: '美食探店', avatar: 'app.media.startIcon' },
    { id: 6, name: '旅行达人', avatar: 'app.media.startIcon' },
  ];
  @State likedList: Post[] = [];
  @State isRefreshingLikes: boolean = false;
  @State isRefreshingHistory: boolean = false;

  private formatLikes(likes: number): string {
    if (likes >= 10000) {
      return `${(likes / 10000).toFixed(1)}w`;
    } else if (likes >= 1000) {
      return `${(likes / 1000).toFixed(1)}k`;
    }
    return `${likes}`;
  }

  aboutToAppear() {
    this.breakpointSystem.register();
    this.draftManager.init(getContext(this));
    this.statisticsUpdated = Date.now();
    this.loadLikedPosts();
    this.loadHistoryPosts();
  }

  private openDraftsPanel(): void {
    this.showDraftsPanel = true;
    this.draftsPanelScale = 0.8;
    this.draftsPanelOpacity = 0;
    this.backgroundDimOpacity = 0;

    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn,
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      this.draftsPanelOffsetX = 0;
      this.draftsPanelScale = 1;
      this.draftsPanelOpacity = 1;
      this.backgroundDimOpacity = 1;
    });
  }

  private closeDraftsPanel(): void {
    animateTo({
      duration: 300,
      curve: Curve.FastOutSlowIn,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.showDraftsPanel = false;
      }
    }, () => {
      this.draftsPanelOffsetX = 500;
      this.draftsPanelScale = 0.8;
      this.draftsPanelOpacity = 0;
      this.backgroundDimOpacity = 0;
    });
  }

  private openLikesPanel(): void {
    this.showLikesPanel = true;
    this.likesPanelScale = 0.8;
    this.likesPanelOpacity = 0;
    this.backgroundDimOpacity = 0;

    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn,
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      this.likesPanelOffsetX = 0;
      this.likesPanelScale = 1;
      this.likesPanelOpacity = 1;
      this.backgroundDimOpacity = 1;
    });
  }

  private closeLikesPanel(): void {
    animateTo({
      duration: 300,
      curve: Curve.FastOutSlowIn,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.showLikesPanel = false;
      }
    }, () => {
      this.likesPanelOffsetX = 500;
      this.likesPanelScale = 0.8;
      this.likesPanelOpacity = 0;
      this.backgroundDimOpacity = 0;
    });
  }

  private openHistoryPanel(): void {
    this.showHistoryPanel = true;
    this.historyPanelScale = 0.8;
    this.historyPanelOpacity = 0;
    this.backgroundDimOpacity = 0;

    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn,
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      this.historyPanelOffsetX = 0;
      this.historyPanelScale = 1;
      this.historyPanelOpacity = 1;
      this.backgroundDimOpacity = 1;
    });
  }

  private closeHistoryPanel(): void {
    animateTo({
      duration: 300,
      curve: Curve.FastOutSlowIn,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.showHistoryPanel = false;
      }
    }, () => {
      this.historyPanelOffsetX = 500;
      this.historyPanelScale = 0.8;
      this.historyPanelOpacity = 0;
      this.backgroundDimOpacity = 0;
    });
  }

  // 监听刷新信号
  onRefreshSignal() {
    if (this.refreshMineData > 0) {
      this.statisticsUpdated = Date.now();
      this.loadLikedPosts();
      this.loadHistoryPosts();
    }
  }

  private loadLikedPosts(): void {
    this.likedList = this.likeManager.getLikedPosts();
  }

  private loadHistoryPosts(): void {
    this.historyList = this.historyManager.getHistoryPosts();
  }

  private refreshLikedPosts(): void {
    if (this.isRefreshingLikes) {
      return;
    }
    this.isRefreshingLikes = true;

    setTimeout(() => {
      this.loadLikedPosts();
      this.isRefreshingLikes = false;
      promptAction.showToast({
        message: '刷新成功',
        duration: 1500
      });
    }, 500);
  }

  private refreshHistoryPosts(): void {
    if (this.isRefreshingHistory) {
      return;
    }
    this.isRefreshingHistory = true;

    setTimeout(() => {
      this.loadHistoryPosts();
      this.isRefreshingHistory = false;
      promptAction.showToast({
        message: '刷新成功',
        duration: 1500
      });
    }, 500);
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
  }

  @Builder
  LeftSidebar() {
    Column() {
      Row() {
        if (this.userAvatar.startsWith('app.media.')) {
          Image($r(this.userAvatar))
            .width(60)
            .height(60)
            .borderRadius(30)
            .margin({ right: 12 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/mine/EditProfilePage' });
            })
        } else {
          Image($rawfile(this.userAvatar))
            .width(60)
            .height(60)
            .borderRadius(30)
            .margin({ right: 12 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/mine/EditProfilePage' });
            })
        }

        Column() {
          Row() {
            Text(this.userName)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 4 })
            Text(`Lv.${this.userLevel}`)
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor('#FFD700')
              .borderRadius(4)
              .padding({ left: 4, right: 4 })
              .margin({ left: 4, bottom: 4 })
          }

          Text(this.userBio)
            .fontSize(12)
            .fontColor('#999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(20)

      Column() {
        Row() {
          Column() {
            Text(this.appStatistics.noteCount.toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
            Text('笔记')
              .fontSize(12)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
          }
          .layoutWeight(1)

          Column() {
            Text(this.appStatistics.followCount.toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
            Text('关注')
              .fontSize(12)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
          }
          .layoutWeight(1)

          Column() {
            Text(this.appStatistics.likeCount.toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
            Text('获赞')
              .fontSize(12)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
      }
      .width('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F8F8F8')
      .borderRadius(12)
      .margin({ left: 16, right: 16, bottom: 20 })

      Column() {
        Column() {
          Text('创作中心')
            .fontSize(14)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
            .fontWeight(FontWeight.Bold)
          Text('发布笔记，分享你的生活')
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F8F8F8')
        .borderRadius(12)

        Button('去发布')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#7B68EE')
          .height(44)
          .width('40%')
          .onClick(() => {
            router.pushUrl({ url: 'pages/CreatePostPage' });
          })
      }
      .width('90%')
      .margin({ bottom: 20 })

      List() {
        ListItem() {
          this.MenuHeader('我的服务')
        }

        ListItem() {
          this.MenuItem('浏览记录', 'sys.symbol.clock', false, () => {
            if (['md', 'lg', 'xl'].includes(this.currentBreakpoint)) {
              this.openHistoryPanel();
            } else {
              promptAction.showToast({
                message: '请在大屏设备上使用此功能',
                duration: 2000
              });
            }
          })
        }

        ListItem() {
          this.MenuItem('我的点赞', 'sys.symbol.heart', false, () => {
            if (['md', 'lg', 'xl'].includes(this.currentBreakpoint)) {
              this.openLikesPanel();
            } else {
              promptAction.showToast({
                message: '请在大屏设备上使用此功能',
                duration: 2000
              });
            }
          })
        }

        ListItem() {
          this.MenuHeader('更多功能')
        }

        ListItem() {
          this.MenuItem('我的草稿', 'sys.symbol.doc', false, () => {
            if (['md', 'lg', 'xl'].includes(this.currentBreakpoint)) {
              this.openDraftsPanel();
            } else {
              promptAction.showToast({
                message: '请在大屏设备上使用此功能',
                duration: 2000
              });
            }
          })
        }

        ListItem() {
          this.MenuItem('设置', 'sys.symbol.gear', false, () => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .border({
      width: { right: 1 },
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : '#EEE'
    })
  }

  @Builder
  MenuHeader(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
      .padding({ left: 20, top: 16, bottom: 8 })
      .width('100%')
  }

  @Builder
  MenuItem(title: string, icon: string, isActive: boolean = false, onClick?: () => void) {
    Row() {
      SymbolGlyph($r(icon))
        .fontSize(22)
        .fontColor([isActive ? '#7B68EE' :
          (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666')])
        .margin({ right: 12 })
      Text(title)
        .fontSize(15)
        .fontColor(isActive ? '#7B68EE' :
          (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333'))
        .fontWeight(isActive ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
    .backgroundColor(isActive ?
      (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123,104,238,0.1)' : '#E8E4FF') :
      Color.Transparent)
    .onClick(() => {
      if (onClick) {
        onClick();
      }
    })
  }

  @Builder
  RightContent() {
    Column() {
      Row() {
        Text('个人中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
        Blank()
        SymbolGlyph($r('sys.symbol.gearshape'))
          .fontSize(24)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999'])
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 20,
        bottom: 10
      })

      Scroll() {
        Column({ space: 24 }) {
          Column() {
            this.SectionHeader('浏览历史', true, () => this.refreshHistoryPosts(), this.isRefreshingHistory)
            List({ space: 12 }) {
              ForEach(this.historyList, (item: Post) => {
                ListItem() {
                  this.PostCard(item)
                }
              }, (item: Post) => item.id)
            }
            .listDirection(Axis.Horizontal)
            .width('100%')
            .height(220)
            .scrollBar(BarState.Off)
            .padding({ left: 20, right: 20 })
          }

          Column() {
            this.SectionHeader('我的点赞', true, () => this.refreshLikedPosts(), this.isRefreshingLikes)
            List({ space: 12 }) {
              ForEach(this.likedList, (item: Post) => {
                ListItem() {
                  this.PostCard(item)
                }
              }, (item: Post) => item.id)
            }
            .listDirection(Axis.Horizontal)
            .width('100%')
            .height(220)
            .scrollBar(BarState.Off)
            .padding({ left: 20, right: 20 })
          }
        }
        .padding({ bottom: 40 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SectionHeader(title: string, showRefresh: boolean = false, onRefresh: () => void = () => {
  }, isRefreshing: boolean = false) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
      Blank()
      if (showRefresh) {
        Row() {
          if (isRefreshing) {
            LoadingProgress()
              .width(16)
              .height(16)
              .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
          } else {
            SymbolGlyph($r('sys.symbol.arrow_clockwise'))
              .fontSize(16)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999'])
          }
          Text(isRefreshing ? '刷新中' : '刷新')
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
            .margin({ left: 4 })
        }
        .padding({
          left: 8,
          right: 8,
          top: 4,
          bottom: 4
        })
        .borderRadius(12)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)')
        .onClick(() => {
          if (!isRefreshing) {
            onRefresh();
          }
        })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 12 })
  }

  @Builder
  PostItemCard(item: PostItem) {
    Column() {
      Image($r(item.cover))
        .width(160)
        .height(140)
        .borderRadius({ topLeft: 12, topRight: 12 })
        .objectFit(ImageFit.Cover)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#EEE')

      Column() {
        Text(item.title)
          .fontSize(13)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
          .width('100%')

        Row() {
          Row() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(12)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999'])
              .margin({ right: 2 })
            Text(item.author || '匿名用户')
              .fontSize(11)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.heart'))
            .fontSize(13)
            .fontColor(['#FF3B30'])
            .margin({ right: 2 })
          Text(this.formatLikes(item.likes))
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
      }
      .padding({
        left: 10,
        right: 10,
        top: 10,
        bottom: 10
      })
      .width('100%')
    }
    .width(160)
    .height(200)
    .borderRadius(12)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F8F8F8')
    .margin({ right: 8 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/PostDetailPage',
        params: { id: item.id }
      })
    })
  }

  @Builder
  PostCard(item: Post) {
    Column() {
      if (item.images.length > 0) {
        Image(item.images[0].startsWith('app.media.') ? $r(item.images[0]) : $rawfile(item.images[0]))
          .width(160)
          .height(140)
          .borderRadius({ topLeft: 12, topRight: 12 })
          .objectFit(ImageFit.Cover)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#EEE')
      } else {
        Column() {
          Text(item.title || item.content)
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
            .maxLines(6)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(18)
            .width('100%')
        }
        .width(160)
        .height(140)
        .borderRadius({ topLeft: 12, topRight: 12 })
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#2C2C2E' : '#EEE')
        .justifyContent(FlexAlign.Center)
        .padding(12)
      }

      Column() {
        Text(item.title || item.content)
          .fontSize(13)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
          .width('100%')

        Row() {
          Row() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(12)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999'])
              .margin({ right: 2 })
            Text(item.userName)
              .fontSize(11)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.heart'))
            .fontSize(13)
            .fontColor(['#FF3B30'])
            .margin({ right: 2 })
          Text(this.formatLikes(item.likes))
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
      }
      .padding({
        left: 10,
        right: 10,
        top: 10,
        bottom: 10
      })
      .width('100%')
    }
    .width(160)
    .height(200)
    .borderRadius(12)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#F8F8F8')
    .margin({ right: 8 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/PostDetailPage',
        params: { id: item.id }
      })
    })
  }

  @Builder
  MobileContent() {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 12 }) {
          this.MobileProfileHeader()
          this.MobileStatsSection()
          this.MobileActionSection()
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        Column({ space: 12 }) {
          LiquidGlass({
            glassRadius: 24,
            blurRadius: 20,
            glassPadding: { top: 16, bottom: 16 },
            glassColor: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
              ? 'rgba(35, 35, 35, 0.55)'
              : 'rgba(205, 205, 205, 0.38)'
          }) {
            Column() {
              this.SectionHeader('浏览历史', true, () => this.refreshHistoryPosts(), this.isRefreshingHistory)
              List({ space: 12 }) {
                ForEach(this.historyList, (item: Post) => {
                  ListItem() {
                    this.PostCard(item)
                  }
                }, (item: Post) => item.id)
              }
              .listDirection(Axis.Horizontal)
              .width('100%')
              .height(220)
              .scrollBar(BarState.Off)
              .padding({ left: 16, right: 16 })
            }
            .width('100%')
          }

          LiquidGlass({
            glassRadius: 24,
            blurRadius: 20,
            glassPadding: { top: 16, bottom: 16 },
            glassColor: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
              ? 'rgba(35, 35, 35, 0.55)'
              : 'rgba(205, 205, 205, 0.38)'
          }) {
            Column() {
              this.SectionHeader('我的点赞', true, () => this.refreshLikedPosts(), this.isRefreshingLikes)
              List({ space: 12 }) {
                ForEach(this.likedList, (item: Post) => {
                  ListItem() {
                    this.PostCard(item)
                  }
                }, (item: Post) => item.id)
              }
              .listDirection(Axis.Horizontal)
              .width('100%')
              .height(220)
              .scrollBar(BarState.Off)
              .padding({ left: 16, right: 16 })
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .padding({ bottom: 32, top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  MobileProfileHeader() {
    LiquidGlass({
      glassRadius: 24,
      blurRadius: 30,
      glassColor: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
        ? 'rgba(40, 40, 40, 0.6)'
        : 'rgba(200, 200, 200, 0.4)'
    }) {
      Column({ space: 16 }) {
        Row() {
          if (this.userAvatar.startsWith('app.media.')) {
            Image($r(this.userAvatar))
              .width(88)
              .height(88)
              .borderRadius(44)
              .border({
                width: 4,
                color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.3)' :
                  'rgba(255,255,255,0.8)'
              })
              .onClick(() => {
                router.pushUrl({ url: 'pages/mine/EditProfilePage' });
              })
          } else {
            Image($rawfile(this.userAvatar))
              .width(88)
              .height(88)
              .borderRadius(44)
              .border({
                width: 4,
                color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.3)' :
                  'rgba(255,255,255,0.8)'
              })
              .onClick(() => {
                router.pushUrl({ url: 'pages/mine/EditProfilePage' });
              })
          }

          Column() {
            Text(this.userName)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#1C1C1E')
              .onClick(() => {
                router.pushUrl({ url: 'pages/mine/EditProfilePage' });
              })
            Text(`Lv.${this.userLevel} · ${this.userBio}`)
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#8E8E93' : '#8E8E93')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(20)
    }
  }

  @Builder
  MobileStatsSection() {
    LiquidGlass({
      glassRadius: 16,
      blurRadius: 20,
      glassColor: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
        ? 'rgba(45, 45, 45, 0.55)'
        : 'rgba(210, 210, 210, 0.35)'
    }) {
      Row() {
        Column() {
          Text(this.appStatistics.noteCount.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
          Text('笔记')
            .fontSize(13)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
        }
        .layoutWeight(1)

        Column() {
          Text(this.appStatistics.likeCount.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
          Text('获赞')
            .fontSize(13)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
        }
        .layoutWeight(1)

        Column() {
          Text(this.appStatistics.followCount.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
          Text('关注')
            .fontSize(13)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 20, bottom: 20 })
    }
  }

  @Builder
  MobileActionSection() {
    Row({ space: 12 }) {
      Column() {
        LiquidGlass({
          glassRadius: 12,
          blurRadius: 15,
          glassWidth: '100%',
          glassColor: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
            ? 'rgba(50, 50, 50, 0.5)'
            : 'rgba(220, 220, 220, 0.3)'
        }) {
          Column() {
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(24)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333'])
              .margin({ bottom: 6 })
            Text('去发布')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
          }
          .width('100%')
          .padding({ top: 18, bottom: 18 })
        }
      }
      .layoutWeight(1)
      .onClick(() => {
        router.pushUrl({ url: 'pages/CreatePostPage' });
      })

      Column() {
        LiquidGlass({
          glassRadius: 12,
          blurRadius: 15,
          glassWidth: '100%',
          glassColor: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
            ? 'rgba(50, 50, 50, 0.5)'
            : 'rgba(220, 220, 220, 0.3)'
        }) {
          Column() {
            SymbolGlyph($r('sys.symbol.gearshape'))
              .fontSize(24)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333'])
              .margin({ bottom: 6 })
            Text('编辑资料')
              .fontSize(14)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
          }
          .width('100%')
          .padding({ top: 18, bottom: 18 })
        }
      }
      .layoutWeight(1)
      .onClick(() => {
        router.pushUrl({ url: 'pages/mine/EditProfilePage' });
      })
    }
    .width('100%')
  }

  @Builder
  RadialDimBackground() {
    Column()
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 180,
        colors: [
          ['rgba(0, 0, 0, 0.6)', 0.0],
          ['rgba(0, 0, 0, 0.35)', 0.5],
          ['rgba(0, 0, 0, 0.6)', 1.0]
        ]
      })
      .opacity(this.backgroundDimOpacity)
      .animation({ duration: 300, curve: Curve.FastOutSlowIn })
  }

  @Builder
  DraftsPanelSlide() {
    Column() {
      LiquidGlass({
        glassWidth: '100%',
        glassHeight: '100%',
        glassPadding: 0,
        glassRadius: 32,
        blurRadius: 24,
        showBorder: true
      }) {
        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(26)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
              .onClick(() => {
                this.closeDraftsPanel();
              })
            Blank()
            Text('我的草稿')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            Blank()
            Column()
              .width(26)
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24,
            top: 24,
            bottom: 16
          })

          MyDraftsPanel()
        }
        .width('100%')
        .height('100%')
      }
    }
    .width(400)
    .height('92%')
    .margin({ top: 16, bottom: 16, right: 16 })
    .translate({ x: this.draftsPanelOffsetX })
    .scale({ x: this.draftsPanelScale, y: this.draftsPanelScale })
    .opacity(this.draftsPanelOpacity)
    .zIndex(100)
    .backgroundColor(Color.Transparent)
  }

  @Builder
  LikesPanelSlide() {
    Column() {
      LiquidGlass({
        glassWidth: '100%',
        glassHeight: '100%',
        glassPadding: 0,
        glassRadius: 32,
        blurRadius: 24,
        showBorder: true
      }) {
        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(26)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
              .onClick(() => {
                this.closeLikesPanel();
              })
            Blank()
            Text('我的点赞')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            Blank()
            Column()
              .width(26)
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24,
            top: 24,
            bottom: 16
          })

          MyLikesPanel()
        }
        .width('100%')
        .height('100%')
      }
    }
    .width(400)
    .height('92%')
    .margin({ top: 16, bottom: 16, right: 16 })
    .translate({ x: this.likesPanelOffsetX })
    .scale({ x: this.likesPanelScale, y: this.likesPanelScale })
    .opacity(this.likesPanelOpacity)
    .zIndex(100)
    .backgroundColor(Color.Transparent)
  }

  @Builder
  HistoryPanelSlide() {
    Column() {
      LiquidGlass({
        glassWidth: '100%',
        glassHeight: '100%',
        glassPadding: 0,
        glassRadius: 32,
        blurRadius: 24,
        showBorder: true
      }) {
        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(26)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
              .onClick(() => {
                this.closeHistoryPanel();
              })
            Blank()
            Text('浏览记录')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            Blank()
            Column()
              .width(26)
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24,
            top: 24,
            bottom: 16
          })

          MyHistoryPanel()
        }
        .width('100%')
        .height('100%')
      }
    }
    .width(400)
    .height('92%')
    .margin({ top: 16, bottom: 16, right: 16 })
    .translate({ x: this.historyPanelOffsetX })
    .scale({ x: this.historyPanelScale, y: this.historyPanelScale })
    .opacity(this.historyPanelOpacity)
    .zIndex(100)
    .backgroundColor(Color.Transparent)
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      if (['md', 'lg', 'xl'].includes(this.currentBreakpoint)) {
        Row() {
          Column() {
            this.LeftSidebar()
          }
          .width(300)
          .height('100%')

          Column() {
            this.RightContent()
          }
          .layoutWeight(1)
          .height('100%')
        }
        .width('100%')
        .height('100%')

        if (this.showDraftsPanel || this.showLikesPanel || this.showHistoryPanel) {
          this.RadialDimBackground()
          Column() {
            Blank()
          }
          .width('100%')
          .height('100%')
          .onClick(() => {
            if (this.showDraftsPanel) {
              this.closeDraftsPanel();
            } else if (this.showLikesPanel) {
              this.closeLikesPanel();
            } else if (this.showHistoryPanel) {
              this.closeHistoryPanel();
            }
          })

          if (this.showDraftsPanel) {
            this.DraftsPanelSlide()
          }
          if (this.showLikesPanel) {
            this.LikesPanelSlide()
          }
          if (this.showHistoryPanel) {
            this.HistoryPanelSlide()
          }
        }
      } else {
        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.list_bullet'))
              .width(28)
              .height(28)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1C1C1E'])
              .onClick(() => {
                animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
                  this.isSidebarOpen = true;
                })
              })

            Text('我的')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#1C1C1E')
              .margin({ left: 12 })

            Blank()

            SymbolGlyph($r('sys.symbol.gearshape'))
              .width(28)
              .height(28)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1C1C1E'])
              .onClick(() => {
                router.pushUrl({ url: 'pages/SettingsPage' });
              })
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })

          this.MobileContent()
        }
        .width('100%')
        .height('100%')

        if (this.showDraftsPanel || this.showLikesPanel || this.showHistoryPanel) {
          this.RadialDimBackground()
          Column() {
            Blank()
          }
          .width('100%')
          .height('100%')
          .onClick(() => {
            if (this.showDraftsPanel) {
              this.closeDraftsPanel();
            } else if (this.showLikesPanel) {
              this.closeLikesPanel();
            } else if (this.showHistoryPanel) {
              this.closeHistoryPanel();
            }
          })

          if (this.showDraftsPanel) {
            this.DraftsPanelSlide()
          }
          if (this.showLikesPanel) {
            this.LikesPanelSlide()
          }
          if (this.showHistoryPanel) {
            this.HistoryPanelSlide()
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    }
  }