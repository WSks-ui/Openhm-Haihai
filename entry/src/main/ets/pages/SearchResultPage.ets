import router from '@ohos.router';
import { Post, mockPosts, currentKeplerPost, setCurrentKeplerPost } from '../model/Post';
import { BreakpointSystem } from '../utils/BreakpointSystem';
import { ContentGenerator } from '../utils/ContentGenerator';
import { USER_NAMES } from '../model/commentGenerator';
import promptAction from '@ohos.promptAction';

import { KeplerResultView } from '../components/search_result/KeplerResultView';
import { AllResultsView } from '../components/search_result/AllResultsView';
import { UserResultsView } from '../components/search_result/UserResultsView';
import { SearchLoadingSkeleton } from '../components/search_result/SearchLoadingSkeleton';
import { LiquidGlass } from '../components/LiquidGlass';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';

/**
 * SearchResultPage - 搜索结果页面
 * 
 * 沉浸式效果实现：
 * 1. 顶部搜索栏通过 safeAreaTop 避开状态栏区域
 * 2. 整个页面扩展到安全区域，实现全屏沉浸效果
 */

class TabInfo {
  x: number = 0;
  width: number = 0;
}

@Entry
@Component
struct SearchResultPage {
  @State keyword: string = '';
  @State searchResults: Post[] = [];
  @State categories: string[] = ['全部', '用户', 'Kepler总结'];
  @State selectedCategoryIndex: number = 0;
  @State isLoading: boolean = false;
  @State lastSearchedKeyword: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  
  // 沉浸式效果：安全区域高度
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;
  
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  // 标签动画状态
  @State tabIndicatorX: number = 0;
  @State tabIndicatorWidth: number = 0;
  @State tabIndicatorHeight: number = 0;
  private tabInfos: TabInfo[] = [];

  aboutToAppear() {
    this.breakpointSystem.register();
    const params = router.getParams() as Record<string, string>;
    if (params && params['keyword']) {
      this.keyword = params['keyword'];
      this.performSearch(this.keyword);
    }
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
  }

  // 处理标签切换的新方法
  onTabClick(index: number) {
    this.selectedCategoryIndex = index;
    
    this.updateDisplayedResults();
    
    // 动画指示器
    const target = this.tabInfos[index];
    if (target && target.width > 0) {
      animateTo({ 
        curve: curves.springMotion(0.6, 0.7),
        duration: 500 
      }, () => {
        this.tabIndicatorX = target.x;
        this.tabIndicatorWidth = target.width;
      });
    }
  }

  // 根据当前类别和数据更新显示的结果
  updateDisplayedResults() {
    const lowerKeyword = this.lastSearchedKeyword.toLowerCase();

    // 筛选本地结果
    const localResults = mockPosts.filter(post => {
      const contentMatch = post.content.toLowerCase().includes(lowerKeyword);
      const userMatch = post.userName.toLowerCase().includes(lowerKeyword);
      const titleMatch = post.title ? post.title.toLowerCase().includes(lowerKeyword) : false;
      return contentMatch || userMatch || titleMatch;
    });

    // 根据类别与Kepler帖子合并
    let finalResults: Post[] = [];

    if (this.selectedCategoryIndex === 0) { // 全部
      if (currentKeplerPost) {
        finalResults = [currentKeplerPost, ...localResults];
      } else {
        finalResults = localResults;
      }
    } else if (this.selectedCategoryIndex === 1) { // 用户
      // 用户过滤器（逻辑：检查 userName 是否与关键字匹配）
      // 原始代码除了选项卡 UI 外，没有实现严格的类别过滤逻辑。
      // 对于“用户”选项卡，只排除 Kepler 帖子。
      finalResults = localResults;
    } else if (this.selectedCategoryIndex === 2) { // Kepler总结
      if (currentKeplerPost) {
        finalResults = [currentKeplerPost];
      } else {
        finalResults = [];
      }
    }

    this.searchResults = finalResults;
  }

  async performSearch(keyword: string, forceRegenerate: boolean = false) {
    // 如果关键字没有改变且不是强制重新生成，不要重新获取
    if (keyword === this.lastSearchedKeyword && !forceRegenerate) {
      this.updateDisplayedResults();
      return;
    }

    this.isLoading = true;
    this.searchResults = []; // 清除先前结果
    this.lastSearchedKeyword = keyword; // 更新上次搜索的关键词

    // 1. 检查网络连接
    const isOnline = await ContentGenerator.checkNetwork();
    if (!isOnline) {
      this.isLoading = false;
      promptAction.showToast({ message: '当前处于离线状态，搜索功能无法使用' });
      return;
    }

    try {
      // 2. 并行执行：本地搜索 + AI生成内容
      const aiContentPromise = ContentGenerator.generateContent(keyword);

      // 在等待 AI 时立即使用本地结果更新显示
      this.updateDisplayedResults();

      // 等待 Kepler 生成结果
      const aiContent = await aiContentPromise;

      // 随机选择一个用户名
      const randomName = USER_NAMES[Math.floor(Math.random() * USER_NAMES.length)];

      // 创建 Kepler 摘要卡片
      const aiPost = new Post(
        `ai_${Date.now()}`,
        randomName, // 使用随机用户名
        'app.media.startIcon',
        aiContent,
        [], // 无图片
        999,
        0,
        '刚刚',
        `Kepler 关于 "${keyword}" 的总结`,
        []
      );

      // 设置当前 Kepler 帖子（替换旧帖子）
      setCurrentKeplerPost(aiPost);

      // 再次更新显示以包含新的kepler帖子
      this.updateDisplayedResults();

    } catch (err) {
      console.error('Search error:', err);
      // 即使 Kepler 失败，也显示本地结果，但提示用户
      this.updateDisplayedResults();

      // 检查是否显示了本地结果
      const hasLocalResults = mockPosts.some(post => {
        const lower = keyword.toLowerCase();
        return post.content.toLowerCase().includes(lower) ||
        post.userName.toLowerCase().includes(lower) ||
          (post.title && post.title.toLowerCase().includes(lower));
      });

      if (hasLocalResults) {
        promptAction.showToast({ message: 'Kepler 生成失败，已显示搜索结果' });
      } else {
        promptAction.showToast({ message: '搜索失败，请稍后重试' });
      }
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部安全区域留白（避开状态栏）
      Column()
        .width('100%')
        .height(this.safeAreaTop)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')

      // 顶部搜索栏（固定在顶部）- 优化版
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333'])
          .margin({ right: 16 })
          .onClick(() => {
            router.back();
          })

        Row() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(20)
            .fontColor(['#7B68EE'])
            .margin({ right: 12 })

          Text(this.keyword)
            .fontSize(16)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(20)
            .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.6)' :
              '#999999'])
            .margin({ left: 12 })
            .onClick(() => {
              this.keyword = '';
            })
        }
        .layoutWeight(1)
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          'rgba(255,255,255,0.1)' : '#F8F8FA')
        .borderRadius(24)
        .border({
          width: 1,
          color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.1)' :
            'rgba(0,0,0,0.05)'
        })
        .shadow({
          radius: 8,
          color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' :
            'rgba(123, 104, 238, 0.1)',
          offsetY: 2
        })
        .alignItems(VerticalAlign.Center)

        Text('搜索')
          .fontSize(16)
          .fontColor('#7B68EE')
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
          .onClick(() => {
            this.performSearch(this.keyword);
          })
      }
      .width('100%')
      .constraintSize({ maxWidth: ['lg', 'xl'].includes(this.currentBreakpoint) ? 1200 : '100%' })
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 8
      })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
      .zIndex(20)

      Stack({ alignContent: Alignment.Top }) {
        // 主要内容区域（可滚动），放在第一位以位于标签后面
        Column() {
          if (this.isLoading) {
            SearchLoadingSkeleton({ selectedCategoryIndex: this.selectedCategoryIndex })
              .width('100%')
              .layoutWeight(1)
          } else if (this.searchResults.length === 0) {
            // 空状态
            Column() {
              SymbolGlyph($r('sys.symbol.magnifyingglass'))
                .fontSize(80)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#555555' : '#CCCCCC'])
                .margin({ bottom: 16 })
              Text('没有找到相关结果')
                .fontSize(16)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888888' : '#999')
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .padding({ top: 60 })
          } else {
            Stack() {
              if (this.selectedCategoryIndex === 2 && this.searchResults.length > 0 && this.searchResults[0]) {
                // Kepler 视图
                KeplerResultView({
                  post: this.searchResults[0],
                  keyword: this.keyword,
                  onRegenerate: () => {
                    this.performSearch(this.keyword, true);
                  }
                })
                  .width('100%')
                  .layoutWeight(1)
                  .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 20 }))
                    .animation({ duration: 300, curve: Curve.EaseInOut }))
              } else if (this.selectedCategoryIndex === 1) {
                // 用户视图
                UserResultsView({ searchResults: this.searchResults })
                  .width('100%')
                  .layoutWeight(1)
                  .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 20 }))
                    .animation({ duration: 300, curve: Curve.EaseInOut }))
              } else {
                // 全部视图
                AllResultsView({ searchResults: this.searchResults })
                  .width('100%')
                  .layoutWeight(1)
                  .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 20 }))
                    .animation({ duration: 300, curve: Curve.EaseInOut }))
              }
            }
            .layoutWeight(1)
            .width('100%')
            .alignContent(Alignment.TopStart)
          }
        }
        .width('100%')
        .height('100%')

        // 分类标签（悬浮在顶部）
        Column() {
          Row() {
            LiquidGlass({
              glassWidth: 'auto',
              glassRadius: 30,
              glassPadding: 4,
              blurRadius: 30
            }) {
              Stack({ alignContent: Alignment.Start }) {
                // 2.1 The Moving Liquid Glass Indicator (High Gloss Pill)
                if (this.tabIndicatorWidth > 0 && this.tabIndicatorHeight > 0) {
                  Column() {
                    Text('')
                  }
                  .width(this.tabIndicatorWidth)
                  .height(this.tabIndicatorHeight)
                  .borderRadius(24)
                  .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                    'rgba(255,255,255,0.25)' : 'rgba(255,255,255, 0.95)')
                  .backdropBlur(20)
                  .shadow({
                    radius: 12,
                    color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' :
                      'rgba(0,0,0,0.12)',
                    offsetY: 4
                  })
                  .position({ x: this.tabIndicatorX, y: 0 })
                  .zIndex(0)
                  .hitTestBehavior(HitTestMode.None)
                }

                // 2.2 The Tab Items
                Row() {
                  ForEach(this.categories, (item: string, index: number) => {
                    Column() {
                      Text(item)
                        .fontSize(15)
                        .fontWeight(this.selectedCategoryIndex === index ? FontWeight.Bold : FontWeight.Medium)
                        .fontColor(this.selectedCategoryIndex === index ?
                          (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFF' : '#333') :
                          (this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
                            'rgba(255,255,255,0.6)' : 'rgba(0,0,0,0.5)')
                        )
                    }
                    .padding({
                      left: index === 2 ? 28 : 24,
                      right: index === 2 ? 28 : 24,
                      top: 12,
                      bottom: 12
                    })
                    .onClick(() => {
                      this.onTabClick(index);
                    })
                    .onAreaChange((_old, newArea) => {
                      let info = new TabInfo();
                      info.x = Number(newArea.position.x);
                      info.width = Number(newArea.width);
                      this.tabInfos[index] = info;

                      // 所有标签的高度应该一致，使用第一个标签的高度作为基准
                      if (index === 0 && this.tabIndicatorHeight === 0) {
                        this.tabIndicatorHeight = Number(newArea.height);
                      }

                      if (index === this.selectedCategoryIndex) {
                        animateTo({
                          curve: curves.springMotion(0.6, 0.7),
                          duration: 500
                        }, () => {
                          this.tabIndicatorX = Number(newArea.position.x);
                          this.tabIndicatorWidth = Number(newArea.width);
                          this.tabIndicatorHeight = Number(newArea.height);
                        });
                      }
                    })
                  }, (item: string) => item)
                }
                .zIndex(1)
              }
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 8, bottom: 8 })
          .backgroundColor(Color.Transparent)
        }
        .width('100%')
        .zIndex(10)
        // 分类胶囊
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    // 沉浸式效果：扩展整个页面到顶部和底部安全区域
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}