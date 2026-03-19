import router from '@ohos.router';
import { ConfigurationConstant } from '@kit.AbilityKit';

// 初始化持久化存储
PersistentStorage.persistProp('initialSearchKeyword', '');
PersistentStorage.persistProp('openSearchPage', false);

@Entry
@Component
struct TopicSquarePage {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageLink('initialSearchKeyword') initialSearchKeyword: string = '';
  @StorageLink('openSearchPage') openSearchPage: boolean = false;
  @State topics: string[] = [
    '#今日灵魂拷问', '#附近的人', '#鸿蒙开发', '#美食打卡', '#周末去哪儿',
    '#健身日常', '#阅读分享', '#萌宠时刻', '#日落摄影', '#职场吐槽',
    '#新科技', '#游戏人生', '#电影推荐', '#音乐分享', '#旅行日记'
  ];
  @State scrollY: number = 0;

  // 处理标签点击
  private handleTagClick(tag: string): void {
    // 去除标签开头的 # 号（如果有）
    const keyword = tag.startsWith('#') ? tag.substring(1) : tag;
    // 设置搜索关键词
    this.initialSearchKeyword = keyword;
    // 标记需要打开搜索页面
    this.openSearchPage = true;
    // 返回首页
    router.back();
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Top }) {
        if (this.scrollY > 20) {
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(24)
              .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431'])
              .onClick(() => router.back())
            Text('话题广场')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .margin({ left: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.8)' : 'rgba(255,255,255,0.9)')
          .zIndex(100)
        }

        Scroll() {
          Column({ space: 24 }) {
            Text('话题广场')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .padding({ left: 16, top: 32, bottom: 8 })
              .width('100%')
              .opacity(Math.max(0, 1 - this.scrollY / 40))
              .animation({ duration: 100 })

            Text('发现有趣的话题，参与热门讨论')
              .fontSize(15)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
              .padding({ left: 16 })
              .width('100%')

            Row() {
              Text('本周热门')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            }
            .width('100%')
            .padding({ left: 16, right: 16 })

            Scroll() {
              Row({ space: 12 }) {
                ForEach(this.topics.slice(0, 6), (item: string, index: number) => {
                  Column() {
                    Stack({ alignContent: Alignment.BottomStart }) {
                      Image($r('app.media.background'))
                        .width('100%')
                        .height(100)
                        .objectFit(ImageFit.Cover)
                      Column()
                        .width('100%')
                        .height('100%')
                        .linearGradient({
                          direction: GradientDirection.Top,
                          colors: [
                            ['rgba(0,0,0,0)', 0.3],
                            ['rgba(0,0,0,0.8)', 1]
                          ]
                        })
                      Text(item)
                        .fontSize(13)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(Color.White)
                        .padding(10)
                    }
                    .width('100%')
                    .height(100)
                    .borderRadius(12)
                  }
                  .width(140)
                  .height(100)
                  .borderRadius(12)
                  .clip(true)
                  .onClick(() => {
                    this.handleTagClick(item);
                  })
                })
              }
              .padding({ left: 16 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)

            Row() {
              Text('热门标签')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            }
            .width('100%')
            .padding({ left: 16, right: 16 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.topics, (item: string, index: number) => {
                Text(item)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .backgroundColor(this.getTagBgColor(index))
                  .borderRadius(20)
                  .margin({ right: 10, bottom: 10 })
                  .onClick(() => {
                    this.handleTagClick(item);
                  })
              })
            }
            .padding({ left: 16, right: 16 })

            Row() {
              Text('最新讨论')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            }
            .width('100%')
            .padding({ left: 16 })

            Column({ space: 12 }) {
              ForEach([1, 2, 3, 4], (item: number) => {
                Row() {
                  Circle()
                    .width(44)
                    .height(44)
                    .fill(this.getTagBgColor(item))
                  Column() {
                    Text(`关于 ${this.topics[item % this.topics.length]} 的讨论`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${item * 10} 分钟前 · ${item * 5} 人参与`)
                      .fontSize(12)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .margin({ left: 12 })

                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(16)
                    .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#666' : '#999'])
                }
                .width('100%')
                .padding(12)
                .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : '#FFFFFF')
                .borderRadius(12)
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/PostDetailPage',
                    params: { id: item.toString() }
                  });
                })
              })
            }
            .padding({ left: 16, right: 16, bottom: 100 })
          }
        }
        .scrollBar(BarState.Off)
        .onScroll((x, y) => {
          this.scrollY += y;
        })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F9F9F9')
  }

  private getTagBgColor(index: number): ResourceColor {
    const colors = [
      this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,105,180,0.25)' : '#FFF0F5',
      this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,188,212,0.25)' : '#E0F7FA',
      this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(123,104,238,0.25)' : '#F3F0FF',
      this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,165,0,0.25)' : '#FFF8E1',
      this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(52,199,89,0.25)' : '#E8F8E8'
    ];
    return colors[index % colors.length];
  }
}
