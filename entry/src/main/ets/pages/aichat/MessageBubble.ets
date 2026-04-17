import { ConfigurationConstant } from '@kit.AbilityKit';
import { ChatMessage, MessageSegment } from './types';
import { BRAND_PRIMARY } from '../../constants/ThemeTokens';

@Component
export struct MessageBubble {
  @ObjectLink msg: ChatMessage;
  @StorageProp('currentColorMode') currentMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @Builder
  renderSegments(segments: MessageSegment[]) {
    ForEach(segments, (segment: MessageSegment) => {
      if (segment.type === 'header') {
        Text(segment.content)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
            '#FFFFFF' : '#333')
          .margin({ top: 16, bottom: 8 })
          .copyOption(CopyOptions.LocalDevice)
      } else if (segment.type === 'quote') {
        Text(segment.content)
          .fontSize(14)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
            '#AAAAAA' : '#666')
          .padding(12)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
            '#2C2C2E' : '#F7F8FA')
          .borderRadius(16)
          .margin({ top: 4, bottom: 4 })
          .copyOption(CopyOptions.LocalDevice)
      } else if (segment.type === 'highlight') {
        Column() {
          Text(segment.content)
            .fontSize(15)
            .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
              '#FFECB3' : '#5D4037')
            .lineHeight(24)
            .copyOption(CopyOptions.LocalDevice)
        }
        .padding(12)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          '#4A3B2A' : '#FFF8E1')
        .borderRadius(12)
        .margin({ top: 8, bottom: 8 })
        .alignItems(HorizontalAlign.Start)
      } else {
        Text(segment.content)
          .fontSize(16)
          .lineHeight(28)
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
            '#E0E0E0' : '#333')
          .copyOption(CopyOptions.LocalDevice)
      }
    })
  }

  build() {
    if (this.msg.isUser) {
      this.UserMessageBubble()
    } else {
      this.AiMessageBubble()
    }
  }

  @Builder
  UserMessageBubble() {
    Row() {
      Text(this.msg.content)
        .fontSize(16)
        .lineHeight(24)
        .fontColor(Color.White)
        .padding(12)
        .backgroundColor('BRAND_PRIMARY')
        .borderRadius({
          topLeft: 20,
          topRight: 4,
          bottomLeft: 20,
          bottomRight: 20
        })
        .constraintSize({ maxWidth: '78%' })
        .margin({ right: 16 })
        .copyOption(CopyOptions.LocalDevice)
        .shadow({ radius: 4, color: 'rgba(52, 120, 246, 0.2)', offsetY: 2 })
    }
    .justifyContent(FlexAlign.End)
    .width('100%')
  }

  @Builder
  AiMessageBubble() {
    Row() {
      if (this.msg.segments && this.msg.segments.length > 0) {
        Column({ space: 8 }) {
          this.renderSegments(this.msg.segments)
        }
        .alignItems(HorizontalAlign.Start)
        .padding(12)
        .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#1C1C1E' :
          Color.White)
        .borderRadius({
          topLeft: 4,
          topRight: 20,
          bottomLeft: 20,
          bottomRight: 20
        })
        .constraintSize({ maxWidth: '78%' })
        .margin({ left: 16, right: 16 })
        .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 })
      } else {
        Text(this.msg.content)
          .fontSize(16)
          .lineHeight(24)
          .padding(12)
          .backgroundColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
            '#1C1C1E' : Color.White)
          .borderRadius({
            topLeft: 4,
            topRight: 20,
            bottomLeft: 20,
            bottomRight: 20
          })
          .constraintSize({ maxWidth: '78%' })
          .margin({ left: 16, right: 16 })
          .copyOption(CopyOptions.LocalDevice)
          .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 })
          .fontColor(this.currentMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#E0E0E0' :
            '#182431')
      }
    }
  }
}
