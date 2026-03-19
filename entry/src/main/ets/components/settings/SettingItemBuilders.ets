import { ConfigurationConstant } from '@kit.AbilityKit';
import { SettingItem } from '../../types/SettingsTypes';

@Builder
export function SettingItem(title: string, hasArrow: boolean = true, onClick?: () => void) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontColor('#333333')
      .layoutWeight(1)

    if (hasArrow) {
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor(['#CCCCCC'])
    }
  }
  .width('100%')
  .height(52)
  .padding({ left: 16, right: 16 })
  .onClick(() => {
    if (onClick) {
      onClick();
    }
  })
}

@Builder
export function SettingGroup(items: SettingItem[]) {
  Column() {
    ForEach(items, (item: SettingItem, index: number) => {
      SettingItem(item.title, item.hasArrow !== false, item.onClick)
      if (index < items.length - 1) {
        Divider()
          .color('rgba(0,0,0,0.05)')
          .margin({ left: 16, right: 16 })
      }
    })
  }
  .width('100%')
  .backgroundColor('#FFFFFF')
  .borderRadius(16)
}

@Builder
export function ToggleSettingItem(title: string, value: boolean, onChange: (val: boolean) => void) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontColor('#1C1C1E')
      .fontWeight(FontWeight.Medium)
    Blank()
    Toggle({ type: ToggleType.Switch, isOn: value })
      .selectedColor('#7B68EE')
      .onChange((isOn: boolean) => {
        onChange(isOn);
      })
  }
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 20 })
}

@Builder
export function ArrowSettingItem(title: string, onClick: () => void) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontColor('#1C1C1E')
      .fontWeight(FontWeight.Medium)
    Blank()
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(20)
      .fontColor(['#C7C7CC'])
  }
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 20 })
  .justifyContent(FlexAlign.Start)
  .onClick(() => {
    onClick();
  })
}

@Builder
export function EditProfileItem(title: string, value: string, onChange: (val: string) => void) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontColor('#1C1C1E')
      .fontWeight(FontWeight.Medium)
    Blank()
    TextInput({ text: value })
      .layoutWeight(1)
      .backgroundColor(Color.Transparent)
      .textAlign(TextAlign.End)
      .fontColor('#333333')
      .maxLines(1)
      .onChange(onChange)
  }
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 20 })
}

@Builder
export function EditProfileInfoItem(title: string, value: string) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontColor('#1C1C1E')
      .fontWeight(FontWeight.Medium)
    Blank()
    Text(value)
      .fontSize(16)
      .fontColor('#8E8E93')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 20 })
}

@Builder
export function EditProfileSelectItem(title: string, value: string, onClick: () => void) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontColor('#1C1C1E')
      .fontWeight(FontWeight.Medium)
    Blank()
    Text(value)
      .fontSize(16)
      .fontColor('#8E8E93')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(20)
      .fontColor(['#C7C7CC'])
      .margin({ left: 8 })
  }
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 20 })
  .onClick(() => {
    onClick();
  })
}

@Builder
export function EditProfileArrowItem(title: string, onClick: () => void) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontColor('#1C1C1E')
      .fontWeight(FontWeight.Medium)
    Blank()
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(20)
      .fontColor(['#C7C7CC'])
  }
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 20 })
  .onClick(() => {
    onClick();
  })
}
