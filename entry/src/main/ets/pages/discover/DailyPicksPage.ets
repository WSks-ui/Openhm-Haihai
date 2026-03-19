import router from '@ohos.router';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { BreakpointSystem } from '../../utils/BreakpointSystem';
import { Post, mockPosts } from '../../model/Post';

@Entry
@Component
struct DailyPicksPage {
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  
  @StorageProp('safeAreaTop') safeAreaTop: number = 0;
  @StorageProp('safeAreaBottom') safeAreaBottom: number = 0;
  
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  
  @State scrollY: number = 0;
  
  @State selectedPosts: Post[] = [];
  
  aboutToAppear() {
    this.breakpointSystem.register();
    this.selectedPosts = mockPosts
      .slice()
      .sort((a, b) => (b.likes + b.commentsCount) - (a.likes + a.commentsCount))
      .slice(0, 12);
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
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
            Text('每日精选')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .margin({ left: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.8)' : 'rgba(255,255,255,0.9)')
          .backdropBlur(20)
          .zIndex(100)
        }

        Scroll() {
          Column({ space: 20 }) {
            Text('每日精选')
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
              .padding({ left: 16, top: 32, bottom: 8 })
              .width('100%')
              .opacity(Math.max(0, 1 - this.scrollY / 40))
              .animation({ duration: 100 })

            Text('精选优质内容，每日更新')
              .fontSize(15)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
              .padding({ left: 16 })
              .width('100%')

            if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
              Grid() {
                ForEach(this.selectedPosts, (post: Post, index: number) => {
                  GridItem() {
                    this.PostCard(post)
                  }
                }, (post: Post) => post.id)
              }
              .columnsTemplate('1fr 1fr')
              .columnsGap(24)
              .rowsGap(24)
              .padding({ left: 24, right: 24, bottom: 100 })
            } else {
              Column({ space: 16 }) {
                ForEach(this.selectedPosts, (post: Post, index: number) => {
                  this.PostCard(post)
                }, (post: Post) => post.id)
              }
              .padding({ left: 16, right: 16, bottom: 100 })
            }
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
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
  
  @Builder
  PostCard(post: Post) {
    Column() {
      if (post.images.length > 0) {
        Stack({ alignContent: Alignment.TopStart }) {
          Image(post.images[0].startsWith('app.media.') ? $r(post.images[0]) : $rawfile(post.images[0]))
            .width('100%')
            .height(this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'md' ? 200 : 160)
            .borderRadius(16)
            .objectFit(ImageFit.Cover)
          Column()
            .width('100%')
            .height(this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'md' ? 200 : 160)
            .borderRadius(16)
            .linearGradient({
              direction: GradientDirection.Top,
              colors: [
                ['rgba(0,0,0,0)', 0],
                ['rgba(0,0,0,0.6)', 1]
              ]
            })
          if (post.likes > 100) {
            Text('#热门')
              .fontSize(12)
              .fontColor(Color.White)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor('rgba(123, 104, 238, 0.9)')
              .borderRadius(12)
              .margin(12)
          }
        }
        .width('100%')
        .height(this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'md' ? 200 : 160)
        .borderRadius(16)
        .clip(true)
      }

      Column({ space: 10 }) {
        if (post.title && post.title.length > 0) {
          Text(post.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#182431')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Text(post.content)
          .fontSize(14)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#AAAAAA' : '#666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(20)
          .width('100%')

        Row() {
          Row() {
            Image($rawfile(post.userAvatar))
              .width(24)
              .height(24)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
            Text(post.userName)
              .fontSize(13)
              .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
              .margin({ left: 8 })
          }
          .alignItems(VerticalAlign.Center)
          .layoutWeight(1)

          Row({ space: 12 }) {
            Row({ space: 4 }) {
              SymbolGlyph($r('sys.symbol.heart'))
                .fontSize(14)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999'])
              Text(post.likes.toString())
                .fontSize(13)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
            }

            Row({ space: 4 }) {
              SymbolGlyph($r('sys.symbol.message'))
                .fontSize(14)
                .fontColor([this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999'])
              Text(post.commentsCount.toString())
                .fontSize(13)
                .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#888' : '#999')
            }
          }
        }
        .width('100%')
      }
      .padding(16)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(255,255,255,0.08)' : '#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.08)',
      offsetY: 4
    })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/PostDetailPage',
        params: { id: post.id }
      })
    })
  }
}
