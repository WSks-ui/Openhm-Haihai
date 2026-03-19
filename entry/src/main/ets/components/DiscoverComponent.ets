import router from '@ohos.router';
import { BreakpointSystem } from '../utils/BreakpointSystem';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { mockPosts, Post } from '../model/Post';
import { LiquidGlass } from './LiquidGlass';
import { aiSummaryService } from '../utils/AISummaryService';
import { LikeManager } from '../utils/LikeManager';

interface TopicItem {
  id: string;
  title: string;
  discussCount: number;
  isNew: boolean;
}

interface TopicCircle {
  id: number;
  name: string;
  icon: string;
  memberCount: number;
  color: string;
}

@Component
struct FeatureCardComponent {
  @State pressed: boolean = false;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  title: string = '';
  icon: string = '';
  iconColor: string = '';
  url: string = '';

  build() {
    Column() {
      SymbolGlyph($r(this.icon))
        .fontSize(36)
        .fontColor([this.iconColor])
        .margin({ bottom: 10 })
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
    }
    .width('100%')
    .height(110)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : '#FFFFFF')
    .borderRadius(24)
    .shadow({
      radius: 8,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.04)',
      offsetY: 2
    })
    .scale({ x: this.pressed ? 0.96 : 1, y: this.pressed ? 0.96 : 1 })
    .animation({ duration: 150, curve: Curve.EaseInOut })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      router.pushUrl({ url: this.url })
    })
  }
}

@Component
struct HotTopicItemComponent {
  @State pressed: boolean = false;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  item: TopicItem = { id: '', title: '', discussCount: 0, isNew: false };
  index: number = 0;
  openDetailPanel?: (post: Post) => void;

  build() {
    Row() {
      Text(`${this.index + 1}`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.index < 3 ? '#FFD700' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666666' : '#999999'))
        .width(40)
        .textAlign(TextAlign.Center)
        .margin({ right: 14 })

      Column({ space: 6 }) {
        Row() {
          Text(this.item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          
          if (this.item.isNew) {
            Text('NEW')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('#FF6B6B')
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(6)
              .margin({ left: 10 })
          }
        }
        .width('100%')
        
        Text(`${this.item.discussCount} 讨论`)
          .fontSize(13)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#888888')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.06)' : '#FFFFFF')
    .borderRadius(20)
    .shadow({
      radius: 8,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.15)' : 'rgba(0,0,0,0.03)',
      offsetY: 2
    })
    .alignItems(VerticalAlign.Center)
    .scale({ x: this.pressed ? 0.98 : 1, y: this.pressed ? 0.98 : 1 })
    .animation({ duration: 150, curve: Curve.EaseInOut })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      if (['md', 'lg', 'xl'].includes(this.currentBreakpoint)) {
        const post = mockPosts.find(p => p.id === this.item.id);
        if (post && this.openDetailPanel) {
          this.openDetailPanel(post);
        }
      } else {
        router.pushUrl({
          url: 'pages/PostDetailPage',
          params: { id: this.item.id.toString() }
        })
      }
    })
  }
}

@Component
struct HotTopicGridItemComponent {
  @State pressed: boolean = false;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  item: TopicItem = { id: '', title: '', discussCount: 0, isNew: false };
  index: number = 0;
  openDetailPanel?: (post: Post) => void;

  build() {
    Column({ space: 10 }) {
      Row() {
        Text(`${this.index + 1}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.index < 3 ? '#FFD700' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666666' : '#999999'))
        Blank()
        if (this.item.isNew) {
          Text('NEW')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor('#FF6B6B')
            .padding({ left: 6, right: 6, top: 3, bottom: 3 })
            .borderRadius(6)
        }
      }
      .width('100%')

      Text(this.item.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .lineHeight(22)

      Text(`${this.item.discussCount} 讨论`)
        .fontSize(13)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#888888')
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.06)' : '#FFFFFF')
    .borderRadius(20)
    .shadow({
      radius: 8,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.15)' : 'rgba(0,0,0,0.03)',
      offsetY: 2
    })
    .scale({ x: this.pressed ? 0.98 : 1, y: this.pressed ? 0.98 : 1 })
    .animation({ duration: 150, curve: Curve.EaseInOut })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      const post = mockPosts.find(p => p.id === this.item.id);
      if (post && this.openDetailPanel) {
        this.openDetailPanel(post);
      }
    })
  }
}

@Component
struct TopicCircleItemComponent {
  @State pressed: boolean = false;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  circle: TopicCircle = { id: 0, name: '', icon: '', memberCount: 0, color: '#000000' };

  build() {
    Row() {
      Column() {
        SymbolGlyph($r(this.circle.icon))
          .fontSize(26)
          .fontColor([this.circle.color])
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.12)' : `${this.circle.color}18`)
      .borderRadius(24)
      .margin({ right: 14 })

      Column({ space: 4 }) {
        Text(this.circle.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
        Text(`${(this.circle.memberCount / 1000).toFixed(1)}k 人`)
          .fontSize(13)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#888888')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666666' : '#999999'])
    }
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(this.pressed ? (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)') : Color.Transparent)
    .animation({ duration: 150, curve: Curve.EaseInOut })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
  }
}

@Component
export struct DiscoverComponent {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageLink('showTopicList') @Watch('onShowTopicListChange') showTopicList: boolean = false;
  @State scrollY: number = 0;
  @State selectedTopicId: string = '';
  @State showDetail: boolean = false;
  @State selectedPost: Post | null = null;
  @State showSidebar: boolean = false;
  @State detailPanelOffsetX: number = 500;
  @State detailPanelScale: number = 0.8;
  @State detailPanelOpacity: number = 0;
  @State detailPanelPhoneScale: number = 0.8;
  @State detailPanelPhoneOpacity: number = 0;
  @State detailPanelPhoneOffsetY: number = 200;
  @State backgroundDimOpacity: number = 0;
  @State topicListOffsetX: number = 320;
  @State topicListOpacity: number = 0;
  
  @State aiSummaryState: 'idle' | 'loading' | 'success' | 'error' = 'idle';
  @State aiSummaryContent: string = '';
  @State aiSummaryError: string = '';
  @State isLiked: boolean = false;
  @State likeScale: number = 1;
  
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  private likeManager: LikeManager = LikeManager.getInstance();

  @State hotTopics: Array<TopicItem> = mockPosts
    .sort((a, b) => (b.likes + b.commentsCount) - (a.likes + a.commentsCount))
    .slice(0, 12)
    .map((post: Post, index: number): TopicItem => ({
      id: post.id,
      title: post.title || post.content.substring(0, 20),
      discussCount: post.likes + post.commentsCount,
      isNew: index < 2
    }));

  @State topicCircles: TopicCircle[] = [
    { id: 1, name: '科技圈', icon: 'sys.symbol.laptopcomputer', memberCount: 12500, color: '#007AFF' },
    { id: 2, name: '美食圈', icon: 'sys.symbol.fork.knife', memberCount: 8900, color: '#FF6B6B' },
    { id: 3, name: '旅行圈', icon: 'sys.symbol.airplane', memberCount: 6700, color: '#34C759' },
    { id: 4, name: '摄影圈', icon: 'sys.symbol.camera', memberCount: 5200, color: '#FF9500' },
    { id: 5, name: '读书圈', icon: 'sys.symbol.book', memberCount: 4100, color: '#5856D6' },
    { id: 6, name: '音乐圈', icon: 'sys.symbol.music.note', memberCount: 3800, color: '#AF52DE' }
  ];

  aboutToAppear() {
    this.breakpointSystem.register();
    aiSummaryService.init();
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
  }

  onShowTopicListChange(): void {
    if (this.currentBreakpoint === 'md') {
      if (this.showTopicList) {
        animateTo({
          duration: 300,
          curve: Curve.EaseInOut
        }, () => {
          this.topicListOffsetX = 0;
          this.topicListOpacity = 1;
        });
      } else {
        animateTo({
          duration: 300,
          curve: Curve.EaseInOut
        }, () => {
          this.topicListOffsetX = 320;
          this.topicListOpacity = 0;
        });
      }
    }
  }

  private openDetailPanel(post: Post): void {
    this.selectedPost = post;
    this.showDetail = true;
    this.aiSummaryState = 'idle';
    this.aiSummaryContent = '';
    this.aiSummaryError = '';
    this.detailPanelScale = 0.8;
    this.detailPanelOpacity = 0;
    this.detailPanelPhoneScale = 0.8;
    this.detailPanelPhoneOpacity = 0;
    this.detailPanelPhoneOffsetY = 200;
    this.backgroundDimOpacity = 0;
    this.isLiked = this.likeManager.isPostLiked(post.id);
    this.likeScale = 1;
    
    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
      }
    }, () => {
      this.detailPanelOffsetX = 0;
      this.detailPanelScale = 1;
      this.detailPanelOpacity = 1;
      this.detailPanelPhoneOffsetY = 0;
      this.detailPanelPhoneScale = 1;
      this.detailPanelPhoneOpacity = 1;
      this.backgroundDimOpacity = 1;
      this.generateAISummary();
    });
  }

  private generateAISummary(): void {
    if (!this.selectedPost) {
      return;
    }
    const content = this.selectedPost.content || this.selectedPost.title || '';
    if (!content) {
      return;
    }
    aiSummaryService.generateSummary(
      this.selectedPost.id,
      content,
      (state, data) => {
        this.aiSummaryState = state;
        if (state === 'success') {
          this.aiSummaryContent = data || '';
          this.aiSummaryError = '';
        } else if (state === 'error') {
          this.aiSummaryError = data || '生成摘要失败';
        }
      }
    );
  }

  private retryAISummary(): void {
    if (!this.selectedPost) {
      return;
    }
    const content = this.selectedPost.content || this.selectedPost.title || '';
    if (!content) {
      return;
    }
    this.aiSummaryError = '';
    aiSummaryService.retry(
      this.selectedPost.id,
      content,
      (state, data) => {
        this.aiSummaryState = state;
        if (state === 'success') {
          this.aiSummaryContent = data || '';
          this.aiSummaryError = '';
        } else if (state === 'error') {
          this.aiSummaryError = data || '生成摘要失败';
        }
      }
    );
  }

  private handleLike(): void {
    if (!this.selectedPost) {
      return;
    }
    this.likeScale = 1.3;
    animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
      this.likeScale = 1.3;
    });
    animateTo({ duration: 150, curve: Curve.EaseIn, delay: 100 }, () => {
      this.likeScale = 0.9;
    });
    animateTo({ duration: 100, curve: Curve.EaseOut, delay: 250 }, () => {
      this.likeScale = 1;
    });
    
    this.isLiked = this.likeManager.toggleLike(this.selectedPost);
  }

  private closeDetailPanel(): void {
    animateTo({
      duration: 300,
      curve: Curve.FastOutSlowIn,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.showDetail = false;
        this.selectedPost = null;
        this.detailPanelScale = 0.8;
        this.detailPanelOpacity = 0;
        this.detailPanelPhoneScale = 0.8;
        this.detailPanelPhoneOpacity = 0;
        this.detailPanelPhoneOffsetY = 200;
        this.backgroundDimOpacity = 0;
      }
    }, () => {
      this.detailPanelOffsetX = 500;
      this.detailPanelScale = 0.8;
      this.detailPanelOpacity = 0;
      this.detailPanelPhoneScale = 0.8;
      this.detailPanelPhoneOpacity = 0;
      this.detailPanelPhoneOffsetY = 200;
      this.backgroundDimOpacity = 0;
    });
  }

  build() {
    if (['lg', 'xl'].includes(this.currentBreakpoint)) {
      this.LargeTabletLayout()
    } else if (this.currentBreakpoint === 'md') {
      this.MediumTabletLayout()
    } else {
      this.PhoneLayout()
    }
  }

  @Builder
  PhoneLayout() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.scrollY > 20) {
        Column() {
          Column() {
            Row() {
              Text('发现')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              Blank()
              SymbolGlyph($r('sys.symbol.list_bullet'))
                .fontSize(24)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
                .onClick(() => {
                  this.showSidebar = true;
                })
            }
            .width('100%')
          }
          .width('100%')
          .height(80)
          .padding({ top: 32, bottom: 12, left: 24, right: 24 })
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.85)' : 'rgba(255,255,255,0.92)')
          .backdropBlur(20)
        }
        .zIndex(100)
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }

      Scroll() {
        Column({ space: 32 }) {
          Column({ space: 12 }) {
            Text('发现')
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .padding({ left: 24, top: 32, bottom: 4 })
              .width('100%')
              .opacity(Math.max(0, 1 - this.scrollY / 40))
              .animation({ duration: 100 })

            Text('探索精彩内容，发现有趣话题')
              .fontSize(16)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#999999' : '#666666')
              .padding({ left: 24, right: 24 })
              .width('100%')
              .opacity(Math.max(0, 1 - this.scrollY / 40))
              .animation({ duration: 100 })
          }

          Scroll() {
            Row({ space: 10 }) {
              this.TagItem('#今日灵魂拷问', '#FF69B4', '#FFF0F5')
              this.TagItem('#附近的人', '#00BCD4', '#E0F7FA')
              this.TagItem('#我的年度总结', '#7B68EE', '#F3F0FF')
              this.TagItem('#周末去哪儿', '#FFA500', '#FFF8E1')
            }
            .padding({ left: 24, right: 24 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')

          GridRow({
            columns: 2,
            gutter: 16
          }) {
            GridCol() {
              FeatureCardComponent({
                title: '话题广场',
                icon: 'sys.symbol.list_bullet',
                iconColor: '#FF6B6B',
                url: 'pages/discover/TopicSquarePage'
              })
            }
            GridCol() {
              FeatureCardComponent({
                title: '每日精选',
                icon: 'sys.symbol.star',
                iconColor: '#6C5CE7',
                url: 'pages/discover/DailyPicksPage'
              })
            }
          }
          .padding({ left: 24, right: 24 })

          Column({ space: 16 }) {
            Text('热门推荐')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .margin({ left: 24 })

            List({ space: 12 }) {
              ForEach(this.hotTopics, (item: TopicItem, index: number) => {
                ListItem() {
                  HotTopicItemComponent({
                    item: item,
                    index: index,
                    openDetailPanel: (post: Post) => this.openDetailPanel(post)
                  })
                }
              }, (item: TopicItem) => item.id.toString())
            }
            .padding({ left: 24, right: 24, bottom: 100 })
          }
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .onScroll((x, y) => {
        this.scrollY += y;
      })
      .edgeEffect(EdgeEffect.Spring)

      if (this.showDetail && this.selectedPost) {
        this.RadialDimBackground()
        Column() {
          Blank()
        }
        .width('100%')
        .height('100%')
        .onClick(() => this.closeDetailPanel())

        this.DetailPanelPhone()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F8F9FA')
    .bindContentCover($$this.showSidebar, this.SidebarBuilder(), {
      modalTransition: ModalTransition.DEFAULT
    })
  }

  @Builder
  MediumTabletLayout() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Row() {
        Column() {
          this.LeftContent(3)
        }
        .layoutWeight(3)
        .height('100%')

        if (this.showTopicList) {
          Column() {
            this.RightSidebar()
          }
          .width(300)
          .height('100%')
          .translate({ x: this.topicListOffsetX })
          .opacity(this.topicListOpacity)
        }
      }
      .width('100%')
      .height('100%')

      if (this.showDetail && this.selectedPost) {
        this.RadialDimBackground()
        Column() {
          Blank()
        }
        .width('100%')
        .height('100%')
        .onClick(() => this.closeDetailPanel())

        this.DetailPanelSlide()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F8F9FA')
  }

  @Builder
  LargeTabletLayout() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Row() {
        Column() {
          this.LeftContent(4)
        }
        .layoutWeight(2)
        .height('100%')

        Column() {
          this.RightSidebar()
        }
        .width(340)
        .height('100%')
      }
      .width('100%')
      .height('100%')

      if (this.showDetail && this.selectedPost) {
        this.RadialDimBackground()
        Column() {
          Blank()
        }
        .width('100%')
        .height('100%')
        .onClick(() => this.closeDetailPanel())

        this.DetailPanelSlide()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F8F9FA')
  }

  @Builder
  LeftContent(gridColumns: number) {
    Stack({ alignContent: Alignment.Top }) {
      if (this.scrollY > 20) {
        Column() {
          Column() {
            Text('发现')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
          }
          .width('100%')
          .height(80)
          .padding({ top: 32, bottom: 12, left: 24 })
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.85)' : 'rgba(255,255,255,0.92)')
          .backdropBlur(20)
        }
        .zIndex(100)
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }

      Scroll() {
        Column({ space: 32 }) {
          Column({ space: 12 }) {
            Text('发现')
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .padding({ left: 24, top: 32, bottom: 4 })
              .width('100%')
              .opacity(Math.max(0, 1 - this.scrollY / 40))
              .animation({ duration: 100 })

            Text('探索精彩内容，发现有趣话题')
              .fontSize(16)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#999999' : '#666666')
              .padding({ left: 24, right: 24 })
              .width('100%')
              .opacity(Math.max(0, 1 - this.scrollY / 40))
              .animation({ duration: 100 })
          }

          Scroll() {
            Row({ space: 10 }) {
              this.TagItem('#今日灵魂拷问', '#FF69B4', '#FFF0F5')
              this.TagItem('#附近的人', '#00BCD4', '#E0F7FA')
              this.TagItem('#我的年度总结', '#7B68EE', '#F3F0FF')
              this.TagItem('#周末去哪儿', '#FFA500', '#FFF8E1')
              if (gridColumns >= 4) {
                this.TagItem('#科技前沿', '#34C759', '#E8F8E8')
                this.TagItem('#生活日常', '#FF9500', '#FFF8E8')
              }
            }
            .padding({ left: 24, right: 24 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')

          GridRow({
            columns: gridColumns,
            gutter: 16
          }) {
            GridCol() {
              FeatureCardComponent({
                title: '话题广场',
                icon: 'sys.symbol.list_bullet',
                iconColor: '#FF6B6B',
                url: 'pages/discover/TopicSquarePage'
              })
            }
            GridCol() {
              FeatureCardComponent({
                title: '每日精选',
                icon: 'sys.symbol.star',
                iconColor: '#6C5CE7',
                url: 'pages/discover/DailyPicksPage'
              })
            }
          }
          .padding({ left: 24, right: 24 })

          Column({ space: 16 }) {
            Text('热门推荐')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .margin({ left: 24 })

            GridRow({
              columns: gridColumns,
              gutter: 12
            }) {
              ForEach(this.hotTopics, (item: TopicItem, index: number) => {
                GridCol() {
                  HotTopicGridItemComponent({
                    item: item,
                    index: index,
                    openDetailPanel: (post: Post) => this.openDetailPanel(post)
                  })
                }
              }, (item: TopicItem) => item.id.toString())
            }
            .padding({ left: 24, right: 24, bottom: 100 })
          }
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .onScroll((x, y) => {
        this.scrollY += y;
      })
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RightSidebar() {
    Column() {
      Column() {
        Text('话题列表')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
          .width('100%')
          .padding({ left: 18, top: 20, bottom: 16 })

        List({ space: 8 }) {
          ForEach(this.topicCircles, (circle: TopicCircle) => {
            ListItem() {
              TopicCircleItemComponent({
                circle: circle
              })
            }
          }, (circle: TopicCircle) => circle.id.toString())
        }
        .padding({ left: 18, right: 18, bottom: 20 })
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
      .borderRadius(20)
      .shadow({
        radius: 16,
        color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.06)',
        offsetY: 4
      })
      .margin({ left: 0, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SidebarBuilder() {
    Column() {
      Row() {
        Text('兴趣图谱')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
        Blank()
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(24)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
          .onClick(() => {
            this.showSidebar = false;
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 20 })

      Scroll() {
        Column({ space: 16 }) {
          Column()
            .height(100)
        }
        .width('100%')
        .padding({ left: 24, right: 24, bottom: 24 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#FFFFFF')
  }

  @Builder
  TagItem(text: string, color: string, bgColor: string) {
    Text(text)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(color)
      .padding({ left: 18, right: 18, top: 10, bottom: 10 })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.12)' : bgColor)
      .borderRadius(24)
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
  DetailPanelPhone() {
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
                this.closeDetailPanel();
              })
            Blank()
            Text('详情')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            Blank()
            SymbolGlyph($r('sys.symbol.gearshape'))
              .fontSize(26)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 24, bottom: 16 })

          if (this.selectedPost) {
            Scroll() {
              Column({ space: 24 }) {
                if (this.selectedPost.images.length > 0) {
                  Image(this.selectedPost.images[0].startsWith('app.media.') ? $r(this.selectedPost.images[0]) : $rawfile(this.selectedPost.images[0]))
                    .width('100%')
                    .height(240)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(20)
                }

                Text(this.selectedPost.content)
                  .fontSize(17)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
                  .lineHeight(26)
                  .width('100%')

                Row() {
                  Row() {
                    SymbolGlyph($r('sys.symbol.heart'))
                      .fontSize(22)
                      .fontColor([this.isLiked ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')])
                      .scale({ x: this.likeScale, y: this.likeScale })
                    Text(this.selectedPost.likes.toString())
                      .fontSize(15)
                      .fontColor(this.isLiked ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666666'))
                      .margin({ left: 6 })
                  }
                  .onClick(() => this.handleLike())
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)

                Column() {
                  Text('AI 摘要')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#7B68EE')
                    .width('100%')
                    .margin({ bottom: 10 })
                  
                  if (this.aiSummaryState === 'loading') {
                    Row({ space: 10 }) {
                      LoadingProgress()
                        .width(18)
                        .height(18)
                        .color('#7B68EE')
                      Text('AI 正在生成摘要...')
                        .fontSize(14)
                        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123, 104, 238, 0.18)' : '#F3F0FF')
                    .borderRadius(16)
                  } else if (this.aiSummaryState === 'success' && this.aiSummaryContent) {
                    Text(this.aiSummaryContent)
                      .fontSize(14)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
                      .width('100%')
                      .padding(16)
                      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123, 104, 238, 0.18)' : '#F3F0FF')
                      .borderRadius(16)
                      .lineHeight(22)
                  } else if (this.aiSummaryState === 'error') {
                    Column({ space: 10 }) {
                      Text(this.aiSummaryError || '生成摘要失败')
                        .fontSize(14)
                        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FF8A80' : '#F53F3F')
                        .width('100%')
                      Text('点击重试')
                        .fontSize(14)
                        .fontColor('#165DFF')
                        .alignSelf(ItemAlign.End)
                        .onClick(() => this.retryAISummary())
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 138, 128, 0.18)' : '#FFEBEE')
                    .borderRadius(16)
                  }
                }
                .width('100%')
                .margin({ top: 12 })

                Column()
                  .height(100)
              }
              .width('100%')
              .padding({ left: 24, right: 24, top: 8, bottom: 24 })
            }
            .layoutWeight(1)
            .width('100%')
            .scrollBar(BarState.Auto)
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('92%')
    .height('85%')
    .borderRadius(32)
    .translate({ y: this.detailPanelPhoneOffsetY })
    .scale({ x: this.detailPanelPhoneScale, y: this.detailPanelPhoneScale })
    .opacity(this.detailPanelPhoneOpacity)
    .zIndex(100)
    .backgroundColor(Color.Transparent)
  }

  @Builder
  DetailPanelSlide() {
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
                this.closeDetailPanel();
              })
            Blank()
            Text('详情')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            Blank()
            SymbolGlyph($r('sys.symbol.gearshape'))
              .fontSize(26)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 24, bottom: 16 })

          if (this.selectedPost) {
            Scroll() {
              Column({ space: 24 }) {
                if (this.selectedPost.images.length > 0) {
                  Image(this.selectedPost.images[0].startsWith('app.media.') ? $r(this.selectedPost.images[0]) : $rawfile(this.selectedPost.images[0]))
                    .width('100%')
                    .height(240)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(20)
                }

                Text(this.selectedPost.content)
                  .fontSize(17)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
                  .lineHeight(26)
                  .width('100%')

                Row() {
                  Row() {
                    SymbolGlyph($r('sys.symbol.heart'))
                      .fontSize(22)
                      .fontColor([this.isLiked ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')])
                      .scale({ x: this.likeScale, y: this.likeScale })
                    Text(this.selectedPost.likes.toString())
                      .fontSize(15)
                      .fontColor(this.isLiked ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666666'))
                      .margin({ left: 6 })
                  }
                  .onClick(() => this.handleLike())
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)

                Column() {
                  Text('AI 摘要')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#7B68EE')
                    .width('100%')
                    .margin({ bottom: 10 })
                  
                  if (this.aiSummaryState === 'loading') {
                    Row({ space: 10 }) {
                      LoadingProgress()
                        .width(18)
                        .height(18)
                        .color('#7B68EE')
                      Text('AI 正在生成摘要...')
                        .fontSize(14)
                        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123, 104, 238, 0.18)' : '#F3F0FF')
                    .borderRadius(16)
                  } else if (this.aiSummaryState === 'success' && this.aiSummaryContent) {
                    Text(this.aiSummaryContent)
                      .fontSize(14)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
                      .width('100%')
                      .padding(16)
                      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123, 104, 238, 0.18)' : '#F3F0FF')
                      .borderRadius(16)
                      .lineHeight(22)
                  } else if (this.aiSummaryState === 'error') {
                    Column({ space: 10 }) {
                      Text(this.aiSummaryError || '生成摘要失败')
                        .fontSize(14)
                        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FF8A80' : '#F53F3F')
                        .width('100%')
                      Text('点击重试')
                        .fontSize(14)
                        .fontColor('#165DFF')
                        .alignSelf(ItemAlign.End)
                        .onClick(() => this.retryAISummary())
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255, 138, 128, 0.18)' : '#FFEBEE')
                    .borderRadius(16)
                  }
                }
                .width('100%')
                .margin({ top: 12 })

                Column()
                  .height(100)
              }
              .width('100%')
              .padding({ left: 24, right: 24, top: 8, bottom: 24 })
            }
            .layoutWeight(1)
            .width('100%')
            .scrollBar(BarState.Auto)
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width(400)
    .height('92%')
    .margin({ top: 16, bottom: 16, right: 16 })
    .translate({ x: this.detailPanelOffsetX })
    .scale({ x: this.detailPanelScale, y: this.detailPanelScale })
    .opacity(this.detailPanelOpacity)
    .zIndex(100)
    .backgroundColor(Color.Transparent)
  }
}
