import { Post } from '../../model/Post';
import { ConfigurationConstant } from '@kit.AbilityKit';
import router from '@ohos.router';
import { BreakpointSystem } from '../../utils/BreakpointSystem';

@Component
export struct PostWaterFlow {
  @Prop searchResults: Post[] = [];
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  build() {
    Column() {
      WaterFlow() {
        ForEach(this.searchResults, (item: Post) => {
          FlowItem() {
            Column() {
              if (item.images && item.images.length > 0) {
                Image(item.images[0].startsWith('app.media.') ? $r(item.images[0]) : $rawfile(item.images[0]))
                  .width('100%')
                  .height(180)
                  .objectFit(ImageFit.Cover)
                  .borderRadius({ topLeft: 8, topRight: 8 })
              }
              
              Column() {
                if (item.title) {
                  Text(item.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#FFFFFF' : '#333333')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ bottom: 4 })
                }

                Text(item.content)
                  .fontSize(14)
                  .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#CCCCCC' : '#666666')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ bottom: 8 })
                
                Row() {
                  Row() {
                    Image(item.userAvatar.startsWith('app.media.') ? $r(item.userAvatar) : $rawfile(item.userAvatar))
                      .width(16)
                      .height(16)
                      .borderRadius(8)
                      .margin({ right: 4 })
                    Text(item.userName)
                      .fontSize(12)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#999999' : '#999999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)

                  Row() {
                    Image($r('app.media.startIcon'))
                      .width(12)
                      .height(12)
                      .fillColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#999999' : '#999999')
                      .margin({ right: 2 })
                    Text(item.likes.toString())
                      .fontSize(12)
                      .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#999999' : '#999999')
                  }
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
              }
              .padding(12)
              .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
              .borderRadius({ bottomLeft: 8, bottomRight: 8 })
            }
            .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' : '#FFFFFF')
            .borderRadius(8)
            .shadow({ 
              radius: 4, 
              color: this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)', 
              offsetY: 2 
            })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/PostDetailPage',
                params: { id: item.id }
              })
            })
          }
        }, (item: Post) => item.id)
      }
      .columnsTemplate(this.currentBreakpoint === 'xl' ? "1fr 1fr 1fr 1fr" :
                      (this.currentBreakpoint === 'lg' ? "1fr 1fr 1fr 1fr" :
                      (this.currentBreakpoint === 'md' ? "1fr 1fr 1fr" : "1fr 1fr")))
      .columnsGap(12)
      .rowsGap(12)
      .padding({ left: 12, right: 12, top: 60, bottom: 20 })
      .layoutWeight(1)
      .constraintSize({ maxWidth: ['lg', 'xl'].includes(this.currentBreakpoint) ? 1200 : '100%' })
      .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#000000' : '#F5F5F5')
      .clip(false)
    }
    .width('100%')
    .height('100%')
  }
}
