import router from '@ohos.router';
import { BreakpointSystem } from '../../utils/BreakpointSystem';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { mockPosts, Post } from '../../model/Post';
import { LiquidGlass } from '../common/LiquidGlass';
import { aiSummaryService } from '../../utils/AISummaryService';
import { LikeManager } from '../../utils/LikeManager';
import { BRAND_PRIMARY } from '../../constants/ThemeTokens';

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
  description?: string;
  postCount?: number;
  todayActive?: number;
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
  openCirclePanel: (circle: TopicCircle) => void = () => {};

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
    .onClick(() => {
      this.openCirclePanel(this.circle);
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
  @State showTopicSelector: boolean = false;
  @State topicSelectorScale: number = 1;
  @State topicSelectorOpacity: number = 1;
  @State topicSelectorOffsetX: number = 400;
  @State showCirclePanel: boolean = false;
  @State selectedCircle: TopicCircle | null = null;
  @State circlePanelOffsetX: number = 400;
  @State showPostDetail: boolean = false;
  @State selectedPostForDetail: Post | null = null;
  @State postDetailTranslateX: number = 400;

  @State aiSummaryState: 'idle' | 'loading' | 'success' | 'error' = 'idle';
  @State aiSummaryContent: string = '';
  @State aiSummaryError: string = '';
  @State isLiked: boolean = false;
  @State likeScale: number = 1;
  @State forceUpdate: number = 0;

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

  @State topicCircles: TopicCircle[] = [];

  @State pulseScale: number = 1;
  @State iconScale: number = 1;
  @State particle1Y: number = 0;
  @State particle2Y: number = 0;
  @State particle3Y: number = 0;
  @State particle1Opacity: number = 0.6;
  @State particle2Opacity: number = 0.4;
  @State particle3Opacity: number = 0.5;
  @State glowOpacity: number = 0.3;
  @State isAnimPressed: boolean = false;
  @State animPressScale: number = 1;
  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;
  @State isDragging: boolean = false;
  @State dragScale: number = 1;

  private availableTopics: TopicCircle[] = [
    { id: 1, name: '科技圈', icon: 'sys.symbol.laptopcomputer', memberCount: 12500, color: 'BRAND_PRIMARY', description: '最新科技资讯、数码产品分享', postCount: 2340, todayActive: 856 },
    { id: 2, name: '美食圈', icon: 'sys.symbol.fork.knife', memberCount: 8900, color: '#FF6B6B', description: '发现美味、分享食谱', postCount: 1892, todayActive: 623 },
    { id: 3, name: '旅行圈', icon: 'sys.symbol.airplane', memberCount: 6700, color: '#34C759', description: '世界那么大，一起去看看', postCount: 1456, todayActive: 412 },
    { id: 4, name: '摄影圈', icon: 'sys.symbol.camera', memberCount: 5200, color: '#FF9500', description: '用镜头记录美好瞬间', postCount: 987, todayActive: 298 },
    { id: 5, name: '读书圈', icon: 'sys.symbol.book', memberCount: 4100, color: '#5856D6', description: '阅读是一座随身携带的避难所', postCount: 756, todayActive: 187 },
    { id: 6, name: '音乐圈', icon: 'sys.symbol.music.note', memberCount: 3800, color: '#AF52DE', description: '让音乐带你飞翔', postCount: 643, todayActive: 156 }
  ];

  private getCirclePosts(circleId: number): Post[] {
    const techPostIds = ['4', '7', '11', '20', '21', '22'];
    const foodPostIds = ['6', '12', '23', '24'];
    const travelPostIds = ['3', '9', '17'];
    const photoPostIds = ['3', '17'];
    const bookPostIds = ['14'];
    const musicPostIds = ['16'];

    let relevantIds: string[] = [];
    switch (circleId) {
      case 1: relevantIds = techPostIds; break;
      case 2: relevantIds = foodPostIds; break;
      case 3: relevantIds = travelPostIds; break;
      case 4: relevantIds = photoPostIds; break;
      case 5: relevantIds = bookPostIds; break;
      case 6: relevantIds = musicPostIds; break;
      default: relevantIds = [];
    }

    const posts = mockPosts.filter(p => relevantIds.includes(p.id));
    return posts.length > 0 ? posts : mockPosts.slice(0, 3);
  }

  aboutToAppear() {
    this.breakpointSystem.register();
    aiSummaryService.init();
    this.startPulseAnimation();
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
  }

  private startPulseAnimation(): void {
    animateTo({
      duration: 3000,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.pulseScale = 1.15;
    });

    setTimeout(() => {
      animateTo({
        duration: 2500,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      }, () => {
        this.iconScale = 1.12;
      });
    }, 750);

    animateTo({
      duration: 4000,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.particle1Y = -20;
      this.particle1Opacity = 0.9;
    });

    setTimeout(() => {
      animateTo({
        duration: 3500,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      }, () => {
        this.particle2Y = -15;
        this.particle2Opacity = 0.8;
      });
    }, 400);

    setTimeout(() => {
      animateTo({
        duration: 4500,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      }, () => {
        this.particle3Y = -25;
        this.particle3Opacity = 0.7;
      });
    }, 800);

    animateTo({
      duration: 3000,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.glowOpacity = 0.6;
    });
  }

  private handleAnimPress(): void {
    if (this.isAnimPressed) {
      return;
    }
    this.isAnimPressed = true;

    animateTo({
      duration: 100,
      curve: Curve.EaseOut
    }, () => {
      this.animPressScale = 0.92;
    });

    setTimeout(() => {
      animateTo({
        duration: 200,
        curve: Curve.FastOutSlowIn
      }, () => {
        this.animPressScale = 1.02;
      });
      setTimeout(() => {
        animateTo({
          duration: 150,
          curve: Curve.EaseOut
        }, () => {
          this.animPressScale = 1;
          this.isAnimPressed = false;
        });
      }, 200);
    }, 100);
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

  private openTopicSelector(): void {
    this.showTopicSelector = true;
    this.topicSelectorScale = 0.8;
    this.topicSelectorOpacity = 0;
    this.topicSelectorOffsetX = 400;
    this.backgroundDimOpacity = 0;
    
    animateTo({
      duration: 300,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.topicSelectorScale = 1;
      this.topicSelectorOpacity = 1;
      this.topicSelectorOffsetX = 0;
      this.backgroundDimOpacity = 1;
    });
  }

  private closeTopicSelector(): void {
    animateTo({
      duration: 250,
      curve: Curve.FastOutSlowIn,
      onFinish: () => {
        this.showTopicSelector = false;
        this.topicSelectorOffsetX = 400;
        this.topicSelectorScale = 0.8;
        this.topicSelectorOpacity = 0;
        this.backgroundDimOpacity = 0;
      }
    }, () => {
      this.topicSelectorScale = 0.8;
      this.topicSelectorOpacity = 0;
      this.topicSelectorOffsetX = 400;
      this.backgroundDimOpacity = 0;
    });
  }

  private openCirclePanel(circle: TopicCircle): void {
    this.selectedCircle = circle;
    this.showCirclePanel = true;
    this.circlePanelOffsetX = 400;

    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.circlePanelOffsetX = 0;
    });
  }

  private closeCirclePanel(): void {
    animateTo({
      duration: 280,
      curve: Curve.FastOutSlowIn,
      onFinish: () => {
        this.showCirclePanel = false;
        this.selectedCircle = null;
        this.circlePanelOffsetX = 400;
      }
    }, () => {
      this.circlePanelOffsetX = 400;
    });
  }

  private openPostDetail(post: Post): void {
    this.selectedPostForDetail = post;
    this.showPostDetail = true;

    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.circlePanelOffsetX = -30;
      this.postDetailTranslateX = 0;
    });
  }

  private closePostDetail(): void {
    animateTo({
      duration: 280,
      curve: Curve.FastOutSlowIn,
      onFinish: () => {
        this.showPostDetail = false;
        this.selectedPostForDetail = null;
        this.circlePanelOffsetX = 0;
        this.postDetailTranslateX = 400;
      }
    }, () => {
      this.circlePanelOffsetX = 0;
      this.postDetailTranslateX = 400;
    });
  }

  private toggleTopic(topic: TopicCircle): void {
    const index = this.topicCircles.findIndex(t => t.id === topic.id);
    if (index !== -1) {
      this.topicCircles.splice(index, 1);
    } else {
      this.topicCircles.push(topic);
    }
  }

  private isTopicSelected(topicId: number): boolean {
    return this.topicCircles.some(t => t.id === topicId);
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

      if (this.showTopicSelector) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [
              ['rgba(0, 0, 0, 0.5)', 0.0],
              ['rgba(0, 0, 0, 0.3)', 0.5],
              ['rgba(0, 0, 0, 0.5)', 1.0]
            ]
          })
          .opacity(this.backgroundDimOpacity)
          .animation({ duration: 300, curve: Curve.FastOutSlowIn })
        
        Column() {
          Blank()
        }
        .width('100%')
        .height('100%')
        .onClick(() => {
          this.closeTopicSelector();
        })

        this.TopicSelectorPanel()
      }

      if (this.showCirclePanel && this.selectedCircle) {
        Column() {
          this.CirclePanel()
        }
        .width(320)
        .height('100%')
        .translate({ x: this.circlePanelOffsetX })
      }

      if (this.showPostDetail && this.selectedPostForDetail) {
        Column() {
          this.PostDetailPanel()
        }
        .width(320)
        .height('100%')
        .translate({ x: this.postDetailTranslateX })
      }

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

      if (this.showTopicSelector) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [
              ['rgba(0, 0, 0, 0.5)', 0.0],
              ['rgba(0, 0, 0, 0.3)', 0.5],
              ['rgba(0, 0, 0, 0.5)', 1.0]
            ]
          })
          .opacity(this.backgroundDimOpacity)
          .animation({ duration: 300, curve: Curve.FastOutSlowIn })
        
        Column() {
          Blank()
        }
        .width('100%')
        .height('100%')
        .onClick(() => {
          this.closeTopicSelector();
        })

        this.TopicSelectorPanel()
      }

      if (this.showCirclePanel && this.selectedCircle) {
        Column() {
          this.CirclePanel()
        }
        .width(320)
        .height('100%')
        .translate({ x: this.circlePanelOffsetX })
      }

      if (this.showPostDetail && this.selectedPostForDetail) {
        Column() {
          this.PostDetailPanel()
        }
        .width(320)
        .height('100%')
        .translate({ x: this.postDetailTranslateX })
      }

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

      if (this.showCirclePanel && this.selectedCircle) {
        Column() {
          this.CirclePanel()
        }
        .width(320)
        .height('100%')
        .translate({ x: this.circlePanelOffsetX })
      }

      if (this.showPostDetail && this.selectedPostForDetail) {
        Column() {
          this.PostDetailPanel()
        }
        .width(320)
        .height('100%')
        .translate({ x: this.postDetailTranslateX })
      }

      if (this.showTopicSelector) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [
              ['rgba(0, 0, 0, 0.5)', 0.0],
              ['rgba(0, 0, 0, 0.3)', 0.5],
              ['rgba(0, 0, 0, 0.5)', 1.0]
            ]
          })
          .opacity(this.backgroundDimOpacity)
          .animation({ duration: 300, curve: Curve.FastOutSlowIn })

        Column() {
          Blank()
        }
        .width('100%')
        .height('100%')
        .onClick(() => {
          this.closeTopicSelector();
        })

        this.TopicSelectorPanel()
      }

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
        Row() {
          SymbolGlyph($r('sys.symbol.hash'))
            .fontSize(18)
            .fontColor(['#FF6B6B'])
          Text('话题列表')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
          Blank()
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(22)
            .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
            .onClick(() => {
              this.openTopicSelector();
            })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 20, bottom: 16 })

        if (this.topicCircles.length === 0) {
          this.EmptyTopicGuide()
        } else {
          List({ space: 8 }) {
            ForEach(this.topicCircles, (circle: TopicCircle) => {
              ListItem() {
                TopicCircleItemComponent({
                  circle: circle,
                  openCirclePanel: (c: TopicCircle) => this.openCirclePanel(c)
                })
              }
            }, (circle: TopicCircle) => circle.id.toString())
          }
          .padding({ left: 18, right: 18, bottom: 20 })
          .layoutWeight(1)
        }
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
  EmptyTopicGuide() {
    Column({ space: 24 }) {
      Column() {
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Circle()
              .width(120)
              .height(120)
              .fill(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,107,107,0.08)' : 'rgba(255,107,107,0.06)')
              .opacity(this.glowOpacity)

            Circle()
              .width(100)
              .height(100)
              .fill(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,107,107,0.12)' : 'rgba(255,107,107,0.10)')
              .scale({ x: this.pulseScale * this.animPressScale, y: this.pulseScale * this.animPressScale })

            Circle()
              .width(70)
              .height(70)
              .fill(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,107,107,0.20)' : '#FFF0F0')
              .scale({ x: this.pulseScale * 0.95 * this.animPressScale, y: this.pulseScale * 0.95 * this.animPressScale })

            Circle()
              .width(50)
              .height(50)
              .fill(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,107,107,0.25)' : '#FFE4E4')
              .scale({ x: this.iconScale * this.animPressScale, y: this.iconScale * this.animPressScale })

            Circle()
              .width(8)
              .height(8)
              .fill('#FF6B6B')
              .translate({ y: this.particle1Y })
              .opacity(this.particle1Opacity)
              .offset({ x: 50, y: -30 })

            Circle()
              .width(6)
              .height(6)
              .fill('#FF9500')
              .translate({ y: this.particle2Y })
              .opacity(this.particle2Opacity)
              .offset({ x: -45, y: -25 })

            Circle()
              .width(5)
              .height(5)
              .fill('#5856D6')
              .translate({ y: this.particle3Y })
              .opacity(this.particle3Opacity)
              .offset({ x: 35, y: 35 })

            Circle()
              .width(4)
              .height(4)
              .fill('#34C759')
              .translate({ y: this.particle1Y * 0.8 })
              .opacity(this.particle1Opacity * 0.8)
              .offset({ x: -40, y: 30 })
          }
          .width('100%')
          .height(140)
        }
        .width('100%')
        .scale({ x: this.animPressScale * this.dragScale, y: this.animPressScale * this.dragScale })
        .translate({ x: this.dragOffsetX, y: this.dragOffsetY })
        .animation({ duration: this.isDragging ? 0 : 200, curve: Curve.EaseOut })
        .gesture(
          PanGesture()
            .onActionStart(() => {
              this.isDragging = true;
              this.dragScale = 1.08;
            })
            .onActionUpdate((event: GestureEvent) => {
              this.dragOffsetX = event.offsetX * 0.25;
              this.dragOffsetY = event.offsetY * 0.25;
            })
            .onActionEnd(() => {
              this.isDragging = false;
              animateTo({
                duration: 150,
                curve: Curve.FastOutLinearIn
              }, () => {
                this.dragScale = 0.95;
              });
              animateTo({
                duration: 400,
                curve: Curve.FastOutSlowIn
              }, () => {
                this.dragOffsetX = 0;
                this.dragOffsetY = 0;
              });
              setTimeout(() => {
                animateTo({
                  duration: 250,
                  curve: Curve.FastOutSlowIn
                }, () => {
                  this.dragScale = 1;
                });
              }, 150);
            })
        )
        .onClick(() => {
          if (!this.isDragging) {
            this.handleAnimPress();
          }
        })
      }
      .width('100%')

      Column({ space: 12 }) {
        Text('还没有添加话题')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')

        Row({ space: 6 }) {
          Text('›')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
          Text('点击右上角 + 添加话题')
            .fontSize(13)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
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
  TopicSelectorItem(topic: TopicCircle) {
    Row() {
      Column() {
        SymbolGlyph($r(topic.icon))
          .fontSize(26)
          .fontColor([topic.color])
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.12)' : `${topic.color}18`)
      .borderRadius(24)
      .margin({ right: 14 })

      Column({ space: 4 }) {
        Text(topic.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
        Text(`${(topic.memberCount / 1000).toFixed(1)}k 人`)
          .fontSize(13)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#888888')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.isTopicSelected(topic.id)) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(28)
          .fontColor(['#34C759'])
      } else {
        SymbolGlyph($r('sys.symbol.circle'))
          .fontSize(28)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666666' : '#CCCCCC'])
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor(this.isTopicSelected(topic.id) ? (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(52, 199, 89, 0.15)' : 'rgba(52, 199, 89, 0.08)') : Color.Transparent)
    .onClick(() => {
      this.toggleTopic(topic);
    })
  }

  @Builder
  TopicSelectorPanel() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        LiquidGlass({
          glassWidth: '100%',
          glassHeight: '100%',
          glassPadding: 0,
          glassRadius: 28,
          blurRadius: 24,
          showBorder: true
        }) {
          Column() {
            Row() {
              Text('选择话题')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              Blank()
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(22)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666666' : '#999999'])
                .onClick(() => {
                  this.closeTopicSelector();
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 20, bottom: 12 })

            Text('选择你感兴趣的话题，定制你的发现体验')
              .fontSize(13)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#666666')
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 16 })

            Scroll() {
              Column({ space: 8 }) {
                ForEach(this.availableTopics, (topic: TopicCircle) => {
                  this.TopicSelectorItem(topic)
                }, (topic: TopicCircle) => topic.id.toString())
              }
              .width('100%')
              .padding({ left: 8, right: 8, bottom: 20 })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
          .width('100%')
          .height('100%')
        }
      }
      .width(320)
      .height('75%')
      .translate({ x: this.topicSelectorOffsetX, y: 50 })
    }
    .width('100%')
    .height('100%')
    .scale({ x: this.topicSelectorScale, y: this.topicSelectorScale })
    .opacity(this.topicSelectorOpacity)
    .zIndex(200)
  }

  @Builder
  CirclePanel() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        LiquidGlass({
          glassWidth: '100%',
          glassHeight: '100%',
          glassPadding: 0,
          glassRadius: 28,
          blurRadius: 24,
          showBorder: true
        }) {
          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(22)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666666' : '#999999'])
                .onClick(() => {
                  this.closeCirclePanel();
                })
              Blank()
              Text(this.selectedCircle?.name || '')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              Blank()
              Text('...')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666666' : '#999999')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 20, bottom: 16 })

            if (this.selectedCircle) {
              Column({ space: 12 }) {
                Row({ space: 16 }) {
                  Column() {
                    Text(`${(this.selectedCircle.memberCount / 1000).toFixed(1)}k`)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.selectedCircle.color)
                    Text('成员')
                      .fontSize(12)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
                  }

                  Column() {
                    Text(`${this.selectedCircle.postCount || 0}`)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.selectedCircle.color)
                    Text('帖子')
                      .fontSize(12)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
                  }

                  Column() {
                    Text(`${this.selectedCircle.todayActive || 0}`)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.selectedCircle.color)
                    Text('今日活跃')
                      .fontSize(12)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
                  }
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: 8, bottom: 12 })

                Text(this.selectedCircle.description || '')
                  .fontSize(13)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
                  .textAlign(TextAlign.Center)
                  .width('100%')
              }
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 16 })
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)')
              .borderRadius(16)
            }

            Text('最新帖子')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 12 })

            if (this.selectedCircle) {
              List({ space: 12 }) {
                ForEach(this.getCirclePosts(this.selectedCircle.id), (post: Post) => {
                  ListItem() {
                    this.CirclePostItem(post, (p: Post) => {
                      this.likeManager.toggleLike(p);
                      this.forceUpdate++;
                    }, (p: Post) => this.openPostDetail(p))
                  }
                }, (post: Post) => `${post.id}-${this.forceUpdate}`)
              }
              .padding({ left: 20, right: 20, bottom: 20 })
              .layoutWeight(1)
            }
          }
          .width('100%')
          .height('100%')
        }
      }
      .width('85%')
      .constraintSize({ maxWidth: 400 })
      .height('80%')
      .translate({ x: this.circlePanelOffsetX })
    }
    .width('100%')
    .height('100%')
    .zIndex(200)
  }

  @Builder
  CirclePostItem(post: Post, onLike: (post: Post) => void, onOpenDetail: (post: Post) => void) {
    Column({ space: 10 }) {
      Row() {
        Column() {
          Text(post.userName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
          Text(post.time)
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.heart'))
            .fontSize(16)
            .fontColor([this.likeManager.isPostLiked(post.id) ? '#FF6B6B' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')])
          Text(`${post.likes}`)
            .fontSize(13)
            .fontColor(this.likeManager.isPostLiked(post.id) ? '#FF6B6B' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'))
        }
        .onClick(() => {
          onLike(post);
        })
      }
      .width('100%')

      Text(post.title || post.content.substring(0, 30))
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(post.content)
        .fontSize(13)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 16 }) {
        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.heart'))
            .fontSize(14)
            .fontColor([this.likeManager.isPostLiked(post.id) ? '#FF6B6B' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')])
          Text(`${post.likes}`)
            .fontSize(12)
            .fontColor(this.likeManager.isPostLiked(post.id) ? '#FF6B6B' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999'))
        }

        Row({ space: 4 }) {
          Text('💬')
            .fontSize(14)
          Text(`${post.commentsCount}`)
            .fontSize(12)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
        }
      }
      .width('100%')
      .padding({ top: 8 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.06)' : '#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.04)',
      offsetY: 2
    })
    .onClick(() => {
      onOpenDetail(post);
    })
  }

  @Builder
  PostDetailPanel() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        LiquidGlass({
          glassWidth: '100%',
          glassHeight: '100%',
          glassPadding: 0,
          glassRadius: 24,
          blurRadius: 20,
          showBorder: true
        }) {
          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(22)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666666' : '#999999'])
                .onClick(() => {
                  this.closePostDetail();
                })
              Blank()
              Text('帖子详情')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              Blank()
              SymbolGlyph($r('sys.symbol.heart'))
                .fontSize(22)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FF6B6B' : '#FF6B6B'])
                .onClick(() => {
                  if (this.selectedPostForDetail) {
                    this.isLiked = this.likeManager.toggleLike(this.selectedPostForDetail);
                  }
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 20, bottom: 16 })

            if (this.selectedPostForDetail) {
              Scroll() {
                Column({ space: 16 }) {
                  Row({ space: 12 }) {
                    Text(this.selectedPostForDetail.userName)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E5E5E5' : '#182431')
                    Text(this.selectedPostForDetail.time)
                      .fontSize(13)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
                  }
                  .width('100%')

                  if (this.selectedPostForDetail.title) {
                    Text(this.selectedPostForDetail.title)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
                      .width('100%')
                  }

                  Text(this.selectedPostForDetail.content)
                    .fontSize(15)
                    .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#CCCCCC' : '#333333')
                    .width('100%')
                    .lineHeight(24)

                  Row({ space: 20 }) {
                    Row({ space: 4 }) {
                      SymbolGlyph($r('sys.symbol.heart'))
                        .fontSize(18)
                        .fontColor([this.isLiked ? '#FF6B6B' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')])
                      Text(`${this.selectedPostForDetail.likes}`)
                        .fontSize(14)
                        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
                    }

                    Row({ space: 4 }) {
                      Text('💬')
                        .fontSize(16)
                      Text(`${this.selectedPostForDetail.commentsCount}`)
                        .fontSize(14)
                        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999999')
                    }
                  }
                  .width('100%')
                  .padding({ top: 12 })
                }
                .width('100%')
                .padding({ left: 20, right: 20, bottom: 20 })
              }
              .layoutWeight(1)
              .scrollBar(BarState.Off)
            }
          }
          .width('100%')
          .height('100%')
        }
      }
      .width('85%')
      .constraintSize({ maxWidth: 400 })
      .height('80%')
      .translate({ x: this.postDetailTranslateX })
    }
    .width('100%')
    .height('100%')
    .zIndex(250)
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
