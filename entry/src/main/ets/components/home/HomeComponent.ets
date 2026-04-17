import { Post, mockPosts } from '../../model/Post';
import { SearchPage } from '../search/SearchPage';
import router from '@ohos.router';
import { BreakpointSystem } from '../../utils/BreakpointSystem';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { LiquidGlass } from '../common/LiquidGlass';
import promptAction from '@ohos.promptAction';
import { LikeManager } from '../../utils/LikeManager';
import { BRAND_PRIMARY } from '../../constants/ThemeTokens';
import { PostDataSource } from '../../utils/BasicDataSource';

// 初始化持久化存储
PersistentStorage.persistProp('initialSearchKeyword', '');
PersistentStorage.persistProp('openSearchPage', false);

@Component
export struct HomeComponent {

  // 使用 LazyForEach 数据源
  private postDataSource: PostDataSource = new PostDataSource([]);
  @State isRefreshing: boolean = false;              // 是否正在下拉刷新
  @State isSearchPresented: boolean = false;         // 搜索页面是否弹出
  @State isLoading: boolean = false;                 // 是否处于加载状态（用于骨架屏
  @State isLoadingMore: boolean = false;             // 是否正在加载更多
  @State isVoiceInput: boolean = false;              // 是否通过语音启动搜索

  //  全局状态
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'; // 当前屏幕断点（'sm'手机 'md'平板 'lg'大屏）
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;// 当前主题模式（浅色/深色）
  @StorageLink('openSearchPage') @Watch('onOpenSearchPageChange') openSearchPage: boolean = false; // 是否需要打开搜索页面
  @StorageLink('refreshHomeData') @Watch('onRefreshSignal') refreshHomeData: number = 0; // 监听刷新信号

  // 断点监听器实例 — 使用单例，由 Index.ets 统一注册
  private breakpointSystem: BreakpointSystem = BreakpointSystem.getInstance();
  private likeManager: LikeManager = LikeManager.getInstance();

  aboutToAppear() {
    // 断点监听由 Index.ets 统一管理，子组件无需重复注册
    this.refreshPosts();
  }

  // 监听刷新信号
  onRefreshSignal() {
    if (this.refreshHomeData > 0) {
      this.refreshPosts();
    }
  }

  private refreshPosts() {
    const newPosts: Post[] = [];
    for (let i = 0; i < mockPosts.length; i++) {
      newPosts.push(mockPosts[i].copy());
    }
    this.postDataSource.setData(newPosts);
  }

  // 监听搜索页面打开状态
  onOpenSearchPageChange() {
    if (this.openSearchPage) {
      this.isVoiceInput = false;
      this.isSearchPresented = true;
      this.openSearchPage = false;
    }
  }

  // 子组件无需注销断点监听，由 Index.ets 统一管理

  // 辅助方法：生成随机新帖子
  private generateNewPosts(count: number): Post[] {
    const newPosts: Post[] = [];
    for (let i = 0; i < count; i++) {
      // 随机选择一个现有帖子作为模板
      const templateIndex = Math.floor(Math.random() * mockPosts.length);
      const template = mockPosts[templateIndex];

      const newId = `new_${Date.now()}_${i}`; // 生成唯一 ID

      // 创建新帖子
      const newPost = new Post(
        newId,
        template.userName,
        template.userAvatar,
        template.content,
        [...template.images], // 浅拷贝图片数组
        Math.floor(Math.random() * 1000), // 随机点赞数
        Math.floor(Math.random() * 50),   // 随机评论数
        '刚刚',                           // 时间
        template.title,
        [...template.commentList] // 浅拷贝评论列表
      );
      newPosts.push(newPost);
    }
    return newPosts;
  }

  // 加载更多数据
  private loadMorePosts() {
    if (this.isLoadingMore) {
      return;
    }
    this.isLoadingMore = true;

    setTimeout(() => {
      // 生成 10 个新帖子作为”更多数据”
      const morePosts = this.generateNewPosts(10);

      // 追加到数据源末尾
      const currentData = this.postDataSource.getAllData();
      this.postDataSource.setData([...currentData, ...morePosts]);

      // 同步更新全局 mockPosts
      mockPosts.push(...morePosts);

      this.isLoadingMore = false;
    }, 1500); // 模拟网络延迟
  }

  // 列表底部加载视图
  @Builder
  Footer() {
    Row() {
      if (this.isLoadingMore) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
          .margin({ right: 8 })
        Text('正在加载更多...')
          .fontSize(14)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
      } else {
        Text('上滑加载更多')
          .fontSize(14)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
          .padding({ top: 10, bottom: 10 })
      }
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
  }

  // 搜索页面构建器：用于模态弹出搜索界面
  @Builder
  SearchBuilder() {
    SearchPage({ isPresented: $isSearchPresented,  // 双向绑定弹出状态
      startVoiceInput: $isVoiceInput               // 控制是否启动语音输入
    })
  }

  // 下拉刷新头部指示器：包含 Loading 动画和提示文本
  @Builder
  RefreshHeader() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
      Text(' ')// 占位文本
        .fontSize(14)
        .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666666')
        .margin({ left: 8 })
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
    .translate({ y: 80 }) // 视觉下移,确保动画出现在Header下方
  }

  // 骨架屏单个卡片占位符：用于加载时的视觉反馈
  @Builder
  SkeletonItem() {
    Column() {
      // 图片占位符
      Row()
        .width('100%')
        .height(150)
        .backgroundColor('#EEEEEE')
        .borderRadius({ topLeft: 12, topRight: 12 })
      // 文字内容占位（标题 + 描述）
      Column() {
        Row()
          .width('80%')
          .height(16)
          .backgroundColor('#EEEEEE')
          .margin({ bottom: 8 })
          .borderRadius(4)
        Row()
          .width('60%')
          .height(16)
          .backgroundColor('#EEEEEE')
          .margin({ bottom: 12 })
          .borderRadius(4)

        // 用户信息占位（头像 + 昵称）
        Row() {
          Row()
            .width(20)
            .height(20)
            .backgroundColor('#EEEEEE')
            .borderRadius(10)
          Row()
            .width(60)
            .height(12)
            .backgroundColor('#EEEEEE')
            .margin({ left: 8 })
            .borderRadius(4)
        }
      }
      .padding(16) // 统一内边距
    }
    .width('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(16) // 统一圆角
    .shadow({ 
      radius: 12, 
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.04)', 
      offsetY: 4 
    }) 
  }
  // 主UI
  build() {
    // 使用 Stack 实现 Header 悬浮在内容之上
    Stack({ alignContent: Alignment.Top }) {
      // 顶部液态玻璃
      Column() {
        LiquidGlass({
          glassWidth: '95%',
          glassPadding: { left: 16, right: 16, top: 12, bottom: 12 },
          glassRadius: 32
        }) {
          Row() {
            // 页面标题
          Text('首页')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#333')
            .margin({ right: 16 })
          
          if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') {
             // 平板模式下靠左
          }

            // 搜索区域（响应式布局）
          Row() {
             // 左侧搜索点击区域（图标 + 文本）
             Row() {
               SymbolGlyph($r('sys.symbol.magnifyingglass')) // 使用系统搜索图标
                 .fontSize(16)
                 .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999'])
                 .margin({ left: 12, right: 8 })
               
               Text('探索新鲜事...')
                 .fontSize(14)
                 .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
                 .layoutWeight(1) // 让文字占据剩余空间
             }
             .layoutWeight(1)
             .height('100%')
             .alignItems(VerticalAlign.Center)
             .onClick(() => {
                this.isVoiceInput = false;
                this.isSearchPresented = true;
             })

            // 右侧：麦克风图标（语音搜索入口）
             SymbolGlyph($r('sys.symbol.mic'))
                .fontSize(16)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999'])
                .padding({ left: 8, right: 12, top: 4, bottom: 4 })
                .onClick(() => {
                  this.isVoiceInput = true;
                  this.isSearchPresented = true;
                })
          }
          .layoutWeight(this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg' ? 0 : 1) // 平板模式不自动拉伸
          .width(this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg' ? 400 : 'auto') // 平板模式稍微加宽搜索栏，方便点击
          .height(32) // 恢复较小的高度，保持精致感
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)') // 半透明/浅色背景
          .borderRadius(16) // 对应高度的圆角
          .border({ width: 1, color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'transparent' : 'rgba(0,0,0,0.1)' }) // 增加极细边框

            // AI 聊天入口（响应式图标）
          if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') {
             Blank() // 平板模式右侧留白
             
             // 平板模式
            Text('Kepler')
              .fontSize(24)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .margin({ left: 12 })
             SymbolGlyph($r('sys.symbol.chevron_right')) // 圆形箭头图标
               .fontSize(28)
               .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
               .margin({ left: 16 ,right: 16 })
               .onClick(() => {
                  router.pushUrl({ url: 'pages/AIChatPage' });
               })
          } else {
             //  AI 聊天入口
             SymbolGlyph($r('sys.symbol.message')) // 聊天气泡图标
               .fontSize(24)
               .fontColor(['BRAND_PRIMARY'])
               .margin({ left: 16 })
               .onClick(() => {
                  router.pushUrl({ url: 'pages/AIChatPage' });
               })
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .margin({ top: 12 }) // 顶部留白
    .zIndex(10) // 确保在列表之上


      // 内容区域（下拉刷新）
      Refresh({ refreshing: $$this.isRefreshing, builder: this.RefreshHeader() }) {
        if (this.isLoading) {
           // 骨架加载视图
           WaterFlow() {
             ForEach([1, 2, 3, 4, 5, 6, 7, 8], (item: number) => { // 增加骨架屏数量
               FlowItem() {
                 this.SkeletonItem()
               }
             })
           }
           // 响应式列数优化：手机2列，中屏3列，大屏4列，超大屏4列
           .columnsTemplate((this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl' ? "1fr 1fr 1fr 1fr" :
                           (this.currentBreakpoint === 'md' ? "1fr 1fr 1fr" : "1fr 1fr")))
           .columnsGap(12)
           .rowsGap(12)
           .padding({ left: 12, right: 12, top: 80, bottom: 100 }) // 顶部避开 Header，底部避开 TabBar
           .layoutWeight(1)
        } else {
          // 显示真实帖子卡片 - 使用 LazyForEach 实现懒加载
          WaterFlow({ footer: this.Footer() }) {
            LazyForEach(this.postDataSource, (item: Post) => {
              FlowItem() {
                PostCardItem({ item: item })
              }
            }, (item: Post) => item.id)
          }
          // 响应式列数优化：手机2列，中屏3列，大屏4列，超大屏4列
          .columnsTemplate((this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl' ? "1fr 1fr 1fr 1fr" :
                          (this.currentBreakpoint === 'md' ? "1fr 1fr 1fr" : "1fr 1fr")))
          .columnsGap(12)
          .rowsGap(12)
          .padding({ left: 12, right: 12, top: 80, bottom: 100 }) // 顶部留出Header高度，底部留出TabBar高度
          .clip(false) // 允许内容滚动到 padding 区域
          .layoutWeight(1)
          .onReachEnd(() => {
            this.loadMorePosts();
          })
        }

      }
      .onRefreshing(() => {
        // 模拟刷新逻辑
        this.isLoading = true;
        setTimeout(() => {
          this.isRefreshing = false;
          this.isLoading = false;

          // 生成 10 个新帖子
          const newPosts = this.generateNewPosts(10);

          // 将新帖子添加到数据源头部
          const currentData = this.postDataSource.getAllData();
          this.postDataSource.setData([...newPosts, ...currentData]);

          // 同步更新全局 mockPosts，以便详情页能找到
          mockPosts.unshift(...newPosts);

          promptAction.showToast({
            message: `为您推荐了 ${newPosts.length} 条新内容`,
            duration: 2000
          });

        }, 2000)
      })
      .width('100%')
      .height('100%')
      .clip(false) // 允许子组件绘制到边界外
    }
    .width('100%')
    .height('100%')
    .bindContentCover($$this.isSearchPresented, this.SearchBuilder(), {
      modalTransition: ModalTransition.DEFAULT
    })
  }
}

@Component
struct PostCardItem {
  @Prop item: Post = mockPosts[0]; 
  @State isPressed: boolean = false;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  private formatLikes(likes: number): string {
    if (likes >= 10000) {
      return `${(likes / 10000).toFixed(1)}w`;
    } else if (likes >= 1000) {
      return `${(likes / 1000).toFixed(1)}k`;
    }
    return `${likes}`;
  }

  build() {
    Column() {
      // 图片区域
      if (this.item.images.length > 0) {
        Image(this.item.images[0].startsWith('app.media.') ? $r(this.item.images[0]) : $rawfile(this.item.images[0]))
          .width('100%')
          .height(220) // 略微增加高度
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 16, topRight: 16 }) // 更大的圆角
          .sharedTransition(this.item.id, { duration: 300, curve: Curve.EaseInOut })
      } 
      
      // 内容区域
      Column() {
        // 帖子正文（最多3行，超出省略）
        Text(this.item.content)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' : '#1D2129')
          .lineHeight(24)
          .margin({ bottom: 12 })

        // 底部：用户信息 + 点赞数
        Row() {
          // 左侧：用户头像 + 昵称
          Row() {
            Image(this.item.userAvatar.startsWith('app.media.') ? $r(this.item.userAvatar) : $rawfile(this.item.userAvatar))
              .width(24)
              .height(24)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
              .flexShrink(0)
            Text(this.item.userName)
              .fontSize(13)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#86909C' : '#4E5969')
              .margin({ left: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .layoutWeight(1)
          .alignItems(VerticalAlign.Center)

          // 右侧：点赞图标 + 数量
          Row() {
             SymbolGlyph($r('sys.symbol.heart')) // 使用系统图标
               .fontSize(18)
               .fontColor([this.item.isLiked ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#86909C' : '#4E5969')])
               .margin({ right: 4 })
               .flexShrink(0)
             Text(this.formatLikes(this.item.likes))
               .fontSize(13)
               .fontColor(this.item.isLiked ? '#FF3B30' : (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#86909C' : '#4E5969'))
               .maxLines(1)
               .flexShrink(0)
          }
          .flexShrink(0)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .padding(16)
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
      .borderRadius(this.item.images.length > 0 ? { bottomLeft: 16, bottomRight: 16 } : 16)
    }
    .width('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(16) // 统一大圆角
    .shadow({ 
      radius: 12, 
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.04)', 
      offsetY: 4 
    })

    //交互反馈：按下缩放效果
    .scale({ x: this.isPressed ? 0.98 : 1, y: this.isPressed ? 0.98 : 1 })
    .animation({ duration: 200, curve: Curve.EaseInOut }) // Animation for scale
    .onTouch((event) => {
        if (event.type === TouchType.Down) {
            this.isPressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.isPressed = false;
        }
    })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/PostDetailPage',
        params: { id: this.item.id }
      })
    })
  }
}
